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
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(
    initialPage: _getIndex(DateTime.now()),
  );

  bool _isCollapsed = false;
  static const double _kExpandedHeight = 280.0;

  double get _expandedHeight {
    final scaled = MediaQuery.textScalerOf(context).scale(120);
    return _kExpandedHeight + (scaled > 120 ? scaled - 120 : 0);
  }

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
    _scrollController.addListener(_onScroll);

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // With NestedScrollView, the outer controller monitors the header
    // expansion — and its offset stops exactly where the header is done
    // collapsing, which is why that boundary is a named function.
    final isCollapsed = _scrollController.hasClients &&
        isHeaderCollapsed(_scrollController.offset, _expandedHeight);

    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  Future<void> _goToMonth(DateTime date) async {
    final current = ref.read(ledgerViewModelProvider).selectedDate;
    if (current.year == date.year && current.month == date.month) return;

    // Update state
    ref.read(ledgerViewModelProvider.notifier).setMonth(date);

    // Animate PageView
    if (_pageController.hasClients) {
      final targetPage = _getIndex(date);
      if ((_pageController.page?.round() ?? 0) != targetPage) {
        await _pageController.animateToPage(
          targetPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }

    // Scroll to top to expand header
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
    final selectedDate = ledgerState.selectedDate;
    // The month's figures are the provider's business, not the view model's:
    // both the month and the ledger's currency feed them, and only Riverpod
    // sees both. See [ledgerMonthlySummaryProvider].
    final summaryAsync = ref.watch(ledgerMonthlySummaryProvider(selectedDate));

    final l10n = AppLocalizations.of(context)!;

    // The ledger's own currency, the same one the header and the day totals
    // use — not the display preference, which the accounts may have outgrown.
    final currency = ref.watch(displayCurrencySymbolProvider);

    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverOverlapAbsorber(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              sliver: SliverAppBar(
                pinned: true,
                expandedHeight: _expandedHeight,
                forceElevated: innerBoxIsScrolled,
                // The FAB goes straight to the form, which carries all three
                // kinds — a transfer is one tap away on its type selector, so
                // it needs no separate entry point here.
                actions: [
                  AppIconButton(
                    icon: const Icon(LucideIcons.search),
                    tooltip: l10n.searchHint,
                    onPressed: () => context.push('/ledger/search'),
                  ),
                ],
                // The month sits here, in the toolbar, so it shares a centre
                // line with the search action; once collapsed the balance
                // joins it. See [LedgerAppBarTitle].
                title: LedgerAppBarTitle(
                  selectedDate: selectedDate,
                  summaryAsync: summaryAsync,
                  collapsed: _isCollapsed,
                  onMonthChanged: _goToMonth,
                  onMonthTap: () => _onMonthTap(selectedDate),
                ),
                // Expanded Content (FlexibleSpace)
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: LedgerHeader(summaryAsync: summaryAsync),
                  ),
                ),
              ),
            ),
          ];
        },
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            final date = _getDate(index);
            final current = ref.read(ledgerViewModelProvider).selectedDate;
            if (current.year != date.year || current.month != date.month) {
              ref.read(ledgerViewModelProvider.notifier).setMonth(date);
            }
          },
          itemBuilder: (context, index) {
            final month = _getDate(index);
            return LedgerTransactionList(
              key: ValueKey(month),
              month: month,
              currency: currency,
              l10n: l10n,
            );
          },
        ),
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
