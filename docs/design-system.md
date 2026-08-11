# Feather Ledger design system

The application uses neutral Material 3 surfaces, restrained semantic color and
one shared set of geometry and typography roles. Business state, translated
labels and formatted money remain owned by the feature.

## Where to change a visual rule

| Concern | Owner |
| --- | --- |
| Light/dark color roles and Material component themes | `lib/app/theme/app_theme.dart` |
| Income, expense and independent frequency-chart color | `AppSemanticColors` |
| Corners, control sizes, card padding and responsive page gutters | `lib/app/theme/app_metrics.dart` |
| Balance, amount, statistic, section title and metadata roles | `lib/app/theme/app_typography.dart` |
| Account-type accent colors | `lib/app/theme/account_card_theme.dart` |
| Reusable visual implementations | `lib/app/design_system/` |

`AppTheme` builds both brightness modes through the same configuration. Changing
the shared metrics changes their derived Material themes and DS variants. The
extensions implement `copyWith` and `lerp` for theme transitions.

Dialogs fill the available horizontal space after the shared 16 dp side
insets, up to 560 dp on larger screens. This rule lives in `DialogTheme` and
applies to simple menus, confirmations and pickers; content only determines
height. Avoid per-dialog width or inset overrides.

## Choosing a variant

- `AppCard`: flat, padded surface; `.outlined`: a light boundary on the page
  surface; `.group`: an unpadded surface for related list rows; `.account`:
  subdued account tint and texture. The account variant uses global geometry.
- `AppButton`: primary action; `.secondary`: tonal action; `.outlined`:
  secondary boundary; `.text`: quiet action; `.destructive`: error-colored
  confirmation. Supply `icon` when the label needs an icon. Existing boolean
  arguments remain compatible; new call sites should prefer named variants.
- `AppIconButton`: quiet toolbar action; `.surface`: isolated shortcut;
  `.destructive`: destructive action. The global icon-button theme owns the
  minimum tap size and disabled state.
- `AppTextField.search`: filled search surface. `AppTextField` also accepts
  `AppFieldVariant.inline` for a field in a form row and `.amount` for a large
  amount. Controllers, formatters, validation and raw-text callbacks are passed
  through without reformatting text or moving the caret.
- `AppSegmentedControl<T>`: compact mutually exclusive choices on a weak
  background, with no outlines or separators. `AppChoiceChips<T>`: choices that
  need to wrap with longer translations or larger text.
- `AppFormRow`: a row inside an already padded container; `.page`: a full-width
  row with responsive page insets inside its tap response.
- `AppBadge` / `AppIconBadge`: state/category labels and rounded icon bases.
  Category colors are data supplied by callers, not a replacement palette.
- `AppSheetHandle` and `AppDivider`: shared sheet chrome and separators.
- `AppReceiptSheet`: receipt silhouette, perforation, fixed toolbar and bounded
  scrolling body. `showAppReceiptSheet` supplies the transparent modal route.
  Callers provide content, actions and an optional footer; history queries and
  barcode encoding remain in the recorded-transaction feature widget.
- `AppBottomActionBar`: full-width, 52 dp primary action with shared page
  gutters, keyboard motion and bottom safe area. Both transaction editors and
  the pending receipt's Post action use it.

## Feature usage

Use `context.pagePadding` for page gutters, `context.metrics` for reusable
geometry and `context.spacing` for the existing 4/8/16/24/32 rhythm. Use
`AppTypography.balance`, `.amount`, `.statistic`, `.sectionTitle` and `.meta`
instead of defining another font size or weight in a widget. Color overrides
can still express income, expense, selected state or category data.

Ledger/Settings theme helpers delegate to these shared roles. The ledger date
rail width, chart geometry, barcode encoding and field-name measurement remain
feature-owned. Shared receipt decoration belongs to `AppReceiptSheet`.
`LedgerReceiptContent` and `LedgerNoteField` reuse ledger-specific labels and
facts across recorded and pending flows; they do not dispatch write actions.

Frequency heatmap color deliberately does not use `ColorScheme.primary`.
Primary is neutral for actions and navigation; chart intensity must remain
independent. Never change persisted category colors or icon keys as part of a
visual refresh.

## Verification

Run `flutter analyze --no-pub` and `flutter test --no-pub test/ui`. Shared-system
tests exercise contrast, minimum touch targets, disabled/selected behavior,
theme interpolation and the ledger summary at 320 dp with enlarged text in
English, Simplified Chinese and Traditional Chinese. Existing feature tests
cover controlled amount input, filters, edit/delete flows and chart switching.
