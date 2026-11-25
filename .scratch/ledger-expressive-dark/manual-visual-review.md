# Expressive dark & light — manual visual review checklist

Branch: `feat/ledger-expressive-dark` (head `06c008c`)
Automated coverage: `flutter analyze` clean, `flutter test` 864 passed / 1 pre-existing
unrelated failure (`test/ui/app/floating_choice_test.dart:32`, also red on `main`).

Everything below is what the test suite **cannot** prove — it asserts geometry and
computed colors, not how the screen looks. Triage each item on a device/emulator.

## 1. Theme & design system (ticket 01)

- [ ] **Default light** on a real device: `surface` / `surfaceContainerLow` /
      `surfaceContainer` / `surfaceContainerHigh` read as four distinguishable
      layers — not four greys that collapse into each other on a cheap panel.
- [ ] **Default dark**: same check. Dark surfaces are close in luminance
      (`#111413` / `#191D1B` / `#1B201E` / `#222826`) — confirm the day card still
      separates from the page background at low brightness / outdoors.
- [ ] **Dynamic color** with Material You on Android 12+: pull a strongly tinted
      wallpaper (red/green) and confirm the normalized surface hierarchy stays
      neutral enough for the ledger's income/expense colors to still be readable.
- [ ] **Dynamic color fallback**: kill the platform channel (or run on iOS/desktop)
      and confirm the app falls back to the fixed palettes without a flash of
      default blue.
- [ ] Income / expense tonal containers in both brightnesses: does the pairing read
      as "money in" / "money out" without leaning on the color alone?
- [ ] Dynamic color *and* dark mode together: the accent-derived `primaryContainer`
      FAB and today badge must stay legible against `surfaceContainerLow` card.

## 2. Compact readonly amounts (ticket 02)

- [ ] `+¥10.00` / `-¥10.00` / `-¥12.34` / `¥20.00` — sign flush against the
      currency symbol, no stray space, no double sign, on the ledger rows, search
      rows, receipt sheet, budget screens, and report breakdown.
- [ ] Tabular figures: digits do not jitter horizontally when a month total
      animates from `¥0.00` to `¥123,456.78`.
- [ ] Editable inputs still show a space (`$ -12.34`) and CSV export is byte-identical
      to before — both are intentionally out of scope.

## 3. Month toolbar & overview card (ticket 03)

- [ ] Centered `< month >` toolbar: tapping the chevrons and the month label feels
      like the same control; 48dp hit targets are comfortable one-handed.
- [ ] Eye toggle hides Total Balance **and** month income/expense **and** the
      collapsed-bar balance in one tap — no partially masked state.
- [ ] The 50/50 income/expense tiles look balanced with a 6-figure amount and a
      1-figure amount on the same row (nothing wraps or clips).
- [ ] Overview card's 24dp radius vs day cards' 18dp radius: the hierarchy reads
      as intended, not as an inconsistency.

## 4. Sticky day cards & rows (ticket 04 + polish)

- [ ] Left rail: today badge is a circle that is visually distinct from other days
      without stealing attention; the rail width does not drift between single- and
      double-digit days.
- [ ] **Status pill on the second line** (this polish): pending / skipped / failed
      pills sit 6dp after the account name, 20dp tall. Check at 360dp width with a
      long account name — the name should ellipsize and the pill stay on one line
      (it scales down rather than wrapping).
- [ ] **Skipped rows muted at 0.58 alpha**: still legible (WCAG is computed, but
      perceived contrast on an OLED panel matters more) — the row should read as
      "second tier", not as "disabled/loading".
- [ ] Two-line rows: title (note or category) and subtitle (account, or `from → to`)
      with the category avatar and amount both optically centered. Look for a
      1px vertical drift on rows whose subtitle is a transfer.
- [ ] Row rhythm with 3+ transactions in a day: 60dp min height / 10dp padding
      should feel dense but not cramped; verify no clipped glyphs.
- [ ] **Daily subtotal footer**: the divider at 0.45 alpha of `outlineVariant`
      should be visible on both light and dark, and the reduced 6dp padding should
      read as a footer rather than a full row.
- [ ] Subtotal appears only when ≥ 2 visible rows **and** at least one countable
      income/expense — confirm one-transaction days have no footer.

## 5. Collapsed app bar transition (polish)

- [ ] Scroll up: the date/balance row must be cleanly clipped as it goes under the
      app bar — no half-visible text bleeding past the `surfaceContainer` backing.
- [ ] The `surfaceContainer` tint + 2dp `scrolledUnderElevation` appear at the
      right moment (just as content starts under the bar), and disappear when
      scrolling back to the top. No flicker on a fast fling.
- [ ] Collapsed title hierarchy: month as `titleMedium` w600 on the left, balance in
      a `surfaceContainerHigh` capsule on the right — check the capsule does not
      look like a button (it is not tappable).
- [ ] With dynamic color the capsule tint should still be distinguishable from the
      scrolled app bar background.

## 6. Bottom navigation & FAB (ticket 05)

- [ ] Selected book icon is solid, unselected is outlined; the `secondaryContainer`
      pill only surrounds the selected destination.
- [ ] Scroll to the last transaction: the amount must clear the FAB and the nav bar
      with visible air (88dp floor) in both portrait and landscape.
- [ ] Nav bar hides on scroll and returns on scroll-up without the FAB jumping.
- [ ] Long-press / swipe-back gestures do not conflict with the nav bar indicator.

## 7. Edge cases only a human will notice

- [ ] `textScale` 2.0 with a long localized category name (zh_Hant): nothing
      overflows, nothing overlaps the amount.
- [ ] RTL is out of scope, but confirm no forced LTR assumptions broke the rail.
- [ ] Skeleton / empty / loading states still match the new card + rail layout
      (they are easy to forget after a card redesign).
- [ ] Animation feel: the eye-mask, collapse, and nav hide should share a similar
      duration curve.

## Known out-of-scope / pre-existing

- `test/ui/app/floating_choice_test.dart:32` fails on `main` too (Ahem font wraps
  `Budget tracking` inside 200px → 56px). Not touched by this branch.
- iOS `CFBundleDisplayName` / `InfoPlist.strings` localization remains unimplemented
  (pre-existing, see AGENTS.md).
