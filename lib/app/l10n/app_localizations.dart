import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Accounted For'**
  String get appTitle;

  /// Title for ledger screen
  ///
  /// In en, this message translates to:
  /// **'Ledger'**
  String get ledgerTitle;

  /// Income label
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// Expense label
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Balance label
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// The reports screen's third figure — that month's closing balance, unlike the ledger header's running total
  ///
  /// In en, this message translates to:
  /// **'Month-end balance'**
  String get monthEndBalance;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// Message when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'No transactions this month'**
  String get noTransactionsThisMonth;

  /// Empty state title when no transactions exist
  ///
  /// In en, this message translates to:
  /// **'No transactions'**
  String get noTransactionsTitle;

  /// Empty state hint to add a transaction
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a new one'**
  String get noTransactionsHint;

  /// Empty state title when the current currency has no accounts
  ///
  /// In en, this message translates to:
  /// **'No accounts in this currency'**
  String get noAccountsInCurrencyTitle;

  /// Empty state hint to create an account in the current currency
  ///
  /// In en, this message translates to:
  /// **'Create an account to start tracking'**
  String get noAccountsInCurrencyHint;

  /// Title for add transaction screen
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get addTransaction;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Title for edit transaction screen
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get editTransaction;

  /// Confirmation message for deleting a transaction
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction? This action cannot be undone.'**
  String get deleteTransactionConfirmation;

  /// Amount field label
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// Heatmap mode option for frequency
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// Date field label
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// Date on the transaction form, when it is the current day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Date on the transaction form, when it is the day before
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Date on the transaction form, when it is the day after
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Hint text for category name input
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryNameHint;

  /// Generic name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Category color section label
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// Category icon section label
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get icon;

  /// Account field label
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Note field label
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// Hint inside the empty note field; the field name is already on its left
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get noteHint;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Required field validation message
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// Invalid amount validation message
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// Message when no categories exist
  ///
  /// In en, this message translates to:
  /// **'No categories found. Please add some first.'**
  String get noCategoriesFound;

  /// Message when no accounts exist
  ///
  /// In en, this message translates to:
  /// **'No accounts found.'**
  String get noAccountsFound;

  /// Error message prefix
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorPrefix(String error);

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Subtitle under the Settings entry in More
  ///
  /// In en, this message translates to:
  /// **'Theme, language and currency'**
  String get settingsHint;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Currency symbol setting label
  ///
  /// In en, this message translates to:
  /// **'Currency Symbol'**
  String get currencySymbol;

  /// Account currency picker label
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountCurrency;

  /// Account management filter option showing every currency
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get accountAllCurrencies;

  /// Hint on the account form telling which currency ledger a balance adjustment is recorded in
  ///
  /// In en, this message translates to:
  /// **'Balance changes are recorded in the {currency} ledger.'**
  String accountBalanceAdjustmentLedgerHint(String currency);

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Language preference that uses the device language
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// Simplified Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get simplifiedChinese;

  /// Traditional Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get traditionalChinese;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Reports screen title
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @viewReports.
  ///
  /// In en, this message translates to:
  /// **'View reports'**
  String get viewReports;

  /// Activity heatmap section title
  ///
  /// In en, this message translates to:
  /// **'Activity Heatmap'**
  String get activityHeatmap;

  /// Daily signed net amount shown in a heatmap day tooltip
  ///
  /// In en, this message translates to:
  /// **'Net flow: {amount}'**
  String heatmapNetFlow(String amount);

  /// No description provided for @heatmapZeroNetFlow.
  ///
  /// In en, this message translates to:
  /// **'Zero net flow'**
  String get heatmapZeroNetFlow;

  /// No description provided for @heatmapNetInflow.
  ///
  /// In en, this message translates to:
  /// **'Net inflow'**
  String get heatmapNetInflow;

  /// No description provided for @heatmapNetOutflow.
  ///
  /// In en, this message translates to:
  /// **'Net outflow'**
  String get heatmapNetOutflow;

  /// Income breakdown chart title
  ///
  /// In en, this message translates to:
  /// **'Income Breakdown'**
  String get incomeBreakdown;

  /// Expense breakdown chart title
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get expenseBreakdown;

  /// Label for aggregated categories in reports
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get others;

  /// Message when no data is available
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// More screen title
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Accounts menu item
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accounts;

  /// Subtitle under the Accounts entry in More
  ///
  /// In en, this message translates to:
  /// **'Your accounts and their balances'**
  String get accountsHint;

  /// Categories menu item
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// Subtitle under the Categories entry in More
  ///
  /// In en, this message translates to:
  /// **'Income and expense categories'**
  String get categoriesHint;

  /// Dollar currency option
  ///
  /// In en, this message translates to:
  /// **'\$ (Dollar)'**
  String get dollarCurrency;

  /// Yuan currency option
  ///
  /// In en, this message translates to:
  /// **'¥ (Yuan)'**
  String get yuanCurrency;

  /// Yen currency option
  ///
  /// In en, this message translates to:
  /// **'¥ (Yen)'**
  String get yenCurrency;

  /// Euro currency option
  ///
  /// In en, this message translates to:
  /// **'€ (Euro)'**
  String get euroCurrency;

  /// Pound currency option
  ///
  /// In en, this message translates to:
  /// **'£ (Pound)'**
  String get poundCurrency;

  /// Title for accounts screen
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// Title for add account screen
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get addAccount;

  /// Title for edit account screen
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get editAccount;

  /// Account name field label
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get accountName;

  /// Account type field label
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get accountTypeBank;

  /// No description provided for @accountTypeCredit.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountTypeCredit;

  /// No description provided for @accountTypeOther.
  ///
  /// In en, this message translates to:
  /// **'Other account'**
  String get accountTypeOther;

  /// No description provided for @accountExcludedFromTotals.
  ///
  /// In en, this message translates to:
  /// **'Excluded from totals'**
  String get accountExcludedFromTotals;

  /// No description provided for @accountArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get accountArchived;

  /// Initial balance field label
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

  /// No description provided for @transactionType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionType;

  /// Message when account is saved
  ///
  /// In en, this message translates to:
  /// **'Account saved'**
  String get accountSaved;

  /// Title for balance change confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Balance change detected'**
  String get balanceChangeDetectedTitle;

  /// Message for balance change confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Balance has changed. A correction transaction will be created. Continue?'**
  String get balanceChangeDetectedMessage;

  /// Description for automated account balance adjustment transaction
  ///
  /// In en, this message translates to:
  /// **'Balance adjustment'**
  String get accountBalanceAdjustmentDescription;

  /// Note on the transaction recording a new account's starting balance
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get accountInitialBalanceNote;

  /// Switch on the account form: whether this account counts toward the ledger's aggregate figures
  ///
  /// In en, this message translates to:
  /// **'Include in totals'**
  String get accountIncludeInTotals;

  /// Explanation under the include-in-totals switch, saying what turning it off does and does not do
  ///
  /// In en, this message translates to:
  /// **'Off: this account is left out of the total balance and the income and expense totals. Its transactions still show in the ledger.'**
  String get accountIncludeInTotalsHint;

  /// Notes for automated account balance adjustment transaction
  ///
  /// In en, this message translates to:
  /// **'Balance correction'**
  String get accountBalanceAdjustmentNotes;

  /// Confirmation message for deleting an account
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this account?'**
  String get deleteAccountConfirmation;

  /// Confirmation title for deleting a category
  ///
  /// In en, this message translates to:
  /// **'Delete category?'**
  String get deleteCategoryConfirmationTitle;

  /// Confirmation message for deleting a category
  ///
  /// In en, this message translates to:
  /// **'This will not delete existing transactions.'**
  String get deleteCategoryConfirmationMessage;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Feedback menu item
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// Subtitle under the Feedback entry in More
  ///
  /// In en, this message translates to:
  /// **'Tell us what you think'**
  String get feedbackHint;

  /// About menu item
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Subtitle under the About entry in More
  ///
  /// In en, this message translates to:
  /// **'App information and open-source licences'**
  String get aboutHint;

  /// Open Source Licenses menu item
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Message for unimplemented features
  ///
  /// In en, this message translates to:
  /// **'Feature not available'**
  String get featureNotAvailable;

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Manage Categories'**
  String get manageCategories;

  /// No description provided for @manageAccounts.
  ///
  /// In en, this message translates to:
  /// **'Manage Accounts'**
  String get manageAccounts;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// Default category name: Entertainment
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// Default category name: Clothing
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// Default category name: Household Supplies
  ///
  /// In en, this message translates to:
  /// **'Household Supplies'**
  String get categoryHouseholdSupplies;

  /// Default category name: Communications
  ///
  /// In en, this message translates to:
  /// **'Communications'**
  String get categoryCommunications;

  /// Default category name: Health
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// Default category name: Education
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// Default category name: Gifts
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get categoryGifts;

  /// System category name: Balance correction (Expense)
  ///
  /// In en, this message translates to:
  /// **'Balance correction'**
  String get categoryReversalExpense;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryBonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get categoryBonus;

  /// Default category name: Part-time Job
  ///
  /// In en, this message translates to:
  /// **'Part-time Job'**
  String get categoryPartTimeJob;

  /// Default category name: Allowance
  ///
  /// In en, this message translates to:
  /// **'Allowance'**
  String get categoryAllowance;

  /// Default category name: Investment Returns
  ///
  /// In en, this message translates to:
  /// **'Investment Returns'**
  String get categoryInvestmentReturns;

  /// System category name: Balance correction (Income)
  ///
  /// In en, this message translates to:
  /// **'Balance correction'**
  String get categoryReversalIncome;

  /// No description provided for @accountCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountCash;

  /// No description provided for @accountBankCard.
  ///
  /// In en, this message translates to:
  /// **'Bank Card'**
  String get accountBankCard;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get errorAccountNotFound;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'Account is archived'**
  String get errorAccountArchived;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get errorCategoryNotFound;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'Category is archived'**
  String get errorCategoryArchived;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'Category type does not match the transaction type'**
  String get errorCategoryTypeMismatch;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'System categories cannot be archived'**
  String get errorSystemCategoryProtected;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'Invalid transfer'**
  String get errorInvalidTransfer;

  /// Localized ledger error code message
  ///
  /// In en, this message translates to:
  /// **'This transaction is not valid and was not saved'**
  String get errorInvalidTransactionShape;

  /// Transfer display label (US5)
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// Transfer display label (US5)
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get transferFrom;

  /// Transfer display label (US5)
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get transferTo;

  /// Transfer form title when creating (spec 004)
  ///
  /// In en, this message translates to:
  /// **'New Transfer'**
  String get addTransfer;

  /// Transfer form title when correcting (spec 004)
  ///
  /// In en, this message translates to:
  /// **'Edit Transfer'**
  String get editTransfer;

  /// Localized ledger error code message (US6)
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get errorTransactionNotFound;

  /// Localized ledger error code message (US6)
  ///
  /// In en, this message translates to:
  /// **'Transaction was already reversed'**
  String get errorTransactionAlreadyReversed;

  /// Localized ledger error code message (spec 004)
  ///
  /// In en, this message translates to:
  /// **'Both accounts must use the same currency'**
  String get errorCurrencyMismatch;

  /// Localized ledger error code message (spec 004)
  ///
  /// In en, this message translates to:
  /// **'Choose two different accounts'**
  String get errorSameAccountTransfer;

  /// Localized ledger error code message (spec 004)
  ///
  /// In en, this message translates to:
  /// **'This scheduled transaction was already posted'**
  String get errorScheduledAlreadyPosted;

  /// No description provided for @errorScheduledNotSkipped.
  ///
  /// In en, this message translates to:
  /// **'Only skipped bills can be restored to pending'**
  String get errorScheduledNotSkipped;

  /// No description provided for @errorRecurringSeriesStopped.
  ///
  /// In en, this message translates to:
  /// **'This recurring rule has been stopped'**
  String get errorRecurringSeriesStopped;

  /// No description provided for @errorScheduledDateTaken.
  ///
  /// In en, this message translates to:
  /// **'This series already has a bill on that date'**
  String get errorScheduledDateTaken;

  /// No description provided for @errorCountLimitTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Total occurrences must be greater than the bills already recorded or skipped'**
  String get errorCountLimitTooSmall;

  /// No description provided for @editRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit recurring bill'**
  String get editRecurringTitle;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextStep;

  /// No description provided for @billUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bill updated'**
  String get billUpdated;

  /// Localized ledger error code message (spec 004)
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknownEvent;

  /// Transaction detail section showing the event chain (US6)
  ///
  /// In en, this message translates to:
  /// **'Audit history'**
  String get auditHistory;

  /// Audit history entry for TransactionRecorded (US6)
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get eventRecorded;

  /// Audit history entry for TransactionReversed (US6)
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get eventReversed;

  /// Reversal reason label (US6)
  ///
  /// In en, this message translates to:
  /// **'User deleted'**
  String get reversalUserDeleted;

  /// Reversal reason label (US6)
  ///
  /// In en, this message translates to:
  /// **'Correction'**
  String get reversalCorrection;

  /// Developer-only maintenance entry (US8)
  ///
  /// In en, this message translates to:
  /// **'Rebuild projections'**
  String get rebuildProjections;

  /// Subtitle of the developer rebuild entry (US8)
  ///
  /// In en, this message translates to:
  /// **'Developer tool — long-press to run'**
  String get rebuildProjectionsHint;

  /// Confirmation dialog body (US8)
  ///
  /// In en, this message translates to:
  /// **'Clear all derived data and replay the full event history? Recurring rules and preferences are kept.'**
  String get rebuildProjectionsConfirm;

  /// Rebuild success snackbar (US8)
  ///
  /// In en, this message translates to:
  /// **'Projections rebuilt'**
  String get rebuildProjectionsSuccess;

  /// Rebuild failure snackbar (US8)
  ///
  /// In en, this message translates to:
  /// **'Rebuild failed'**
  String get rebuildProjectionsFailure;

  /// Title of the dialog shown when an expense overdraws a non-credit account
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get overdraftWarningTitle;

  /// Body of the overdraft confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This transaction will cause an overdraft. Continue?'**
  String get overdraftWarningMessage;

  /// Tooltip for the month picker's previous-year button
  ///
  /// In en, this message translates to:
  /// **'Previous Year'**
  String get previousYear;

  /// Tooltip for the month picker's next-year button
  ///
  /// In en, this message translates to:
  /// **'Next Year'**
  String get nextYear;

  /// File type label for the .flbackup filter in the platform file dialog
  ///
  /// In en, this message translates to:
  /// **'Accounted For backup'**
  String get backupFileTypeLabel;

  /// Settings entry that exports the ledger (spec 004, US4)
  ///
  /// In en, this message translates to:
  /// **'Back up now'**
  String get backupNow;

  /// Subtitle of the backup entry
  ///
  /// In en, this message translates to:
  /// **'Export the whole ledger to a single file'**
  String get backupNowHint;

  /// Settings entry that stages a restore (spec 004, US4)
  ///
  /// In en, this message translates to:
  /// **'Restore from backup'**
  String get restoreFromBackup;

  /// Subtitle of the restore entry
  ///
  /// In en, this message translates to:
  /// **'Replace all data from a backup file'**
  String get restoreFromBackupHint;

  /// Confirmation after a backup is shared
  ///
  /// In en, this message translates to:
  /// **'Backup created'**
  String get backupCreated;

  /// Title of the restore confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get restoreConfirmTitle;

  /// States exactly what a restore costs — a restore is a replacement, never a merge
  ///
  /// In en, this message translates to:
  /// **'This backup holds {backupEvents} events. This ledger has {currentEvents}, so restoring discards {discarded} of them. Everything currently stored will be replaced.'**
  String restoreConfirmMessage(
    int backupEvents,
    int currentEvents,
    int discarded,
  );

  /// Title shown once a restore has been staged
  ///
  /// In en, this message translates to:
  /// **'Restore ready'**
  String get restoreReadyTitle;

  /// Explains why a restart is needed: the database cannot be swapped while it is open
  ///
  /// In en, this message translates to:
  /// **'Close Accounted For completely and open it again to finish restoring.'**
  String get restoreReadyMessage;

  /// Button that closes the app so the staged restore can run
  ///
  /// In en, this message translates to:
  /// **'Exit now'**
  String get exitNow;

  /// No description provided for @postInstanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Record this bill'**
  String get postInstanceTitle;

  /// No description provided for @postInstanceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record this bill as a transaction?'**
  String get postInstanceConfirm;

  /// No description provided for @postInstance.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postInstance;

  /// No description provided for @instancePosted.
  ///
  /// In en, this message translates to:
  /// **'Bill recorded'**
  String get instancePosted;

  /// No description provided for @deleteRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete recurring bill'**
  String get deleteRecurringTitle;

  /// No description provided for @scopeThisOnly.
  ///
  /// In en, this message translates to:
  /// **'Only this bill'**
  String get scopeThisOnly;

  /// No description provided for @saveRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Save recurring bill'**
  String get saveRecurringTitle;

  /// No description provided for @scopeThisOnlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Category, account, repeat, auto-post and reminder belong to the whole rule'**
  String get scopeThisOnlyUnavailable;

  /// No description provided for @scopeThisAndFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and following bills'**
  String get scopeThisAndFollowing;

  /// No description provided for @scopeAll.
  ///
  /// In en, this message translates to:
  /// **'All bills'**
  String get scopeAll;

  /// No description provided for @scopeAllHint.
  ///
  /// In en, this message translates to:
  /// **'Bills already recorded are kept'**
  String get scopeAllHint;

  /// No description provided for @scopeUpdateRule.
  ///
  /// In en, this message translates to:
  /// **'Update repeating rule'**
  String get scopeUpdateRule;

  /// No description provided for @scopeUpdateRuleHint.
  ///
  /// In en, this message translates to:
  /// **'Recorded bills are kept; future pending bills follow the updated rule'**
  String get scopeUpdateRuleHint;

  /// No description provided for @skipThisBill.
  ///
  /// In en, this message translates to:
  /// **'Skip this bill'**
  String get skipThisBill;

  /// No description provided for @skipBillTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip this bill?'**
  String get skipBillTitle;

  /// No description provided for @skipBillConfirm.
  ///
  /// In en, this message translates to:
  /// **'This bill will not be recorded, while future bills in this repeating rule continue as scheduled.'**
  String get skipBillConfirm;

  /// No description provided for @skipBillAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipBillAction;

  /// No description provided for @billSkipped.
  ///
  /// In en, this message translates to:
  /// **'Bill skipped'**
  String get billSkipped;

  /// No description provided for @stopRepeatingRule.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get stopRepeatingRule;

  /// No description provided for @stopRepeatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating rule?'**
  String get stopRepeatingTitle;

  /// No description provided for @stopRepeatingConfirm.
  ///
  /// In en, this message translates to:
  /// **'All pending bills under this rule will be removed. Bills already recorded are kept.'**
  String get stopRepeatingConfirm;

  /// No description provided for @stopRepeatingAction.
  ///
  /// In en, this message translates to:
  /// **'Stop repeating'**
  String get stopRepeatingAction;

  /// No description provided for @repeatingStopped.
  ///
  /// In en, this message translates to:
  /// **'Repeating rule stopped'**
  String get repeatingStopped;

  /// No description provided for @deletePlan.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get deletePlan;

  /// No description provided for @deletePlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete plan?'**
  String get deletePlanTitle;

  /// No description provided for @deletePlanConfirm.
  ///
  /// In en, this message translates to:
  /// **'This planned bill will be permanently removed.'**
  String get deletePlanConfirm;

  /// No description provided for @billDeleted.
  ///
  /// In en, this message translates to:
  /// **'Bill deleted'**
  String get billDeleted;

  /// No description provided for @frequencyDaily.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get frequencyDaily;

  /// No description provided for @frequencyWeekly.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get frequencyWeekly;

  /// No description provided for @frequencyMonthly.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get frequencyMonthly;

  /// No description provided for @frequencyYearly.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get frequencyYearly;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes, categories, accounts'**
  String get searchHint;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTitle;

  /// No description provided for @filterAllKinds.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllKinds;

  /// No description provided for @filterAnyAccount.
  ///
  /// In en, this message translates to:
  /// **'Any account'**
  String get filterAnyAccount;

  /// No description provided for @filterAnyCategory.
  ///
  /// In en, this message translates to:
  /// **'Any category'**
  String get filterAnyCategory;

  /// No description provided for @filterAnyDate.
  ///
  /// In en, this message translates to:
  /// **'Any date'**
  String get filterAnyDate;

  /// No description provided for @filterDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get filterDateRange;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get filterApply;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get noSearchResults;

  /// No description provided for @pendingBill.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingBill;

  /// No description provided for @repeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// No description provided for @transactionModeDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get transactionModeDefault;

  /// No description provided for @transactionModePlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get transactionModePlanned;

  /// No description provided for @transactionModeSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get transactionModeSubscription;

  /// No description provided for @transactionModeRepeating.
  ///
  /// In en, this message translates to:
  /// **'Repeating'**
  String get transactionModeRepeating;

  /// Toggle in transaction form controlling whether a repeating series auto-posts when bills fall due
  ///
  /// In en, this message translates to:
  /// **'Auto-post'**
  String get autoPostWhenDue;

  /// Session banner on ledger screen when bounded materialization adds newly discovered overdue bills
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Added 1 overdue bill to review} other{Added {count} overdue bills to review}}'**
  String overdueBillsAdded(int count);

  /// No description provided for @repeatNever.
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get repeatNever;

  /// No description provided for @repeatSetupFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved. The repeat could not be set up: {error}'**
  String repeatSetupFailed(String error);

  /// Action that opens the transaction attachment picker
  ///
  /// In en, this message translates to:
  /// **'Add attachment'**
  String get addAttachment;

  /// Transaction attachment section label
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// Tooltip for removing an attachment from the transaction form
  ///
  /// In en, this message translates to:
  /// **'Remove attachment'**
  String get removeAttachment;

  /// Placeholder for a required choice that has not been made
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Number of attachments on a transaction
  ///
  /// In en, this message translates to:
  /// **'{count} attachments'**
  String attachmentCount(int count);

  /// No description provided for @uploadCategoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Upload icon'**
  String get uploadCategoryIcon;

  /// No description provided for @categoryIconFileType.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get categoryIconFileType;

  /// No description provided for @cropCategoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Crop icon'**
  String get cropCategoryIcon;

  /// No description provided for @categoryIconCropDescription.
  ///
  /// In en, this message translates to:
  /// **'Drag to move the image; pinch or use the slider to zoom.'**
  String get categoryIconCropDescription;

  /// No description provided for @invalidCategoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose a PNG or JPEG between 32 pixels and 5 MB.'**
  String get invalidCategoryIcon;

  /// No description provided for @categoryIconZoom.
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get categoryIconZoom;

  /// No description provided for @categoryIconUploadHint.
  ///
  /// In en, this message translates to:
  /// **'PNG or JPEG · up to 5 MB'**
  String get categoryIconUploadHint;

  /// No description provided for @customRepeat.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customRepeat;

  /// No description provided for @repeatEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get repeatEvery;

  /// No description provided for @repeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get repeatInterval;

  /// No description provided for @repeatStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get repeatStart;

  /// No description provided for @repeatEnds.
  ///
  /// In en, this message translates to:
  /// **'When to end'**
  String get repeatEnds;

  /// No description provided for @repeatNeverEnds.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNeverEnds;

  /// No description provided for @repeatUntil.
  ///
  /// In en, this message translates to:
  /// **'On date'**
  String get repeatUntil;

  /// No description provided for @repeatCount.
  ///
  /// In en, this message translates to:
  /// **'Number of occurrences'**
  String get repeatCount;

  /// No description provided for @repeatCountPrefix.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatCountPrefix;

  /// No description provided for @repeatCountSuffix.
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get repeatCountSuffix;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @reminderNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get reminderNone;

  /// No description provided for @reminder5.
  ///
  /// In en, this message translates to:
  /// **'5 minutes before'**
  String get reminder5;

  /// No description provided for @reminder10.
  ///
  /// In en, this message translates to:
  /// **'10 minutes before'**
  String get reminder10;

  /// No description provided for @reminder15.
  ///
  /// In en, this message translates to:
  /// **'15 minutes before'**
  String get reminder15;

  /// No description provided for @reminder30.
  ///
  /// In en, this message translates to:
  /// **'30 minutes before'**
  String get reminder30;

  /// No description provided for @reminderHour.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get reminderHour;

  /// No description provided for @reminderDay.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get reminderDay;

  /// No description provided for @reminderCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get reminderCustom;

  /// No description provided for @reminderUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get reminderUnitMinutes;

  /// No description provided for @reminderUnitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get reminderUnitHours;

  /// No description provided for @reminderUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get reminderUnitDays;

  /// No description provided for @reminderPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications and precise alarms to use reminders.'**
  String get reminderPermissionRequired;

  /// No description provided for @reminderNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming transaction'**
  String get reminderNotificationTitle;

  /// No description provided for @reminderChannel.
  ///
  /// In en, this message translates to:
  /// **'Transaction reminders'**
  String get reminderChannel;

  /// No description provided for @reminderCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom reminder'**
  String get reminderCustomTitle;

  /// No description provided for @reminderAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reminderAmount;

  /// No description provided for @reminderMinutesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes before'**
  String reminderMinutesValue(int count);

  /// No description provided for @notificationSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get notificationSkip;

  /// No description provided for @notificationSkipped.
  ///
  /// In en, this message translates to:
  /// **'Bill skipped'**
  String get notificationSkipped;

  /// No description provided for @notificationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This bill is no longer available.'**
  String get notificationUnavailable;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'This bill has been deleted.'**
  String get notificationDeleted;

  /// No description provided for @accountArchiveAction.
  ///
  /// In en, this message translates to:
  /// **'Archive account'**
  String get accountArchiveAction;

  /// No description provided for @accountRestoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore account'**
  String get accountRestoreAction;

  /// No description provided for @accountArchivedSection.
  ///
  /// In en, this message translates to:
  /// **'Archived accounts'**
  String get accountArchivedSection;

  /// No description provided for @accountArchiveExplanation.
  ///
  /// In en, this message translates to:
  /// **'Archiving permanently deletes this account’s recurring rules and future pending bills, and cancels their reminders. Overdue pending bills and recorded transactions are kept. Restoring the account will not restore the deleted rules or bills.'**
  String get accountArchiveExplanation;

  /// No description provided for @accountDeleteExplanation.
  ///
  /// In en, this message translates to:
  /// **'Delete this account? Its event history is retained.'**
  String get accountDeleteExplanation;

  /// No description provided for @accountUsageTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get accountUsageTransactions;

  /// No description provided for @accountUsageSeries.
  ///
  /// In en, this message translates to:
  /// **'Recurring rules'**
  String get accountUsageSeries;

  /// No description provided for @accountUsagePending.
  ///
  /// In en, this message translates to:
  /// **'Pending bills'**
  String get accountUsagePending;

  /// No description provided for @errorAccountHasReferences.
  ///
  /// In en, this message translates to:
  /// **'This account has active transactions or recurring rules. Archive it instead, or resolve the linked records first.'**
  String get errorAccountHasReferences;

  /// No description provided for @errorAccountHasActiveSchedules.
  ///
  /// In en, this message translates to:
  /// **'This account has active recurring rules or pending bills. Resolve them before archiving.'**
  String get errorAccountHasActiveSchedules;

  /// No description provided for @accountDeleteChooseAction.
  ///
  /// In en, this message translates to:
  /// **'This account has transactions or scheduled rules. Choose how to proceed.'**
  String get accountDeleteChooseAction;

  /// No description provided for @accountDeleteArchivedChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose whether to delete the associated transactions and scheduled rules or move them to another account.'**
  String get accountDeleteArchivedChooseAction;

  /// No description provided for @accountMoveAndDelete.
  ///
  /// In en, this message translates to:
  /// **'Move records and delete'**
  String get accountMoveAndDelete;

  /// No description provided for @accountDeleteWithTransactions.
  ///
  /// In en, this message translates to:
  /// **'Delete account and records'**
  String get accountDeleteWithTransactions;

  /// No description provided for @accountSelectDestination.
  ///
  /// In en, this message translates to:
  /// **'Select a destination account'**
  String get accountSelectDestination;

  /// No description provided for @accountNoDestination.
  ///
  /// In en, this message translates to:
  /// **'No other active account with the same currency is available.'**
  String get accountNoDestination;

  /// No description provided for @accountDeleteImpact.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustments will be reversed. Deleting records also reverses transfers on the other account; moving records changes the destination account balance. Scheduled rules follow the selected action.'**
  String get accountDeleteImpact;

  /// No description provided for @accountConfirmOperation.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get accountConfirmOperation;

  /// No description provided for @supportCenter.
  ///
  /// In en, this message translates to:
  /// **'Support center'**
  String get supportCenter;

  /// No description provided for @supportCenterHint.
  ///
  /// In en, this message translates to:
  /// **'Get help and find answers'**
  String get supportCenterHint;

  /// No description provided for @appOverview.
  ///
  /// In en, this message translates to:
  /// **'App overview'**
  String get appOverview;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get termsOfService;

  /// No description provided for @feedbackConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Your email app will open to send feedback to {email}.'**
  String feedbackConfirmation(String email);

  /// No description provided for @openEmailApp.
  ///
  /// In en, this message translates to:
  /// **'Open email app'**
  String get openEmailApp;

  /// No description provided for @feedbackEmailSubject.
  ///
  /// In en, this message translates to:
  /// **'Accounted For feedback'**
  String get feedbackEmailSubject;

  /// No description provided for @emailUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get emailUnavailable;

  /// No description provided for @emailUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'No email app could be opened. You can copy {email} and contact us from another app.'**
  String emailUnavailableMessage(String email);

  /// No description provided for @copyEmail.
  ///
  /// In en, this message translates to:
  /// **'Copy email'**
  String get copyEmail;

  /// No description provided for @linkUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get linkUnavailable;

  /// No description provided for @linkUnavailableMessage.
  ///
  /// In en, this message translates to:
  /// **'Please check that a browser is available and try again.'**
  String get linkUnavailableMessage;

  /// No description provided for @autoPostedCountMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Auto-posted 1 scheduled bill} other{Auto-posted {count} scheduled bills}}'**
  String autoPostedCountMessage(int count);

  /// No description provided for @skippedBill.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skippedBill;

  /// No description provided for @restoreToPending.
  ///
  /// In en, this message translates to:
  /// **'Restore to pending'**
  String get restoreToPending;

  /// No description provided for @billRestored.
  ///
  /// In en, this message translates to:
  /// **'Bill restored to pending'**
  String get billRestored;

  /// No description provided for @failedBill.
  ///
  /// In en, this message translates to:
  /// **'Auto-post failed'**
  String get failedBill;

  /// No description provided for @failedBillBanner.
  ///
  /// In en, this message translates to:
  /// **'Automatic posting failed. Check the account or category, then retry or skip.'**
  String get failedBillBanner;

  /// No description provided for @retryPost.
  ///
  /// In en, this message translates to:
  /// **'Retry post'**
  String get retryPost;

  /// No description provided for @currencyBacklogTitle.
  ///
  /// In en, this message translates to:
  /// **'Due auto-posting bills in {currency}'**
  String currencyBacklogTitle(String currency);

  /// No description provided for @currencyBacklogMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 auto-posting bill became due while using another currency.} other{{count} auto-posting bills became due while using another currency.}}'**
  String currencyBacklogMessage(int count);

  /// No description provided for @currencyBacklogPostAll.
  ///
  /// In en, this message translates to:
  /// **'Post all'**
  String get currencyBacklogPostAll;

  /// No description provided for @currencyBacklogKeepPending.
  ///
  /// In en, this message translates to:
  /// **'Keep as pending'**
  String get currencyBacklogKeepPending;

  /// No description provided for @errorBudgetNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Review note cannot exceed 500 characters'**
  String get errorBudgetNoteTooLong;

  /// No description provided for @budgetModePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get budgetModePlan;

  /// No description provided for @budgetModeTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get budgetModeTrack;

  /// No description provided for @budgetModeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get budgetModeReview;

  /// No description provided for @budgetReviewPreviewToggle.
  ///
  /// In en, this message translates to:
  /// **'Review preview'**
  String get budgetReviewPreviewToggle;

  /// No description provided for @budgetTracking.
  ///
  /// In en, this message translates to:
  /// **'Budget tracking'**
  String get budgetTracking;

  /// No description provided for @budgetTotal.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get budgetTotal;

  /// No description provided for @budgetActualSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budgetActualSpent;

  /// No description provided for @budgetPendingShort.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get budgetPendingShort;

  /// No description provided for @budgetProjectedRemaining.
  ///
  /// In en, this message translates to:
  /// **'Projected left'**
  String get budgetProjectedRemaining;

  /// No description provided for @budgetProjectedOver.
  ///
  /// In en, this message translates to:
  /// **'Projected over'**
  String get budgetProjectedOver;

  /// No description provided for @budgetCompliance.
  ///
  /// In en, this message translates to:
  /// **'On budget'**
  String get budgetCompliance;

  /// No description provided for @budgetCommitted.
  ///
  /// In en, this message translates to:
  /// **'Committed'**
  String get budgetCommitted;

  /// No description provided for @budgetCommittedSpending.
  ///
  /// In en, this message translates to:
  /// **'Committed spending'**
  String get budgetCommittedSpending;

  /// No description provided for @budgetDiscretionarySpending.
  ///
  /// In en, this message translates to:
  /// **'Discretionary spending'**
  String get budgetDiscretionarySpending;

  /// No description provided for @budgetDiscretionary.
  ///
  /// In en, this message translates to:
  /// **'Discretionary'**
  String get budgetDiscretionary;

  /// No description provided for @budgetCommittedBaseline.
  ///
  /// In en, this message translates to:
  /// **'Committed baseline'**
  String get budgetCommittedBaseline;

  /// No description provided for @budgetOverviewMonthlySurplus.
  ///
  /// In en, this message translates to:
  /// **'Monthly surplus'**
  String get budgetOverviewMonthlySurplus;

  /// No description provided for @budgetOverviewMonthlyOverspend.
  ///
  /// In en, this message translates to:
  /// **'Monthly overspend'**
  String get budgetOverviewMonthlyOverspend;

  /// No description provided for @budgetOverviewAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available to spend'**
  String get budgetOverviewAvailable;

  /// No description provided for @budgetOverviewBudgetUsage.
  ///
  /// In en, this message translates to:
  /// **'Budget used'**
  String get budgetOverviewBudgetUsage;

  /// No description provided for @budgetOverviewBaselineShare.
  ///
  /// In en, this message translates to:
  /// **'Baseline share'**
  String get budgetOverviewBaselineShare;

  /// No description provided for @budgetAllExpensesLine.
  ///
  /// In en, this message translates to:
  /// **'All expenses {total} (unbudgeted {unbudgeted})'**
  String budgetAllExpensesLine(String total, String unbudgeted);

  /// No description provided for @budgetAllExpensesOnly.
  ///
  /// In en, this message translates to:
  /// **'All expenses {total}'**
  String budgetAllExpensesOnly(String total);

  /// No description provided for @budgetLeftoverPendingHint.
  ///
  /// In en, this message translates to:
  /// **'Past month has unposted scheduled bills excluded from review totals.'**
  String get budgetLeftoverPendingHint;

  /// No description provided for @budgetMaterializedOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Includes materialized pending bills only.'**
  String get budgetMaterializedOnlyHint;

  /// No description provided for @budgetTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'6-Month Budget vs Actual'**
  String get budgetTrendTitle;

  /// No description provided for @budgetReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly Review & Trends'**
  String get budgetReviewTitle;

  /// No description provided for @budgetReviewScopeNote.
  ///
  /// In en, this message translates to:
  /// **'Whole month, including unbudgeted categories.'**
  String get budgetReviewScopeNote;

  /// No description provided for @budgetReviewCommittedActual.
  ///
  /// In en, this message translates to:
  /// **'Committed spent'**
  String get budgetReviewCommittedActual;

  /// No description provided for @budgetReviewDiscretionaryActual.
  ///
  /// In en, this message translates to:
  /// **'Discretionary spent'**
  String get budgetReviewDiscretionaryActual;

  /// No description provided for @budgetReviewBaselineNote.
  ///
  /// In en, this message translates to:
  /// **'Committed spent + effective pending bills. Reference only; the three figures are not additive.'**
  String get budgetReviewBaselineNote;

  /// No description provided for @budgetReviewNoteEmptyDeletes.
  ///
  /// In en, this message translates to:
  /// **'Leave the note empty and save to remove it.'**
  String get budgetReviewNoteEmptyDeletes;

  /// No description provided for @budgetTrendLegendActual.
  ///
  /// In en, this message translates to:
  /// **'All actual spend'**
  String get budgetTrendLegendActual;

  /// No description provided for @budgetTrendLegendBudget.
  ///
  /// In en, this message translates to:
  /// **'Total budget'**
  String get budgetTrendLegendBudget;

  /// No description provided for @budgetTrendLegendAverage.
  ///
  /// In en, this message translates to:
  /// **'3-month average'**
  String get budgetTrendLegendAverage;

  /// No description provided for @budgetAttributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Month Review & Attribution'**
  String get budgetAttributionTitle;

  /// No description provided for @budgetOverTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Over Budget'**
  String get budgetOverTopTitle;

  /// No description provided for @budgetUnderTopTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Under Budget'**
  String get budgetUnderTopTitle;

  /// No description provided for @budgetUnbudgetedAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Unbudgeted Spend Alerts'**
  String get budgetUnbudgetedAlertsTitle;

  /// No description provided for @budgetMonthNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Month review note'**
  String get budgetMonthNoteLabel;

  /// No description provided for @budgetCategoryNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Category review note'**
  String get budgetCategoryNoteLabel;

  /// No description provided for @budgetNotePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a brief note on why this month varied (max 500 chars)...'**
  String get budgetNotePlaceholder;

  /// No description provided for @budgetNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Review note saved'**
  String get budgetNoteSaved;

  /// No description provided for @budgetSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get budgetSaveNote;

  /// No description provided for @budgetNoteCharCount.
  ///
  /// In en, this message translates to:
  /// **'{count}/500'**
  String budgetNoteCharCount(int count);

  /// No description provided for @budgetSectionBudgeted.
  ///
  /// In en, this message translates to:
  /// **'Budgeted categories'**
  String get budgetSectionBudgeted;

  /// No description provided for @budgetSectionUnbudgetedActive.
  ///
  /// In en, this message translates to:
  /// **'Unbudgeted spending'**
  String get budgetSectionUnbudgetedActive;

  /// No description provided for @budgetSectionRemaining.
  ///
  /// In en, this message translates to:
  /// **'Other categories (tap to set budget)'**
  String get budgetSectionRemaining;

  /// No description provided for @budgetSetButton.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get budgetSetButton;

  /// No description provided for @budgetRowProjectedOver.
  ///
  /// In en, this message translates to:
  /// **'Projected over {amount}'**
  String budgetRowProjectedOver(String amount);

  /// No description provided for @budgetRowOver.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String budgetRowOver(String amount);

  /// No description provided for @budgetRowRemaining.
  ///
  /// In en, this message translates to:
  /// **'Left {amount}'**
  String budgetRowRemaining(String amount);

  /// No description provided for @budgetRowReviewRemaining.
  ///
  /// In en, this message translates to:
  /// **'Unspent {amount}'**
  String budgetRowReviewRemaining(String amount);

  /// No description provided for @budgetRowReviewOver.
  ///
  /// In en, this message translates to:
  /// **'Overspent {amount}'**
  String budgetRowReviewOver(String amount);

  /// No description provided for @budgetRowPlanBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget {amount}'**
  String budgetRowPlanBudget(String amount);

  /// No description provided for @budgetRowPendingIncluded.
  ///
  /// In en, this message translates to:
  /// **'Includes {amount} pending'**
  String budgetRowPendingIncluded(String amount);

  /// No description provided for @budgetRowPending.
  ///
  /// In en, this message translates to:
  /// **'Pending {amount}'**
  String budgetRowPending(String amount);

  /// No description provided for @budgetRowUsage.
  ///
  /// In en, this message translates to:
  /// **'Used {percent}'**
  String budgetRowUsage(String percent);

  /// No description provided for @budgetRowBaseline.
  ///
  /// In en, this message translates to:
  /// **'Fixed baseline {amount}'**
  String budgetRowBaseline(String amount);

  /// No description provided for @budgetRowShare.
  ///
  /// In en, this message translates to:
  /// **'{percent} of month\'s spend'**
  String budgetRowShare(String percent);

  /// No description provided for @budgetRowGroupSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent {amount}'**
  String budgetRowGroupSpent(String amount);

  /// No description provided for @budgetRowAnomalySemantics.
  ///
  /// In en, this message translates to:
  /// **'Unusually high against its three-month average'**
  String get budgetRowAnomalySemantics;

  /// No description provided for @budgetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Category Budget'**
  String get budgetEditTitle;

  /// No description provided for @budgetAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get budgetAmountLabel;

  /// No description provided for @budgetLastMonthRef.
  ///
  /// In en, this message translates to:
  /// **'Last mo {amount}'**
  String budgetLastMonthRef(String amount);

  /// No description provided for @budgetThreeMoAvgRef.
  ///
  /// In en, this message translates to:
  /// **'3-mo avg {amount}'**
  String budgetThreeMoAvgRef(String amount);

  /// No description provided for @budgetCommittedRef.
  ///
  /// In en, this message translates to:
  /// **'Committed {amount}'**
  String budgetCommittedRef(String amount);

  /// No description provided for @budgetScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Apply changes to'**
  String get budgetScopeLabel;

  /// No description provided for @budgetScopeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month only'**
  String get budgetScopeThisMonth;

  /// No description provided for @budgetScopeThisAndFollowing.
  ///
  /// In en, this message translates to:
  /// **'This & following months'**
  String get budgetScopeThisAndFollowing;

  /// No description provided for @budgetScopeFutureOverrideWarning.
  ///
  /// In en, this message translates to:
  /// **'Later months already have custom rules and will be replaced.'**
  String get budgetScopeFutureOverrideWarning;

  /// No description provided for @budgetHistoryEditHint.
  ///
  /// In en, this message translates to:
  /// **'Past month has ended. Consider adjusting current or future months instead.'**
  String get budgetHistoryEditHint;

  /// No description provided for @budgetZeroAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Budget must be greater than 0. Tap Remove budget to unset.'**
  String get budgetZeroAmountHint;

  /// No description provided for @budgetClearAction.
  ///
  /// In en, this message translates to:
  /// **'Remove budget'**
  String get budgetClearAction;

  /// No description provided for @budgetClearConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {category} budget?'**
  String budgetClearConfirmTitle(String category);

  /// No description provided for @budgetClearConfirmThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Deletes the {amount} {category} budget for {month} and clears this month\'s category review note.'**
  String budgetClearConfirmThisMonth(
    String month,
    String category,
    String amount,
  );

  /// No description provided for @budgetClearConfirmThisAndFollowing.
  ///
  /// In en, this message translates to:
  /// **'Deletes the {amount} {category} budget for {month} and clears {category} review notes from {month} onward, including months that carry the budget forward.'**
  String budgetClearConfirmThisAndFollowing(
    String month,
    String category,
    String amount,
  );

  /// No description provided for @budgetClearFutureRulesWarning.
  ///
  /// In en, this message translates to:
  /// **'Budgets already set in later months will also be removed.'**
  String get budgetClearFutureRulesWarning;

  /// No description provided for @budgetSaved.
  ///
  /// In en, this message translates to:
  /// **'Budget updated'**
  String get budgetSaved;

  /// No description provided for @budgetCleared.
  ///
  /// In en, this message translates to:
  /// **'Budget removed'**
  String get budgetCleared;

  /// No description provided for @budgetStatusInBudget.
  ///
  /// In en, this message translates to:
  /// **'In budget'**
  String get budgetStatusInBudget;

  /// No description provided for @budgetStatusAtRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get budgetStatusAtRisk;

  /// No description provided for @budgetStatusOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get budgetStatusOver;

  /// No description provided for @budgetAnomalyBadge.
  ///
  /// In en, this message translates to:
  /// **'+{percent}% vs 3m avg'**
  String budgetAnomalyBadge(int percent);

  /// No description provided for @budgetArchivedReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get budgetArchivedReadOnly;

  /// No description provided for @budgetArchivedNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Archived category — historical budgets and notes are read-only.'**
  String get budgetArchivedNoteHint;

  /// No description provided for @budgetTopTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Top contributing expenses'**
  String get budgetTopTransactionsTitle;

  /// No description provided for @budgetViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get budgetViewAll;

  /// No description provided for @budgetNoTransactionsInMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses recorded in this month.'**
  String get budgetNoTransactionsInMonth;

  /// No description provided for @budgetEmptyNoAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account to start budgeting'**
  String get budgetEmptyNoAccountsTitle;

  /// No description provided for @budgetEmptyNoAccountsBody.
  ///
  /// In en, this message translates to:
  /// **'No active accounts exist for {currency} yet.'**
  String budgetEmptyNoAccountsBody(String currency);

  /// No description provided for @budgetEmptyNoBudgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan your monthly spending'**
  String get budgetEmptyNoBudgetsTitle;

  /// No description provided for @budgetEmptyNoBudgetsBody.
  ///
  /// In en, this message translates to:
  /// **'Tap any category below or + above to set your first category limit.'**
  String get budgetEmptyNoBudgetsBody;

  /// No description provided for @budgetPickCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose category'**
  String get budgetPickCategoryTitle;

  /// No description provided for @budgetHintRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining {remaining} · After this: {after}'**
  String budgetHintRemaining(String remaining, String after);

  /// No description provided for @budgetHintAtRisk.
  ///
  /// In en, this message translates to:
  /// **'After this + pending: {after} over'**
  String budgetHintAtRisk(String after);

  /// No description provided for @budgetHintOver.
  ///
  /// In en, this message translates to:
  /// **'Budget exceeded by {over} after this'**
  String budgetHintOver(String over);

  /// No description provided for @budgetHintUnset.
  ///
  /// In en, this message translates to:
  /// **'No budget set · Month spent {spent}'**
  String budgetHintUnset(String spent);

  /// No description provided for @budgetHintExcludedAccount.
  ///
  /// In en, this message translates to:
  /// **'Excluded from budget totals'**
  String get budgetHintExcludedAccount;

  /// No description provided for @budgetHintPastPlanned.
  ///
  /// In en, this message translates to:
  /// **'Past-month planned bills are excluded from closed reviews'**
  String get budgetHintPastPlanned;

  /// No description provided for @hideOverviewAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide overview amounts'**
  String get hideOverviewAmounts;

  /// No description provided for @showOverviewAmounts.
  ///
  /// In en, this message translates to:
  /// **'Show overview amounts'**
  String get showOverviewAmounts;

  /// No description provided for @monthIncome.
  ///
  /// In en, this message translates to:
  /// **'{month} income'**
  String monthIncome(String month);

  /// No description provided for @monthExpense.
  ///
  /// In en, this message translates to:
  /// **'{month} expense'**
  String monthExpense(String month);

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
