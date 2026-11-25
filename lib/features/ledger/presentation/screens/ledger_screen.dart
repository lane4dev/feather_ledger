import 'package:feather_ledger/app/design_system/app_icon_button.dart';
import 'package:feather_ledger/app/design_system/app_floating_action_button_location.dart';
import 'package:feather_ledger/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';

import 'package:feather_ledger/shared/presentation/widgets/feather_month_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../view_model/ledger_view_model.dart';
import '../widgets/ledger_header.dart';
import '../widgets/ledger_transaction_list.dart';
import '../widgets/overdue_materialization_banner.dart';

/// Asks the app shell to reveal its navigation bar.
class LedgerShowNavigationNotification extends Notification {
  const LedgerShowNavigationNotification();
}

/// Notifies the app shell when the ledger moves to another month.
class LedgerMonthChangedNotification extends LedgerShowNavigationNotification {
  const LedgerMonthChangedNotification();
}

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
  final _monthControllers = <DateTime, ScrollController>{};
  bool _collapsed = false;
  bool _scrolled = false;

  void _resetEmptyMonth(DateTime month) {
    if (!mounted) return;
    final selected = ref.read(ledgerViewModelProvider).selectedDate;
    if (selected.year != month.year ||
        selected.month != month.month ||
        ref
                .read(ledgerMonthlyTransactionsProvider(month))
                .asData
                ?.value
                .isEmpty !=
            true) return;
    final controller = _monthControllers[month];
    if (controller != null && controller.hasClients && controller.offset != 0) {
      controller.jumpTo(0);
    }
    const LedgerShowNavigationNotification().dispatch(context);
  }

  void _syncHeader(DateTime month, double headerHeight) {
    if (!mounted) return;
    final selected = ref.read(ledgerViewModelProvider).selectedDate;
    if (selected.year != month.year || selected.month != month.month) return;
    final controller = _monthControllers[month];
    final hasOffset = controller != null && controller.hasClients;
    final collapsed = hasOffset && controller.offset >= headerHeight - 0.5;
    final scrolled = hasOffset && controller.offset > 0.5;
    if (_collapsed != collapsed || _scrolled != scrolled) {
      setState(() {
        _collapsed = collapsed;
        _scrolled = scrolled;
      });
    }
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

    const LedgerMonthChangedNotification().dispatch(context);
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
    // The picker marks months that still owe a bill (spec 006, US33). Watched
    // in build so the stream has emitted before the picker opens.
    final markedMonths =
        ref.read(pendingBillMonthsProvider).value ?? const <DateTime>{};
    FeatherMonthPicker.show(
      context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      markedMonths: markedMonths,
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
    // Keep the pending-months stream alive while the screen is open so the
    // month picker can read it synchronously in [_onMonthTap].
    ref.watch(pendingBillMonthsProvider);
    ref.listen(ledgerMonthlyTransactionsProvider(selectedDate),
        (previous, next) {
      if (next.asData?.value.isEmpty != true ||
          previous?.asData?.value.isEmpty == true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetEmptyMonth(selectedDate);
      });
    });
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
    final scheme = Theme.of(context).colorScheme;

    // The ledger's own currency, the same one the header and the day totals
    // use — not the display preference, which the accounts may have outgrown.
    final currency = ref.watch(displayCurrencySymbolProvider);
    final summary = ref.watch(ledgerMonthlySummaryProvider(selectedDate));
    final scaled = MediaQuery.textScalerOf(context).scale(120);
    // The header slot only has to be as tall as the card plus its insets
    // (roughly 185dp at the default text size); it used to be 220 because the
    // card was bottom-aligned and the extra 35dp sat above it as dead space.
    // Kept slightly generous so a wrapped footer label at 360dp width does not
    // overflow, and the text-scale term covers everything larger.
    final headerHeight = 200.0 + (scaled > 120 ? (scaled - 120) * 1.3 : 0);

    return Scaffold(
      body: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            centerTitle: !_collapsed,
            titleSpacing: _collapsed ? null : 8,
            elevation: _scrolled ? 2.0 : 0.0,
            scrolledUnderElevation: _scrolled ? 2.0 : 0.0,
            backgroundColor:
                _scrolled ? scheme.surfaceContainer : scheme.surface,
            surfaceTintColor: scheme.surfaceContainer,
            shadowColor: scheme.shadow.withValues(alpha: 0.12),
            title: _collapsed
                ? InkWell(
                    borderRadius: context.metrics.chipBorderRadius,
                    onTap: () {
                      final controller = _monthControllers[selectedDate];
                      if (controller != null && controller.hasClients) {
                        controller.animateTo(0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut);
                      }
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: kMinInteractiveDimension,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: 1.0,
                        child: LedgerAppBarTitle(
                          selectedDate: selectedDate,
                          summaryAsync: summary,
                          collapsed: true,
                          onMonthChanged: _goToMonth,
                          onMonthTap: () => _onMonthTap(selectedDate),
                        ),
                      ),
                    ),
                  )
                : LedgerAppBarTitle(
                    selectedDate: selectedDate,
                    summaryAsync: summary,
                    collapsed: false,
                    onMonthChanged: _goToMonth,
                    onMonthTap: () => _onMonthTap(selectedDate),
                  ),
            actions: [
              AppIconButton(
                icon: const Icon(LucideIcons.search),
                tooltip: l10n.searchHint,
                onPressed: () => context.push('/ledger/search'),
              )
            ],
          ),
          const SliverToBoxAdapter(
            child: OverdueMaterializationBanner(),
          ),
          SliverFillRemaining(
              child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (_programmaticMonthChange) {
                final target = ref.read(ledgerViewModelProvider).selectedDate;
                if (_getIndex(target) == index) {
                  _syncHeader(_getDate(index), headerHeight);
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _resetEmptyMonth(_getDate(index)));
                }
                return;
              }
              final date = _getDate(index);
              final current = ref.read(ledgerViewModelProvider).selectedDate;
              if (current.year != date.year || current.month != date.month) {
                ref.read(ledgerViewModelProvider.notifier).setMonth(date);
                const LedgerMonthChangedNotification().dispatch(context);
              }
              _syncHeader(date, headerHeight);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _resetEmptyMonth(date);
                  _syncHeader(date, headerHeight);
                }
              });
            },
            itemBuilder: (context, index) {
              final month = _getDate(index);
              return _LedgerMonthPage(
                key: ValueKey(month),
                month: month,
                currency: currency,
                l10n: l10n,
                headerHeight: headerHeight,
                onController: (controller) {
                  if (controller == null) {
                    _monthControllers.remove(month);
                  } else {
                    _monthControllers[month] = controller;
                  }
                },
                onScroll: () => _syncHeader(month, headerHeight),
              );
            },
          )),
        ],
      ),
      floatingActionButtonLocation: AppFloatingActionButtonLocation(context),
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
      required this.headerHeight,
      required this.onController,
      required this.onScroll});

  final DateTime month;
  final String currency;
  final AppLocalizations l10n;
  final double headerHeight;
  final ValueChanged<ScrollController?> onController;
  final VoidCallback onScroll;

  @override
  ConsumerState<_LedgerMonthPage> createState() => _LedgerMonthPageState();
}

class _LedgerMonthPageState extends ConsumerState<_LedgerMonthPage>
    with AutomaticKeepAliveClientMixin {
  final _summaryCardKey = GlobalKey();
  @override
  bool get wantKeepAlive => _keepAlive;
  bool _keepAlive = false;
  final _controller = ScrollController();

  void _onScroll() {
    final keepAlive = _controller.hasClients && _controller.offset > 0;
    if (_keepAlive != keepAlive) {
      _keepAlive = keepAlive;
      updateKeepAlive();
    }
    widget.onScroll();
  }

  @override
  void initState() {
    super.initState();
    widget.onController(_controller);
    _controller.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onScroll();
    });
  }

  @override
  void dispose() {
    widget.onController(null);
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LedgerTransactionList(
      month: widget.month,
      currency: widget.currency,
      l10n: widget.l10n,
      controller: _controller,
      headerHeight: widget.headerHeight,
      summaryCardKey: _summaryCardKey,
    );
  }
}
