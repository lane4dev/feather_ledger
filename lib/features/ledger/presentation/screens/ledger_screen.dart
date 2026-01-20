import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    // Simple logic: if scrolled past a threshold, show title.
    // Threshold: expanded height - toolbar height
    const threshold = _kExpandedHeight - kToolbarHeight;
    final isCollapsed =
        _scrollController.hasClients && _scrollController.offset > threshold;

    if (isCollapsed != _isCollapsed) {
      setState(() {
        _isCollapsed = isCollapsed;
      });
    }
  }

  void _onMonthTap(DateTime current) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).setMonth(picked);
      // Reset scroll
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final summaryAsync = ref.watch(ledgerSummaryProvider);
    final transactionsAsync =
        ref.watch(dailyTransactionsProvider); // Phase 4 wiring
    final currency = ref.watch(currencyControllerProvider).valueOrNull ?? '\$';

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _kExpandedHeight,
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
                    onMonthChanged: (date) async {
                      ref.read(selectedDateProvider.notifier).setMonth(date);
                      await _scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    },
                    onMonthTap: () => _onMonthTap(selectedDate),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ),
          ),

          // Phase 4: LedgerTimeline
          transactionsAsync.when(
            data: (grouped) {
              if (grouped.isEmpty) {
                // Phase 5: Empty state
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
                    isScrollControlled: true, // Allow full height if needed
                    useSafeArea: true,
                    builder: (context) => TransactionDetailSheet(
                      transaction: tx,
                      currencySymbol: currency,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/ledger/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
