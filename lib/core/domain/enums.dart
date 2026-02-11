/// 交易类型：收入 vs 支出
enum TransactionType {
  income,
  expense;
}

/// 交易角色，用于表示交易的流入或流出
enum TransactionRole {
  outflow,
  inflow;
}

/// 账户类型：现金、银行卡等
enum AccountType {
  cash,
  bank,
  credit,
  other;
}
