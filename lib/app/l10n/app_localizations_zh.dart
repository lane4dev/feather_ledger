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
  String get total_balance => '全部余额';

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
}
