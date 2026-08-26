import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../view_model/ledger_view_model.dart';
import '../widgets/ledger_header.dart';
import '../widgets/ledger_transaction_list.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final PageController _pageController = PageController(
    initialPage: _getIndex(DateTime.now()),
  );

  int _monthNavigation = 0;
  bool _programmaticMonthChange = false;

  // Base date for PageView index mapping
  static final DateTime _baseDate = DateTime(2000, 1);

  static int _getIndex(DateTime date) {
    return (date.year - _baseDate.year) * 12 + (date.month - _baseDate.month);
  }

  static DateTime _getDate(int index) {
    return DateTime(_baseDate.year, _baseDate.month + index);
  }

  @override
  void initState() {
    super.initState();
    // Synchronize initial page with selected date if different
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedDate = ref.read(ledgerViewModelProvider).selectedDate;
      final targetIndex = _getIndex(selectedDate);
      if (_pageController.hasClients &&
          _pageController.page?.round() != targetIndex) {
        _pageController.jumpToPage(targetIndex);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToMonth(DateTime date) async {
    final current = ref.read(ledgerViewModelProvider).selectedDate;
    if (current.year == date.year && current.month == date.month) return;

    final navigation = ++_monthNavigation;
    _programmaticMonthChange = true;
    ref.read(ledgerViewModelProvider.notifier).setMonth(date);

    try {
      if (_pageController.hasClients) {
        final targetPage = _getIndex(date);
        final currentPage = _pageController.page?.round() ?? targetPage;
        if (currentPage != targetPage) {
          await _pageController.animateToPage(
            targetPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    } finally {
      if (mounted && navigation == _monthNavigation) {
        _programmaticMonthChange = false;
        if (_pageController.hasClients && _pageController.page != null) {
          ref.read(ledgerViewModelProvider.notifier).setMonth(
                _getDate(_pageController.page!.round()),
              );
        }
      }
    }
  }

  void _onMonthTap(DateTime current) {
    FeatherMonthPicker.show(
      context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      onMonthSelected: (picked) {
        _goToMonth(picked);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ledgerState = ref.watch(ledgerViewModelProvider);
    final selectedDate =
        DateTime(ledgerState.selectedDate.year, ledgerState.selectedDate.month);
    // The month's figures are the provider's business, not the view model's:
    // both the month and the ledger's currency feed them, and only Riverpod
    // sees both. See [ledgerMonthlySummaryProvider].
    // Keep just the neighbouring months subscribed while this screen is open.
    // All three still react to ledger and currency changes normally.
    ref.listen(
        ledgerMonthlySummaryProvider(
            DateTime(selectedDate.year, selectedDate.month - 1)),
        (_, __) {});
    ref.listen(
        ledgerMonthlySummaryProvider(
            DateTime(selectedDate.year, selectedDate.month + 1)),
        (_, __) {});

    final l10n = AppLocalizations.of(context)!;

    // The ledger's own currency, the same one the header and the day totals
    // use — not the display preference, which the accounts may have outgrown.
    final currency = ref.watch(displayCurrencySymbolProvider);

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          if (_programmaticMonthChange) return;
          final date = _getDate(index);
          final current = ref.read(ledgerViewModelProvider).selectedDate;
          if (current.year != date.year || current.month != date.month) {
            ref.read(ledgerViewModelProvider.notifier).setMonth(date);
          }
        },
        itemBuilder: (context, index) {
          final month = _getDate(index);
          return _LedgerMonthPage(
            key: ValueKey(month),
            month: month,
            currency: currency,
            l10n: l10n,
            onMonthChanged: _goToMonth,
            onMonthTap: () => _onMonthTap(month),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/ledger/add');
        },
        child: const Icon(LucideIcons.plus),
      ),
    );
  }
}

class _LedgerMonthPage extends ConsumerStatefulWidget {
  const _LedgerMonthPage(
      {super.key,
      required this.month,
      required this.currency,
      required this.l10n,
      required this.onMonthChanged,
      required this.onMonthTap});

  final DateTime month;
  final String currency;
  final AppLocalizations l10n;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onMonthTap;

  @override
  ConsumerState<_LedgerMonthPage> createState() => _LedgerMonthPageState();
}

class _LedgerMonthPageState extends ConsumerState<_LedgerMonthPage> {
  final _scrollController = ScrollController();
  bool _isCollapsed = false;
  static const double _baseExpandedHeight = 280;

  double get _expandedHeight {
    final scaled = MediaQuery.textScalerOf(context).scale(120);
    return _baseExpandedHeight + (scaled > 120 ? scaled - 120 : 0);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final collapsed = _scrollController.hasClients &&
        isHeaderCollapsed(_scrollController.offset, _expandedHeight);
    if (collapsed != _isCollapsed) setState(() => _isCollapsed = collapsed);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(ledgerMonthlySummaryProvider(widget.month));
    return NestedScrollView(
      controller: _scrollController,
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverOverlapAbsorber(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          sliver: SliverAppBar(
            pinned: true,
            expandedHeight: _expandedHeight,
            forceElevated: innerBoxIsScrolled,
            actions: [
              AppIconButton(
                icon: const Icon(LucideIcons.search),
                tooltip: widget.l10n.searchHint,
                onPressed: () => context.push('/ledger/search'),
              ),
            ],
            title: LedgerAppBarTitle(
              selectedDate: widget.month,
              summaryAsync: summary,
              collapsed: _isCollapsed,
              onMonthChanged: widget.onMonthChanged,
              onMonthTap: widget.onMonthTap,
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(child: LedgerHeader(summaryAsync: summary)),
            ),
          ),
        ),
      ],
      body: LedgerTransactionList(
          month: widget.month, currency: widget.currency, l10n: widget.l10n),
    );
  }
}
