# Light theme — manual visual review

Scope: the light-only visual upgrade of ledger/budget L1 surfaces, shared cards, bottom navigation,
FAB, Pending pill and the light ledger hero. Dark mode is intended to be pixel-identical.

## What was verified automatically

- `flutter analyze`: no new errors/warnings (same info-level baseline as before the change).
- Design-system, ledger header, ledger visual-regression, ledger navigation, budget overview and
  budget visual-regression suites: all green.
- Budget L2/L3 assertions at 400x700 and 320x700 @1.6, en/zh_Hans/zh_Hant, light and dark.
- Linux desktop captures (temporary, not committed):
  - light ledger — grey canvas, deep-teal hero, white type, teal FAB, white nav + cyan pill
  - light budget L1 — white group card, pale tinted hero, cyan pill
  - light More — white grouped cards on grey
  - light search — grey canvas, `surfaceContainerHigh` field
  - light Add Transaction — white type-selector track with hairline, white field cards

## Needs a human eye

1. **Real phone, 400x700 and 320dp @1.6 text.** Desktop captures cannot reproduce Android insets,
   system bars, or the on-screen keyboard.
2. **Budget L2 review and L3 category detail in light.** Both are assertion-covered but were not
   captured; check the hero-to-list transition, chart grid contrast and the composition bar.
3. **Selected segment fill on Add Transaction** is a dusty rose (`secondaryContainer`). It is the
   existing M3 role, not a new token — confirm it matches the brand rather than reading as disabled.
4. **More → Support center row** renders on `surfaceContainer` (slightly grey) while its neighbours
   are white cards. Confirm the grouping is intentional.
5. **Interactive states** — hover, pressed and ripple on white cards, the nav bar and the teal FAB
   cannot be judged from static captures.
6. **Dark regression by eye.** All new colour branches are gated on `Theme.of(context).brightness`;
   compare dark ledger/budget before and after on device.
7. **Pending pill border.** The requested 0.8dp `#D3DCE6` border is 1.23:1 against its fill, below
   the old 3:1 test threshold; only the label text is high contrast. This is intentional but visible
   only at large text / high DPI.
8. **Nav hairline** (`#E4E9F0`, 0.5dp) is deliberately faint. Confirm it reads as a separator and
   not as a rendering seam on OLED.
