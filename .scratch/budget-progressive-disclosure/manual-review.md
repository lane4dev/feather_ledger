# Budget progressive disclosure — manual review

Run this on a real device (or a simulator with real fonts) before merge. The
automated suite in `test/ui/features/budget/` covers layout, copy wiring and
navigation, but it runs on the test font (every glyph is a square) and cannot
judge gradients, hairlines, motion feel or how the shipped typeface wraps.

Budget pages: **L1** = `/budget` home, **L2** = monthly review, **L3** = category
detail. The clock used by every check is the device clock; to pin a mode move
between the current month, a past month and a future month with the arrows or
the month picker.

## 1. Smallest target + large text

- Page: L1 (track month, and a plan month)
- Viewport: 320 dp wide, system text 1.6x (accessibility "Largest")
- Look at: overview card, row names/amounts, "+" button, review entry
- Expected: no clipping or overlapping text, nothing scrolls horizontally,
  every row still tappable, overview amount scales down instead of overflowing.
  Density is deliberately lower here: the rows stack their amount under the name
  and only ~1 row fits beside the overview. Confirm that reading order still
  makes sense.
- [ ] pass  [ ] fail — notes:

## 2. Traditional Chinese copy length

- Page: L1, L2, L3
- Viewport: 400x700 and 320x700, language 繁體中文 (zh_Hant)
- Look at: month label, overview labels and footer metrics, review entry line,
  trend legend, note editor counter, clear-dialog body
- Expected: no ellipsized label except the deliberate single-line note preview;
  dialog copy fits without a scrollbar; no English leaks.
- [ ] pass  [ ] fail — notes:

## 3. Rendering at 1x and 3x DPR

- Page: L1 overview (track, plan, review months) and one category row with an
  anomaly marker
- Viewport: same device, compare DPR 1 (or emulator) against the real 3x screen
- Look at: the overview gradient and hairline border, the diagonal hatch over
  the plan-mode baseline, the 2 dp today tick, the 6 dp anomaly dot
- Expected: gradient is smooth with no banding, the baseline hatch reads as a
  diagonal stripe (not a moiré smear) at both densities and its segment edges
  stay square, tick and dot are crisp (not blurry or invisible), anomaly dot is
  the amber warning colour rather than the red expense colour.
- [ ] pass  [ ] fail — notes:

## 4. Motion and reduce-motion

- Page: L1 → L2 → L3 and back
- Viewport: 400x700
- Look at: the 250 ms overview surface cross-fade when switching modes, the L2
  enter/exit transition
- Expected: ~250 ms, no jank on a mid-range device, back gesture reverses
  smoothly. With the system "remove animations" setting on, both transitions
  become instant (no half-faded frame, no slide).
- [ ] pass  [ ] fail — notes:

## 5. Assertion suite vs. device eyeball

- Page: L1 track, L1 plan, L2, L3
- Viewport: 400x700, light and dark
- Look at: the same properties the automated visual-regression test asserts
  (three-tier amount, hatched baseline, today tick, anomaly colour, legend)
- Expected: device matches what the assertions describe. There are no image
  goldens in this repository (the test font would make them meaningless), so
  this pass is the only pixel-level comparison.
- [ ] pass  [ ] fail — notes:

## 6. Review-bar density in a historical month

- Page: L1 in a past month (review mode), and the tracked month
- Viewport: 400x700
- Look at: the compact review bar directly under the overview, then the
  budgeted/unbudgeted groups below it
- Expected: the bar reads as one line with the worst overrun (or surplus/quiet
  copy), a note preview when one exists, and it does not push the first
  category row off the screen. Tapping it opens L2 for that same month.
- [ ] pass  [ ] fail — notes:

## 7. Note-preview truncation

- Page: L1 review bar with a long month note (L2 editor, >40 characters)
- Viewport: 400x700 and 320x700
- Look at: the note preview line
- Expected: one line, ends with an ellipsis at a word boundary, never clips
  mid-glyph, and the full note remains readable in L2.
- [ ] pass  [ ] fail — notes:

## 8. Bottom gap above the navigation bar

- Page: L1 any mode, scrolled to the end
- Viewport: device with a gesture bar (and one with 3-button nav)
- Look at: the last action (review entry / plan hint / unbudgeted action)
- Expected: at least 88 dp of clearance; the last row is fully above the bar
  and still tappable, including with the gesture bar inset applied.
- [ ] pass  [ ] fail — notes:

## 9. Known deliberate deviations (do not report as bugs)

- No chevron on category rows: the month arrows own the chevron glyph, so rows
  are recognised by their amounts and tap behaviour.
- Plan-mode baseline wording reuses the committed-baseline copy
  ("Committed…") instead of inventing a second "baseline" term.
- `test/ui/app/floating_choice_test.dart` fails before and after this ticket
  (`Expected: <48> Actual: <56.0>`); it is unrelated to the budget work and was
  left untouched.
- 320 dp @1.6x shows one full row next to the overview; density is traded for
  legibility at that size on purpose.

## 10. L2 review page refinements

- Month capsule: scroll the review page up; the app bar takes a shallow
  `surfaceContainer` tint and the month pill never clips or jumps.
- Composition card: subtitle on top, equal-width 固定支出 / 弹性支出, the 6 dp
  strip shows both shares, and the baseline row sits under a hairline divider.
  A historical month with no pending bills shows no baseline row.
- Attribution: no ✨, 按已入账口径 sits beside both TOP headings, icons are
  circular tonal badges.
- Trend: note dots sit centred under their month labels; three light Y ticks
  appear; tapping a bar shows the actual/budget tooltip.
- Note preview: an empty month shows the dashed 20 dp card with the pen badge,
  `记一句本月复盘`, and the `+ 添加` pill; a saved note shows the notebook icon,
  the primary vertical bar, and `更新于 …` under the text.
- [ ] pass  [ ] fail — notes:

## 11. Budget app bar scroll tint

- Pages: L1 month list and L2 review
- Scroll down: the app bar turns a shallow `surfaceContainer`; scroll back to
  the top and it returns to the page surface with no shadow or jump.
- [ ] pass  [ ] fail — notes:

## 12. Month review note card and sheet

- Page: L2 月度复盘与趋势, bottom of the page
- Light and dark, 400x700, plus one narrow 320 dp device.
- Empty month: 20 dp card with a 1 dp dashed `outlineVariant` border, 36 dp
  tonal pen badge, two-line prompt, and a `+ 添加` pill; no `(最多 500 字)`
  placeholder anywhere on the card.
- Saved note: `surfaceContainerLow` card, 13 sp `onSurfaceVariant` header with
  the notebook icon, a 34 dp tonal pencil on the right, a 3 dp `primary` bar
  beside 15 sp / 1.6 text capped at five lines, and `更新于 M月d日`.
- Tapping anywhere on either card opens the sheet; tapping the pencil opens the
  same sheet.
- Sheet: 28 dp top radius, centred drag handle, month pill beside the title,
  delete icon only when a note already exists. The input sits on a white
  (`surfaceContainerLowest`) 16 dp inset with a 14 dp visual gutter on all four
  sides; the cursor lands in the field on open.
- Counter: hidden at 399 characters, appears softly at 400 (`400/500`), turns
  `error` above 500 and disables 保存.
- Empty field: three chips (大额支出原因 / 下月调整 / 结余心得); tapping one
  inserts its prefix at the cursor and the chips disappear.
- Keyboard: summon the soft keyboard; 取消 and 保存 stay fully above it on a
  700 dp-tall viewport and on a 320 dp-wide device.
- Delete: the trash icon clears the note, closes the sheet, shows
  `复盘备忘已删除` with 撤销, and 撤销 restores the previous text.
- [ ] pass  [ ] fail — notes:

## 13. The hero as the review's door

- Page: L1 预算, tracked and closed months, plus the planned month.
- The independent 月度复盘与趋势 card is gone from the bottom of a tracked month
  and from under the hero of a closed month; the page ends with 计划外支出 for
  a tracked month and with the plan hint for a future one.
- Track and review: a 16 dp `onSurfaceVariant` chevron sits to the right of the
  `达标率 x/y` pill; tapping anywhere on the hero ripples with the card's 24 dp
  corners and pushes L2. Coming back lands on the same month.
- Plan: no chevron, and tapping the hero does nothing — no ripple, no push.
- A month with a note shows one clipped line under the footer, separated by a
  40%-alpha `outlineVariant` hairline: 14 dp notebook-pen icon, then the note
  with `…` at the first line's end. A month without a note shows no extra row,
  and the card keeps its compact height.
- [ ] pass  [ ] fail — notes:

## 14. The category note uses the month-note surface

- Page: L3 分类详情, a category with a saved note and a category without one.
  Check light and dark at 400 dp, plus 320 dp at 1.6x text.
- Saved note: the card is visually identical to the one on L2 (L2 月度复盘 →
  月度复盘备忘), with `分类复盘备忘` as the header label, a 34 dp tonal pencil,
  the 3 dp `primary` bar and five-line clamp. There is no standalone section
  title above it and no inline text field on the page.
- Empty note: the same dashed prompt as L2, with `记一句这个分类的复盘` and the
  shared subtitle, plus the `+ 添加` pill. Tapping it opens the editor.
- Editor: the same modal sheet as L2 — drag handle, `分类复盘备忘` title, a pill
  carrying the category name instead of the month, the 500-character counter,
  the three quick-note chips and the pinned 取消 / 保存 row.
- Delete: the trash icon appears only when a note exists; it clears the note,
  closes the sheet, and offers 撤销 like the month note.
- Archived category: the note renders as the same saved card but with no pencil
  (the card is inert), followed by the `已归档` read-only hint; an archived
  category without a note shows only the hint.
- Clearing the budget removes the note without leaving a stale card: the prompt
  replaces the saved card and the chart marker disappears in the same frame.
- [ ] pass  [ ] fail — notes:
