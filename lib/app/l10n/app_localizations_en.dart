// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Accounted For';

  @override
  String get ledgerTitle => 'Ledger';

  @override
  String get income => 'Income';

  @override
  String get expense => 'Expense';

  @override
  String get balance => 'Balance';

  @override
  String get monthEndBalance => 'Month-end balance';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get noTransactionsThisMonth => 'No transactions this month';

  @override
  String get noTransactionsTitle => 'No transactions';

  @override
  String get noTransactionsHint => 'Tap + to add a new one';

  @override
  String get noAccountsInCurrencyTitle => 'No accounts in this currency';

  @override
  String get noAccountsInCurrencyHint => 'Create an account to start tracking';

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
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get tomorrow => 'Tomorrow';

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
  String get noteHint => 'Add a note';

  @override
  String get save => 'Save';

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
  String get settingsHint => 'Theme, language and currency';

  @override
  String get theme => 'Theme';

  @override
  String get language => 'Language';

  @override
  String get currencySymbol => 'Currency Symbol';

  @override
  String get accountCurrency => 'Currency';

  @override
  String get accountAllCurrencies => 'All currencies';

  @override
  String accountBalanceAdjustmentLedgerHint(String currency) {
    return 'Balance changes are recorded in the $currency ledger.';
  }

  @override
  String get system => 'System';

  @override
  String get followSystem => 'Follow system';

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
  String heatmapNetFlow(String amount) {
    return 'Net flow: $amount';
  }

  @override
  String get heatmapZeroNetFlow => 'Zero net flow';

  @override
  String get heatmapNetInflow => 'Net inflow';

  @override
  String get heatmapNetOutflow => 'Net outflow';

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
  String get accountsHint => 'Your accounts and their balances';

  @override
  String get categories => 'Categories';

  @override
  String get categoriesHint => 'Income and expense categories';

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
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank account';

  @override
  String get accountTypeCredit => 'Credit card';

  @override
  String get accountTypeOther => 'Other account';

  @override
  String get accountExcludedFromTotals => 'Excluded from totals';

  @override
  String get accountArchived => 'Archived';

  @override
  String get initialBalance => 'Initial Balance';

  @override
  String get transactionType => 'Type';

  @override
  String get accountSaved => 'Account saved';

  @override
  String get balanceChangeDetectedTitle => 'Balance change detected';

  @override
  String get balanceChangeDetectedMessage =>
      'Balance has changed. A correction transaction will be created. Continue?';

  @override
  String get accountBalanceAdjustmentDescription => 'Balance adjustment';

  @override
  String get accountInitialBalanceNote => 'Initial Balance';

  @override
  String get accountIncludeInTotals => 'Include in totals';

  @override
  String get accountIncludeInTotalsHint =>
      'Off: this account is left out of the total balance and the income and expense totals. Its transactions still show in the ledger.';

  @override
  String get accountBalanceAdjustmentNotes => 'Balance correction';

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
  String get feedbackHint => 'Tell us what you think';

  @override
  String get about => 'About';

  @override
  String get aboutHint => 'App information and open-source licences';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get version => 'Version';

  @override
  String get featureNotAvailable => 'Feature not available';

  @override
  String get manageCategories => 'Manage Categories';

  @override
  String get manageAccounts => 'Manage Accounts';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryClothing => 'Clothing';

  @override
  String get categoryHouseholdSupplies => 'Household Supplies';

  @override
  String get categoryCommunications => 'Communications';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categoryGifts => 'Gifts';

  @override
  String get categoryReversalExpense => 'Balance correction';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryBonus => 'Bonus';

  @override
  String get categoryPartTimeJob => 'Part-time Job';

  @override
  String get categoryAllowance => 'Allowance';

  @override
  String get categoryInvestmentReturns => 'Investment Returns';

  @override
  String get categoryReversalIncome => 'Balance correction';

  @override
  String get accountCash => 'Cash';

  @override
  String get accountBankCard => 'Bank Card';

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
  String get errorInvalidTransactionShape =>
      'This transaction is not valid and was not saved';

  @override
  String get transfer => 'Transfer';

  @override
  String get transferFrom => 'From';

  @override
  String get transferTo => 'To';

  @override
  String get addTransfer => 'New Transfer';

  @override
  String get editTransfer => 'Edit Transfer';

  @override
  String get errorTransactionNotFound => 'Transaction not found';

  @override
  String get errorTransactionAlreadyReversed =>
      'Transaction was already reversed';

  @override
  String get errorCurrencyMismatch =>
      'Both accounts must use the same currency';

  @override
  String get errorSameAccountTransfer => 'Choose two different accounts';

  @override
  String get errorScheduledAlreadyPosted =>
      'This scheduled transaction was already posted';

  @override
  String get errorScheduledDateTaken =>
      'This series already has a bill on that date';

  @override
  String get editRecurringTitle => 'Edit recurring bill';

  @override
  String get nextStep => 'Next';

  @override
  String get billUpdated => 'Bill updated';

  @override
  String get errorUnknownEvent => 'Something went wrong. Please try again.';

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
  String get overdraftWarningTitle => 'Warning';

  @override
  String get overdraftWarningMessage =>
      'This transaction will cause an overdraft. Continue?';

  @override
  String get previousYear => 'Previous Year';

  @override
  String get nextYear => 'Next Year';

  @override
  String get backupFileTypeLabel => 'Accounted For backup';

  @override
  String get backupNow => 'Back up now';

  @override
  String get backupNowHint => 'Export the whole ledger to a single file';

  @override
  String get restoreFromBackup => 'Restore from backup';

  @override
  String get restoreFromBackupHint => 'Replace all data from a backup file';

  @override
  String get backupCreated => 'Backup created';

  @override
  String get restoreConfirmTitle => 'Replace all data?';

  @override
  String restoreConfirmMessage(
      int backupEvents, int currentEvents, int discarded) {
    return 'This backup holds $backupEvents events. This ledger has $currentEvents, so restoring discards $discarded of them. Everything currently stored will be replaced.';
  }

  @override
  String get restoreReadyTitle => 'Restore ready';

  @override
  String get restoreReadyMessage =>
      'Close Accounted For completely and open it again to finish restoring.';

  @override
  String get exitNow => 'Exit now';

  @override
  String get postInstanceTitle => 'Record this bill';

  @override
  String get postInstanceConfirm => 'Record this bill as a transaction?';

  @override
  String get postInstance => 'Post';

  @override
  String get instancePosted => 'Bill recorded';

  @override
  String get deleteRecurringTitle => 'Delete recurring bill';

  @override
  String get scopeThisOnly => 'This bill';

  @override
  String get saveRecurringTitle => 'Save recurring bill';

  @override
  String get scopeThisOnlyUnavailable =>
      'Category, account, note and reminder belong to the whole rule';

  @override
  String get scopeThisAndFollowing => 'This and following bills';

  @override
  String get scopeAll => 'All bills';

  @override
  String get scopeAllHint => 'Bills already recorded are kept';

  @override
  String get billDeleted => 'Bill deleted';

  @override
  String get frequencyDaily => 'day';

  @override
  String get frequencyWeekly => 'week';

  @override
  String get frequencyMonthly => 'month';

  @override
  String get frequencyYearly => 'year';

  @override
  String get searchHint => 'Search notes, categories, accounts';

  @override
  String get filterTitle => 'Filter';

  @override
  String get filterAllKinds => 'All';

  @override
  String get filterAnyAccount => 'Any account';

  @override
  String get filterAnyCategory => 'Any category';

  @override
  String get filterAnyDate => 'Any date';

  @override
  String get filterDateRange => 'Date range';

  @override
  String get filterApply => 'Apply';

  @override
  String get filterClear => 'Clear';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get noSearchResults => 'No matching transactions';

  @override
  String get pendingBill => 'Pending';

  @override
  String get repeat => 'Repeat';

  @override
  String get transactionModeDefault => 'Default';

  @override
  String get transactionModePlanned => 'Planned';

  @override
  String get transactionModeSubscription => 'Subscription';

  @override
  String get transactionModeRepeating => 'Repeating';

  @override
  String get autoPostSettingsTitle => 'Auto-post bills';

  @override
  String get restoreConfirmationTitle => 'Restore confirmation';

  @override
  String get restoreConfirmationRisk =>
      'These bills may have been recorded on another device.';

  @override
  String restoreConfirmationCount(int count) {
    return '$count bills';
  }

  @override
  String get restoreReject => 'Turn manual';

  @override
  String get restoreDefer => 'Later';

  @override
  String get repeatNever => 'Does not repeat';

  @override
  String repeatSetupFailed(String error) {
    return 'Saved. The repeat could not be set up: $error';
  }

  @override
  String get addAttachment => 'Add attachment';

  @override
  String get attachments => 'Attachments';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get select => 'Select';

  @override
  String attachmentCount(int count) {
    return '$count attachments';
  }

  @override
  String get uploadCategoryIcon => 'Upload icon';

  @override
  String get categoryIconFileType => 'Images';

  @override
  String get cropCategoryIcon => 'Crop icon';

  @override
  String get categoryIconCropDescription =>
      'Drag to move the image; pinch or use the slider to zoom.';

  @override
  String get invalidCategoryIcon =>
      'Choose a PNG or JPEG between 32 pixels and 5 MB.';

  @override
  String get categoryIconZoom => 'Zoom';

  @override
  String get categoryIconUploadHint => 'PNG or JPEG · up to 5 MB';

  @override
  String get customRepeat => 'Custom';

  @override
  String get repeatEvery => 'Every';

  @override
  String get repeatInterval => 'Interval';

  @override
  String get repeatStart => 'Start';

  @override
  String get repeatEnds => 'When to end';

  @override
  String get repeatNeverEnds => 'Never';

  @override
  String get repeatUntil => 'On date';

  @override
  String get repeatCount => 'Number of occurrences';

  @override
  String get repeatCountPrefix => 'Repeat';

  @override
  String get repeatCountSuffix => 'times';

  @override
  String get reminder => 'Reminder';

  @override
  String get reminderNone => 'None';

  @override
  String get reminder5 => '5 minutes before';

  @override
  String get reminder10 => '10 minutes before';

  @override
  String get reminder15 => '15 minutes before';

  @override
  String get reminder30 => '30 minutes before';

  @override
  String get reminderHour => '1 hour before';

  @override
  String get reminderDay => '1 day before';

  @override
  String get reminderCustom => 'Custom';

  @override
  String get reminderUnitMinutes => 'Minutes';

  @override
  String get reminderUnitHours => 'Hours';

  @override
  String get reminderUnitDays => 'Days';

  @override
  String get reminderPermissionRequired =>
      'Allow notifications and precise alarms to use reminders.';

  @override
  String get reminderNotificationTitle => 'Upcoming transaction';

  @override
  String get reminderChannel => 'Transaction reminders';

  @override
  String get reminderCustomTitle => 'Custom reminder';

  @override
  String get reminderAmount => 'Amount';

  @override
  String reminderMinutesValue(int count) {
    return '$count minutes before';
  }

  @override
  String get notificationSkip => 'Skip';

  @override
  String get notificationSkipped => 'Bill skipped';

  @override
  String get notificationUnavailable => 'This bill is no longer available.';

  @override
  String get notificationDeleted => 'This bill has been deleted.';

  @override
  String get accountArchiveAction => 'Archive account';

  @override
  String get accountRestoreAction => 'Restore account';

  @override
  String get accountArchivedSection => 'Archived accounts';

  @override
  String get accountArchiveExplanation =>
      'Archiving permanently deletes this account’s recurring rules and future pending bills, and cancels their reminders. Overdue pending bills and recorded transactions are kept. Restoring the account will not restore the deleted rules or bills.';

  @override
  String get accountDeleteExplanation =>
      'Delete this account? Its event history is retained.';

  @override
  String get accountUsageTransactions => 'Transactions';

  @override
  String get accountUsageSeries => 'Recurring rules';

  @override
  String get accountUsagePending => 'Pending bills';

  @override
  String get errorAccountHasReferences =>
      'This account has active transactions or recurring rules. Archive it instead, or resolve the linked records first.';

  @override
  String get errorAccountHasActiveSchedules =>
      'This account has active recurring rules or pending bills. Resolve them before archiving.';

  @override
  String get accountDeleteChooseAction =>
      'This account has transactions or scheduled rules. Choose how to proceed.';

  @override
  String get accountDeleteArchivedChooseAction =>
      'Choose whether to delete the associated transactions and scheduled rules or move them to another account.';

  @override
  String get accountMoveAndDelete => 'Move records and delete';

  @override
  String get accountDeleteWithTransactions => 'Delete account and records';

  @override
  String get accountSelectDestination => 'Select a destination account';

  @override
  String get accountNoDestination =>
      'No other active account with the same currency is available.';

  @override
  String get accountDeleteImpact =>
      'Balance adjustments will be reversed. Deleting records also reverses transfers on the other account; moving records changes the destination account balance. Scheduled rules follow the selected action.';

  @override
  String get accountConfirmOperation => 'Confirm';

  @override
  String get supportCenter => 'Support center';

  @override
  String get supportCenterHint => 'Get help and find answers';

  @override
  String get appOverview => 'App overview';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfService => 'Terms of service';

  @override
  String feedbackConfirmation(String email) {
    return 'Your email app will open to send feedback to $email.';
  }

  @override
  String get openEmailApp => 'Open email app';

  @override
  String get feedbackEmailSubject => 'Accounted For feedback';

  @override
  String get emailUnavailable => 'Could not open email app';

  @override
  String emailUnavailableMessage(String email) {
    return 'No email app could be opened. You can copy $email and contact us from another app.';
  }

  @override
  String get copyEmail => 'Copy email';

  @override
  String get linkUnavailable => 'Could not open link';

  @override
  String get linkUnavailableMessage =>
      'Please check that a browser is available and try again.';
}
