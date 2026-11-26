# 07: ADR 与文档对齐及全量回归收口

Triage: ready-for-agent
Status: resolved

**Blocked by:** 03 · 远期虚拟账单按需落库与预算详情交互, 05 · 远过去起点保存确认与历史回填护栏, 06 · 休眠重启历史回填上限与自动入账熔断

关联规格见 [spec.md](../spec.md)。

**What to build:** 在所有周期物化与预算虚拟投影能力落地后，同步更新滞后的工程文档与架构决策记录（ADR），并执行全量静态分析与全量测试套件回归，确保代码、术语表、ADR 与测试完全一致。

## 验收标准

- [x] 修订或补充 ADR-0005：明确 `occurrence_key` 的本地日历日 `YYYY-MM-DD` 语义、`materialize_from` 与 `completed_count_offset` 职责、以及远期虚拟账单按需落库（Materialize-on-Write）约定；如有新术语（或现有术语边界变化），同步核对并对齐 `CONTEXT.md`。
- [x] 全面更新仓库根 `AGENTS.md` 中严重滞后的「周期与预约交易」章节，使其与当前实际代码（本地日历日展开、当月+未来 2 个完整自然月物化、预算双层 Overlay 投影、远过去确认、休眠 12 月/100 条天花板与 30 天/10 笔自动入账熔断、二元作用域与稀疏覆盖、首期不默认即时入账）100% 一致。
- [x] 清理规格落地后遗留的死代码与废弃注释（如旧的 90 天/`[3, 12]`/`maxKeep = 3` 注释及不再使用的降级提示测试辅助代码）。
- [x] 全量运行 `flutter analyze`（无 error 与 warning）与完整 `flutter test` 回归套件全部通过。
