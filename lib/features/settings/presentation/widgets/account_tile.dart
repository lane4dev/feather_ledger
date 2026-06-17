import 'package:flutter/material.dart';

import 'package:feather_ledger/core/domain/entities/account.dart';
import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/money_format.dart';

class AccountTile extends StatelessWidget {
  final AccountEntity account;
  final VoidCallback? onTap;
  final String currencySymbol;

  const AccountTile({
    super.key,
    required this.account,
    this.onTap,
    this.currencySymbol = '\$',
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: Icon(account.type.icon),
      ),
      title: Text(account.name),
      subtitle: Text(
        account.type.localizedLabel(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        '$currencySymbol${formatMinor(account.balanceMinor)}',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: onTap,
    );
  }
}
