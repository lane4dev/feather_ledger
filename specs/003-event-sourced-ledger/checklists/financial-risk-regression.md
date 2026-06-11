# 财务风险回归矩阵（12 项核销表，spec 003 / T075）

> 每项风险至少一条 G/W/T（Given/When/Then）回归测试钉死。测试文件路径相对仓库根；全部经
> `LedgerService`/`AccountService` 服务接缝驱动（spec 单一接缝策略）。全量运行：
> `flutter test`（Phase 12 终验全绿，见 quickstart.md）。

| # | 风险 | Given | When | Then | 钉死测试 |
|---|------|-------|------|------|----------|
| 1 | 金额 double/float 漂移 | 输入 10.50 元支出 | 提交记账 | 写入一条 debit posting=1050 minor units，余额减 1050 | `test/unit/features/ledger/domain/services/record_transaction_test.dart`（10.50→1050）；`test/unit/core/domain/money/money_test.dart`（币种不匹配拒绝、double 禁止） |
| 2 | 收支转三套模型互相漂移 | 任意 Transaction+Postings 事件流 | 投影后核对 | income/expense 单腿、transfer 双腿且方向/金额不变量成立 | `test/unit/features/ledger/domain/events/ledger_event_test.dart`；`transaction.dart` validate 经 `test/unit/features/ledger/domain/services/record_transaction_test.dart` 覆盖 |
| 3 | 转账污染收支统计 | 一月内记录 1 笔支出 + 1 笔 A→B 转账 | 读取月度汇总 | expense=-支出额、income=0（`kind == transfer` 唯一排除口径） | `test/unit/features/ledger/domain/ledger_transfer_test.dart`（transfer is excluded from income/expense monthly totals） |
| 4 | 信用卡还款重复计支出 | 储蓄→信用卡转账 25000 | 读取月度统计 | expense=0、income=0；信用卡余额 +25000（还款=转账语义） | `test/unit/features/ledger/domain/ledger_transfer_test.dart`（savings→credit repayment is a transfer, not an expense） |
| 5 | 删除交易断审计链 | 记录支出后 UI 删除 | 读取事件流 | 原 TransactionRecorded 保留 + TransactionReversed(userDeleted) 追加，列表隐藏、余额回滚 | `test/unit/features/ledger/domain/services/reverse_and_correct_transaction_test.dart`（delete hides the row…） |
| 6 | 修改历史后快照不更新 | 1 月支出 5000，改账为 8000（同月） | 读取 1 月与 2 月快照 | 1 月 expense=-8000 且 2 月 opening=1 月 closing（级联重锚） | `test/unit/features/ledger/domain/services/monthly_snapshot_test.dart`（correction and deletion cascade through following months） |
| 7 | 投影与事件存储不一致 | 固定+随机操作序列（含修改/删除/转账） | clear 后按 GSN 全量重放 | 四个投影+快照逐字段等价；事件流不被触碰 | `test/unit/features/ledger/domain/services/projection_rebuild_equivalence_test.dart` |
| 8 | 分类硬删除/归档失真 | 交易已记录，分类随后归档并改名 | 读取报表分类分组 | 仍按交易行写时快照显示原名/图标/颜色 | `test/unit/features/reports/data/repositories/reports_repository_test.dart`（groups by write-time snapshot, surviving category archival） |
| 9 | 未来交易余额定义不清 | 当前月记录下月交易 | 读取当前余额与快照 | 余额=全部未冲正 posting 之和（含未来交易），未来月行物化 | `test/unit/features/ledger/domain/services/record_transaction_test.dart`（future balance）；`monthly_snapshot_test.dart`（opening balance anchors…） |
| 10 | 多币种错误合并 | 两个不同币种账户发起转账 | 提交转账 | 拒绝（currencyMismatch）且零写入 | `test/unit/features/ledger/domain/ledger_transfer_test.dart`（cross-currency transfer is rejected） |
| 11 | UI 直改 read model | 全库写路径 | 审计写入口 | 事件化投影只由投影器写；UI 只 watch 投影、写走命令（conversion 的 CRUD 状态更新为唯一豁免，与事件同事务） | `projection_rebuild_equivalence_test.dart`（重放确定性=单写者）+ `convert_scheduled_to_posted_test.dart`（豁免行同事务翻转）；T072/T073 `rg` 审计零残留 |
| 12 | 余额多处重复计算 | 含期初/收支/转账/冲正的脚本化历史 | 对账不变量 | Σ live posting 增量=账户余额−期初；transfer 净额零；冲正不进统计；逐月 opening=上月 closing | `test/unit/features/ledger/domain/services/ledger_invariants_test.dart` |

## 核销口径

- 全部 12 项在 `flutter test` 全量运行中有对应断言；#11 同时依赖 T072/T073 的 `rg` 审计结论（旧写入口零残留，见 tasks.md 核销基线）。
- 迁移治理约束见 `.specify/memory/constitution.md` 原则 VII（事件溯源纪律）与 `AGENTS.md` 的最终架构描述（T074）。
