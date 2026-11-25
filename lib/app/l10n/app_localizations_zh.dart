// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '记然';

  @override
  String get ledgerTitle => '账本';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '余额';

  @override
  String get monthEndBalance => '期末余额';

  @override
  String get totalBalance => '全部余额';

  @override
  String get noTransactionsThisMonth => '本月无交易记录';

  @override
  String get noTransactionsTitle => '暂无交易';

  @override
  String get noTransactionsHint => '点击 + 添加一笔交易';

  @override
  String get noAccountsInCurrencyTitle => '该币种暂无账户';

  @override
  String get noAccountsInCurrencyHint => '创建账户以开始记账';

  @override
  String get addTransaction => '添加交易';

  @override
  String get edit => '编辑';

  @override
  String get editTransaction => '编辑交易';

  @override
  String get deleteTransactionConfirmation => '确定要删除此交易吗？此操作无法撤销。';

  @override
  String get amount => '金额';

  @override
  String get frequency => '频率';

  @override
  String get date => '日期';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get tomorrow => '明天';

  @override
  String get category => '分类';

  @override
  String get categoryNameHint => '分类名称';

  @override
  String get name => '名称';

  @override
  String get color => '颜色';

  @override
  String get icon => '图标';

  @override
  String get account => '账户';

  @override
  String get note => '备注';

  @override
  String get noteHint => '添加备注';

  @override
  String get save => '保存';

  @override
  String get required => '必填';

  @override
  String get invalidAmount => '金额无效';

  @override
  String get noCategoriesFound => '未找到分类，请先添加分类。';

  @override
  String get noAccountsFound => '未找到账户。';

  @override
  String errorPrefix(String error) {
    return '错误：$error';
  }

  @override
  String get settings => '设置';

  @override
  String get settingsHint => '主题、语言与币种';

  @override
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get currencySymbol => '货币符号';

  @override
  String get accountCurrency => '币种';

  @override
  String get accountAllCurrencies => '全部币种';

  @override
  String accountBalanceAdjustmentLedgerHint(String currency) {
    return '余额调整将记录在 $currency 账本中。';
  }

  @override
  String get system => '跟随系统';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get english => '英语';

  @override
  String get chinese => '中文';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁体中文';

  @override
  String get loading => '加载中...';

  @override
  String get reports => '报表';

  @override
  String get budget => '预算';

  @override
  String get viewReports => '查看报表';

  @override
  String get activityHeatmap => '活动热力图';

  @override
  String heatmapNetFlow(String amount) {
    return '净流量：$amount';
  }

  @override
  String get heatmapZeroNetFlow => '净流量为零';

  @override
  String get heatmapNetInflow => '净流入';

  @override
  String get heatmapNetOutflow => '净流出';

  @override
  String get incomeBreakdown => '收入明细';

  @override
  String get expenseBreakdown => '支出明细';

  @override
  String get others => '其余项';

  @override
  String get noData => '暂无数据';

  @override
  String get more => '更多';

  @override
  String get accounts => '账户';

  @override
  String get accountsHint => '账户与各自的余额';

  @override
  String get categories => '分类';

  @override
  String get categoriesHint => '收入与支出的分类';

  @override
  String get dollarCurrency => '\$ (美元)';

  @override
  String get yuanCurrency => '¥ (人民币)';

  @override
  String get yenCurrency => '¥ (日元)';

  @override
  String get euroCurrency => '€ (欧元)';

  @override
  String get poundCurrency => '£ (英镑)';

  @override
  String get accountsTitle => '账户';

  @override
  String get addAccount => '添加账户';

  @override
  String get editAccount => '编辑账户';

  @override
  String get accountName => '账户名称';

  @override
  String get accountType => '账户类型';

  @override
  String get accountTypeCash => '现金';

  @override
  String get accountTypeBank => '银行账户';

  @override
  String get accountTypeCredit => '信用卡';

  @override
  String get accountTypeOther => '其他账户';

  @override
  String get accountExcludedFromTotals => '不计入合计';

  @override
  String get accountArchived => '已归档';

  @override
  String get initialBalance => '初始余额';

  @override
  String get transactionType => '类型';

  @override
  String get accountSaved => '账户已保存';

  @override
  String get balanceChangeDetectedTitle => '检测到余额变更';

  @override
  String get balanceChangeDetectedMessage => '余额已更改，将创建一笔更正交易。是否继续？';

  @override
  String get accountBalanceAdjustmentDescription => '余额调整';

  @override
  String get accountInitialBalanceNote => '初始余额';

  @override
  String get accountIncludeInTotals => '纳入余额统计';

  @override
  String get accountIncludeInTotalsHint => '关闭后，此账户不计入总余额与收支合计，但它的交易仍会显示在账本里。';

  @override
  String get accountBalanceAdjustmentNotes => '余额修正';

  @override
  String get deleteAccountConfirmation => '确定要删除此账户吗？';

  @override
  String get deleteCategoryConfirmationTitle => '确定要删除该分类吗？';

  @override
  String get deleteCategoryConfirmationMessage => '不会删除已有的交易记录。';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get feedback => '意见反馈';

  @override
  String get feedbackHint => '告诉我们你的想法';

  @override
  String get about => '关于';

  @override
  String get aboutHint => '应用信息与开源许可';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get version => '版本';

  @override
  String get featureNotAvailable => '功能暂不可用';

  @override
  String get manageCategories => '管理分类';

  @override
  String get manageAccounts => '管理账户';

  @override
  String get categoryFood => '餐饮';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryEntertainment => '娱乐';

  @override
  String get categoryShopping => '购物';

  @override
  String get categoryClothing => '服装';

  @override
  String get categoryHouseholdSupplies => '日用品';

  @override
  String get categoryCommunications => '通讯';

  @override
  String get categoryHealth => '健康';

  @override
  String get categoryEducation => '教育';

  @override
  String get categoryGifts => '礼物';

  @override
  String get categoryReversalExpense => '余额更正';

  @override
  String get categorySalary => '薪水';

  @override
  String get categoryBonus => '奖金';

  @override
  String get categoryPartTimeJob => '兼职';

  @override
  String get categoryAllowance => '零用钱';

  @override
  String get categoryInvestmentReturns => '投资收益';

  @override
  String get categoryReversalIncome => '余额更正';

  @override
  String get accountCash => '现金';

  @override
  String get accountBankCard => '银行卡';

  @override
  String get errorAccountNotFound => '账户不存在';

  @override
  String get errorAccountArchived => '账户已归档';

  @override
  String get errorCategoryNotFound => '分类不存在';

  @override
  String get errorCategoryArchived => '分类已归档';

  @override
  String get errorCategoryTypeMismatch => '分类类型与交易类型不符';

  @override
  String get errorSystemCategoryProtected => '系统分类不可归档';

  @override
  String get errorInvalidTransfer => '无效转账';

  @override
  String get errorInvalidTransactionShape => '交易无效，未保存';

  @override
  String get transfer => '转账';

  @override
  String get transferFrom => '转出账户';

  @override
  String get transferTo => '转入账户';

  @override
  String get addTransfer => '新建转账';

  @override
  String get editTransfer => '编辑转账';

  @override
  String get errorTransactionNotFound => '交易不存在';

  @override
  String get errorTransactionAlreadyReversed => '交易已被冲正';

  @override
  String get errorCurrencyMismatch => '两个账户必须使用同一种货币';

  @override
  String get errorSameAccountTransfer => '请选择两个不同的账户';

  @override
  String get errorScheduledAlreadyPosted => '该周期交易已入账';

  @override
  String get errorScheduledNotSkipped => '仅已跳过的账单可以恢复为待入账';

  @override
  String get errorRecurringSeriesStopped => '该周期规则已停止';

  @override
  String get errorScheduledDateTaken => '这条规则在那天已经有一笔账单了';

  @override
  String get errorCountLimitTooSmall => '总次数必须大于已入账和已跳过的次数';

  @override
  String get editRecurringTitle => '编辑周期账单';

  @override
  String get nextStep => '下一步';

  @override
  String get billUpdated => '账单已更新';

  @override
  String get errorUnknownEvent => '出了点问题，请重试。';

  @override
  String get auditHistory => '审计历史';

  @override
  String get eventRecorded => '已记录';

  @override
  String get eventReversed => '已冲正';

  @override
  String get reversalUserDeleted => '用户删除';

  @override
  String get reversalCorrection => '修改';

  @override
  String get rebuildProjections => '重建投影';

  @override
  String get rebuildProjectionsHint => '开发者工具——长按执行';

  @override
  String get rebuildProjectionsConfirm => '清空全部派生数据并从完整事件历史重放？定期规则与偏好设置保留。';

  @override
  String get rebuildProjectionsSuccess => '投影已重建';

  @override
  String get rebuildProjectionsFailure => '重建失败';

  @override
  String get overdraftWarningTitle => '警告';

  @override
  String get overdraftWarningMessage => '该交易将导致账户透支，是否继续？';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get backupFileTypeLabel => '记然 备份';

  @override
  String get backupNow => '立即备份';

  @override
  String get backupNowHint => '把整个账本导出为一个文件';

  @override
  String get restoreFromBackup => '从备份恢复';

  @override
  String get restoreFromBackupHint => '用备份文件替换全部数据';

  @override
  String get backupCreated => '备份已生成';

  @override
  String get restoreConfirmTitle => '替换全部数据？';

  @override
  String restoreConfirmMessage(
    int backupEvents,
    int currentEvents,
    int discarded,
  ) {
    return '这份备份包含 $backupEvents 条事件，当前账本有 $currentEvents 条，恢复将丢弃其中 $discarded 条。当前存储的全部内容都会被替换。';
  }

  @override
  String get restoreReadyTitle => '恢复已就绪';

  @override
  String get restoreReadyMessage => '请完全关闭记然 后重新打开，以完成恢复。';

  @override
  String get exitNow => '现在退出';

  @override
  String get postInstanceTitle => '记入这笔';

  @override
  String get postInstanceConfirm => '把这笔账单记为交易？';

  @override
  String get postInstance => '记入';

  @override
  String get instancePosted => '已记入';

  @override
  String get deleteRecurringTitle => '删除周期账单';

  @override
  String get scopeThisOnly => '仅编辑本期';

  @override
  String get saveRecurringTitle => '保存周期账单';

  @override
  String get scopeThisOnlyUnavailable => '分类、账户、重复规则、自动入账和提醒属于整条规则';

  @override
  String get scopeThisAndFollowing => '该项记录和后续记录';

  @override
  String get scopeAll => '所有记录';

  @override
  String get scopeAllHint => '已经入账的记录会保留';

  @override
  String get scopeUpdateRule => '修改重复规则';

  @override
  String get scopeUpdateRuleHint => '已入账记录保留不变；后续待入账账单按新规则生成';

  @override
  String get skipThisBill => '跳过本期';

  @override
  String get skipBillTitle => '跳过本期账单？';

  @override
  String get skipBillConfirm => '本期账单将标记为已跳过，后续重复规则仍按计划继续生成。';

  @override
  String get skipBillAction => '跳过';

  @override
  String get billSkipped => '已跳过本期账单';

  @override
  String get stopRepeatingRule => '停止重复';

  @override
  String get stopRepeatingTitle => '停止重复规则？';

  @override
  String get stopRepeatingConfirm => '将删除该规则下所有未入账账单；已入账的历史记录会保留。';

  @override
  String get stopRepeatingAction => '停止重复';

  @override
  String get repeatingStopped => '已停止重复规则';

  @override
  String get deletePlan => '删除该计划';

  @override
  String get deletePlanTitle => '删除该计划？';

  @override
  String get deletePlanConfirm => '该计划账单将被永久删除。';

  @override
  String get billDeleted => '账单已删除';

  @override
  String get frequencyDaily => '天';

  @override
  String get frequencyWeekly => '周';

  @override
  String get frequencyMonthly => '月';

  @override
  String get frequencyYearly => '年';

  @override
  String get searchHint => '搜索备注、分类、账户';

  @override
  String get filterTitle => '筛选';

  @override
  String get filterAllKinds => '全部';

  @override
  String get filterAnyAccount => '任意账户';

  @override
  String get filterAnyCategory => '任意分类';

  @override
  String get filterAnyDate => '任意日期';

  @override
  String get filterDateRange => '日期范围';

  @override
  String get filterApply => '应用';

  @override
  String get filterClear => '清空';

  @override
  String get exportCsv => '导出 CSV';

  @override
  String get noSearchResults => '没有匹配的交易';

  @override
  String get pendingBill => '待入账';

  @override
  String get repeat => '重复';

  @override
  String get transactionModeDefault => '默认';

  @override
  String get transactionModePlanned => '计划';

  @override
  String get transactionModeSubscription => '订阅';

  @override
  String get transactionModeRepeating => '重复';

  @override
  String get autoPostWhenDue => '自动入账';

  @override
  String overdueBillsAdded(int count) {
    return '新补齐了 $count 笔已到期账单';
  }

  @override
  String get repeatNever => '不重复';

  @override
  String repeatSetupFailed(String error) {
    return '已保存。但重复规则创建失败：$error';
  }

  @override
  String get addAttachment => '添加附件';

  @override
  String get attachments => '附件';

  @override
  String get removeAttachment => '移除附件';

  @override
  String get select => '请选择';

  @override
  String attachmentCount(int count) {
    return '$count 个附件';
  }

  @override
  String get uploadCategoryIcon => '上传图标';

  @override
  String get categoryIconFileType => '图片';

  @override
  String get cropCategoryIcon => '裁剪图标';

  @override
  String get categoryIconCropDescription => '拖动图片调整位置，双指捏合或使用滑块缩放。';

  @override
  String get invalidCategoryIcon => '请选择不超过 5 MB、宽高至少为 32 像素的 PNG 或 JPEG 图片。';

  @override
  String get categoryIconZoom => '缩放';

  @override
  String get categoryIconUploadHint => 'PNG 或 JPEG，最大 5 MB';

  @override
  String get customRepeat => '自定义';

  @override
  String get repeatEvery => '每';

  @override
  String get repeatInterval => '间隔';

  @override
  String get repeatStart => '开始时间';

  @override
  String get repeatEnds => '何时结束重复';

  @override
  String get repeatNeverEnds => '永不结束';

  @override
  String get repeatUntil => '在此日期结束';

  @override
  String get repeatCount => '重复次数';

  @override
  String get repeatCountPrefix => '重复';

  @override
  String get repeatCountSuffix => '次';

  @override
  String get reminder => '提醒';

  @override
  String get reminderNone => '不提醒';

  @override
  String get reminder5 => '提前 5 分钟';

  @override
  String get reminder10 => '提前 10 分钟';

  @override
  String get reminder15 => '提前 15 分钟';

  @override
  String get reminder30 => '提前 30 分钟';

  @override
  String get reminderHour => '提前 1 小时';

  @override
  String get reminderDay => '提前 1 天';

  @override
  String get reminderCustom => '自定义';

  @override
  String get reminderUnitMinutes => '分钟';

  @override
  String get reminderUnitHours => '小时';

  @override
  String get reminderUnitDays => '天';

  @override
  String get reminderPermissionRequired => '请允许通知和精确提醒，以使用提醒功能。';

  @override
  String get reminderNotificationTitle => '待入账交易提醒';

  @override
  String get reminderChannel => '交易提醒';

  @override
  String get reminderCustomTitle => '自定义提醒';

  @override
  String get reminderAmount => '数量';

  @override
  String reminderMinutesValue(int count) {
    return '提前 $count 分钟';
  }

  @override
  String get notificationSkip => '跳过';

  @override
  String get notificationSkipped => '已跳过这笔账单';

  @override
  String get notificationUnavailable => '该账单已不存在。';

  @override
  String get notificationDeleted => '这笔账单已删除。';

  @override
  String get accountArchiveAction => '归档账户';

  @override
  String get accountRestoreAction => '恢复账户';

  @override
  String get accountArchivedSection => '已归档账户';

  @override
  String get accountArchiveExplanation =>
      '归档将删除此账户的周期规则和未来待入账账单，并取消对应提醒。已到期的待入账账单和已入账交易会保留。恢复账户后，已删除的规则和账单不会恢复。';

  @override
  String get accountDeleteExplanation => '确定删除此账户吗？事件历史会保留。';

  @override
  String get accountUsageTransactions => '关联交易';

  @override
  String get accountUsageSeries => '周期规则';

  @override
  String get accountUsagePending => '待入账账单';

  @override
  String get errorAccountHasReferences => '此账户仍有未删除的交易或周期规则。可选择归档，或先处理关联记录。';

  @override
  String get errorAccountHasActiveSchedules => '此账户有仍在进行的周期规则或待入账账单，请先处理。';

  @override
  String get accountDeleteChooseAction => '此账户有关联交易或周期规则，请选择处理方式。';

  @override
  String get accountDeleteArchivedChooseAction => '请选择删除关联交易及周期规则，或将它们转移到其他账户。';

  @override
  String get accountMoveAndDelete => '转移记录并删除';

  @override
  String get accountDeleteWithTransactions => '删除账户及记录';

  @override
  String get accountSelectDestination => '选择目标账户';

  @override
  String get accountNoDestination => '没有可用的同币种其他正常账户。';

  @override
  String get accountDeleteImpact =>
      '初始余额和余额调整会被冲销。删除转账会同时影响另一账户的余额；转移记录会改变目标账户余额。周期规则将按所选方式处理。';

  @override
  String get accountConfirmOperation => '确认';

  @override
  String get supportCenter => '支持中心';

  @override
  String get supportCenterHint => '获取帮助与常见问题解答';

  @override
  String get appOverview => '应用介绍';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String feedbackConfirmation(String email) {
    return '将打开您的邮件应用，向 $email 发送反馈。';
  }

  @override
  String get openEmailApp => '打开邮件应用';

  @override
  String get feedbackEmailSubject => 'Accounted For 意见反馈';

  @override
  String get emailUnavailable => '无法打开邮件应用';

  @override
  String emailUnavailableMessage(String email) {
    return '无法打开邮件应用。您可以复制 $email，通过其他应用联系我们。';
  }

  @override
  String get copyEmail => '复制邮箱';

  @override
  String get linkUnavailable => '无法打开链接';

  @override
  String get linkUnavailableMessage => '请确认设备上有可用的浏览器，然后重试。';

  @override
  String autoPostedCountMessage(int count) {
    return '已自动记入 $count 笔自动入账账单';
  }

  @override
  String get skippedBill => '已跳过';

  @override
  String get restoreToPending => '恢复为待入账';

  @override
  String get billRestored => '已恢复为待入账';

  @override
  String get failedBill => '自动入账失败';

  @override
  String get failedBillBanner => '自动入账失败，请检查账户或分类后重试记入或跳过本期。';

  @override
  String get retryPost => '重试记入';

  @override
  String currencyBacklogTitle(String currency) {
    return '$currency 有待自动入账账单';
  }

  @override
  String currencyBacklogMessage(int count) {
    return '切换到其他币种期间，有 $count 笔开启自动入账的账单已到期。';
  }

  @override
  String get currencyBacklogPostAll => '全部入账';

  @override
  String get currencyBacklogKeepPending => '保留为待入账';

  @override
  String get errorBudgetNoteTooLong => '复盘备忘不能超过 500 字';

  @override
  String get budgetModePlan => '规划';

  @override
  String get budgetModeTrack => '跟踪';

  @override
  String get budgetModeReview => '复盘';

  @override
  String get budgetReviewPreviewToggle => '复盘预览';

  @override
  String get budgetTracking => '预算跟踪';

  @override
  String get budgetTotal => '本月总预算';

  @override
  String get budgetActualSpent => '已消费';

  @override
  String get budgetPendingShort => '待入账';

  @override
  String get budgetProjectedRemaining => '预计剩余';

  @override
  String get budgetProjectedOver => '预计超支';

  @override
  String get budgetCompliance => '达标率';

  @override
  String get budgetCommitted => '固定';

  @override
  String get budgetCommittedSpending => '固定消费';

  @override
  String get budgetDiscretionarySpending => '弹性消费';

  @override
  String get budgetDiscretionary => '弹性';

  @override
  String get budgetCommittedBaseline => '固定基线';

  @override
  String get budgetOverviewMonthlySurplus => '本月结余';

  @override
  String get budgetOverviewMonthlyOverspend => '本月超支';

  @override
  String get budgetOverviewAvailable => '可自由支配';

  @override
  String get budgetOverviewBudgetUsage => '预算使用率';

  @override
  String get budgetOverviewBaselineShare => '基线占比';

  @override
  String budgetAllExpensesLine(String total, String unbudgeted) {
    return '本月全部实耗 $total（含未设预算 $unbudgeted）';
  }

  @override
  String budgetAllExpensesOnly(String total) {
    return '本月全部实耗 $total';
  }

  @override
  String get budgetLeftoverPendingHint => '该历史月仍有未入账周期账单，复盘统计已忽略。';

  @override
  String get budgetMaterializedOnlyHint => '待入账仅含已物化排期账单。';

  @override
  String get budgetTrendTitle => '近 6 个月预算 vs 实际';

  @override
  String get budgetReviewTitle => '月度复盘与趋势';

  @override
  String get budgetReviewScopeNote => '整月口径，含未设预算的分类。';

  @override
  String get budgetReviewCommittedActual => '固定支出';

  @override
  String get budgetReviewDiscretionaryActual => '弹性支出';

  @override
  String get budgetReviewBaselineNote => '固定支出 + 生效中的待入账。仅供参考，三个数字不可相加。';

  @override
  String get budgetReviewNoteEmptyDeletes => '备注留空并保存即可删除。';

  @override
  String get budgetTrendLegendActual => '全部实际支出';

  @override
  String get budgetTrendLegendBudget => '已设预算总额';

  @override
  String get budgetTrendLegendAverage => '3 个月平均';

  @override
  String get budgetAttributionTitle => '月度复盘与归因';

  @override
  String get budgetOverTopTitle => '超支 TOP';

  @override
  String get budgetUnderTopTitle => '结余 TOP';

  @override
  String get budgetUnbudgetedAlertsTitle => '未设预算大额预警';

  @override
  String get budgetMonthNoteLabel => '月度复盘备忘';

  @override
  String get budgetCategoryNoteLabel => '分类复盘备忘';

  @override
  String get budgetNotePlaceholder => '记录本月偏差原因或下月调整思路（最多 500 字）...';

  @override
  String get budgetNoteSaved => '复盘备忘已保存';

  @override
  String get budgetSaveNote => '保存备忘';

  @override
  String budgetNoteCharCount(int count) {
    return '$count/500';
  }

  @override
  String get budgetSectionBudgeted => '已设预算分类';

  @override
  String get budgetSectionUnbudgetedActive => '计划外支出';

  @override
  String get budgetSectionRemaining => '其余分类（点击设预算）';

  @override
  String get budgetSetButton => '设预算';

  @override
  String budgetRowProjectedOver(String amount) {
    return '预计超支 $amount';
  }

  @override
  String budgetRowOver(String amount) {
    return '已超支 $amount';
  }

  @override
  String budgetRowRemaining(String amount) {
    return '剩余 $amount';
  }

  @override
  String budgetRowReviewRemaining(String amount) {
    return '结余 $amount';
  }

  @override
  String budgetRowReviewOver(String amount) {
    return '超支 $amount';
  }

  @override
  String budgetRowPlanBudget(String amount) {
    return '预算 $amount';
  }

  @override
  String budgetRowPendingIncluded(String amount) {
    return '含待入账 $amount';
  }

  @override
  String budgetRowPending(String amount) {
    return '待入账 $amount';
  }

  @override
  String budgetRowUsage(String percent) {
    return '已用 $percent';
  }

  @override
  String budgetRowBaseline(String amount) {
    return '固定基线 $amount';
  }

  @override
  String budgetRowShare(String percent) {
    return '占本月总支出 $percent';
  }

  @override
  String budgetRowGroupSpent(String amount) {
    return '已消费 $amount';
  }

  @override
  String get budgetRowAnomalySemantics => '波动明显高于近三月均值';

  @override
  String get budgetEditTitle => '设置分类预算';

  @override
  String get budgetAmountLabel => '月度预算额度';

  @override
  String budgetLastMonthRef(String amount) {
    return '上月实际 $amount';
  }

  @override
  String budgetThreeMoAvgRef(String amount) {
    return '近3月均 $amount';
  }

  @override
  String budgetCommittedRef(String amount) {
    return '固定底线 $amount';
  }

  @override
  String get budgetScopeLabel => '应用范围';

  @override
  String get budgetScopeThisMonth => '仅本月';

  @override
  String get budgetScopeThisAndFollowing => '本月及以后';

  @override
  String get budgetScopeFutureOverrideWarning =>
      '后续月份已存在独立预算规则，选择“本月及以后”将覆盖它们。';

  @override
  String get budgetHistoryEditHint => '历史月已结束，建议调整当前或未来月份以指导后续执行。';

  @override
  String get budgetZeroAmountHint => '预算需大于 0；如需取消请点击「取消预算」。';

  @override
  String get budgetClearAction => '取消预算';

  @override
  String budgetClearConfirmTitle(String category) {
    return '删除$category预算？';
  }

  @override
  String budgetClearConfirmThisMonth(
    String month,
    String category,
    String amount,
  ) {
    return '将删除 $month 的$category预算 $amount，并清除本月的分类复盘备忘。';
  }

  @override
  String budgetClearConfirmThisAndFollowing(
    String month,
    String category,
    String amount,
  ) {
    return '将删除 $month 及以后的$category预算 $amount，并清除 $month 及以后的$category分类复盘备忘（含沿用预算、未单独设预算的月份）。';
  }

  @override
  String get budgetClearFutureRulesWarning => '此操作也会清除之后已设置的预算。';

  @override
  String get budgetSaved => '预算已更新';

  @override
  String get budgetCleared => '预算已取消';

  @override
  String get budgetStatusInBudget => '达标';

  @override
  String get budgetStatusAtRisk => '预警';

  @override
  String get budgetStatusOver => '超支';

  @override
  String budgetAnomalyBadge(int percent) {
    return '较均值 +$percent%';
  }

  @override
  String get budgetArchivedReadOnly => '已归档';

  @override
  String get budgetArchivedNoteHint => '该分类已归档，历史预算与复盘备忘仅供只读查看。';

  @override
  String get budgetTopTransactionsTitle => '主要贡献支出';

  @override
  String get budgetViewAll => '查看全部';

  @override
  String get budgetNoTransactionsInMonth => '本月暂无支出记录。';

  @override
  String get budgetEmptyNoAccountsTitle => '新建账户后即可规划预算';

  @override
  String budgetEmptyNoAccountsBody(String currency) {
    return '当前币种（$currency）下暂无活跃账户。';
  }

  @override
  String get budgetEmptyNoBudgetsTitle => '规划你的月度支出';

  @override
  String get budgetEmptyNoBudgetsBody => '点击下方任意分类或右上角 + 即可设置首个分类预算。';

  @override
  String get budgetPickCategoryTitle => '选择支出分类';

  @override
  String budgetHintRemaining(String remaining, String after) {
    return '本月余 $remaining · 记后余 $after';
  }

  @override
  String budgetHintAtRisk(String after) {
    return '含待入账预计超 $after';
  }

  @override
  String budgetHintOver(String over) {
    return '记后将超支 $over';
  }

  @override
  String budgetHintUnset(String spent) {
    return '未设预算 · 本月已耗 $spent';
  }

  @override
  String get budgetHintExcludedAccount => '该账户不计入预算统计';

  @override
  String get budgetHintPastPlanned => '历史月计划账单不计入已完结复盘';

  @override
  String get hideOverviewAmounts => '隐藏概览金额';

  @override
  String get showOverviewAmounts => '显示概览金额';

  @override
  String monthIncome(String month) {
    return '$month收入';
  }

  @override
  String monthExpense(String month) {
    return '$month支出';
  }

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => '记然';

  @override
  String get ledgerTitle => '账本';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '余额';

  @override
  String get monthEndBalance => '期末余额';

  @override
  String get totalBalance => '全部余额';

  @override
  String get noTransactionsThisMonth => '本月无交易记录';

  @override
  String get noTransactionsTitle => '暂无交易';

  @override
  String get noTransactionsHint => '点击 + 添加一笔交易';

  @override
  String get noAccountsInCurrencyTitle => '该币种暂无账户';

  @override
  String get noAccountsInCurrencyHint => '创建账户以开始记账';

  @override
  String get addTransaction => '添加交易';

  @override
  String get edit => '编辑';

  @override
  String get editTransaction => '编辑交易';

  @override
  String get deleteTransactionConfirmation => '确定要删除此交易吗？此操作无法撤销。';

  @override
  String get amount => '金额';

  @override
  String get frequency => '频率';

  @override
  String get date => '日期';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get tomorrow => '明天';

  @override
  String get category => '分类';

  @override
  String get categoryNameHint => '分类名称';

  @override
  String get name => '名称';

  @override
  String get color => '颜色';

  @override
  String get icon => '图标';

  @override
  String get account => '账户';

  @override
  String get note => '备注';

  @override
  String get noteHint => '添加备注';

  @override
  String get save => '保存';

  @override
  String get required => '必填';

  @override
  String get invalidAmount => '金额无效';

  @override
  String get noCategoriesFound => '未找到分类，请先添加分类。';

  @override
  String get noAccountsFound => '未找到账户。';

  @override
  String errorPrefix(String error) {
    return '错误：$error';
  }

  @override
  String get settings => '设置';

  @override
  String get settingsHint => '主题、语言与币种';

  @override
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get currencySymbol => '货币符号';

  @override
  String get accountCurrency => '币种';

  @override
  String get accountAllCurrencies => '全部币种';

  @override
  String accountBalanceAdjustmentLedgerHint(String currency) {
    return '余额调整将记录在 $currency 账本中。';
  }

  @override
  String get system => '跟随系统';

  @override
  String get followSystem => '跟随系统';

  @override
  String get light => '浅色';

  @override
  String get dark => '深色';

  @override
  String get english => '英语';

  @override
  String get chinese => '中文';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁体中文';

  @override
  String get loading => '加载中...';

  @override
  String get reports => '报表';

  @override
  String get budget => '预算';

  @override
  String get viewReports => '查看报表';

  @override
  String get activityHeatmap => '活动热力图';

  @override
  String heatmapNetFlow(String amount) {
    return '净流量：$amount';
  }

  @override
  String get heatmapZeroNetFlow => '净流量为零';

  @override
  String get heatmapNetInflow => '净流入';

  @override
  String get heatmapNetOutflow => '净流出';

  @override
  String get incomeBreakdown => '收入明细';

  @override
  String get expenseBreakdown => '支出明细';

  @override
  String get others => '其余项';

  @override
  String get noData => '暂无数据';

  @override
  String get more => '更多';

  @override
  String get accounts => '账户';

  @override
  String get accountsHint => '账户与各自的余额';

  @override
  String get categories => '分类';

  @override
  String get categoriesHint => '收入与支出的分类';

  @override
  String get dollarCurrency => '\$ (美元)';

  @override
  String get yuanCurrency => '¥ (人民币)';

  @override
  String get yenCurrency => '¥ (日元)';

  @override
  String get euroCurrency => '€ (欧元)';

  @override
  String get poundCurrency => '£ (英镑)';

  @override
  String get accountsTitle => '账户';

  @override
  String get addAccount => '添加账户';

  @override
  String get editAccount => '编辑账户';

  @override
  String get accountName => '账户名称';

  @override
  String get accountType => '账户类型';

  @override
  String get accountTypeCash => '现金';

  @override
  String get accountTypeBank => '银行账户';

  @override
  String get accountTypeCredit => '信用卡';

  @override
  String get accountTypeOther => '其他账户';

  @override
  String get accountExcludedFromTotals => '不计入合计';

  @override
  String get accountArchived => '已归档';

  @override
  String get initialBalance => '初始余额';

  @override
  String get transactionType => '类型';

  @override
  String get accountSaved => '账户已保存';

  @override
  String get balanceChangeDetectedTitle => '检测到余额变更';

  @override
  String get balanceChangeDetectedMessage => '余额已更改，将创建一笔更正交易。是否继续？';

  @override
  String get accountBalanceAdjustmentDescription => '余额调整';

  @override
  String get accountInitialBalanceNote => '初始余额';

  @override
  String get accountIncludeInTotals => '纳入余额统计';

  @override
  String get accountIncludeInTotalsHint => '关闭后，此账户不计入总余额与收支合计，但它的交易仍会显示在账本里。';

  @override
  String get accountBalanceAdjustmentNotes => '余额修正';

  @override
  String get deleteAccountConfirmation => '确定要删除此账户吗？';

  @override
  String get deleteCategoryConfirmationTitle => '确定要删除该分类吗？';

  @override
  String get deleteCategoryConfirmationMessage => '不会删除已有的交易记录。';

  @override
  String get delete => '删除';

  @override
  String get cancel => '取消';

  @override
  String get feedback => '意见反馈';

  @override
  String get feedbackHint => '告诉我们你的想法';

  @override
  String get about => '关于';

  @override
  String get aboutHint => '应用信息与开源许可';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get version => '版本';

  @override
  String get featureNotAvailable => '功能暂不可用';

  @override
  String get manageCategories => '管理分类';

  @override
  String get manageAccounts => '管理账户';

  @override
  String get categoryFood => '餐饮';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryEntertainment => '娱乐';

  @override
  String get categoryShopping => '购物';

  @override
  String get categoryClothing => '服装';

  @override
  String get categoryHouseholdSupplies => '日用品';

  @override
  String get categoryCommunications => '通讯';

  @override
  String get categoryHealth => '健康';

  @override
  String get categoryEducation => '教育';

  @override
  String get categoryGifts => '礼物';

  @override
  String get categoryReversalExpense => '余额更正';

  @override
  String get categorySalary => '薪水';

  @override
  String get categoryBonus => '奖金';

  @override
  String get categoryPartTimeJob => '兼职';

  @override
  String get categoryAllowance => '零用钱';

  @override
  String get categoryInvestmentReturns => '投资收益';

  @override
  String get categoryReversalIncome => '余额更正';

  @override
  String get accountCash => '现金';

  @override
  String get accountBankCard => '银行卡';

  @override
  String get errorAccountNotFound => '账户不存在';

  @override
  String get errorAccountArchived => '账户已归档';

  @override
  String get errorCategoryNotFound => '分类不存在';

  @override
  String get errorCategoryArchived => '分类已归档';

  @override
  String get errorCategoryTypeMismatch => '分类类型与交易类型不符';

  @override
  String get errorSystemCategoryProtected => '系统分类不可归档';

  @override
  String get errorInvalidTransfer => '无效转账';

  @override
  String get errorInvalidTransactionShape => '交易无效，未保存';

  @override
  String get transfer => '转账';

  @override
  String get transferFrom => '转出账户';

  @override
  String get transferTo => '转入账户';

  @override
  String get addTransfer => '新建转账';

  @override
  String get editTransfer => '编辑转账';

  @override
  String get errorTransactionNotFound => '交易不存在';

  @override
  String get errorTransactionAlreadyReversed => '交易已被冲正';

  @override
  String get errorCurrencyMismatch => '两个账户必须使用同一种货币';

  @override
  String get errorSameAccountTransfer => '请选择两个不同的账户';

  @override
  String get errorScheduledAlreadyPosted => '该周期交易已入账';

  @override
  String get errorScheduledNotSkipped => '仅已跳过的账单可以恢复为待入账';

  @override
  String get errorRecurringSeriesStopped => '该周期规则已停止';

  @override
  String get errorScheduledDateTaken => '这条规则在那天已经有一笔账单了';

  @override
  String get errorCountLimitTooSmall => '总次数必须大于已入账和已跳过的次数';

  @override
  String get editRecurringTitle => '编辑周期账单';

  @override
  String get nextStep => '下一步';

  @override
  String get billUpdated => '账单已更新';

  @override
  String get errorUnknownEvent => '出了点问题，请重试。';

  @override
  String get auditHistory => '审计历史';

  @override
  String get eventRecorded => '已记录';

  @override
  String get eventReversed => '已冲正';

  @override
  String get reversalUserDeleted => '用户删除';

  @override
  String get reversalCorrection => '修改';

  @override
  String get rebuildProjections => '重建投影';

  @override
  String get rebuildProjectionsHint => '开发者工具——长按执行';

  @override
  String get rebuildProjectionsConfirm => '清空全部派生数据并从完整事件历史重放？定期规则与偏好设置保留。';

  @override
  String get rebuildProjectionsSuccess => '投影已重建';

  @override
  String get rebuildProjectionsFailure => '重建失败';

  @override
  String get overdraftWarningTitle => '警告';

  @override
  String get overdraftWarningMessage => '该交易将导致账户透支，是否继续？';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get backupFileTypeLabel => '记然 备份';

  @override
  String get backupNow => '立即备份';

  @override
  String get backupNowHint => '把整个账本导出为一个文件';

  @override
  String get restoreFromBackup => '从备份恢复';

  @override
  String get restoreFromBackupHint => '用备份文件替换全部数据';

  @override
  String get backupCreated => '备份已生成';

  @override
  String get restoreConfirmTitle => '替换全部数据？';

  @override
  String restoreConfirmMessage(
    int backupEvents,
    int currentEvents,
    int discarded,
  ) {
    return '这份备份包含 $backupEvents 条事件，当前账本有 $currentEvents 条，恢复将丢弃其中 $discarded 条。当前存储的全部内容都会被替换。';
  }

  @override
  String get restoreReadyTitle => '恢复已就绪';

  @override
  String get restoreReadyMessage => '请完全关闭记然 后重新打开，以完成恢复。';

  @override
  String get exitNow => '现在退出';

  @override
  String get postInstanceTitle => '记入这笔';

  @override
  String get postInstanceConfirm => '把这笔账单记为交易？';

  @override
  String get postInstance => '记入';

  @override
  String get instancePosted => '已记入';

  @override
  String get deleteRecurringTitle => '删除周期账单';

  @override
  String get scopeThisOnly => '仅编辑本期';

  @override
  String get saveRecurringTitle => '保存周期账单';

  @override
  String get scopeThisOnlyUnavailable => '分类、账户、重复规则、自动入账和提醒属于整条规则';

  @override
  String get scopeThisAndFollowing => '该项记录和后续记录';

  @override
  String get scopeAll => '所有记录';

  @override
  String get scopeAllHint => '已经入账的记录会保留';

  @override
  String get scopeUpdateRule => '修改重复规则';

  @override
  String get scopeUpdateRuleHint => '已入账记录保留不变；后续待入账账单按新规则生成';

  @override
  String get skipThisBill => '跳过本期';

  @override
  String get skipBillTitle => '跳过本期账单？';

  @override
  String get skipBillConfirm => '本期账单将标记为已跳过，后续重复规则仍按计划继续生成。';

  @override
  String get skipBillAction => '跳过';

  @override
  String get billSkipped => '已跳过本期账单';

  @override
  String get stopRepeatingRule => '停止重复';

  @override
  String get stopRepeatingTitle => '停止重复规则？';

  @override
  String get stopRepeatingConfirm => '将删除该规则下所有未入账账单；已入账的历史记录会保留。';

  @override
  String get stopRepeatingAction => '停止重复';

  @override
  String get repeatingStopped => '已停止重复规则';

  @override
  String get deletePlan => '删除该计划';

  @override
  String get deletePlanTitle => '删除该计划？';

  @override
  String get deletePlanConfirm => '该计划账单将被永久删除。';

  @override
  String get billDeleted => '账单已删除';

  @override
  String get frequencyDaily => '天';

  @override
  String get frequencyWeekly => '周';

  @override
  String get frequencyMonthly => '月';

  @override
  String get frequencyYearly => '年';

  @override
  String get searchHint => '搜索备注、分类、账户';

  @override
  String get filterTitle => '筛选';

  @override
  String get filterAllKinds => '全部';

  @override
  String get filterAnyAccount => '任意账户';

  @override
  String get filterAnyCategory => '任意分类';

  @override
  String get filterAnyDate => '任意日期';

  @override
  String get filterDateRange => '日期范围';

  @override
  String get filterApply => '应用';

  @override
  String get filterClear => '清空';

  @override
  String get exportCsv => '导出 CSV';

  @override
  String get noSearchResults => '没有匹配的交易';

  @override
  String get pendingBill => '待入账';

  @override
  String get repeat => '重复';

  @override
  String get transactionModeDefault => '默认';

  @override
  String get transactionModePlanned => '计划';

  @override
  String get transactionModeSubscription => '订阅';

  @override
  String get transactionModeRepeating => '重复';

  @override
  String get autoPostWhenDue => '自动入账';

  @override
  String overdueBillsAdded(int count) {
    return '新补齐了 $count 笔已到期账单';
  }

  @override
  String get repeatNever => '不重复';

  @override
  String repeatSetupFailed(String error) {
    return '已保存。但重复规则创建失败：$error';
  }

  @override
  String get addAttachment => '添加附件';

  @override
  String get attachments => '附件';

  @override
  String get removeAttachment => '移除附件';

  @override
  String get select => '请选择';

  @override
  String attachmentCount(int count) {
    return '$count 个附件';
  }

  @override
  String get uploadCategoryIcon => '上传图标';

  @override
  String get categoryIconFileType => '图片';

  @override
  String get cropCategoryIcon => '裁剪图标';

  @override
  String get categoryIconCropDescription => '拖动图片调整位置，双指捏合或使用滑块缩放。';

  @override
  String get invalidCategoryIcon => '请选择不超过 5 MB、宽高至少为 32 像素的 PNG 或 JPEG 图片。';

  @override
  String get categoryIconZoom => '缩放';

  @override
  String get categoryIconUploadHint => 'PNG 或 JPEG，最大 5 MB';

  @override
  String get customRepeat => '自定义';

  @override
  String get repeatEvery => '每';

  @override
  String get repeatInterval => '间隔';

  @override
  String get repeatStart => '开始时间';

  @override
  String get repeatEnds => '何时结束重复';

  @override
  String get repeatNeverEnds => '永不结束';

  @override
  String get repeatUntil => '在此日期结束';

  @override
  String get repeatCount => '重复次数';

  @override
  String get repeatCountPrefix => '重复';

  @override
  String get repeatCountSuffix => '次';

  @override
  String get reminder => '提醒';

  @override
  String get reminderNone => '不提醒';

  @override
  String get reminder5 => '提前 5 分钟';

  @override
  String get reminder10 => '提前 10 分钟';

  @override
  String get reminder15 => '提前 15 分钟';

  @override
  String get reminder30 => '提前 30 分钟';

  @override
  String get reminderHour => '提前 1 小时';

  @override
  String get reminderDay => '提前 1 天';

  @override
  String get reminderCustom => '自定义';

  @override
  String get reminderUnitMinutes => '分钟';

  @override
  String get reminderUnitHours => '小时';

  @override
  String get reminderUnitDays => '天';

  @override
  String get reminderPermissionRequired => '请允许通知和精确提醒，以使用提醒功能。';

  @override
  String get reminderNotificationTitle => '待入账交易提醒';

  @override
  String get reminderChannel => '交易提醒';

  @override
  String get reminderCustomTitle => '自定义提醒';

  @override
  String get reminderAmount => '数量';

  @override
  String reminderMinutesValue(int count) {
    return '提前 $count 分钟';
  }

  @override
  String get notificationSkip => '跳过';

  @override
  String get notificationSkipped => '已跳过这笔账单';

  @override
  String get notificationUnavailable => '该账单已不存在。';

  @override
  String get notificationDeleted => '这笔账单已删除。';

  @override
  String get accountArchiveAction => '归档账户';

  @override
  String get accountRestoreAction => '恢复账户';

  @override
  String get accountArchivedSection => '已归档账户';

  @override
  String get accountArchiveExplanation =>
      '归档将删除此账户的周期规则和未来待入账账单，并取消对应提醒。已到期的待入账账单和已入账交易会保留。恢复账户后，已删除的规则和账单不会恢复。';

  @override
  String get accountDeleteExplanation => '确定删除此账户吗？事件历史会保留。';

  @override
  String get accountUsageTransactions => '关联交易';

  @override
  String get accountUsageSeries => '周期规则';

  @override
  String get accountUsagePending => '待入账账单';

  @override
  String get errorAccountHasReferences => '此账户仍有未删除的交易或周期规则。可选择归档，或先处理关联记录。';

  @override
  String get errorAccountHasActiveSchedules => '此账户有仍在进行的周期规则或待入账账单，请先处理。';

  @override
  String get accountDeleteChooseAction => '此账户有关联交易或周期规则，请选择处理方式。';

  @override
  String get accountDeleteArchivedChooseAction => '请选择删除关联交易及周期规则，或将它们转移到其他账户。';

  @override
  String get accountMoveAndDelete => '转移记录并删除';

  @override
  String get accountDeleteWithTransactions => '删除账户及记录';

  @override
  String get accountSelectDestination => '选择目标账户';

  @override
  String get accountNoDestination => '没有可用的同币种其他正常账户。';

  @override
  String get accountDeleteImpact =>
      '初始余额和余额调整会被冲销。删除转账会同时影响另一账户的余额；转移记录会改变目标账户余额。周期规则将按所选方式处理。';

  @override
  String get accountConfirmOperation => '确认';

  @override
  String get supportCenter => '支持中心';

  @override
  String get supportCenterHint => '获取帮助与常见问题解答';

  @override
  String get appOverview => '应用介绍';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String get termsOfService => '服务条款';

  @override
  String feedbackConfirmation(String email) {
    return '将打开您的邮件应用，向 $email 发送反馈。';
  }

  @override
  String get openEmailApp => '打开邮件应用';

  @override
  String get feedbackEmailSubject => 'Accounted For 意见反馈';

  @override
  String get emailUnavailable => '无法打开邮件应用';

  @override
  String emailUnavailableMessage(String email) {
    return '无法打开邮件应用。您可以复制 $email，通过其他应用联系我们。';
  }

  @override
  String get copyEmail => '复制邮箱';

  @override
  String get linkUnavailable => '无法打开链接';

  @override
  String get linkUnavailableMessage => '请确认设备上有可用的浏览器，然后重试。';

  @override
  String autoPostedCountMessage(int count) {
    return '已自动记入 $count 笔自动入账账单';
  }

  @override
  String get skippedBill => '已跳过';

  @override
  String get restoreToPending => '恢复为待入账';

  @override
  String get billRestored => '已恢复为待入账';

  @override
  String get failedBill => '自动入账失败';

  @override
  String get failedBillBanner => '自动入账失败，请检查账户或分类后重试记入或跳过本期。';

  @override
  String get retryPost => '重试记入';

  @override
  String currencyBacklogTitle(String currency) {
    return '$currency 有待自动入账账单';
  }

  @override
  String currencyBacklogMessage(int count) {
    return '切换到其他币种期间，有 $count 笔开启自动入账的账单已到期。';
  }

  @override
  String get currencyBacklogPostAll => '全部入账';

  @override
  String get currencyBacklogKeepPending => '保留为待入账';

  @override
  String get errorBudgetNoteTooLong => '复盘备忘不能超过 500 字';

  @override
  String get budgetModePlan => '规划';

  @override
  String get budgetModeTrack => '跟踪';

  @override
  String get budgetModeReview => '复盘';

  @override
  String get budgetReviewPreviewToggle => '复盘预览';

  @override
  String get budgetTracking => '预算跟踪';

  @override
  String get budgetTotal => '本月总预算';

  @override
  String get budgetActualSpent => '已消费';

  @override
  String get budgetPendingShort => '待入账';

  @override
  String get budgetProjectedRemaining => '预计剩余';

  @override
  String get budgetProjectedOver => '预计超支';

  @override
  String get budgetCompliance => '达标率';

  @override
  String get budgetCommitted => '固定';

  @override
  String get budgetCommittedSpending => '固定消费';

  @override
  String get budgetDiscretionarySpending => '弹性消费';

  @override
  String get budgetDiscretionary => '弹性';

  @override
  String get budgetCommittedBaseline => '固定基线';

  @override
  String get budgetOverviewMonthlySurplus => '本月结余';

  @override
  String get budgetOverviewMonthlyOverspend => '本月超支';

  @override
  String get budgetOverviewAvailable => '可自由支配';

  @override
  String get budgetOverviewBudgetUsage => '预算使用率';

  @override
  String get budgetOverviewBaselineShare => '基线占比';

  @override
  String budgetAllExpensesLine(String total, String unbudgeted) {
    return '本月全部实耗 $total（含未设预算 $unbudgeted）';
  }

  @override
  String budgetAllExpensesOnly(String total) {
    return '本月全部实耗 $total';
  }

  @override
  String get budgetLeftoverPendingHint => '该历史月仍有未入账周期账单，复盘统计已忽略。';

  @override
  String get budgetMaterializedOnlyHint => '待入账仅含已物化排期账单。';

  @override
  String get budgetTrendTitle => '近 6 个月预算 vs 实际';

  @override
  String get budgetReviewTitle => '月度复盘与趋势';

  @override
  String get budgetReviewScopeNote => '整月口径，含未设预算的分类。';

  @override
  String get budgetReviewCommittedActual => '固定支出';

  @override
  String get budgetReviewDiscretionaryActual => '弹性支出';

  @override
  String get budgetReviewBaselineNote => '固定支出 + 生效中的待入账。仅供参考，三个数字不可相加。';

  @override
  String get budgetReviewNoteEmptyDeletes => '备注留空并保存即可删除。';

  @override
  String get budgetTrendLegendActual => '全部实际支出';

  @override
  String get budgetTrendLegendBudget => '已设预算总额';

  @override
  String get budgetTrendLegendAverage => '3 个月平均';

  @override
  String get budgetAttributionTitle => '月度复盘与归因';

  @override
  String get budgetOverTopTitle => '超支 TOP';

  @override
  String get budgetUnderTopTitle => '结余 TOP';

  @override
  String get budgetUnbudgetedAlertsTitle => '未设预算大额预警';

  @override
  String get budgetMonthNoteLabel => '月度复盘备忘';

  @override
  String get budgetCategoryNoteLabel => '分类复盘备忘';

  @override
  String get budgetNotePlaceholder => '记录本月偏差原因或下月调整思路（最多 500 字）...';

  @override
  String get budgetNoteSaved => '复盘备忘已保存';

  @override
  String get budgetSaveNote => '保存备忘';

  @override
  String budgetNoteCharCount(int count) {
    return '$count/500';
  }

  @override
  String get budgetSectionBudgeted => '已设预算分类';

  @override
  String get budgetSectionUnbudgetedActive => '计划外支出';

  @override
  String get budgetSectionRemaining => '其余分类（点击设预算）';

  @override
  String get budgetSetButton => '设预算';

  @override
  String budgetRowProjectedOver(String amount) {
    return '预计超支 $amount';
  }

  @override
  String budgetRowOver(String amount) {
    return '已超支 $amount';
  }

  @override
  String budgetRowRemaining(String amount) {
    return '剩余 $amount';
  }

  @override
  String budgetRowReviewRemaining(String amount) {
    return '结余 $amount';
  }

  @override
  String budgetRowReviewOver(String amount) {
    return '超支 $amount';
  }

  @override
  String budgetRowPlanBudget(String amount) {
    return '预算 $amount';
  }

  @override
  String budgetRowPendingIncluded(String amount) {
    return '含待入账 $amount';
  }

  @override
  String budgetRowPending(String amount) {
    return '待入账 $amount';
  }

  @override
  String budgetRowUsage(String percent) {
    return '已用 $percent';
  }

  @override
  String budgetRowBaseline(String amount) {
    return '固定基线 $amount';
  }

  @override
  String budgetRowShare(String percent) {
    return '占本月总支出 $percent';
  }

  @override
  String budgetRowGroupSpent(String amount) {
    return '已消费 $amount';
  }

  @override
  String get budgetRowAnomalySemantics => '波动明显高于近三月均值';

  @override
  String get budgetEditTitle => '设置分类预算';

  @override
  String get budgetAmountLabel => '月度预算额度';

  @override
  String budgetLastMonthRef(String amount) {
    return '上月实际 $amount';
  }

  @override
  String budgetThreeMoAvgRef(String amount) {
    return '近3月均 $amount';
  }

  @override
  String budgetCommittedRef(String amount) {
    return '固定底线 $amount';
  }

  @override
  String get budgetScopeLabel => '应用范围';

  @override
  String get budgetScopeThisMonth => '仅本月';

  @override
  String get budgetScopeThisAndFollowing => '本月及以后';

  @override
  String get budgetScopeFutureOverrideWarning =>
      '后续月份已存在独立预算规则，选择“本月及以后”将覆盖它们。';

  @override
  String get budgetHistoryEditHint => '历史月已结束，建议调整当前或未来月份以指导后续执行。';

  @override
  String get budgetZeroAmountHint => '预算需大于 0；如需取消请点击「取消预算」。';

  @override
  String get budgetClearAction => '取消预算';

  @override
  String budgetClearConfirmTitle(String category) {
    return '删除$category预算？';
  }

  @override
  String budgetClearConfirmThisMonth(
    String month,
    String category,
    String amount,
  ) {
    return '将删除 $month 的$category预算 $amount，并清除本月的分类复盘备忘。';
  }

  @override
  String budgetClearConfirmThisAndFollowing(
    String month,
    String category,
    String amount,
  ) {
    return '将删除 $month 及以后的$category预算 $amount，并清除 $month 及以后的$category分类复盘备忘（含沿用预算、未单独设预算的月份）。';
  }

  @override
  String get budgetClearFutureRulesWarning => '此操作也会清除之后已设置的预算。';

  @override
  String get budgetSaved => '预算已更新';

  @override
  String get budgetCleared => '预算已取消';

  @override
  String get budgetStatusInBudget => '达标';

  @override
  String get budgetStatusAtRisk => '预警';

  @override
  String get budgetStatusOver => '超支';

  @override
  String budgetAnomalyBadge(int percent) {
    return '较均值 +$percent%';
  }

  @override
  String get budgetArchivedReadOnly => '已归档';

  @override
  String get budgetArchivedNoteHint => '该分类已归档，历史预算与复盘备忘仅供只读查看。';

  @override
  String get budgetTopTransactionsTitle => '主要贡献支出';

  @override
  String get budgetViewAll => '查看全部';

  @override
  String get budgetNoTransactionsInMonth => '本月暂无支出记录。';

  @override
  String get budgetEmptyNoAccountsTitle => '新建账户后即可规划预算';

  @override
  String budgetEmptyNoAccountsBody(String currency) {
    return '当前币种（$currency）下暂无活跃账户。';
  }

  @override
  String get budgetEmptyNoBudgetsTitle => '规划你的月度支出';

  @override
  String get budgetEmptyNoBudgetsBody => '点击下方任意分类或右上角 + 即可设置首个分类预算。';

  @override
  String get budgetPickCategoryTitle => '选择支出分类';

  @override
  String budgetHintRemaining(String remaining, String after) {
    return '本月余 $remaining · 记后余 $after';
  }

  @override
  String budgetHintAtRisk(String after) {
    return '含待入账预计超 $after';
  }

  @override
  String budgetHintOver(String over) {
    return '记后将超支 $over';
  }

  @override
  String budgetHintUnset(String spent) {
    return '未设预算 · 本月已耗 $spent';
  }

  @override
  String get budgetHintExcludedAccount => '该账户不计入预算统计';

  @override
  String get budgetHintPastPlanned => '历史月计划账单不计入已完结复盘';

  @override
  String get hideOverviewAmounts => '隐藏概览金额';

  @override
  String get showOverviewAmounts => '显示概览金额';

  @override
  String monthIncome(String month) {
    return '$month收入';
  }

  @override
  String monthExpense(String month) {
    return '$month支出';
  }

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '記然';

  @override
  String get ledgerTitle => '帳本';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '餘額';

  @override
  String get monthEndBalance => '期末餘額';

  @override
  String get totalBalance => '全部餘額';

  @override
  String get noTransactionsThisMonth => '本月無交易記錄';

  @override
  String get noTransactionsTitle => '暫無交易';

  @override
  String get noTransactionsHint => '點擊 + 新增一筆交易';

  @override
  String get noAccountsInCurrencyTitle => '該幣種暫無帳戶';

  @override
  String get noAccountsInCurrencyHint => '建立帳戶以開始記帳';

  @override
  String get addTransaction => '新增交易';

  @override
  String get edit => '編輯';

  @override
  String get editTransaction => '編輯交易';

  @override
  String get deleteTransactionConfirmation => '確定要刪除此交易嗎？此操作無法復原。';

  @override
  String get amount => '金額';

  @override
  String get frequency => '頻率';

  @override
  String get date => '日期';

  @override
  String get today => '今天';

  @override
  String get yesterday => '昨天';

  @override
  String get tomorrow => '明天';

  @override
  String get category => '分類';

  @override
  String get categoryNameHint => '分類名稱';

  @override
  String get name => '名稱';

  @override
  String get color => '顏色';

  @override
  String get icon => '圖示';

  @override
  String get account => '帳戶';

  @override
  String get note => '備註';

  @override
  String get noteHint => '新增備註';

  @override
  String get save => '保存';

  @override
  String get required => '必填';

  @override
  String get invalidAmount => '金額無效';

  @override
  String get noCategoriesFound => '未找到分類，請先新增分類。';

  @override
  String get noAccountsFound => '未找到帳戶。';

  @override
  String errorPrefix(String error) {
    return '錯誤：$error';
  }

  @override
  String get settings => '設定';

  @override
  String get settingsHint => '主題、語言與幣種';

  @override
  String get theme => '主題';

  @override
  String get language => '語言';

  @override
  String get currencySymbol => '貨幣符號';

  @override
  String get accountCurrency => '幣種';

  @override
  String get accountAllCurrencies => '全部幣種';

  @override
  String accountBalanceAdjustmentLedgerHint(String currency) {
    return '餘額調整將記錄在 $currency 帳本中。';
  }

  @override
  String get system => '跟隨系統';

  @override
  String get followSystem => '跟隨系統';

  @override
  String get light => '淺色';

  @override
  String get dark => '深色';

  @override
  String get english => '英語';

  @override
  String get chinese => '中文';

  @override
  String get simplifiedChinese => '簡體中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get loading => '載入中...';

  @override
  String get reports => '報表';

  @override
  String get budget => '預算';

  @override
  String get viewReports => '查看報表';

  @override
  String get activityHeatmap => '活動熱力圖';

  @override
  String heatmapNetFlow(String amount) {
    return '淨流量：$amount';
  }

  @override
  String get heatmapZeroNetFlow => '淨流量為零';

  @override
  String get heatmapNetInflow => '淨流入';

  @override
  String get heatmapNetOutflow => '淨流出';

  @override
  String get incomeBreakdown => '收入明細';

  @override
  String get expenseBreakdown => '支出明細';

  @override
  String get others => '其餘項';

  @override
  String get noData => '暫無資料';

  @override
  String get more => '更多';

  @override
  String get accounts => '帳戶';

  @override
  String get accountsHint => '帳戶與各自的餘額';

  @override
  String get categories => '分類';

  @override
  String get categoriesHint => '收入與支出的分類';

  @override
  String get dollarCurrency => '\$ (美元)';

  @override
  String get yuanCurrency => '¥ (人民幣)';

  @override
  String get yenCurrency => '¥ (日圓)';

  @override
  String get euroCurrency => '€ (歐元)';

  @override
  String get poundCurrency => '£ (英鎊)';

  @override
  String get accountsTitle => '帳戶';

  @override
  String get addAccount => '新增帳戶';

  @override
  String get editAccount => '編輯帳戶';

  @override
  String get accountName => '帳戶名稱';

  @override
  String get accountType => '帳戶類型';

  @override
  String get accountTypeCash => '現金';

  @override
  String get accountTypeBank => '銀行帳戶';

  @override
  String get accountTypeCredit => '信用卡';

  @override
  String get accountTypeOther => '其他帳戶';

  @override
  String get accountExcludedFromTotals => '不計入合計';

  @override
  String get accountArchived => '已封存';

  @override
  String get initialBalance => '初始餘額';

  @override
  String get transactionType => '類型';

  @override
  String get accountSaved => '帳戶已儲存';

  @override
  String get balanceChangeDetectedTitle => '偵測到餘額變更';

  @override
  String get balanceChangeDetectedMessage => '餘額已更改，將建立一筆更正交易。是否繼續？';

  @override
  String get accountBalanceAdjustmentDescription => '餘額調整';

  @override
  String get accountInitialBalanceNote => '初始餘額';

  @override
  String get accountIncludeInTotals => '納入餘額統計';

  @override
  String get accountIncludeInTotalsHint => '關閉後，此帳戶不計入總餘額與收支合計，但它的交易仍會顯示在帳本裡。';

  @override
  String get accountBalanceAdjustmentNotes => '餘額修正';

  @override
  String get deleteAccountConfirmation => '確定要刪除此帳戶嗎？';

  @override
  String get deleteCategoryConfirmationTitle => '確定要刪除該分類嗎？';

  @override
  String get deleteCategoryConfirmationMessage => '不會刪除既有的交易記錄。';

  @override
  String get delete => '刪除';

  @override
  String get cancel => '取消';

  @override
  String get feedback => '意見回饋';

  @override
  String get feedbackHint => '告訴我們你的想法';

  @override
  String get about => '關於';

  @override
  String get aboutHint => '應用程式資訊與開源授權';

  @override
  String get openSourceLicenses => '開源許可';

  @override
  String get version => '版本';

  @override
  String get featureNotAvailable => '功能暫不可用';

  @override
  String get manageCategories => '管理分類';

  @override
  String get manageAccounts => '管理帳戶';

  @override
  String get categoryFood => '餐飲';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryEntertainment => '娛樂';

  @override
  String get categoryShopping => '購物';

  @override
  String get categoryClothing => '服裝';

  @override
  String get categoryHouseholdSupplies => '日用品';

  @override
  String get categoryCommunications => '通訊';

  @override
  String get categoryHealth => '健康';

  @override
  String get categoryEducation => '教育';

  @override
  String get categoryGifts => '禮物';

  @override
  String get categoryReversalExpense => '餘額更正';

  @override
  String get categorySalary => '薪資';

  @override
  String get categoryBonus => '獎金';

  @override
  String get categoryPartTimeJob => '兼職';

  @override
  String get categoryAllowance => '零用錢';

  @override
  String get categoryInvestmentReturns => '投資收益';

  @override
  String get categoryReversalIncome => '餘額更正';

  @override
  String get accountCash => '現金';

  @override
  String get accountBankCard => '銀行卡';

  @override
  String get errorAccountNotFound => '帳戶不存在';

  @override
  String get errorAccountArchived => '帳戶已封存';

  @override
  String get errorCategoryNotFound => '分類不存在';

  @override
  String get errorCategoryArchived => '分類已封存';

  @override
  String get errorCategoryTypeMismatch => '分類類型與交易類型不符';

  @override
  String get errorSystemCategoryProtected => '系統分類不可封存';

  @override
  String get errorInvalidTransfer => '無效轉帳';

  @override
  String get errorInvalidTransactionShape => '交易無效，未儲存';

  @override
  String get transfer => '轉帳';

  @override
  String get transferFrom => '轉出帳戶';

  @override
  String get transferTo => '轉入帳戶';

  @override
  String get addTransfer => '新增轉帳';

  @override
  String get editTransfer => '編輯轉帳';

  @override
  String get errorTransactionNotFound => '交易不存在';

  @override
  String get errorTransactionAlreadyReversed => '交易已被沖正';

  @override
  String get errorCurrencyMismatch => '兩個帳戶必須使用同一種貨幣';

  @override
  String get errorSameAccountTransfer => '請選擇兩個不同的帳戶';

  @override
  String get errorScheduledAlreadyPosted => '該週期交易已入帳';

  @override
  String get errorScheduledNotSkipped => '僅已略過的帳單可以恢復為待入帳';

  @override
  String get errorRecurringSeriesStopped => '該週期規則已停止';

  @override
  String get errorScheduledDateTaken => '這條規則在那天已經有一筆帳單了';

  @override
  String get errorCountLimitTooSmall => '總次數必須大於已入帳和已跳過的次數';

  @override
  String get editRecurringTitle => '編輯週期帳單';

  @override
  String get nextStep => '下一步';

  @override
  String get billUpdated => '帳單已更新';

  @override
  String get errorUnknownEvent => '出了點問題，請重試。';

  @override
  String get auditHistory => '審計歷史';

  @override
  String get eventRecorded => '已記錄';

  @override
  String get eventReversed => '已沖正';

  @override
  String get reversalUserDeleted => '使用者刪除';

  @override
  String get reversalCorrection => '修改';

  @override
  String get rebuildProjections => '重建投影';

  @override
  String get rebuildProjectionsHint => '開發者工具——長按執行';

  @override
  String get rebuildProjectionsConfirm => '清空全部衍生資料並從完整事件歷史重放？定期規則與偏好設定保留。';

  @override
  String get rebuildProjectionsSuccess => '投影已重建';

  @override
  String get rebuildProjectionsFailure => '重建失敗';

  @override
  String get overdraftWarningTitle => '警告';

  @override
  String get overdraftWarningMessage => '該交易將導致帳戶透支，是否繼續？';

  @override
  String get previousYear => '上一年';

  @override
  String get nextYear => '下一年';

  @override
  String get backupFileTypeLabel => '記然 備份';

  @override
  String get backupNow => '立即備份';

  @override
  String get backupNowHint => '把整個帳本匯出為一個檔案';

  @override
  String get restoreFromBackup => '從備份還原';

  @override
  String get restoreFromBackupHint => '用備份檔案取代全部資料';

  @override
  String get backupCreated => '備份已產生';

  @override
  String get restoreConfirmTitle => '取代全部資料？';

  @override
  String restoreConfirmMessage(
    int backupEvents,
    int currentEvents,
    int discarded,
  ) {
    return '這份備份包含 $backupEvents 條事件，目前帳本有 $currentEvents 條，還原將捨棄其中 $discarded 條。目前儲存的全部內容都會被取代。';
  }

  @override
  String get restoreReadyTitle => '還原已就緒';

  @override
  String get restoreReadyMessage => '請完全關閉記然 後重新開啟，以完成還原。';

  @override
  String get exitNow => '現在結束';

  @override
  String get postInstanceTitle => '記入這筆';

  @override
  String get postInstanceConfirm => '把這筆帳單記為交易？';

  @override
  String get postInstance => '記入';

  @override
  String get instancePosted => '已記入';

  @override
  String get deleteRecurringTitle => '刪除週期帳單';

  @override
  String get scopeThisOnly => '僅編輯本期';

  @override
  String get saveRecurringTitle => '保存週期帳單';

  @override
  String get scopeThisOnlyUnavailable => '分類、帳戶、重複規則、自動入帳和提醒屬於整條規則';

  @override
  String get scopeThisAndFollowing => '該項記錄和後續記錄';

  @override
  String get scopeAll => '所有記錄';

  @override
  String get scopeAllHint => '已經入帳的記錄會保留';

  @override
  String get scopeUpdateRule => '修改重複規則';

  @override
  String get scopeUpdateRuleHint => '已入帳記錄保留不變；後續待入帳帳單按新規則生成';

  @override
  String get skipThisBill => '跳過本期';

  @override
  String get skipBillTitle => '跳過本期帳單？';

  @override
  String get skipBillConfirm => '本期帳單將標記為已跳過，後續重複規則仍按計畫繼續生成。';

  @override
  String get skipBillAction => '跳過';

  @override
  String get billSkipped => '已跳過本期帳單';

  @override
  String get stopRepeatingRule => '停止重複';

  @override
  String get stopRepeatingTitle => '停止重複規則？';

  @override
  String get stopRepeatingConfirm => '將刪除該規則下所有未入帳帳單；已入帳的歷史記錄會保留。';

  @override
  String get stopRepeatingAction => '停止重複';

  @override
  String get repeatingStopped => '已停止重複規則';

  @override
  String get deletePlan => '刪除該計畫';

  @override
  String get deletePlanTitle => '刪除該計畫？';

  @override
  String get deletePlanConfirm => '該計畫帳單將被永久刪除。';

  @override
  String get billDeleted => '帳單已刪除';

  @override
  String get frequencyDaily => '天';

  @override
  String get frequencyWeekly => '週';

  @override
  String get frequencyMonthly => '月';

  @override
  String get frequencyYearly => '年';

  @override
  String get searchHint => '搜尋備註、分類、帳戶';

  @override
  String get filterTitle => '篩選';

  @override
  String get filterAllKinds => '全部';

  @override
  String get filterAnyAccount => '任意帳戶';

  @override
  String get filterAnyCategory => '任意分類';

  @override
  String get filterAnyDate => '任意日期';

  @override
  String get filterDateRange => '日期範圍';

  @override
  String get filterApply => '套用';

  @override
  String get filterClear => '清除';

  @override
  String get exportCsv => '匯出 CSV';

  @override
  String get noSearchResults => '沒有符合的交易';

  @override
  String get pendingBill => '待入帳';

  @override
  String get repeat => '重複';

  @override
  String get transactionModeDefault => '預設';

  @override
  String get transactionModePlanned => '計畫';

  @override
  String get transactionModeSubscription => '訂閱';

  @override
  String get transactionModeRepeating => '重複';

  @override
  String get autoPostWhenDue => '自動入帳';

  @override
  String overdueBillsAdded(int count) {
    return '新補齊了 $count 筆已到期帳單';
  }

  @override
  String get repeatNever => '不重複';

  @override
  String repeatSetupFailed(String error) {
    return '已儲存。但重複規則建立失敗：$error';
  }

  @override
  String get addAttachment => '新增附件';

  @override
  String get attachments => '附件';

  @override
  String get removeAttachment => '移除附件';

  @override
  String get select => '請選擇';

  @override
  String attachmentCount(int count) {
    return '$count 個附件';
  }

  @override
  String get uploadCategoryIcon => '上傳圖示';

  @override
  String get categoryIconFileType => '圖片';

  @override
  String get cropCategoryIcon => '裁剪圖示';

  @override
  String get categoryIconCropDescription => '拖動圖片調整位置，雙指捏合或使用滑桿縮放。';

  @override
  String get invalidCategoryIcon => '請選擇不超過 5 MB、寬高至少為 32 像素的 PNG 或 JPEG 圖片。';

  @override
  String get categoryIconZoom => '縮放';

  @override
  String get categoryIconUploadHint => 'PNG 或 JPEG，最大 5 MB';

  @override
  String get customRepeat => '自訂';

  @override
  String get repeatEvery => '每';

  @override
  String get repeatInterval => '間隔';

  @override
  String get repeatStart => '開始時間';

  @override
  String get repeatEnds => '何時結束重複';

  @override
  String get repeatNeverEnds => '永不結束';

  @override
  String get repeatUntil => '在此日期結束';

  @override
  String get repeatCount => '重複次數';

  @override
  String get repeatCountPrefix => '重複';

  @override
  String get repeatCountSuffix => '次';

  @override
  String get reminder => '提醒';

  @override
  String get reminderNone => '不提醒';

  @override
  String get reminder5 => '提前 5 分鐘';

  @override
  String get reminder10 => '提前 10 分鐘';

  @override
  String get reminder15 => '提前 15 分鐘';

  @override
  String get reminder30 => '提前 30 分鐘';

  @override
  String get reminderHour => '提前 1 小時';

  @override
  String get reminderDay => '提前 1 天';

  @override
  String get reminderCustom => '自訂';

  @override
  String get reminderUnitMinutes => '分鐘';

  @override
  String get reminderUnitHours => '小時';

  @override
  String get reminderUnitDays => '天';

  @override
  String get reminderPermissionRequired => '請允許通知和精確提醒，以使用提醒功能。';

  @override
  String get reminderNotificationTitle => '待入帳交易提醒';

  @override
  String get reminderChannel => '交易提醒';

  @override
  String get reminderCustomTitle => '自訂提醒';

  @override
  String get reminderAmount => '數量';

  @override
  String reminderMinutesValue(int count) {
    return '提前 $count 分鐘';
  }

  @override
  String get notificationSkip => '略過';

  @override
  String get notificationSkipped => '已略過這筆帳單';

  @override
  String get notificationUnavailable => '該帳單已不存在。';

  @override
  String get notificationDeleted => '這筆帳單已刪除。';

  @override
  String get accountArchiveAction => '封存帳戶';

  @override
  String get accountRestoreAction => '恢復帳戶';

  @override
  String get accountArchivedSection => '已封存帳戶';

  @override
  String get accountArchiveExplanation =>
      '封存將刪除此帳戶的週期規則和未來待入帳帳單，並取消相應提醒。已到期的待入帳帳單和已入帳交易會保留。恢復帳戶後，已刪除的規則和帳單不會恢復。';

  @override
  String get accountDeleteExplanation => '確定刪除此帳戶嗎？事件歷史會保留。';

  @override
  String get accountUsageTransactions => '關聯交易';

  @override
  String get accountUsageSeries => '週期規則';

  @override
  String get accountUsagePending => '待入帳帳單';

  @override
  String get errorAccountHasReferences => '此帳戶仍有未刪除的交易或週期規則。可選擇封存，或先處理關聯記錄。';

  @override
  String get errorAccountHasActiveSchedules => '此帳戶有仍在進行的週期規則或待入帳帳單，請先處理。';

  @override
  String get accountDeleteChooseAction => '此帳戶有關聯交易或週期規則，請選擇處理方式。';

  @override
  String get accountDeleteArchivedChooseAction => '請選擇刪除關聯交易及週期規則，或將它們轉移到其他帳戶。';

  @override
  String get accountMoveAndDelete => '轉移記錄並刪除';

  @override
  String get accountDeleteWithTransactions => '刪除帳戶及記錄';

  @override
  String get accountSelectDestination => '選擇目標帳戶';

  @override
  String get accountNoDestination => '沒有可用的同幣種其他正常帳戶。';

  @override
  String get accountDeleteImpact =>
      '初始餘額和餘額調整會被沖銷。刪除轉帳會同時影響另一帳戶的餘額；轉移記錄會改變目標帳戶餘額。週期規則將按所選方式處理。';

  @override
  String get accountConfirmOperation => '確認';

  @override
  String get supportCenter => '支援中心';

  @override
  String get supportCenterHint => '取得協助與常見問題解答';

  @override
  String get appOverview => '應用程式介紹';

  @override
  String get privacyPolicy => '隱私權政策';

  @override
  String get termsOfService => '服務條款';

  @override
  String feedbackConfirmation(String email) {
    return '將開啟您的郵件應用程式，向 $email 傳送意見回饋。';
  }

  @override
  String get openEmailApp => '開啟郵件應用程式';

  @override
  String get feedbackEmailSubject => 'Accounted For 意見回饋';

  @override
  String get emailUnavailable => '無法開啟郵件應用程式';

  @override
  String emailUnavailableMessage(String email) {
    return '無法開啟郵件應用程式。您可以複製 $email，透過其他應用程式聯絡我們。';
  }

  @override
  String get copyEmail => '複製電子郵件地址';

  @override
  String get linkUnavailable => '無法開啟連結';

  @override
  String get linkUnavailableMessage => '請確認裝置上有可用的瀏覽器，然後再試一次。';

  @override
  String autoPostedCountMessage(int count) {
    return '已自動記入 $count 筆自動入帳帳單';
  }

  @override
  String get skippedBill => '已略過';

  @override
  String get restoreToPending => '恢復為待入帳';

  @override
  String get billRestored => '已恢復為待入帳';

  @override
  String get failedBill => '自動入帳失敗';

  @override
  String get failedBillBanner => '自動入帳失敗，請檢查帳戶或分類後重試記入或跳過本期。';

  @override
  String get retryPost => '重試記入';

  @override
  String currencyBacklogTitle(String currency) {
    return '$currency 有待自動入帳帳單';
  }

  @override
  String currencyBacklogMessage(int count) {
    return '切換到其他幣種期間，有 $count 筆開啟自動入帳的帳單已到期。';
  }

  @override
  String get currencyBacklogPostAll => '全部入帳';

  @override
  String get currencyBacklogKeepPending => '保留為待入帳';

  @override
  String get errorBudgetNoteTooLong => '複盤備忘不能超過 500 字';

  @override
  String get budgetModePlan => '規劃';

  @override
  String get budgetModeTrack => '追蹤';

  @override
  String get budgetModeReview => '複盤';

  @override
  String get budgetReviewPreviewToggle => '複盤預覽';

  @override
  String get budgetTracking => '預算追蹤';

  @override
  String get budgetTotal => '本月總預算';

  @override
  String get budgetActualSpent => '已消費';

  @override
  String get budgetPendingShort => '待入帳';

  @override
  String get budgetProjectedRemaining => '預計剩餘';

  @override
  String get budgetProjectedOver => '預計超支';

  @override
  String get budgetCompliance => '達標率';

  @override
  String get budgetCommitted => '固定';

  @override
  String get budgetCommittedSpending => '固定消費';

  @override
  String get budgetDiscretionarySpending => '彈性消費';

  @override
  String get budgetDiscretionary => '彈性';

  @override
  String get budgetCommittedBaseline => '固定基準線';

  @override
  String get budgetOverviewMonthlySurplus => '本月結餘';

  @override
  String get budgetOverviewMonthlyOverspend => '本月超支';

  @override
  String get budgetOverviewAvailable => '可自由支配';

  @override
  String get budgetOverviewBudgetUsage => '預算使用率';

  @override
  String get budgetOverviewBaselineShare => '基線佔比';

  @override
  String budgetAllExpensesLine(String total, String unbudgeted) {
    return '本月全部實耗 $total（含未設預算 $unbudgeted）';
  }

  @override
  String budgetAllExpensesOnly(String total) {
    return '本月全部實耗 $total';
  }

  @override
  String get budgetLeftoverPendingHint => '該歷史月仍有未入帳週期帳單，複盤統計已忽略。';

  @override
  String get budgetMaterializedOnlyHint => '待入帳僅含已物化排期帳單。';

  @override
  String get budgetTrendTitle => '近 6 個月預算 vs 實際';

  @override
  String get budgetReviewTitle => '月度複盤與趨勢';

  @override
  String get budgetReviewScopeNote => '整月口徑，含未設預算的分類。';

  @override
  String get budgetReviewCommittedActual => '固定支出';

  @override
  String get budgetReviewDiscretionaryActual => '彈性支出';

  @override
  String get budgetReviewBaselineNote => '固定支出 + 生效中的待入帳。僅供參考，三個數字不可相加。';

  @override
  String get budgetReviewNoteEmptyDeletes => '備註留空並儲存即可刪除。';

  @override
  String get budgetTrendLegendActual => '全部實際支出';

  @override
  String get budgetTrendLegendBudget => '已設預算總額';

  @override
  String get budgetTrendLegendAverage => '3 個月平均';

  @override
  String get budgetAttributionTitle => '月度複盤與歸因';

  @override
  String get budgetOverTopTitle => '超支 TOP';

  @override
  String get budgetUnderTopTitle => '結餘 TOP';

  @override
  String get budgetUnbudgetedAlertsTitle => '未設預算大額預警';

  @override
  String get budgetMonthNoteLabel => '月度複盤備忘';

  @override
  String get budgetCategoryNoteLabel => '分類複盤備忘';

  @override
  String get budgetNotePlaceholder => '記錄本月偏差原因或下月調整思路（最多 500 字）...';

  @override
  String get budgetNoteSaved => '複盤備忘已儲存';

  @override
  String get budgetSaveNote => '儲存備忘';

  @override
  String budgetNoteCharCount(int count) {
    return '$count/500';
  }

  @override
  String get budgetSectionBudgeted => '已設預算分類';

  @override
  String get budgetSectionUnbudgetedActive => '計劃外支出';

  @override
  String get budgetSectionRemaining => '其餘分類（點擊設預算）';

  @override
  String get budgetSetButton => '設預算';

  @override
  String budgetRowProjectedOver(String amount) {
    return '預計超支 $amount';
  }

  @override
  String budgetRowOver(String amount) {
    return '已超支 $amount';
  }

  @override
  String budgetRowRemaining(String amount) {
    return '剩餘 $amount';
  }

  @override
  String budgetRowReviewRemaining(String amount) {
    return '結餘 $amount';
  }

  @override
  String budgetRowReviewOver(String amount) {
    return '超支 $amount';
  }

  @override
  String budgetRowPlanBudget(String amount) {
    return '預算 $amount';
  }

  @override
  String budgetRowPendingIncluded(String amount) {
    return '含待入賬 $amount';
  }

  @override
  String budgetRowPending(String amount) {
    return '待入賬 $amount';
  }

  @override
  String budgetRowUsage(String percent) {
    return '已用 $percent';
  }

  @override
  String budgetRowBaseline(String amount) {
    return '固定基準 $amount';
  }

  @override
  String budgetRowShare(String percent) {
    return '占本月總支出 $percent';
  }

  @override
  String budgetRowGroupSpent(String amount) {
    return '已消費 $amount';
  }

  @override
  String get budgetRowAnomalySemantics => '波動明顯高於近三月均值';

  @override
  String get budgetEditTitle => '設定分類預算';

  @override
  String get budgetAmountLabel => '月度預算額度';

  @override
  String budgetLastMonthRef(String amount) {
    return '上月實際 $amount';
  }

  @override
  String budgetThreeMoAvgRef(String amount) {
    return '近3月均 $amount';
  }

  @override
  String budgetCommittedRef(String amount) {
    return '固定基準線 $amount';
  }

  @override
  String get budgetScopeLabel => '套用範圍';

  @override
  String get budgetScopeThisMonth => '僅本月';

  @override
  String get budgetScopeThisAndFollowing => '本月及以後';

  @override
  String get budgetScopeFutureOverrideWarning =>
      '後續月份已存在獨立預算規則，選擇「本月及以後」將覆蓋它們。';

  @override
  String get budgetHistoryEditHint => '歷史月已結束，建議調整目前或未來月份以指導後續執行。';

  @override
  String get budgetZeroAmountHint => '預算須大於 0；如需取消請點擊「取消預算」。';

  @override
  String get budgetClearAction => '取消預算';

  @override
  String budgetClearConfirmTitle(String category) {
    return '刪除$category預算？';
  }

  @override
  String budgetClearConfirmThisMonth(
    String month,
    String category,
    String amount,
  ) {
    return '將刪除 $month 的$category預算 $amount，並清除本月的分類複盤備忘。';
  }

  @override
  String budgetClearConfirmThisAndFollowing(
    String month,
    String category,
    String amount,
  ) {
    return '將刪除 $month 及以後的$category預算 $amount，並清除 $month 及以後的$category分類複盤備忘（含沿用預算、未單獨設預算的月份）。';
  }

  @override
  String get budgetClearFutureRulesWarning => '此操作也會清除之後已設置的預算。';

  @override
  String get budgetSaved => '預算已更新';

  @override
  String get budgetCleared => '預算已取消';

  @override
  String get budgetStatusInBudget => '達標';

  @override
  String get budgetStatusAtRisk => '預警';

  @override
  String get budgetStatusOver => '超支';

  @override
  String budgetAnomalyBadge(int percent) {
    return '較均值 +$percent%';
  }

  @override
  String get budgetArchivedReadOnly => '已封存';

  @override
  String get budgetArchivedNoteHint => '該分類已封存，歷史預算與複盤備忘僅供唯讀檢視。';

  @override
  String get budgetTopTransactionsTitle => '主要貢獻支出';

  @override
  String get budgetViewAll => '查看全部';

  @override
  String get budgetNoTransactionsInMonth => '本月尚無支出記錄。';

  @override
  String get budgetEmptyNoAccountsTitle => '新增帳戶後即可規劃預算';

  @override
  String budgetEmptyNoAccountsBody(String currency) {
    return '目前幣別（$currency）下尚無活躍帳戶。';
  }

  @override
  String get budgetEmptyNoBudgetsTitle => '規劃你的月度支出';

  @override
  String get budgetEmptyNoBudgetsBody => '點擊下方任意分類或右上角 + 即可設定首個分類預算。';

  @override
  String get budgetPickCategoryTitle => '選擇支出分類';

  @override
  String budgetHintRemaining(String remaining, String after) {
    return '本月餘 $remaining · 記後餘 $after';
  }

  @override
  String budgetHintAtRisk(String after) {
    return '含待入帳預計超 $after';
  }

  @override
  String budgetHintOver(String over) {
    return '記後將超支 $over';
  }

  @override
  String budgetHintUnset(String spent) {
    return '未設預算 · 本月已耗 $spent';
  }

  @override
  String get budgetHintExcludedAccount => '該帳戶不計入預算統計';

  @override
  String get budgetHintPastPlanned => '歷史月計劃帳單不計入已完結複盤';

  @override
  String get hideOverviewAmounts => '隱藏概覽金額';

  @override
  String get showOverviewAmounts => '顯示概覽金額';

  @override
  String monthIncome(String month) {
    return '$month收入';
  }

  @override
  String monthExpense(String month) {
    return '$month支出';
  }

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';
}
