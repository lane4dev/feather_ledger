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
  String get categoryReversalExpense => '冲正';

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
  String get categoryReversalIncome => '冲正';

  @override
  String get accountCash => '现金';

  @override
  String get accountBankCard => '银行卡';

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
  String get categoryReversalExpense => '冲正';

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
  String get categoryReversalIncome => '冲正';

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
  String get transfer => '转账';

  @override
  String get transferFrom => '转出账户';

  @override
  String get transferTo => '转入账户';

  @override
  String get errorTransactionNotFound => '交易不存在';

  @override
  String get errorTransactionAlreadyReversed => '交易已被冲正';

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
  String get categoryReversalExpense => '沖正';

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
  String get categoryReversalIncome => '沖正';

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
  String get transfer => '轉帳';

  @override
  String get transferFrom => '轉出帳戶';

  @override
  String get transferTo => '轉入帳戶';

  @override
  String get errorTransactionNotFound => '交易不存在';

  @override
  String get errorTransactionAlreadyReversed => '交易已被沖正';

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
}
