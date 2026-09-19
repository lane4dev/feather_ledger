# 多币种工程方案可实施性核对

本记录对照当前代码与[工程草案](../engineering-design.md)。它记录已核对的事实和需要证明的性质，不把候选实现或尚未回答的问题当作产品决策。

1. **备份后的来源设备状态不可知。** 周一生成的备份不能知道来源设备周二是否切换币种或关闭开关，也不能知道周三是否已记账；目标设备恢复时的开关只反映目标设备。用户已确认，备份时尚未到期、恢复前已到期的普通期次，符合目标设备当前币种和自动入账开关等条件时纳入恢复确认，不能承诺还原来源设备那段时间的历史。具体算法仍需保留备份中已有的手动与确认状态。问题见[新模型数据完整性与备份恢复](../issues/08-migration.md)。
2. **恢复和本机偏好目前不是一个可恢复提交。** [pending_restore.dart](../../../lib/app/bootstrap/pending_restore.dart) 完成库替换并清理暂存目录后返回恢复出的偏好；[main.dart](../../../lib/main.dart) 随后才应用偏好。若在两步之间中断，不能仅凭现在的顺序证明目标设备设置保留或自动入账屏障已经建立。新协议需明确持久阶段、恢复时机与每个中断点的可重试行为，不能把文件替换和数据库事务视为一个原子操作。
3. **时区与期次身份还需证明。** [project_recurring_events_command.dart](../../../lib/features/ledger/domain/commands/project_recurring_events_command.dart) 使用 UTC 展开规则；现有实例 ID 编码系列和日期的毫秒值。若将来让账单始终跟随设备当地时间，须明确未物化期次在更换时区、夏令时缺失/重复时刻、重启及跨设备恢复后的稳定身份，验证不重复入账、不复活墓碑，也不随意改变既有 ID 规则。候选方案尚不是经过证明的设计。
4. **物化数量上限不适用于全部规则。** 当前无限规则才采用 90 天及 3–12 条的滚动窗口；带结束日期或次数上限的规则使用另一条无该上限的路径。新方案的有界按月查询、暂停超过 12 期和恢复确认测试应分别覆盖有限与无限规则，不能以“所有规则最多 12 行”为前提。
5. **通知协调和入账提交不能假定原子。** 当前 [recurring_reminders.dart](../../../lib/features/ledger/data/notifications/recurring_reminders.dart) 会协调待发送通知；[reminder_response_handler.dart](../../../lib/features/ledger/presentation/notifications/reminder_response_handler.dart) 又有启动时通知动作与补记顺序。恢复确认屏障必须在任何自动入账路径之前生效；通知系统调用失败后应可重试，同时保留用户已确认的已显示通知行为。
6. **账单到交易的关联目前无法单靠事件重建。** 当前 `TransactionRecorded` payload 没有来源账单 ID；[convert_scheduled_to_posted_command.dart](../../../lib/features/ledger/domain/commands/convert_scheduled_to_posted_command.dart) 将关联写在不属于事件溯源的实例行中，而删除系列可能删除该行。用户已选择在新交易事件中记录来源账单及更正关联，让已入账账单的关联可重建；不能按日期、金额或命令 ID 猜测。尚未入账即删除的账单仍没有交易事件，须单独处理其通知状态。
7. **本地日期平移不能直接用本地午夜的时长差。** 当前 [update_recurring_bill_command.dart](../../../lib/features/ledger/domain/commands/update_recurring_bill_command.dart) 的 `_daysBetween` 对两个本地午夜取 `difference(...).inDays`。夏令时转换可能让相邻本地午夜相隔 23 或 25 小时，因此该计算不一定等于日历天数；未来支持当地时间规则时应使用日历日期运算，并用跨越夏令时的系列平移测试证明期次与状态对应正确。

## 建议验证方式

- 对备份生成、文件替换、设置迁移、确认屏障和提示决定之间的每个持久化阶段注入中断并重启，检查没有重复、漏处理或覆盖目标设备本机开关。
- 对不同日期范围、有限次数、结束日期、无限规则分别验证分页的完整性和幂等性；包括暂停超过 12 期。
- 对跨时区、夏令时缺失与重复时间，以及设备墙上时钟调整分别测试，断言逻辑期次身份和永久手动资格不被改变。
- 对通知已显示、尚未触发、账单已记入、更正、删除及系列删除分别测试响应；通知协调失败不能回滚成功入账。
