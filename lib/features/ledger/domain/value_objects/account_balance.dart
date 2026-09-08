/// Projected account balance (spec 003, US3): single balance in minor
/// units — the dual posted/available balance is gone.
class AccountBalance {
  final int balance;

  AccountBalance({required this.balance});
}
