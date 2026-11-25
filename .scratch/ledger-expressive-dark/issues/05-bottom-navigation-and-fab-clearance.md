# 05 · 底部导航、FAB 与末条金额避让

Triage: ready-for-agent

Blocked by: 03

关联规格见[账本页 UI 重构](../spec.md)。

## 交付结果

用户可以在账本、预算和更多之间切换，使用加号记账，并在滚动到底时读全最后一笔金额。

## 范围与文件所有权

负责导航壳、LedgerScreen 的 FAB 和 LedgerTransactionList 的尾部留白。接续 03 的页头接线，复用 AppFloatingActionButtonLocation 与主题角色。沿用现有路由、导航栈和空月份滚动规则。

## 验收与测试

- [ ] 底栏仅含「账本 / 预算 / 更多」，背景为 surfaceContainer，选中胶囊为 secondaryContainer。账本选中时使用实心书形，未选中项使用 Lucide 线形图标。设置、备份和恢复仍从更多进入，报表从概览进入。
- [ ] FAB 使用 primaryContainer 与 onPrimaryContainer，点击进入现有新建交易表单。向下浏览时底栏收起，回滚或切月后恢复，底栏动画期间 FAB 位置稳定。
- [ ] 对有流水的月份预留至少 88 dp 可滚动尾距，并计入实际 FAB、底栏和系统安全区。用浅色、暗色及代表性动态色，在 360 dp 和 800 dp 下滚到底，断言最后一个金额边界位于可视区域，且与 FAB、可见底栏均无交集。
- [ ] 扩展导航滚动与更多页 Widget Tests，覆盖末日仅一笔、底栏收起与恢复、删除最后一笔后的空月。空月维持原有提示及滚动行为，关闭设置返回更多。
