# ezBookkeeping 多币种研究

范围：仅核对官方文档与项目源码；以下为参考事实，不是对 Accounted For 已选方案的决定。

- **币种归属账户。** 官方 FAQ 说明每个账户恰好一种币种，现实中的多币种账户可以用子账户拆分。写入交易时币种由账户决定，而不是每笔独立选择。来源：[FAQ — Unable to set currency when adding a transaction](https://ezbookkeeping.mayswind.net/faq/)。
- **两侧金额及币种。** 官方 MCP 交易接口在转账上表达 destination amount 和 destination currency，并在创建接口提供目标金额字段。它证明目标侧可独立表达；并不单凭此证明全部 UI、手续费或汇率记录行为。来源：[MCP transaction API](https://ezbookkeeping.mayswind.net/mcp/)。
- **缺汇率时明确不完整。** 官方 FAQ 说，跨币种总额依赖汇率，缺某账户币种的汇率时不将其金额纳入总额；交易列表的月度总额用 `+` 标志不完整。统计分析会转换为默认币种，但缺少汇率的交易被排除。来源：[FAQ — missing exchange rates](https://ezbookkeeping.mayswind.net/faq/)。
- **汇率来源与更新。** 支持多个中央银行数据源以及用户手工设置；来源有不同基准币种和更新频率。此能力存在联网/可用性与时效语义，不是一个免费获得的静态配置。来源：[Configuration — Exchange Rates](https://ezbookkeeping.mayswind.net/configuration/)、[Exchange Rates](https://ezbookkeeping.mayswind.net/exchange_rates/)。
- **货币元数据包括小数位数。** 项目的货币表为 JPY 标记 `fraction: 0`，为 JOD 标记 `fraction: 3`，其他币种可为 2。此结论只证实元数据定义；不应据此推断数据库采用何种金额缩放，也不能把 Accounted For 旧日元金额直接按新比例重解释。来源：[currency.ts](https://github.com/mayswind/ezbookkeeping/blob/main/src/consts/currency.ts)。
- **汇率方向须具名定义。** MCP 文档的 `rate_to_base` 是 1 单位该币种可换得多少基准币种，而汇率 HTTP API 的 `rate` 描述为 1 单位基准币种可换得多少该币种。接口不同，不可仅用无方向的“rate”复用。来源：[MCP](https://ezbookkeeping.mayswind.net/mcp/)、[Exchange Rates API](https://ezbookkeeping.mayswind.net/httpapi/exchange_rate_api)。

可供讨论的最小借鉴：账户币种是资金的真实单位；界面先展示原币；跨币种总额须具备明确换算条件或明确标示未纳入。联网汇率、双金额跨币种转账、各币种精度和既有数据迁移均应独立决策，不因参考项目具备就默认引入。
