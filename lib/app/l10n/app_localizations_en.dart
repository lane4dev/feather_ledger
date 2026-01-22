// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

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

  @override
  String get total_balance => 'Total Balance';

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
  String get saveTransaction => 'Save Transaction';

  @override
  String get required => 'Required';

  @override
  String get invalidAmount => 'Invalid amount';

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
  String get yuanYenCurrency => '¥ (Yuan/Yen)';

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
}
