# 预算主屏、复盘视图与记账提示原型

Type: prototype
Label: wayfinder:prototype
Status: resolved
Triage: ready-for-human
Blocked by: 01, 02, 03

## Question

`/budget` 主屏（当月跟踪态 vs 历史复盘态）、分类下钻页（6 个月趋势 + 固定/弹性明细 + 调参 + Review Note）以及 `TransactionFormScreen` 记账即时提示的界面线框与交互流应如何设计？

## Context

已锚定交互与规范约束：
- 入口：底部导航第 2 个 Tab `/budget`（`BudgetScreen`），加记账表单 `TransactionFormScreen` 内的轻量只读预算提示；
- 顶部：`FeatherMonthPicker` 切月，纯预算执行/复盘总览（不含账户期初/期末余额）；
- 列表分组：「已设预算分类」「未设预算但本月有实际支出或待入账的分类」「其余活跃分类（折叠/添加预算入口）」；历史归档分类仅在存在历史预算或支出时以快照标示展示；
- 遵循 `constitution.md` III 设计系统硬规则（严禁硬编码 `Colors.`、`TextStyle(`、`EdgeInsets(`，使用 `AppCard` / `AppButton` / `AppTextField`、`AppSemanticColors`、`LucideIcons.*`、四语 ARB、金额经 `presentation/mappers/` 或 `models/` 格式化并守 `- $12.34` 符号顺序）。

本票通过低成本文本/ASCII 线框或交互原型（`prototype` 技能）与用户确认：
1. **`BudgetScreen` 当月/未来月（跟踪态）原型**：总览卡数字层级、双段进度条（Actual 实色 + Pending 浅色/区分态）、分类行信息密度与排序、超支预警视觉。
2. **`BudgetScreen` 历史月（复盘态）原型**：复盘摘要卡（达标率、固定 vs 弹性占比、TOP 超支/结余归因、Review Note 入口）与总览 6 个月趋势图的切换/排布方式，防止首屏过度拥挤。
3. **编辑预算 BottomSheet 原型**：展示「上月实际 / 近 3 月均值 / 本月已排期周期底线」辅助芯片（一键填入）、`LedgerAmountInput`、跨月生效选项（来自 [01](01-temporal-budget-rule-and-editing.md)）与移除预算入口。
4. **分类下钻页/抽屉原型**（路由 `/budget/category` 或 BottomSheet）：顶部近 6 个月预算线 vs 实际柱状图（`fl_chart`，带 Review Note 标记）、固定周期 vs 弹性支出分段明细 + 待入账列表、底部/右上快捷「调整预算」与分类 Review Note 编辑。
5. **`TransactionFormScreen` 记账即时预算提示条**：仅在新建/编辑 `expense` 且选中分类时展示的位置、文案模板、未设预算或预算已超支时的极简视觉态（不阻塞记账提交）。

## Answer

经交互原型对比与按应用设计体系收敛（资产：[.scratch/budget/prototype-budget-ui.html](../../.scratch/budget/prototype-budget-ui.html)），锁定以下 UI 与交互设计：

1. **主屏布局（方案 A · 单页叙事流）**：
   - 顶部采用与 `LedgerAppBarTitle` 一致的 `< YYYY年MM月 ▾ >` 切月控件（点击打开 `FeatherMonthPicker`）；当月右上角提供轻量「复盘预览」切换图标与 `+` 新增预算入口；
   - 顶部总览 `AppCard`（`#F6F6F6 / #1C1C1C` 无边框、20px 圆角、`tabular-nums`）：当月/未来月聚焦「预计剩余可用 / 规划总预算」，双段进度条区分实色 `Actual` 与斜纹 `Pending`；历史月或复盘预览自动切换为「月度实耗 / 总预算 + 达标率」，并附「历史逾期未入账提示」与「未设预算支出提示」；
   - 复盘归因卡（历史月自动展开 / 当月按需展开）：「超支 TOP 3」vs「结余 TOP 3」双栏卡片 + 「月度 Review Note」快捷编辑；
   - 「近 6 个月趋势」柱线图（带预算虚线与 Review Note 节点标记点），历史月默认展开、当月默认折叠。
2. **三段分类列表 + 底部折叠未设分类**：
   - 主列表按 `AppCard.group` 依次展示：「已设预算（Track 按风险降序 / Review 按超支降序）」→「未设预算但有发生（点选可补设）」→ 最底部默认折叠的「其余分类（点击设预算 · N）」（展开显示近 3 月均值与「设预算」按钮）。
   - 分类图标复用 `CategoryIcon`（矢量线性图标 + 柔和圆角底色），绝不使用 emoji。
3. **分类下钻形态（高屏占比 BottomSheet）**：
   - 点击任意分类行弹出 ~88% 屏占比 Modal BottomSheet（`sheetRadius = 28px` + 顶部拖拽条），不新增全屏路由；
   - 内容依次为：顶部名称 + 归档/预算状态 + 右上「调预算」入口 → 近 6 个月预算线 vs 实际柱图（含近 3 月均值）→ 本月支出结构（固定 Committed / 弹性 Discretionary / 待入账 Pending）→ TOP 3 贡献交易（带 `固定/弹性` 标签）→ 分类 Review Note 编辑区（已归档分类只读）。
4. **编辑预算 BottomSheet**：
   - 顶部提供「上月实际 / 近 3 月均值 / 固定底线」一键填入芯片、`LedgerAmountInput` 金额输入、「仅本月 / 本月及以后」作用域切换，以及已设预算时的「取消预算」入口。
5. **`TransactionFormScreen` 记账即时提示条**：
   - 仅在新建/编辑 `expense` 且选中分类时内嵌渲染于金额/分类区下方（只读轻量流），覆盖「余量充足 / 含待入账预警 / 已超支 / 未设预算」4 种状态，**永不阻塞记账保存**。
