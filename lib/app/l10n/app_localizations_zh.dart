// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '轻羽账本';

  @override
  String get ledgerTitle => '账本';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '余额';

  @override
  String get totalBalance => '全部余额';

  @override
  String get noTransactionsThisMonth => '本月无交易记录';

  @override
  String get noTransactionsTitle => '暂无交易';

  @override
  String get noTransactionsHint => '点击 + 添加一笔交易';

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
  String get save => '保存';

  @override
  String get saveTransaction => '保存交易';

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
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get currencySymbol => '货币符号';

  @override
  String get system => '跟随系统';

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
  String get activityHeatmap => '活动热力图';

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
  String get categories => '分类';

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
  String get initialBalance => '初始余额';

  @override
  String get accountSaved => '账户已保存';

  @override
  String get balanceChangeDetectedTitle => '检测到余额变更';

  @override
  String get balanceChangeDetectedMessage => '余额已更改，将创建一笔更正交易。是否继续？';

  @override
  String get accountBalanceAdjustmentDescription => '账户余额调整';

  @override
  String get accountInitialBalanceNote => '差额';

  @override
  String get accountBalanceAdjustmentNotes => '因账户余额变更自动调整。';

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
  String get feedback => '反馈';

  @override
  String get about => '关于';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get version => '版本';

  @override
  String get featureNotAvailable => '功能暂不可用';

  @override
  String get pressBackAgainToExit => '再按一次退出';

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
  String get errorScheduledDateTaken => '这条规则在那天已经有一笔账单了';

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
  String get backupFileTypeLabel => '轻羽账本 备份';

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
      int backupEvents, int currentEvents, int discarded) {
    return '这份备份包含 $backupEvents 条事件，当前账本有 $currentEvents 条，恢复将丢弃其中 $discarded 条。当前存储的全部内容都会被替换。';
  }

  @override
  String get restoreReadyTitle => '恢复已就绪';

  @override
  String get restoreReadyMessage => '请完全关闭 Feather Ledger 后重新打开，以完成恢复。';

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
  String get scopeThisOnly => '该项记录';

  @override
  String get saveRecurringTitle => '保存周期账单';

  @override
  String get scopeThisOnlyUnavailable => '分类、账户和备注属于整条规则';

  @override
  String get scopeThisAndFollowing => '该项记录和后续记录';

  @override
  String get scopeAll => '所有记录';

  @override
  String get scopeAllHint => '已经入账的记录会保留';

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
  String get repeatNever => '不重复';

  @override
  String repeatSetupFailed(String error) {
    return '已保存。但重复规则创建失败：$error';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hans`).
class AppLocalizationsZhHans extends AppLocalizationsZh {
  AppLocalizationsZhHans() : super('zh_Hans');

  @override
  String get appTitle => '轻羽账本';

  @override
  String get ledgerTitle => '账本';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '余额';

  @override
  String get totalBalance => '全部余额';

  @override
  String get noTransactionsThisMonth => '本月无交易记录';

  @override
  String get noTransactionsTitle => '暂无交易';

  @override
  String get noTransactionsHint => '点击 + 添加一笔交易';

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
  String get save => '保存';

  @override
  String get saveTransaction => '保存交易';

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
  String get theme => '主题';

  @override
  String get language => '语言';

  @override
  String get currencySymbol => '货币符号';

  @override
  String get system => '跟随系统';

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
  String get activityHeatmap => '活动热力图';

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
  String get categories => '分类';

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
  String get initialBalance => '初始余额';

  @override
  String get accountSaved => '账户已保存';

  @override
  String get balanceChangeDetectedTitle => '检测到余额变更';

  @override
  String get balanceChangeDetectedMessage => '余额已更改，将创建一笔更正交易。是否继续？';

  @override
  String get accountBalanceAdjustmentDescription => '账户余额调整';

  @override
  String get accountInitialBalanceNote => '差额';

  @override
  String get accountBalanceAdjustmentNotes => '因账户余额变更自动调整。';

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
  String get feedback => '反馈';

  @override
  String get about => '关于';

  @override
  String get openSourceLicenses => '开源许可';

  @override
  String get version => '版本';

  @override
  String get featureNotAvailable => '功能暂不可用';

  @override
  String get pressBackAgainToExit => '再按一次退出';

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
  String get errorScheduledDateTaken => '这条规则在那天已经有一笔账单了';

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
  String get backupFileTypeLabel => '轻羽账本 备份';

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
      int backupEvents, int currentEvents, int discarded) {
    return '这份备份包含 $backupEvents 条事件，当前账本有 $currentEvents 条，恢复将丢弃其中 $discarded 条。当前存储的全部内容都会被替换。';
  }

  @override
  String get restoreReadyTitle => '恢复已就绪';

  @override
  String get restoreReadyMessage => '请完全关闭 Feather Ledger 后重新打开，以完成恢复。';

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
  String get scopeThisOnly => '该项记录';

  @override
  String get saveRecurringTitle => '保存周期账单';

  @override
  String get scopeThisOnlyUnavailable => '分类、账户和备注属于整条规则';

  @override
  String get scopeThisAndFollowing => '该项记录和后续记录';

  @override
  String get scopeAll => '所有记录';

  @override
  String get scopeAllHint => '已经入账的记录会保留';

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
  String get repeatNever => '不重复';

  @override
  String repeatSetupFailed(String error) {
    return '已保存。但重复规则创建失败：$error';
  }
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get appTitle => '輕羽帳本';

  @override
  String get ledgerTitle => '帳本';

  @override
  String get income => '收入';

  @override
  String get expense => '支出';

  @override
  String get balance => '餘額';

  @override
  String get totalBalance => '全部餘額';

  @override
  String get noTransactionsThisMonth => '本月無交易記錄';

  @override
  String get noTransactionsTitle => '暫無交易';

  @override
  String get noTransactionsHint => '點擊 + 新增一筆交易';

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
  String get save => '保存';

  @override
  String get saveTransaction => '儲存交易';

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
  String get theme => '主題';

  @override
  String get language => '語言';

  @override
  String get currencySymbol => '貨幣符號';

  @override
  String get system => '跟隨系統';

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
  String get activityHeatmap => '活動熱力圖';

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
  String get categories => '分類';

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
  String get initialBalance => '初始餘額';

  @override
  String get accountSaved => '帳戶已儲存';

  @override
  String get balanceChangeDetectedTitle => '偵測到餘額變更';

  @override
  String get balanceChangeDetectedMessage => '餘額已更改，將建立一筆更正交易。是否繼續？';

  @override
  String get accountBalanceAdjustmentDescription => '帳戶餘額調整';

  @override
  String get accountInitialBalanceNote => '差額';

  @override
  String get accountBalanceAdjustmentNotes => '因帳戶餘額變更自動調整。';

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
  String get feedback => '回饋';

  @override
  String get about => '關於';

  @override
  String get openSourceLicenses => '開源許可';

  @override
  String get version => '版本';

  @override
  String get featureNotAvailable => '功能暫不可用';

  @override
  String get pressBackAgainToExit => '再按一次退出';

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
  String get errorScheduledDateTaken => '這條規則在那天已經有一筆帳單了';

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
  String get backupFileTypeLabel => '輕羽帳本 備份';

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
      int backupEvents, int currentEvents, int discarded) {
    return '這份備份包含 $backupEvents 條事件，目前帳本有 $currentEvents 條，還原將捨棄其中 $discarded 條。目前儲存的全部內容都會被取代。';
  }

  @override
  String get restoreReadyTitle => '還原已就緒';

  @override
  String get restoreReadyMessage => '請完全關閉 Feather Ledger 後重新開啟，以完成還原。';

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
  String get scopeThisOnly => '該項記錄';

  @override
  String get saveRecurringTitle => '保存週期帳單';

  @override
  String get scopeThisOnlyUnavailable => '分類、帳戶和備註屬於整條規則';

  @override
  String get scopeThisAndFollowing => '該項記錄和後續記錄';

  @override
  String get scopeAll => '所有記錄';

  @override
  String get scopeAllHint => '已經入帳的記錄會保留';

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
  String get repeatNever => '不重複';

  @override
  String repeatSetupFailed(String error) {
    return '已儲存。但重複規則建立失敗：$error';
  }
}
