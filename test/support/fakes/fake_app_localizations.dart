import 'package:feather_ledger/app/l10n/app_localizations.dart';

// A fake AppLocalizations class that returns hardcoded English strings.
// Used for testing purposes where a real BuildContext is not available.
class FakeAppLocalizations implements AppLocalizations {
  @override
  String get localeName => 'en'; // Added missing concrete implementation

  @override
  String get appTitle => 'Feather Ledger';

  @override
  String get ledgerTitle => 'Ledger';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  // ignore: non_constant_identifier_names
  @override
  String get totalBalance => 'Total Balance';

  @override
  String get noTransactionsThisMonth => 'No transactions this month';

  @override
  String get noTransactionsTitle => 'No transactions';

  @override
  String get noTransactionsHint => 'Tap + to add a new one';

  @override
  String get addTransaction => 'Add Transaction';

  @override
  String get edit => 'Edit';

  @override
  String get editTransaction => 'Edit Transaction';

  @override
  String get deleteTransactionConfirmation =>
      'Are you sure you want to delete this transaction? This action cannot be undone.';

  @override
  String get amount => 'Amount';

  @override
  String get frequency => 'Frequency';

  @override
  String get date => 'Date';

  @override
  String get category => 'Category';

  @override
  String get categoryNameHint => 'Category Name';

  @override
  String get name => 'Name';

  @override
  String get color => 'Color';

  @override
  String get icon => 'Icon';

  @override
  String get account => 'Account';

  @override
  String get note => 'Note';

  @override
  String get save => 'Save';

  @override
  String get saveTransaction => 'Save Transaction';

  @override
  String get required => 'Required';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get errorAccountNotFound => 'Account not found';

  @override
  String get errorAccountArchived => 'Account is archived';

  @override
  String get errorCategoryNotFound => 'Category not found';

  @override
  String get errorCategoryArchived => 'Category is archived';

  @override
  String get errorCategoryTypeMismatch =>
      'Category type does not match the transaction type';

  @override
  String get errorSystemCategoryProtected =>
      'System categories cannot be archived';

  @override
  String get errorInvalidTransfer => 'Invalid transfer';

  @override
  String get transfer => 'Transfer';

  @override
  String get transferFrom => 'From';

  @override
  String get transferTo => 'To';

  @override
  String get errorTransactionNotFound => 'Transaction not found';

  @override
  String get errorTransactionAlreadyReversed =>
      'Transaction was already reversed';

  @override
  String get auditHistory => 'Audit history';

  @override
  String get eventRecorded => 'Recorded';

  @override
  String get eventReversed => 'Reversed';

  @override
  String get reversalUserDeleted => 'User deleted';

  @override
  String get reversalCorrection => 'Correction';

  @override
  String get rebuildProjections => 'Rebuild projections';

  @override
  String get rebuildProjectionsHint => 'Developer tool — long-press to run';

  @override
  String get rebuildProjectionsConfirm =>
      'Clear all derived data and replay the full event history? Recurring rules and preferences are kept.';

  @override
  String get rebuildProjectionsSuccess => 'Projections rebuilt';

  @override
  String get rebuildProjectionsFailure => 'Rebuild failed';

  @override
  String get noCategoriesFound => 'No categories found. Please add some first.';

  @override
  String get noAccountsFound => 'No accounts found.';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

  @override
  String get settings => 'Settings';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get currencySymbol => 'Currency Symbol';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get english => 'English';

  @override
  String get chinese => 'Chinese';

  @override
  String get simplifiedChinese => 'Simplified Chinese';

  @override
  String get traditionalChinese => 'Traditional Chinese';

  @override
  String get loading => 'Loading...';

  @override
  String get reports => 'Reports';

  @override
  String get activityHeatmap => 'Activity Heatmap';

  @override
  String get incomeBreakdown => 'Income Breakdown';

  @override
  String get expenseBreakdown => 'Expense Breakdown';

  @override
  String get others => 'Others';

  @override
  String get noData => 'No data';

  @override
  String get more => 'More';

  @override
  String get accounts => 'Accounts';

  @override
  String get categories => 'Categories';

  @override
  String get dollarCurrency => '\$ (Dollar)';

  @override
  String get yuanCurrency => '¥ (Yuan)';

  @override
  String get yenCurrency => '¥ (Yen)';

  @override
  String get euroCurrency => '€ (Euro)';

  @override
  String get poundCurrency => '£ (Pound)';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get addAccount => 'Add Account';

  @override
  String get editAccount => 'Edit Account';

  @override
  String get accountName => 'Account Name';

  @override
  String get accountType => 'Account Type';

  @override
  String get initialBalance => 'Initial Balance';

  @override
  String get accountSaved => 'Account saved';

  @override
  String get balanceChangeDetectedTitle => 'Balance change detected';

  @override
  String get balanceChangeDetectedMessage =>
      'Balance has changed. A correction transaction will be created. Continue?';

  @override
  String get accountBalanceAdjustmentDescription =>
      'Account balance adjustment';

  @override
  String get accountBalanceAdjustmentNotes =>
      'Automated adjustment for account balance change.';

  @override
  String get deleteAccountConfirmation =>
      'Are you sure you want to delete this account?';

  @override
  String get deleteCategoryConfirmationTitle => 'Delete category?';

  @override
  String get deleteCategoryConfirmationMessage =>
      'This will not delete existing transactions.';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get feedback => 'Feedback';

  @override
  String get about => 'About';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get version => 'Version';

  @override
  String get featureNotAvailable => 'Feature not available';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get manageAccounts => 'Manage Accounts';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryBonus => 'Bonus';

  @override
  String get accountCash => 'Cash';

  @override
  String get accountBankCard => 'Bank Card';

  @override
  String get categoryAllowance => 'Allowance';

  @override
  String get categoryClothing => 'Clothing';

  @override
  String get categoryCommunications => 'Communications';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryGifts => 'Gifts';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryHouseholdSupplies => 'Household Supplies';

  @override
  String get categoryInvestmentReturns => 'Investment Returns';

  @override
  String get categoryReversalExpense => 'Reversal';

  @override
  String get categoryPartTimeJob => 'Part-Time Job';

  @override
  String get categoryReversalIncome => 'Reversal';
}
