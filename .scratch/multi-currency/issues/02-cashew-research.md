# 参考 Cashew 的多币种机制
Type: research
Label: wayfinder:research
Status: resolved
Assignee: cashew_research

## Question

从项目的一手文档和源码核实账户币种、跨币转账、汇率、精度及报表的实际设计；哪些有助于本项目，哪些不应照搬？

## Answer

Cashew 使用单币种账户，并以主账户币种和可自定义汇率折算汇总；转账关联两笔交易，账户可配置小数精度。其交易金额使用浮点数，不宜直接照搬到本项目的整数事件模型。历史转账汇率的维护者说明来自 2024 年，不能未经核实地当作当前版本行为。

一手来源、细节与适用边界见 [Cashew 多币种调研](../research/cashew.md)。
