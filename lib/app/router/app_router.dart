import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../l10n/app_localizations.dart';
import '../../features/ledger/domain/entities/ledger_entities.dart';
import '../../features/ledger/presentation/screens/ledger_screen.dart';
import '../../features/ledger/presentation/screens/transaction_form_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/account_management_screen.dart';
import '../../features/settings/presentation/screens/category_management_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter goRouter(Ref ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/ledger',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ledger',
                builder: (context, state) => const LedgerScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey:
                        _rootNavigatorKey, // Open over the shell
                    builder: (context, state) => const TransactionFormScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final transaction = state.extra as TransactionEntity?;
                      return TransactionFormScreen(transaction: transaction);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reports',
                builder: (context, state) => const ReportsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/more',
                  builder: (context, state) => const MoreScreen(),
                  routes: [
                    GoRoute(
                      path: 'settings',
                      builder: (context, state) => const SettingsScreen(),
                    ),
                    GoRoute(
                      path: 'about',
                      builder: (context, state) => const AboutScreen(),
                    ),
                    GoRoute(
                      path: 'accounts',
                      builder: (context, state) =>
                          const AccountManagementScreen(),
                    ),
                    GoRoute(
                      path: 'categories',
                      builder: (context, state) =>
                          const CategoryManagementScreen(),
                    ),
                  ]),
            ],
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatefulWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  State<ScaffoldWithNavBar> createState() => _ScaffoldWithNavBarState();
}

class _ScaffoldWithNavBarState extends State<ScaffoldWithNavBar> {
  static const Duration _exitInterval = Duration(seconds: 2);
  DateTime? _lastBackPressedAt;

  void _handlePopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) {
      return;
    }

    final now = DateTime.now();
    final last = _lastBackPressedAt;
    final l10n = AppLocalizations.of(context)!;

    if (last == null || now.difference(last) > _exitInterval) {
      _lastBackPressedAt = now;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pressBackAgainToExit)),
      );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canPop = GoRouter.of(context).canPop();

    return PopScope(
      canPop: canPop,
      onPopInvokedWithResult: _handlePopInvokedWithResult,
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.book),
              label: l10n.ledgerTitle,
            ),
            NavigationDestination(
              icon: const Icon(Icons.pie_chart),
              label: l10n.reports,
            ),
            NavigationDestination(
              icon: const Icon(Icons.more_horiz),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );
  }
}
