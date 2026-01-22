import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/features/ledger/domain/entities/ledger_entities.dart';
import 'package:feather_ledger/features/ledger/domain/services/ledger_service.dart';
import 'package:feather_ledger/features/settings/presentation/providers/settings_providers.dart';

import '../providers/ledger_providers.dart';
import '../widgets/ledger_header.dart';
import '../widgets/ledger_timeline.dart'; // Will be implemented in Phase 4, using placeholder for now
import '../widgets/ledger_empty.dart'; // Phase 5
import '../widgets/ledger_skeleton.dart'; // Phase 5

import 'transaction_detail_sheet.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isNext = true;
  bool _isCollapsed = false;
  static const double _kExpandedHeight = 180.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Threshold: expanded height - toolbar height
    const threshold = _kExpandedHeight - kToolbarHeight;
    // With NestedScrollView, the outer controller monitors the header expansion.
    final isCollapsed =
        _scrollController.hasClients && _scrollController.offset > threshold;

    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  Future<void> _goToMonth(DateTime date) async {
    final current = ref.read(selectedDateProvider);
    if (current == date) return;

    // Determine direction
    _isNext = date.isAfter(current);
    
    // Update state
    ref.read(selectedDateProvider.notifier).setMonth(date);
    
    // Scroll to top to expand header
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onMonthTap(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Localizations.localeOf(context),
    );
    if (picked != null) {
      await _goToMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(ledgerSummaryProvider);
    final transactionsAsync = ref.watch(dailyTransactionsProvider);
    final currency = ref.watch(currencyControllerProvider).valueOrNull ?? '\$';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity == null) return;
          const sensitivity = 300.0;
          if (details.primaryVelocity! < -sensitivity) {
            // Swipe Left -> Next Month
            final current = ref.read(selectedDateProvider);
            final next = DateTime(current.year, current.month + 1);
            _goToMonth(next);
          } else if (details.primaryVelocity! > sensitivity) {
            // Swipe Right -> Previous Month
            final current = ref.read(selectedDateProvider);
            final prev = DateTime(current.year, current.month - 1);
            _goToMonth(prev);
          }
        },
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  pinned: true,
                  expandedHeight: _kExpandedHeight,
                  forceElevated: innerBoxIsScrolled,
                  // Collapsed Content (Title)
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isCollapsed ? 1.0 : 0.0,
                    child: summaryAsync.when(
                      data: (summary) => LedgerHeaderCompact(
                        selectedDate: selectedDate,
                        summary: summary,
                        currencySymbol: currency,
                      ),
                      loading: () => const SizedBox(),
                      error: (_, __) => const SizedBox(),
                    ),
                  ),
                  // Expanded Content (FlexibleSpace)
                  flexibleSpace: FlexibleSpaceBar(
                    background: SafeArea(
                      child: summaryAsync.when(
                        data: (summary) => LedgerHeader(
                          selectedDate: selectedDate,
                          summary: summary,
                          currencySymbol: currency,
                          onMonthChanged: _goToMonth,
                          onMonthTap: () => _onMonthTap(selectedDate),
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error: $e')),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final isCurrent = child.key == ValueKey(selectedDate);
              final offset = _isNext
                  ? (isCurrent ? const Offset(1, 0) : const Offset(-1, 0))
                  : (isCurrent ? const Offset(-1, 0) : const Offset(1, 0));
              
              return SlideTransition(
                position: Tween<Offset>(
                  begin: offset,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
            child: _LedgerTransactionList(
              key: ValueKey(selectedDate),
              transactionsAsync: transactionsAsync,
              currency: currency,
              l10n: l10n,
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/ledger/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LedgerTransactionList extends ConsumerWidget {
  final AsyncValue<Map<DateTime, List<TransactionEntity>>> transactionsAsync;
  final String currency;
  final AppLocalizations l10n;

  const _LedgerTransactionList({
    super.key,
    required this.transactionsAsync,
    required this.currency,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wrap in a container with background color to prevent transparency issues during slide
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        // NestedScrollView injects the PrimaryScrollController
        slivers: [
          SliverOverlapInjector(
             handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          transactionsAsync.when(
            data: (grouped) {
              if (grouped.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: LedgerEmpty(),
                );
              }
              return LedgerTimeline(
                groupedTransactions: grouped,
                currencySymbol: currency,
                onTransactionTap: (tx) {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    useSafeArea: true,
                    builder: (context) => TransactionDetailSheet(
                      transaction: tx,
                      currencySymbol: currency,
                      onEdit: () {
                        Navigator.of(context).pop();
                        context.push('/ledger/edit', extra: tx);
                      },
                      onDelete: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('${l10n.delete}?'),
                            content: Text(l10n.deleteTransactionConfirmation),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).colorScheme.error,
                                ),
                                child: Text(l10n.delete),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          Navigator.of(context).pop(); // Close sheet
                          try {
                            await ref
                                .read(ledgerServiceProvider)
                                .deleteTransaction(tx.id);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: LedgerSkeleton(),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
