# 14 · 路线汇总与交接（进入 speckit）

Type: grilling
Status: resolved 2026-09-06（由 spec 采纳）

## Answer

本票被 spec 取代（用户指令提前进入 spec 阶段）：12 风险核销表见 [spec.md](../spec.md) §风险与缓解；切片顺序定稿见 §分阶段路线（P1–P10，每阶段含 G/W/T、独立提交、旧路径删除清单）；独立 route.md 不再产出。
Blocked by: 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13

## Question

收敛票：全部上游决策落定后，汇总为最终迁移路线并交接给 speckit（spec → tasks → implement）。

**需要完成**：
1. **12 项财务风险逐条核销**（map Notes 里的清单）：每项确认「在哪张票、以什么决策规避」，未覆盖项回头补票或记录为已知接受的风险。
2. **切片顺序定稿**：以 wayfinder.md 的 12 步优先级为底（Money VO → Event Store 基础表 → TransactionRecorded 打通新增支出闭环 → 投影生成列表与余额 → 收入 → 转账 → 冲正/删除 → 分类软删除 → 月度快照 → rebuild → 月度报表 → 未来项出图），对照 13 张票的实际决策调整顺序（例如票13 若选 (b)，切片里就没有月结步骤）。
3. **每切片输出**（wayfinder.md「输出要求」）：需要决策的问题（应已全由本 map 解决）、影响范围、涉及文件/目录、验收标准（含「无双轨：旧路径已删」）、迁移风险、是否可独立提交、是否需要数据迁移（默认否——数据可丢弃）。
4. **旧路径删除清单**：现有待删代码盘点——`TransactionPosted` 命名、投影器 legs.first 假设、`PostTransferCommand` / `ReverseTransactionCommand` 绕过路径、`AccountService` reconcile 补账、`getRunningBalance`、double 元实体、`LedgerEvent.fromJson` 测试注册 hack、seeder 直写投影。各自挂进哪个切片的验收标准。
5. **交接产物**：把以上汇总为一份可被 speckit-specify 直接消费的输入（决策表 + 切片表），并确认 wayfinder map 关闭。

**代码指针**：AGENTS.md「Event-sourced ledger model」现状清单（旧路径删除的底稿）；wayfinder.md「迁移路线」全节。

**推荐立场**：本票产出为一份 `specs/003-event-sourced-ledger/mattpocock/route.md`（或按用户偏好放 .scratch），内容 = 决策摘要表 + 12 切片表 + 删除清单；完成后 map 上所有票 resolved，frontier 清空，进入 speckit。
