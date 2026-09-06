我希望你使用 `/mattpocock-skills:wayfinder` 来为当前 Flutter 记账应用规划一次架构迁移。

请注意：这一步只做 wayfinding，不直接实现代码。目标是产出一张清晰的 decision map，列出迁移到 CQRS + Event Sourcing 所需解决的关键架构决策，并逐个决策，直到后续可以进入 spec / tasks / implement 阶段。

## 背景

当前项目是一个移动端财务管理 / 记账应用，技术栈大致为：

* Flutter
* Riverpod
* Drift / SQLite
* Feature First 目录结构
* 目标架构：DDD + CQRS + Event Sourcing
* 需要支持账务交易、账户、分类、月度报表、余额、未来可能支持信用卡、预算、多币种、同步/备份

我希望本次迁移遵守以下原则：

1. 遵守 DDD 分层和建模规范
2. 采用 Feature First，而不是按技术层横向堆目录
3. 写侧通过 Command / UseCase / Domain / Event Store 表达业务事实
4. 读侧通过 Projection / Read Model 服务 UI
5. Event Store 是事实来源，Projection 和 Snapshot 都是可重建的派生数据
6. 每月保存账户余额快照，但快照不能替代事件流
7. 账务数据必须可追溯、可重放、可校验
8. 金额必须使用最小货币单位整数表示，不能使用 double / float
9. 转账不能污染收入支出统计
10. 信用卡还款不能被重复计为支出
11. 分类、账户等历史引用不能因为软删除而导致历史交易失真

## 迁移目标

请为我规划从当前代码库迁移到以下目标架构的路线：

```text
lib/
  core/
    database/
    event_sourcing/
    money/
    result/
    clock/

  features/
    ledger/
      domain/
        value_objects/
        entities/
        aggregates/
        commands/
        events/
        services/
        repositories/

      application/
        usecases/
        dto/

      data/
        event_store/
        projections/
        mappers/
        migrations/

      presentation/
        screens/
        viewmodels/
        widgets/

    reports/
      application/
      data/
      presentation/

    settings/
```

其中 `ledger` 是核心领域。`reports` 原则上只读取 ledger 的 projection，不直接修改账务状态。`settings` 不需要强行事件化，普通 CRUD 即可。

## 目标账务模型

请优先评估并决定以下账务模型是否合理：

* 内部采用接近复式记账的 `Transaction + Postings` 模型
* UI 可以展示为收入、支出、转账、信用卡消费、信用卡还款
* 底层不应拆成 `income_table`、`expense_table`、`transfer_table` 三套逻辑
* 一笔交易应包含多个 posting
* 每个 posting 至少包含：

  * accountId
  * amountMinor
  * currencyCode
  * direction / signed amount
  * categoryId 可选
  * memo 可选

请决定：

1. 是否采用 signed amount，还是 debit / credit 方向字段
2. `Transaction`、`Account`、`Category` 是否作为 Aggregate
3. 是否需要单独的 `Ledger` Aggregate 或 Domain Service
4. 余额是否只保存在 Projection 中
5. 交易修改是用 `TransactionCorrected`，还是用 `TransactionReversed + TransactionRecorded`
6. 删除交易在 UI 层如何表达，在事件层如何表达

## Event Store 目标

请规划 Event Store 表结构和事件命名。

初始事件至少包括：

* AccountCreated
* AccountRenamed
* AccountArchived
* CategoryCreated
* CategoryRenamed
* CategoryArchived
* TransactionRecorded
* TransactionReversed

请决定是否还需要：

* TransactionCorrected
* OpeningBalanceSet
* MonthClosed
* MonthReopened
* MonthlyBalanceSnapshotGenerated
* ProjectionRebuilt

Event Store 至少需要考虑：

* eventId
* streamId
* aggregateId
* aggregateType
* eventType
* eventVersion
* streamVersion
* globalSequenceNumber
* payloadJson
* metadataJson
* occurredAt
* recordedAt
* commandId / correlationId / causationId
* schemaVersion

请明确：

1. Drift 中应如何建表
2. 是否需要 stream version 做并发控制
3. 本地单机应用中是否仍需要 commandId 做幂等
4. 写入事件和更新 projection 是否应放在同一个数据库事务中
5. 如果 projection 更新失败，应如何恢复
6. 如何支持事件 schema 版本升级

## Projection 目标

请规划最小可运行的读模型。

MVP 阶段至少需要：

* accounts_view
* transactions_view
* transaction_postings_view
* categories_view

后续需要：

* monthly_account_balance_snapshots
* monthly_category_summaries
* monthly_cashflow_view
* account_balance_history_view

请决定：

1. 哪些 projection 是第一阶段必须实现
2. 哪些 projection 可以第二阶段再实现
3. projection 如何从事件重建
4. projection_version 如何设计
5. 如何测试 projection 的正确性
6. UI 是否只能读取 projection，不能直接读取 event store

## 每月余额快照目标

我希望保存每月账户余额快照，但它只能作为派生数据，不是事实来源。

请重点设计：

```text
monthly_account_balance_snapshots
```

建议字段包括：

* id
* accountId
* currencyCode
* year
* month
* openingBalanceMinor
* closingBalanceMinor
* incomeMinor
* expenseMinor
* transferInMinor
* transferOutMinor
* netChangeMinor
* transactionCount
* eventSequenceFrom
* eventSequenceTo
* projectionVersion
* isClosed
* createdAt
* updatedAt
* rebuiltAt

请决定：

1. 是否按 account + currency + year + month 建唯一约束
2. openingBalance 和 closingBalance 如何计算
3. 修改历史交易后，如何重建受影响月份及之后月份的快照
4. 是否第一阶段就实现 `isClosed`
5. 个人记账 App 是否需要严格月结
6. `MonthClosed` 后是否允许修改历史交易
7. 如果未来支持多币种，快照如何避免错误合并

## 迁移路线

请不要直接给一个大重构方案。请把迁移拆成几个可验证的纵向切片。

我希望优先级类似：

1. 引入 Money / Currency Value Object
2. 引入 Event Store 基础表和事件序列化
3. 用 `TransactionRecorded` 打通“新增支出”闭环
4. 用 projection 生成交易列表和账户余额
5. 支持收入
6. 支持转账
7. 支持交易冲正 / 删除
8. 支持分类软删除
9. 支持月度账户余额快照
10. 支持 projection rebuild
11. 支持月度报表
12. 再考虑信用卡、预算、多币种

请为每个阶段输出：

* 需要决策的问题
* 推荐决策
* 影响范围
* 涉及文件 / 目录
* 验收标准
* 迁移风险
* 是否可以独立提交
* 是否需要数据迁移

## 特别需要避免的财务错误

请在 map 中显式跟踪以下风险，并为每个风险给出规避决策：

1. 金额使用 double / float
2. 收入、支出、转账使用三套底层模型
3. 转账被统计为收入或支出
4. 信用卡还款重复计入支出
5. 删除交易导致审计链断裂
6. 修改历史交易后月度快照不更新
7. projection 和 event store 不一致
8. 分类硬删除导致历史交易丢失分类名
9. 未来日期交易影响当前余额定义不清
10. 多币种余额被错误合并
11. UI 直接修改 read model
12. 账户余额由多个地方重复计算

## 输出要求

请使用 wayfinder 的方式工作：

1. 先读取当前代码库结构
2. 找到现有账务、账户、分类、数据库、状态管理相关代码
3. 创建或更新 wayfinder map
4. 把未知问题拆成 decision tickets
5. 每个 ticket 只解决一个架构决策，不要变成实现任务
6. 决策完成后，把结果汇总到 map
7. 最终输出一条清晰路线：后续如何进入 spec / tasks / implement

不要在本阶段直接改业务代码。

如果当前仓库缺少 issue tracker 配置，则使用 local-markdown 方式保存 map 和 tickets。
