# Data Model: Core MVP

## 1. Schema (Drift/SQLite)

### Table: Accounts
*Storage of asset accounts (e.g., Wallet, Bank)*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | Int | PK, AutoIncrement | Unique ID |
| `name` | Text | Not Null | Display name (e.g. "Cash") |
| `type` | Enum | Not Null | Asset type (Cash, Bank, Credit) |
| `initial_balance` | Real | Default(0) | Starting balance |

### Table: Categories
*Classification for transactions*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | Int | PK, AutoIncrement | Unique ID |
| `name` | Text | Not Null | Display name |
| `icon_key` | Text | Not Null | String key for Material Icon lookup |
| `color_int` | Int | Not Null | ARGB integer for display color |
| `type` | Enum | Not Null | Income or Expense |
| `is_default` | Bool | Default(false) | Prevent deletion of system categories |

### Table: Transactions
*Individual financial records*
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | Int | PK, AutoIncrement | Unique ID |
| `amount` | Real | Not Null | Positive value |
| `type` | Enum | Not Null | Income or Expense |
| `date` | DateTime | Not Null | Transaction date (stored as timestamp) |
| `note` | Text | Nullable | Optional description |
| `category_id` | Int | FK(Categories.id) | Linked category |
| `account_id` | Int | FK(Accounts.id) | Linked account |
| `created_at` | DateTime | Default(Now) | Audit timestamp |

## 2. Key-Value Store (SharedPreferences)

### Domain: Settings
| Key | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `app_theme_mode` | String | "system" | light, dark, system |
| `app_locale` | String | "en" | en, zh |
| `heatmap_logic` | String | "frequency" | frequency, volume, net |
| `currency_symbol` | String | "$" | Display symbol |

## 3. Domain Entities (Dart)

### TransactionModel
```dart
class TransactionModel {
  final int id;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String? note;
  final CategoryModel category;
  final AccountModel account;
}
```

### MonthlySummary (Value Object)
```dart
class MonthlySummary {
  final DateTime month;
  final double totalIncome;
  final double totalExpense;
  final double runningBalance; // Cumulative ending balance
}
```
