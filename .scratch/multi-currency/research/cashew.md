# Cashew 多币种参考调研

调查对象：[Cashew 官方 FAQ](https://cashewapp.web.app/faq.html)、[数据库表源码](https://github.com/jameskokoska/Cashew/blob/main/budget/lib/database/tables.dart) 及维护者公开说明。以下是参考项目的行为，不是 Accounted For 已有的能力。

- 每个账户一个币种；选定的主账户决定默认账户与汇总币种，其他账户按汇率转换到主账户币种。FAQ 同时介绍了录入时将外币转成本位币并保存转换后金额的方式，随后汇率变化不会改写这笔已记录金额。[FAQ：Accounts / Multiple Currencies](https://cashewapp.web.app/faq.html#multiple-currencies)
- 汇率可手工自定义，FAQ 表示未自定义时使用每日更新的外部汇率。合并后的报表因此依赖数据来源与获取时间，需要在目标应用中明确离线、过期、缺失汇率的处理。[FAQ：Custom Currencies](https://cashewapp.web.app/faq.html#multiple-currencies)
- 转账是关联的一对交易，排除在收入和支出汇总之外。[FAQ：Transfers Between Accounts](https://cashewapp.web.app/faq.html)；源码的 `Transactions` 表有 `pairedTransactionFk`。[数据库表](https://github.com/jameskokoska/Cashew/blob/main/budget/lib/database/tables.dart)
- 2024 年维护者解释跨币转账用创建时当期汇率形成两侧金额；历史日期也使用当前汇率，需手工修正。该说明是历史行为证据，不能单凭此断言当前所有版本仍如此。[维护者说明](https://github.com/jameskokoska/Cashew/issues/312)
- FAQ 的小数精度是每账户配置，控制输入和显示；源码 `Wallets` 有 `currency`、`decimals`，而 `Transactions.amount` 使用 `RealColumn`。[FAQ：Decimal Precision](https://cashewapp.web.app/faq.html)、[数据库表](https://github.com/jameskokoska/Cashew/blob/main/budget/lib/database/tables.dart)。这不是照搬为 Accounted For 数据模型的理由：本项目当前事件和投影使用整数金额，转换历史语义及小数位迁移应单独设计。

建议讨论的决策是：先按币种分别汇总以避免错误混加，还是引入需要标注来源和时间的估值；若未来支持跨币转账，记录真实的转出与转入金额并保持可审计，而不是依赖未来变化的汇率重算历史。
