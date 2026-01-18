import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              context.go('/more/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('Accounts'),
            onTap: () {
              // TODO: Accounts screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.pie_chart),
            title: const Text('Budgets'),
            onTap: () {
              // TODO: Budgets screen
            },
          ),
        ],
      ),
    );
  }
}
