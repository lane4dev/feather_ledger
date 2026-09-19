# 多币种现状与风险

以下根据当前代码静态核对；这是观察，不是对目标方案的决定。此前货币设置持久化的修复已进入当前分支，本次规划不修改业务代码。

- **账户及写路径**：`accounts_view` 为账户保存 `currencyCode` 与余额，`transaction_postings_view` 为每条分录保存 `currencyCode`。写入收支时从所选账户取得币种；转账聚合要求两条分录同币种、等额、方向相反。月度快照按账户、币种、年月分别保存。见 [tables.dart](../../../lib/core/data/database/tables.dart)、[record_transaction_command.dart](../../../lib/features/ledger/domain/commands/record_transaction_command.dart)、[transaction.dart](../../../lib/features/ledger/domain/model/transaction.dart)。
- **设置和账户币种不同**：当前设置保存在本机偏好中；创建账户取当时的设置，账户列表使用账户自己的币种。已有账户不会因设置变化而转换币种。见 [currency_provider.dart](../../../lib/core/presentation/providers/currency_provider.dart)、[account_form_sheet.dart](../../../lib/features/settings/presentation/widgets/account_form_sheet.dart)、[account_ui_model.dart](../../../lib/shared/presentation/models/account_ui_model.dart)。
- **交易显示不一致**：普通收支表单、账户余额编辑使用设置符号；实际写入则使用所选账户的币种。账本时间线、详情及搜索用账本统一符号。设置与账户不同或账本存在不同币种时，这些位置可能误标。见 [transaction_form_screen.dart](../../../lib/features/ledger/presentation/screens/transaction_form_screen.dart)、[ledger_screen.dart](../../../lib/features/ledger/presentation/screens/ledger_screen.dart)、[search_screen.dart](../../../lib/features/ledger/presentation/screens/search_screen.dart)。
- **合计混币**：账本日小计不按币种分组；分类统计和金额热度图不按币种过滤或分组。不同币种的整型金额可能被相加并冠以一个符号。见 [ledger_day_group.dart](../../../lib/features/ledger/presentation/models/ledger_day_group.dart)、[reports_dao.dart](../../../lib/core/data/database/daos/reports_dao.dart)。
- **单币种头部规则不一致**：账本头部在所有账户同币种时用该币种，多币种时使用设置币种，只汇总其中一种；报表月度头部一直按设置币种筛选。同一账本两处可能显示不同范围。见 [ledger_view_model.dart](../../../lib/features/ledger/presentation/view_model/ledger_view_model.dart)、[watch_monthly_snapshot_query.dart](../../../lib/features/ledger/domain/queries/watch_monthly_snapshot_query.dart)、[reports_providers.dart](../../../lib/features/reports/presentation/providers/reports_providers.dart)。
- **精度与历史**：输入和格式化目前所有币种固定乘除 100、显示两位小数。事件 payload 和投影存整数，周期系列与实例另存 CRUD 整数；切换成按币种原生精度解释时不能简单重解读旧整数。见 [money.dart](../../../lib/core/domain/money/money.dart)、[money_format.dart](../../../lib/shared/presentation/money_format.dart)、[tables.dart](../../../lib/core/data/database/tables.dart)。
- **导出与备份**：CSV 服务和纯转换函数保留，CSV 每行输出账户币种代码；目前搜索页未发现调用导出服务的入口，不能假设该入口已可用。现有备份包含数据库与已知偏好；目标方案不备份自动入账开关，并须验证新模型自身的备份恢复及上线后演进，不要求兼容上线前备份。见 [transaction_csv.dart](../../../lib/features/ledger/domain/export/transaction_csv.dart)、[search_screen.dart](../../../lib/features/ledger/presentation/screens/search_screen.dart)、[backup_service.dart](../../../lib/features/settings/domain/services/backup_service.dart)。

## 具体例子

人民币账户支出 ¥10.00、美元账户支出 $10.00 同日发生：两个账户的余额可以分别保存，但现有日小计和分类图表可能把 `1000 + 1000` 直接作为一个币种的 20.00 显示。两个金额不是同一量值，不能据此推断总支出。
