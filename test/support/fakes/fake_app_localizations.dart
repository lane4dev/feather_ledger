import 'package:feather_ledger/app/l10n/app_localizations.dart';

// A fake AppLocalizations class that returns hardcoded English strings.
// Used for testing purposes where a real BuildContext is not available.
class FakeAppLocalizations implements AppLocalizations {
  @override
  String get budget => 'Budget';
  @override
  String get viewReports => 'View reports';
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
  String feedbackConfirmation(String email) =>
      'Your email app will open to send feedback to $email.';
  @override
  String get openEmailApp => 'Open email app';
  @override
  String get feedbackEmailSubject => 'Accounted For feedback';
  @override
  String get emailUnavailable => 'Could not open email app';
  @override
  String emailUnavailableMessage(String email) =>
      'No email app could be opened. You can copy $email and contact us from another app.';
  @override
  String get copyEmail => 'Copy email';
  @override
  String get linkUnavailable => 'Could not open link';
  @override
  String get linkUnavailableMessage =>
      'Please check that a browser is available and try again.';
  @override
  String get notificationSkip => 'Skip';
  @override
  String get notificationSkipped => 'Bill skipped';
  @override
  String get notificationUnavailable => 'This bill is no longer available.';
  @override
  String get notificationDeleted => 'This bill has been deleted.';

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
  String reminderMinutesValue(int count) => '$count minutes before';

  @override
  String get repeatCountPrefix => 'Repeat';
  @override
  String get repeatCountSuffix => 'times';
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
  String get categoryIconUploadHint => 'PNG or JPEG · up to 5 MB';
  @override
  String get categoryIconZoom => 'Zoom';
  @override
  String get uploadCategoryIcon => 'Upload icon';
  @override
  String get categoryIconFileType => 'Images';
  @override
  String get cropCategoryIcon => 'Crop icon';
  @override
  String get categoryIconCropDescription => 'Centered square';
  @override
  String get invalidCategoryIcon => 'Invalid image';

  @override
  String get localeName => 'en'; // Added missing concrete implementation

  @override
  String get transactionModeDefault => 'Default';

  @override
  String get transactionModePlanned => 'Planned';

  @override
  String get transactionModeSubscription => 'Subscription';

  @override
  String get transactionModeRepeating => 'Repeating';

  @override
  String get appTitle => 'Accounted For';

  @override
  String get followSystem => 'Follow system';

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
  String get monthEndBalance => 'Month-end balance';

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
  String get transactionType => 'Type';

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
  String get addAttachment => 'Add attachment';

  @override
  String get attachments => 'Attachments';

  @override
  String get removeAttachment => 'Remove attachment';

  @override
  String get select => 'Select';

  @override
  String attachmentCount(int count) => '$count attachments';

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
  String get errorCountLimitTooSmall =>
      'Total occurrences must be greater than the bills already recorded or skipped';

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
  String get noCategoriesFound => 'No categories found. Please add some first.';

  @override
  String get noAccountsFound => 'No accounts found.';

  @override
  String errorPrefix(String error) {
    return 'Error: $error';
  }

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
  String get settings => 'Settings';

  @override
  String get settingsHint => 'Theme, language and currency';

  @override
  String get accountsHint => 'Your accounts and their balances';

  @override
  String get categoriesHint => 'Income and expense categories';

  @override
  String get feedbackHint => 'Tell us what you think';

  @override
  String get aboutHint => 'App information and open-source licences';

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
  String accountBalanceAdjustmentLedgerHint(String currency) =>
      'Balance changes are recorded in the $currency ledger.';

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
  String heatmapNetFlow(String amount) => 'Net flow: $amount';

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
  String get accountInitialBalanceNote => 'Difference';

  @override
  String get accountIncludeInTotals => 'Include in totals';

  @override
  String get accountIncludeInTotalsHint =>
      'Off: this account is left out of the total balance and the income and '
      'expense totals. Its transactions still show in the ledger.';

  @override
  String get categoryReversalExpense => 'Balance correction';

  @override
  String get categoryPartTimeJob => 'Part-Time Job';

  @override
  String get categoryReversalIncome => 'Balance correction';

  // Backup and restore (spec 004, US4). The message mirrors the real ARB's
  // shape so a test asserting on it sees the same interpolation.
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
          int backupEvents, int currentEvents, int discarded) =>
      'This backup holds $backupEvents events. This ledger has $currentEvents, '
      'so restoring discards $discarded of them.';

  @override
  String get restoreReadyTitle => 'Restore ready';

  @override
  String get restoreReadyMessage =>
      'Close Accounted For completely and open it again to finish restoring.';

  @override
  String get exitNow => 'Exit now';

  // Recurring bills (spec 004, US2).

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
  String get scopeThisOnly => 'Only this bill';

  @override
  String get saveRecurringTitle => 'Save recurring bill';

  @override
  String get scopeThisOnlyUnavailable =>
      'Category, account, repeat, auto-post and reminder belong to the whole rule';

  @override
  String get scopeThisAndFollowing => 'This and following bills';

  @override
  String get scopeAll => 'All bills';

  @override
  String get scopeAllHint => 'Bills already recorded are kept';

  @override
  String get scopeUpdateRule => 'Update repeating rule';

  @override
  String get scopeUpdateRuleHint =>
      'Recorded bills are kept; future pending bills follow the updated rule';

  @override
  String get skipThisBill => 'Skip this bill';

  @override
  String get skipBillTitle => 'Skip this bill?';

  @override
  String get skipBillConfirm =>
      'This bill will not be recorded, while future bills in this repeating rule continue as scheduled.';

  @override
  String get skipBillAction => 'Skip';

  @override
  String get billSkipped => 'Bill skipped';

  @override
  String get stopRepeatingRule => 'Stop repeating';

  @override
  String get stopRepeatingTitle => 'Stop repeating rule?';

  @override
  String get stopRepeatingConfirm =>
      'All pending bills under this rule will be removed. Bills already recorded are kept.';

  @override
  String get stopRepeatingAction => 'Stop repeating';

  @override
  String get repeatingStopped => 'Repeating rule stopped';

  @override
  String get deletePlan => 'Delete plan';

  @override
  String get deletePlanTitle => 'Delete plan?';

  @override
  String get deletePlanConfirm =>
      'This planned bill will be permanently removed.';

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

  // Search, filter and CSV export (spec 004, US3).
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
  String get autoPostWhenDue => 'Auto-post';

  @override
  String overdueBillsAdded(int count) => count == 1
      ? 'Added 1 overdue bill to review'
      : 'Added $count overdue bills to review';

  @override
  String get repeatNever => 'Does not repeat';

  @override
  String repeatSetupFailed(String error) =>
      'Saved. The repeat could not be set up: $error';
  @override
  String get accountArchiveAction => "Archive account";
  @override
  String get accountRestoreAction => "Restore account";
  @override
  String get accountArchivedSection => "Archived accounts";
  @override
  String get accountArchiveExplanation =>
      "Archiving permanently deletes this account’s recurring rules and future pending bills, and cancels their reminders. Overdue pending bills and recorded transactions are kept. Restoring the account will not restore the deleted rules or bills.";
  @override
  String get accountDeleteExplanation =>
      "Delete this account? Its event history is retained.";
  @override
  String get accountUsageTransactions => "Transactions";
  @override
  String get accountUsageSeries => "Recurring rules";
  @override
  String get accountUsagePending => "Pending bills";
  @override
  String get errorAccountHasReferences =>
      "This account has active transactions or recurring rules. Archive it instead, or resolve the linked records first.";
  @override
  String get errorAccountHasActiveSchedules =>
      "This account has active recurring rules or pending bills. Resolve them before archiving.";
  @override
  String get accountDeleteChooseAction =>
      "This account has transactions or scheduled rules. Choose how to proceed.";
  @override
  String get accountDeleteArchivedChooseAction =>
      "Choose whether to delete the associated transactions and scheduled rules or move them to another account.";
  @override
  String get accountMoveAndDelete => "Move records and delete";
  @override
  String get accountDeleteWithTransactions => "Delete account and records";
  @override
  String get accountSelectDestination => "Select a destination account";
  @override
  String get accountNoDestination =>
      "No other active account with the same currency is available.";
  @override
  String get accountDeleteImpact =>
      "Balance adjustments will be reversed. Deleting records also reverses transfers on the other account; moving records changes the destination account balance. Scheduled rules follow the selected action.";
  @override
  String get accountConfirmOperation => "Confirm";

  @override
  String get errorScheduledNotSkipped =>
      'Only skipped bills can be restored to pending';

  @override
  String get errorRecurringSeriesStopped =>
      'This recurring rule has been stopped';

  @override
  String autoPostedCountMessage(int count) => count == 1
      ? 'Auto-posted 1 scheduled bill'
      : 'Auto-posted $count scheduled bills';

  @override
  String get skippedBill => 'Skipped';

  @override
  String get restoreToPending => 'Restore to pending';

  @override
  String get billRestored => 'Bill restored to pending';

  @override
  String get failedBill => 'Auto-post failed';

  @override
  String get failedBillBanner =>
      'Automatic posting failed. Check the account or category, then retry or skip.';

  @override
  String get retryPost => 'Retry post';

  @override
  String currencyBacklogTitle(String currency) =>
      'Due auto-posting bills in $currency';

  @override
  String currencyBacklogMessage(int count) => count == 1
      ? '1 auto-posting bill became due while using another currency.'
      : '$count auto-posting bills became due while using another currency.';

  @override
  String get currencyBacklogPostAll => 'Post all';

  @override
  String get currencyBacklogKeepPending => 'Keep as pending';

  @override
  String get errorBudgetNoteTooLong =>
      'Review note cannot exceed 500 characters';

  @override
  String get budgetModePlan => 'Plan';

  @override
  String get budgetModeTrack => 'Track';

  @override
  String get budgetModeReview => 'Review';

  @override
  String get budgetReviewPreviewToggle => 'Review preview';

  @override
  String get budgetBackToTrack => 'Back to track';

  @override
  String get budgetTotal => 'Total budget';

  @override
  String get budgetActualSpent => 'Spent';

  @override
  String get budgetPendingShort => 'Pending';

  @override
  String get budgetProjectedRemaining => 'Projected left';

  @override
  String get budgetProjectedOver => 'Projected over';

  @override
  String get budgetCompliance => 'On budget';

  @override
  String get budgetCommitted => 'Committed';

  @override
  String get budgetDiscretionary => 'Discretionary';

  @override
  String get budgetCommittedBaseline => 'Committed baseline';

  @override
  String budgetAllExpensesLine(String total, String unbudgeted) =>
      'All expenses $total (unbudgeted $unbudgeted)';

  @override
  String budgetAllExpensesOnly(String total) => 'All expenses $total';

  @override
  String get budgetLeftoverPendingHint =>
      'Past month has unposted scheduled bills excluded from review totals.';

  @override
  String get budgetMaterializedOnlyHint =>
      'Includes materialized pending bills only.';

  @override
  String get budgetTrendTitle => '6-Month Budget vs Actual';

  @override
  String get budgetAttributionTitle => 'Month Review & Attribution';

  @override
  String get budgetOverTopTitle => 'Top Over Budget';

  @override
  String get budgetUnderTopTitle => 'Top Under Budget';

  @override
  String get budgetUnbudgetedAlertsTitle => 'Unbudgeted Spend Alerts';

  @override
  String get budgetMonthNoteLabel => 'Month review note';

  @override
  String get budgetCategoryNoteLabel => 'Category review note';

  @override
  String get budgetNotePlaceholder =>
      'Add a brief note on why this month varied (max 500 chars)...';

  @override
  String get budgetNoteSaved => 'Review note saved';

  @override
  String get budgetSaveNote => 'Save note';

  @override
  String budgetNoteCharCount(int count) => '$count/500';

  @override
  String get budgetSectionBudgeted => 'Budgeted categories';

  @override
  String get budgetSectionUnbudgetedActive => 'Unbudgeted with activity';

  @override
  String get budgetSectionRemaining => 'Other categories (tap to set budget)';

  @override
  String get budgetSetButton => 'Set budget';

  @override
  String get budgetEditTitle => 'Set Category Budget';

  @override
  String get budgetAmountLabel => 'Monthly limit';

  @override
  String budgetLastMonthRef(String amount) => 'Last mo $amount';

  @override
  String budgetThreeMoAvgRef(String amount) => '3-mo avg $amount';

  @override
  String budgetCommittedRef(String amount) => 'Committed $amount';

  @override
  String get budgetScopeLabel => 'Apply changes to';

  @override
  String get budgetScopeThisMonth => 'This month only';

  @override
  String get budgetScopeThisAndFollowing => 'This & following months';

  @override
  String get budgetScopeFutureOverrideWarning =>
      'Later months already have custom rules and will be replaced.';

  @override
  String get budgetHistoryEditHint =>
      'Past month has ended. Consider adjusting current or future months instead.';

  @override
  String get budgetZeroAmountHint =>
      'Budget must be greater than 0. Tap Remove budget to unset.';

  @override
  String get budgetClearAction => 'Remove budget';

  @override
  String get budgetClearConfirmTitle => 'Remove budget?';

  @override
  String get budgetSaved => 'Budget updated';

  @override
  String get budgetCleared => 'Budget removed';

  @override
  String get budgetStatusInBudget => 'In budget';

  @override
  String get budgetStatusAtRisk => 'At risk';

  @override
  String get budgetStatusOver => 'Over';

  @override
  String budgetAnomalyBadge(int percent) => '+$percent% vs 3m avg';

  @override
  String get budgetArchivedReadOnly => 'Archived';

  @override
  String get budgetArchivedNoteHint =>
      'Archived category — historical budgets and notes are read-only.';

  @override
  String get budgetTopTransactionsTitle => 'Top contributing expenses';

  @override
  String get budgetNoTransactionsInMonth =>
      'No expenses recorded in this month.';

  @override
  String get budgetEmptyNoAccountsTitle => 'Create an account to start budgeting';

  @override
  String budgetEmptyNoAccountsBody(String currency) =>
      'No active accounts exist for $currency yet.';

  @override
  String get budgetEmptyNoBudgetsTitle => 'Plan your monthly spending';

  @override
  String get budgetEmptyNoBudgetsBody =>
      'Tap any category below or + above to set your first category limit.';

  @override
  String get budgetPickCategoryTitle => 'Choose category';

  @override
  String budgetHintRemaining(String remaining, String after) =>
      'Remaining $remaining · After this: $after';

  @override
  String budgetHintAtRisk(String after) =>
      'After this + pending: $after over';

  @override
  String budgetHintOver(String over) => 'Budget exceeded by $over after this';

  @override
  String budgetHintUnset(String spent) =>
      'No budget set · Month spent $spent';

  @override
  String get budgetHintExcludedAccount => 'Excluded from budget totals';

  @override
  String get budgetHintPastPlanned =>
      'Past-month planned bills are excluded from closed reviews';
}
