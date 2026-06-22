# ezBookkeeping feature evidence audit

**Purpose.** This note records what the upstream project itself documents, so
the Feather Ledger product audit can compare like-for-like without treating
server/deployment capability as a mobile-app requirement. It is not an audit
of Feather Ledger implementation. Sources were checked on 2026-09-21 against
ezBookkeeping's official documentation and its `main` GitHub repository. The
documentation's feature list includes capabilities through 2.0.0; GitHub's
latest listed release at the time was 1.6.1. Consequently, a row marked
"documented" means it is advertised by current upstream documentation, not
necessarily that it is in every released build.

## Primary sources

1. [Official feature list](https://ezbookkeeping.mayswind.net/features/) —
   upstream's complete, version-labelled capability catalogue.
2. [Official basic usage guide](https://ezbookkeeping.mayswind.net/basic_usage/) —
   workflow and semantic details for accounts, transfers, reconciliation and
   charts.
3. [Official transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api)
   — authoritative data fields and add/modify/delete semantics.
4. [Official export and import guide](https://ezbookkeeping.mayswind.net/export_and_import/)
   — formats, mapping/preview and import workflow.
5. [Official README](https://github.com/mayswind/ezbookkeeping/blob/main/README.md)
   — product scope, including its self-hosted/multi-user/security posture.
6. [Official FAQ](https://ezbookkeeping.mayswind.net/faq/) — scheduled-creation
   runtime behavior.
7. [Upstream budget request #289](https://github.com/mayswind/ezbookkeeping/issues/289)
   — useful negative evidence: the request explicitly says the product has no
   planning/forecasting budget support. It is an issue, not a feature claim.

## Evidence matrix

| Area / capability | ezBookkeeping status and exact semantics | Primary evidence | Product-scope reading for Feather Ledger |
| --- | --- | --- | --- |
| Income, expense and transfer | Documented. The transaction type enum includes income, expense and transfer (plus balance modification). A transfer has source and optional destination account and separately stores source/destination amounts, which also supports cross-currency transfer amounts. | [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api); [basic usage](https://ezbookkeeping.mayswind.net/basic_usage/) | Core personal-ledger capability; directly comparable. This is a two-sided transfer representation, not a general journal/double-entry system claim. |
| Create, edit, delete transactions | Documented `add`, `modify`, and `delete` operations; modify can change type, accounts, amounts, tags, images, note and location. | [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api) | Directly comparable. |
| Multiple accounts, types and hierarchy | Documented multiple account categories (including cash, checking, credit card and debt) and two-level account hierarchy/sub-accounts. Credit/debt balances are treated as liabilities; credit cards can have statement date and credit limit. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [basic usage](https://ezbookkeeping.mayswind.net/basic_usage/) | Account hierarchy/type is useful locally; web-specific detail is not required. |
| Account archive and metadata | Documented hidden/archived accounts, account name/icon/color/display order/description and last reconciled time. | [Feature list](https://ezbookkeeping.mayswind.net/features/) | Archive is direct; visual metadata is optional UX. |
| Categories | Documented two-level, income/expense/transfer category trees, icons/color/order/description, and hidden state. Transactions require a secondary category. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [basic usage](https://ezbookkeeping.mayswind.net/basic_usage/) | Directly comparable; it is specifically two levels, not arbitrary-depth categories. |
| Tags | Documented transaction tags, display order and tag groups; a transaction can have zero or many tags. Filters support all/any/not-all/not-any logic per tag group. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api) | High-value local search/analysis dimension. |
| Notes, time and timezone | Documented transaction description, date, time and timezone/UTC offset. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api) | Directly comparable. |
| Images / receipt attachment | Documented transaction images/pictures, with picture IDs/URLs as a first-class transaction field. README also advertises receipt-image recognition. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api); [README](https://github.com/mayswind/ezbookkeeping/blob/main/README.md) | Attachments are a meaningful mobile-first enhancement; AI recognition is optional. |
| Geographic location | Documented latitude/longitude transaction location plus map providers. | [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api); [feature list](https://ezbookkeeping.mayswind.net/features/) | Optional; not a baseline bookkeeping gap. |
| Payee / merchant, custom fields, status | No dedicated payee/merchant, arbitrary custom-field, or transaction-status feature is listed in the official feature list/API. Description can carry free text but is not a structured payee. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api) | Do not infer these capabilities from notes or import data. |
| Split transactions | Not documented as a normal transaction capability. Import documentation says IIF split transactions are converted to separate transactions and several formats cannot import splits, rather than advertising native split preservation. | [export/import guide](https://ezbookkeeping.mayswind.net/export_and_import/) | Do not treat ezBookkeeping as a model for native split implementation. |
| Batch modification, templates and drafts | Documented batch modification through Insights Explorer, scheduled transactions, transaction templates, and auto-saved transaction drafts. | [Feature list](https://ezbookkeeping.mayswind.net/features/) | Templates/drafts are strong mobile UX candidates; explorer-scale batch tooling is optional. |
| Scheduled / planned transactions | Documented schedules. FAQ says a schedule automatically creates an identical transaction on its scheduled date and requires the server to be running continuously; current feature list also includes an every-N-days interval. | [FAQ](https://ezbookkeeping.mayswind.net/faq/); [feature list](https://ezbookkeeping.mayswind.net/features/) | Semantics are valuable, but a local app needs catch-up/on-launch scheduling rather than an always-running server assumption. |
| Search, filters and sorting | List/calendar/gallery views plus filters by category/account/tag/amount/description; date and amount sorts; advanced AND/OR, nested-condition queries in Insights Explorer. API documents keyword, date, attachment, type and tag-logic filters. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [Transaction API](https://ezbookkeeping.mayswind.net/httpapi/transaction_api) | Basic search/filtering is core; custom query builder is advanced. |
| Current/history balances and reconciliation | Account balances, reconciliation statements, exportable statements, and account-balance trend charts are documented. Reconciliation can display running balance after each transaction and create a balance-adjustment transaction from an expected close. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [basic usage](https://ezbookkeeping.mayswind.net/basic_usage/) | Reconciliation is a meaningful P1 personal-finance feature; it does not require server scope. |
| Asset distribution and trend | Asset proportion (including by currency) and asset trend charts are documented; FAQ defines net worth as selected assets minus selected liabilities. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [FAQ](https://ezbookkeeping.mayswind.net/faq/) | Valuable once accounts/types/currency conversion are reliable. |
| Monthly snapshots | No explicit monthly snapshot/rollup storage mechanism is documented; upstream presents balance and trend outcomes, not its persistence design. | [Feature list](https://ezbookkeeping.mayswind.net/features/) | Do not compare internal projection design to a user-visible upstream feature. |
| Budgets, budget progress/history, bill reminders | Not documented in current official feature list. Issue #289's request states the product currently tracks past transactions and lacks planning/forecasting/budgets. Scheduled transactions are documented, but due-date notifications are not. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [issue #289](https://github.com/mayswind/ezbookkeeping/issues/289) | Budgeting is a Feather Ledger product decision, not an ezBookkeeping parity item. Recurring bills can still be valuable. |
| Preset reports | Category/account income-expense proportions and trends, asset proportions/trends, time-range aggregation, multiple chart families, and YoY/period-over-period comparisons are documented. | [Feature list](https://ezbookkeeping.mayswind.net/features/) | Core preset trends/shares should precede exotic chart types. |
| Tags/custom analysis/export charts | Insights Explorer offers logical conditions, result statistics, customizable dimensions/metrics/charts, tag charts, custom charts, and exports filtered/chart data to CSV/TSV/Markdown (and Mermaid for chart export). | [Feature list](https://ezbookkeeping.mayswind.net/features/) | Advanced, potentially feature-creep for a light local app. A constrained filter + CSV export is more appropriate earlier. |
| CSV/Excel/bank/third-party imports | Documented CSV, Excel, OFX/QFX/QIF/IIF, Camt.052/.053, MT940, GnuCash, Firefly III, Beancount, Feidee, Alipay, WeChat Pay and JD Finance imports. CSV/Excel supports mapping, auto-detection, rules and custom scripts; UI previews and permits per-row/batch mapping corrections before import. | [Feature list](https://ezbookkeeping.mayswind.net/features/); [export/import guide](https://ezbookkeeping.mayswind.net/export_and_import/) | CSV mapping and the most relevant regional statement format(s) are high-value. The full import matrix/custom JS should not be a first release target. |
| Duplicate transaction detection | The official configuration documents a server-side duplicate-*submission* interval, but docs reviewed do not claim transaction-level duplicate detection during import. | [configuration](https://ezbookkeeping.mayswind.net/configuration/) | Do not claim import dedup parity without separate proof; a local import fingerprint/preview remains a product opportunity. |
| CSV/TSV export and filtered export | Documented CSV and TSV transaction export; UI permits full export and exporting the current filtered list. | [feature list](https://ezbookkeeping.mayswind.net/features/); [export/import guide](https://ezbookkeeping.mayswind.net/export_and_import/) | Directly comparable. |
| Full backup / restore | Export documentation is transaction data CSV/TSV and importable native export data; it does not establish a complete one-file backup/restore of settings, accounts, categories, schedules and attachments. An issue requests that broader backup. | [export/import guide](https://ezbookkeeping.mayswind.net/export_and_import/); [issue #179](https://github.com/mayswind/ezbookkeeping/issues/179) | A native local backup/restore is valuable independently of ezBookkeeping. |
| Multi-currency, rates and base currency | Documented preset global currencies, multi-currency accounts, multiple rate sources with automatic updates, manual rates and default-currency conversion for analytics. Missing rate data excludes those account transactions from analysis. | [README](https://github.com/mayswind/ezbookkeeping/blob/main/README.md); [feature list](https://ezbookkeeping.mayswind.net/features/); [basic usage](https://ezbookkeeping.mayswind.net/basic_usage/) | Multi-currency storage is useful; automatic network rate sync is an optional service/product decision. |
| Language, formats and timezone | Documented many languages, localized/custom date/time/number/currency formats, custom timezone, first week day, fiscal-year start, RTL and multiple calendars. | [feature list](https://ezbookkeeping.mayswind.net/features/) | Language and locale formatting matter; multi-calendar/RTL only when audience demands them. |
| Security and privacy | README advertises 2FA, OIDC, login rate limiting and PIN/WebAuthn app lock. The full list also covers email/account/session/API controls. These are largely consequences of its hosted multi-user web architecture. | [README](https://github.com/mayswind/ezbookkeeping/blob/main/README.md); [feature list](https://ezbookkeeping.mayswind.net/features/) | For a local Flutter app, PIN/biometric lock and protected backups are comparable; OIDC/2FA/session/rate-limit/admin controls are generally not. |
| Data clearing | Documented clear-account-transactions and clear-all-data commands. | [feature list](https://ezbookkeeping.mayswind.net/features/) | A local app should offer deliberate, recoverable/confirmed data management; ES history makes semantics especially important. |
| Overview/dashboard and appearance | Mobile/desktop UIs, dark mode and customizable overview layout are documented; font size setting is also listed. | [README](https://github.com/mayswind/ezbookkeeping/blob/main/README.md); [feature list](https://ezbookkeeping.mayswind.net/features/) | Dark mode and a focused overview are relevant; fully customizable dashboard can wait. |
| Server/self-hosted/multi-user/API/CLI/deployment | README explicitly describes a self-hosted server, Docker, NAS/Raspberry Pi, SQLite/MySQL/PostgreSQL, PWA and API/CLI tooling; feature list names multi-user, HTTP API and CLI. | [README](https://github.com/mayswind/ezbookkeeping/blob/main/README.md); [feature list](https://ezbookkeeping.mayswind.net/features/) | **Not a parity gap** for a local-first Flutter app unless Feather Ledger intentionally adds sync/sharing. |
| AI/MCP, external object storage and map provider breadth | Documented MCP, AI text/receipt recognition, LLM providers, S3/MinIO/WebDAV and many map tiles. | [feature list](https://ezbookkeeping.mayswind.net/features/) | Advanced and infrastructure-heavy; do not use as a baseline roadmap requirement. |

## Guardrails for the later comparison report

- Use ezBookkeeping's documented user capability as the comparison baseline,
  not its Go/Vue/server architecture.
- Separate **scheduled-transaction data/UI** from automatic execution: the
  latter is a cron/server behavior upstream and needs different local-first
  semantics.
- Do not call budgets, native splits, merchant/payee, custom fields, or
  import deduplication "ezBookkeeping features" based on adjacent fields.
- Treat a Flutter domain object, event, DAO or projection as only an
  implementation prerequisite. The Feather audit must separately verify a
  user-reachable UI/workflow and tests before marking it implemented.
