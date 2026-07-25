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
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Feather Ledger'**
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

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Save transaction button
  ///
  /// In en, this message translates to:
  /// **'Save Transaction'**
  String get saveTransaction;

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

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

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

  /// Activity heatmap section title
  ///
  /// In en, this message translates to:
  /// **'Activity Heatmap'**
  String get activityHeatmap;

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

  /// Initial balance field label
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get initialBalance;

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
  /// **'Account balance adjustment'**
  String get accountBalanceAdjustmentDescription;

  /// Note on the transaction recording a new account's starting balance
  ///
  /// In en, this message translates to:
  /// **'Difference'**
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
  /// **'Automated adjustment for account balance change.'**
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
  /// **'Version details and open-source licences'**
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

  /// Prompt shown when user needs to press back again to exit
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get pressBackAgainToExit;

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

  /// No description provided for @errorScheduledDateTaken.
  ///
  /// In en, this message translates to:
  /// **'This series already has a bill on that date'**
  String get errorScheduledDateTaken;

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
  /// **'Feather Ledger backup'**
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
      int backupEvents, int currentEvents, int discarded);

  /// Title shown once a restore has been staged
  ///
  /// In en, this message translates to:
  /// **'Restore ready'**
  String get restoreReadyTitle;

  /// Explains why a restart is needed: the database cannot be swapped while it is open
  ///
  /// In en, this message translates to:
  /// **'Close Feather Ledger completely and open it again to finish restoring.'**
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
  /// **'This bill'**
  String get scopeThisOnly;

  /// No description provided for @saveRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Save recurring bill'**
  String get saveRecurringTitle;

  /// No description provided for @scopeThisOnlyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Category, account and note belong to the whole rule'**
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
      'that was used.');
}
