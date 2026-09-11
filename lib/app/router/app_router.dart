import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:feather_ledger/app/l10n/app_localizations.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/ledger_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/recurring_bill_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/search_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/screens/transaction_form_screen.dart';
import 'package:feather_ledger/features/ledger/presentation/models/transaction_tile_ui_model.dart';
import 'package:feather_ledger/features/reports/presentation/screens/reports_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/more_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/settings_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/about_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/account_management_screen.dart';
import 'package:feather_ledger/features/settings/presentation/screens/category_management_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                    path: 'search',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const SearchScreen(),
                  ),
                  // One "edit this thing" route: the form reads the extra's
                  // kind itself, so callers push '/ledger/edit' without
                  // knowing what they are editing.
                  GoRoute(
                    path: 'edit',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => TransactionFormScreen(
                      transaction: state.extra as TransactionTileUiModel?,
                    ),
                  ),
                  // A bill waiting to be recorded is edited on its own route,
                  // not through the transaction form: it has no event stream,
                  // and how far the edit reaches is asked when it is saved.
                  GoRoute(
                    path: 'edit-bill',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => RecurringBillFormScreen(
                      transaction: state.extra as TransactionTileUiModel,
                    ),
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
                    // Both leave the shell: a page opened from the more tab is
                    // a place of its own, not a fourth tab, and the bottom bar
                    // has nothing to say about it while it is open.
                    GoRoute(
                      path: 'settings',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const SettingsScreen(),
                    ),
                    GoRoute(
                      path: 'about',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const AboutScreen(),
                    ),
                    // Accounts and categories are not routed again here: the
                    // pickers already reach them at the top-level
                    // `/accounts_management` and `/categories_management`,
                    // which open over the shell for the same reason.
                  ]),
            ],
          ),
        ],
      ),
      // New top-level routes for opening management screens over the whole app
      GoRoute(
        path: '/accounts_management',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AccountManagementScreen(),
      ),
      GoRoute(
        path: '/categories_management',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoryManagementScreen(),
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
  bool _ledgerNavigationVisible = true;
  ScrollDirection _ledgerScrollDirection = ScrollDirection.idle;

  bool _onScroll(ScrollNotification notification) {
    if (widget.navigationShell.currentIndex != 0 ||
        notification.metrics.axis != Axis.vertical) return false;

    if (notification is UserScrollNotification) {
      _ledgerScrollDirection = notification.direction;
    }
    bool? visible;
    if (notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      visible = true;
    } else if (notification is UserScrollNotification ||
        notification is ScrollUpdateNotification &&
            notification.dragDetails != null) {
      if (_ledgerScrollDirection == ScrollDirection.reverse) visible = false;
      if (_ledgerScrollDirection == ScrollDirection.forward) visible = true;
    }
    if (visible != null && visible != _ledgerNavigationVisible) {
      setState(() => _ledgerNavigationVisible = visible!);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBody: widget.navigationShell.currentIndex == 0,
      body: NotificationListener<LedgerShowNavigationNotification>(
        onNotification: (_) {
          if (!_ledgerNavigationVisible) {
            setState(() => _ledgerNavigationVisible = true);
          }
          return false;
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.navigationShell.currentIndex == 0
              ? MediaQuery(
                  // The shell overlays its navigation bar. Descendant pages use
                  // the device inset, not the bar's changing animated height.
                  data: MediaQuery.of(context),
                  child: widget.navigationShell,
                )
              : widget.navigationShell,
        ),
      ),
      bottomNavigationBar: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          end: widget.navigationShell.currentIndex != 0 ||
                  _ledgerNavigationVisible
              ? 1
              : 0,
        ),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        builder: (context, value, child) => ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: value,
            child: Offstage(
              offstage: value == 0,
              child: IgnorePointer(
                ignoring: value < 1,
                child: ExcludeSemantics(
                  excluding: value < 1,
                  child: FractionalTranslation(
                    translation: Offset(0, 1 - value),
                    child: Opacity(opacity: value, child: child),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            if (!_ledgerNavigationVisible) {
              setState(() => _ledgerNavigationVisible = true);
            }
            widget.navigationShell.goBranch(
              index,
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(LucideIcons.book),
              label: l10n.ledgerTitle,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.pieChart),
              label: l10n.reports,
            ),
            NavigationDestination(
              icon: const Icon(LucideIcons.ellipsis),
              label: l10n.more,
            ),
          ],
        ),
      ),
    );
  }
}
