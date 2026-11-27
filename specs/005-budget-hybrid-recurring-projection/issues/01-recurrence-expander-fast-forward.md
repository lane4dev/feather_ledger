# 01: 高频周期规则的周期快进优化与历史起点相位对齐

**What to build:** 优化共享周期推演引擎（`RecurrenceExpander`），使无总次数上限（`countLimit == null`）的高频周期规则（`DAILY`、`WEEKLY` 及其自定义间隔与多星期 `BYDAY`）在展开远期目标月份（如多年前起点查询未来 24 个月）时，能够按整周期数学快进至目标窗口附近再逐期展开，消除线性遍历中间历史日期造成的卡顿；同时在新建或编辑历史起点规则（`startDate < materializeFrom`）时严格保持以 `startDate` 为相位与次数锚点。

**Blocked by:** None (can start immediately)

**Status:** resolved

## 修改范围与涉及页面
- **修改范围**：共享周期推演内核（`RecurrenceExpander`）及其纯领域单元测试。
- **涉及页面**：无直接 UI 修改；间接保障预算页（`/budget`）与记账表单提示条在存在长期高频规则时切换远期月份流畅响应。

## 必须遵循的设计规范
- 遵循 **ADR-0005** 与 **ADR-0008**：所有周期步进继续基于无时区偏移的本地日历日（local civil date）推演，输出本地 `YYYY-MM-DD` 的 `occurrenceKey`，严禁引入 UTC 午夜偏移或夏令时漂移。
- 保持纯领域无副作用（不依赖数据库与系统时钟）。
- 遵循 **CONTEXT.md** 统一术语（*Recurring series*、*Pending bill exposure*）。

## 必须保留的现有功能或交互行为
- 带总次数上限（`countLimit != null`，含 `completedCountOffset`）的规则必须保持精确的次数锚定与扣减语义，不跳过计数。
- `materializeFrom` 下界截断、`endDate` 闭区间截断、`planned` 单次模式（`'single'`）以及物理物化窗口（`monthsAhead = 1`、Phase 0 历史回填与 Phase 2 `minKeep = 1` 保底）的结果 100% 保持不变。
- `BYDAY` 本地星期解释与跨夏令时本地墙钟时刻保持不变。

## Acceptance criteria
- [ ] 对无 `countLimit` 的 `DAILY`（含 `interval = 1` 与 `interval > 1`）与 `WEEKLY`（含 `interval > 1` 与多 `BYDAY`）规则，从多年前的 `startDate` 展开 `nowYm + 24` 月份时，产出期次与完整逐期步进 100% 一致且不线性遍历中间历史日期。
- [ ] 当历史起点规则设置了 `materializeFrom = today`（如新建远过去周期账单选择“仅从今天起生成”）且 `interval > 1` 时，快进后的周期相位严格对齐 `startDate`，绝不以 `materializeFrom` 作为新相位起点。
- [ ] 带 `countLimit` 的历史分期规则在 `startDate < materializeFrom` 场景下，`startDate .. materializeFrom` 之间消耗的期次仍准确计入总次数上限。
- [ ] 既有 `RecurrenceExpander` 全部纯领域单测与物理物化单测保持 100% 通过。

## Answer

Resolved by `161ef7a perf(recurrence): fast-forward unbounded DAILY/WEEKLY expansion`. `_fastForwardAnchor` skips whole DAILY/WEEKLY periods (anchored to `startDate`, Monday week phase for WEEKLY) when `countLimit == null`; count-limited rules stay linear. 20 expander tests including an independent day-stepping oracle and a 1000-year perf guard pass.
