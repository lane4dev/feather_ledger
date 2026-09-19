# 参考 ezBookkeeping 的多币种机制
Type: research
Label: wayfinder:research
Status: resolved
Assignee: ezbookkeeping_research

## Question

从项目的一手文档和源码核实账户币种、转账、换算、精度、缺失汇率以及报表的实际设计；哪些有助于本项目，哪些过重或不适用？

## Answer

每个账户绑定一种币种；转账可表达独立的目标金额和币种。跨币种统计使用汇率，缺少汇率时排除对应金额并标示汇总不完整；币种元数据记录不同小数位数。可借鉴账户币种归属和缺失数据的明确提示；联网汇率、跨币种转账及历史金额精度迁移需要独立决策。

详细依据与来源见[研究记录](../research/ezbookkeeping.md)。
