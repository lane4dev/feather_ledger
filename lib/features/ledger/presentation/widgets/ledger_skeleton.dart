import 'package:flutter/material.dart';

import 'package:feather_ledger/app/theme/app_theme.dart';

import '../theme/ledger_theme.dart';

class LedgerSkeleton extends StatefulWidget {
  const LedgerSkeleton({super.key});

  @override
  State<LedgerSkeleton> createState() => _LedgerSkeletonState();
}

class _LedgerSkeletonState extends State<LedgerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reduced item count to minimize initial layout cost
    return FadeTransition(
      opacity: _animation,
      child: Padding(
        padding: EdgeInsets.only(top: context.spacing.md),
        child: Column(
          children: List.generate(3, (index) => _buildSkeletonGroup(context)),
        ),
      ),
    );
  }

  Widget _buildSkeletonGroup(BuildContext context) {
    return Column(
      children: [
        // Group Header (simulating Anchor)
        Padding(
          padding: EdgeInsets.symmetric(vertical: context.spacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Anchor Column
              SizedBox(
                width: LedgerTheme.colAnchorWidth,
                child: Column(
                  children: [
                    _box(width: 24, height: 24), // Day
                    const SizedBox(height: 4),
                    _box(width: 32, height: 12), // Weekday
                  ],
                ),
              ),
              // List Items (Reduced to 2)
              Expanded(
                child: Column(
                  children:
                      List.generate(2, (i) => _buildSkeletonItem(context)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonItem(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.spacing.md,
        vertical: context.spacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _box(width: 120, height: 16), // Title
                const SizedBox(height: 6),
                _box(width: 80, height: 12), // Meta
              ],
            ),
          ),
          SizedBox(width: context.spacing.md),
          _box(width: 60, height: 16), // Amount
        ],
      ),
    );
  }

  Widget _box({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.2), // Light grey placeholder
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
