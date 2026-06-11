# Data Model: Event-Sourced Ledger

> ⚠️ **迁移前文档（过期标记，T001）**：本 data model 描述迁移前设计，已被已确认规格 [spec.md](spec.md)（2026-09-06 同步）取代，**不可作为实现依据**。过期内容：
> - **double 金额**：现行与目标代码金额一律 int minor units（分）；规格禁止 double/float 参与任何账务计算。
> - **旧事件名与 payload**：`TransactionPosted`（legs + outflow/inflow role、signed amount）、`BalanceAdjustmentApplied`（已否决）。终稿九种事件：`AccountCreated` / `AccountRenamed` / `AccountArchived` / `CategoryCreated` / `CategoryRenamed` / `CategoryArchived` / `TransactionRecorded` / `TransactionReversed` / `OpeningBalanceSet`，payload 全为 int minor units，见 spec.md「Event Model / 事件模型」。
> - **事件信封**：`correlation_id`、`metadata` 列已砍掉。终稿信封含 eventId / streamId / aggregateType / eventType（Dart 类名稳定串，非 runtimeType）/ streamVersion / GSN / payloadJson（内含 schemaVersion）/ occurredAt / recordedAt / commandId，并约束 `unique(streamId, streamVersion)`。
> - **`accounts_view` 双余额**：`posted_balance` + `available_balance` 已废弃；终稿为单一 `balanceMinor` + `currencyCode` + `archived` + `projection_version`。
> - **`transactions_view` 逐腿行结构**：终稿拆为 `transactions_view`（transactionId、kind、分类名/图标写时快照）+ `transaction_postings_view`（posting 行，amountMinor 恒正 + direction）。
> - **`scheduled_transactions_view` 事件投影描述**：终稿中它是 recurring CRUD 豁免表，不参与 rebuild。
>
> 表结构终稿见 spec.md「Projection Model / 投影模型」「Snapshot Model / 快照模型」「Command Model / 命令模型」。

**Feature**: `003-event-sourced-ledger`

## 1. Write Model (The Source of Truth)

### Table: `ledger_events`

This table stores the immutable history of all changes.

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `Int` | PK, AutoIncrement | Global Sequence Number (GSN). Strict ordering. |
| `event_id` | `String` | UUID, Unique | Logical ID of the event (for correlation/idempotency). |
| `type` | `String` | Not Null | Discriminator: `TransactionPosted`, `TransactionReversed`, etc. |
| `occurred_at` | `DateTime` | Not Null | Business date of the transaction. |
| `recorded_at` | `DateTime` | Not Null | System wall-clock time when persisted. |
| `payload` | `String` | JSON | Serialized event data (AccountID, Amount, Metadata). |
| `correlation_id` | `String` | Nullable | Links related events (e.g., Reversal points to original EventID). |
| `metadata` | `String` | JSON, Nullable | Extra context (App version, user agent). |

### Event Types (Payload Schemas)

#### `TransactionPosted`
```json
{
  "transactionId": "uuid",
  "legs": [
    { "accountId": "uuid", "amount": -5000, "role": "outflow" }, // -50.00
    { "accountId": "uuid", "amount": 5000, "role": "inflow" }    // +50.00 (optional, for transfers)
  ],
  "description": "Groceries",
  "categoryId": "uuid",
  "tags": ["food", "essentials"],
  "notes": "Weekly shop"
}
```

#### `TransactionReversed`
```json
{
  "originalTransactionId": "uuid", // Points to the transaction being reversed
  "reason": "User error correction"
}
```

#### `BalanceAdjustmentApplied`
```json
{
  "accountId": "uuid",
  "targetBalance": 10000,
  "adjustmentAmount": 500, // Calculated diff
  "reason": "Reconciliation"
}
```

## 2. Read Models (Projections)

These tables are *derived* from `ledger_events`. They can be blown away and rebuilt.

### Table: `accounts_view`

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | UUID (PK) |
| `name` | `String` | Display name |
| `type` | `Enum` | Asset / Liability |
| `posted_balance` | `Int` | Sum of all posted transaction legs. |
| `available_balance` | `Int` | Posted Balance ± Pending (if pending supported later). |
| `last_updated_event_id` | `Int` | GSN of the last event applied to this row. |

### Table: `transactions_view`

Flattened view for UI lists. Multi-leg transactions (transfers) might be stored as two rows or linked.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Transaction UUID (PK) |
| `account_id` | `String` | Account this row belongs to (Indexed). |
| `date` | `DateTime` | `occurred_at` (Indexed). |
| `amount` | `Int` | Signed integer (minor units). |
| `description` | `String` | |
| `category_id` | `String` | |
| `is_reversed` | `Bool` | True if a reversal event exists for this ID. |
| `original_event_id` | `Int` | Pointer to the creating event. |

### Table: `scheduled_transactions_view`

Projected future instances from Recurring Series.

| Column | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | Derived ID (SeriesID + Date). |
| `series_id` | `String` | FK to `recurring_series`. |
| `date` | `DateTime` | Projected date. |
| `amount` | `Int` | Projected amount. |
| `status` | `Enum` | Pending / Posted / Skipped. |

## 3. Relationships

- `transactions_view.account_id` -> `accounts_view.id`
- `ledger_events` is the root. All Views depend on it.
