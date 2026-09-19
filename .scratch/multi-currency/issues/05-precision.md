# 币种精度与既有金额如何兼容
Type: grilling
Label: wayfinder:grilling
Status: open
Blocked by: 01, 02

## Question

首版五种币种统一保留两位小数。如何明确该存储单位与 JPY 标准最小单位的区别，并让新模型的事件、周期数据、CSV 与备份前后一致？未来如切换原生精度，如何保护新模型上线后记录的数据？

## Comments

- 已确认的首版单位与新模型上线后不应重解释既有整数的约束见 [账本金额精度决策](../../../docs/adr/0004-ledger-amount-scale.md)。用户已排除对新模型上线前数据的兼容；新模型备份验证和未来迁移协议仍需决定，此票保持开放。
