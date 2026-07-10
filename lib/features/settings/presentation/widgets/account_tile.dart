import 'package:flutter/material.dart';

import 'package:feather_ledger/shared/presentation/extensions/account_type_extension.dart';
import 'package:feather_ledger/shared/presentation/models/account_ui_model.dart';

class AccountTile extends StatelessWidget {
  final AccountUiModel account;
  final VoidCallback? onTap;

  const AccountTile({
    super.key,
    required this.account,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        child: Icon(account.account.type.icon),
      ),
      title: Text(account.account.name),
      subtitle: Text(
        account.account.type.localizedLabel(context),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Text(
        account.displayBalance,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      onTap: onTap,
    );
  }
}
