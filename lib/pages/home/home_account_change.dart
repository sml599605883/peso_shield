import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/toast_helper.dart';
import '../../data/models/home_modules.dart';
import '../../providers/repository_provider.dart';
import '../bind_card_page.dart';

Future<void> changeHomeOrderAccount({
  required BuildContext context,
  required WidgetRef ref,
  required HomeOrderProgress item,
  required Future<void> Function(String) navigate,
}) async {
  final close = ToastHelper.showLoading();
  final repository = await ref
      .read(certificationRepositoryProvider.future)
      .catchError((Object error) {
        close();
        throw error;
      });
  final accounts = await repository
      .getUserBankAccounts(productId: item.productId)
      .whenComplete(close);
  if (!accounts.isSuccess) throw StateError(accounts.message);
  if (!context.mounted) return;
  String? selected;
  if (accounts.data.isNotEmpty) {
    selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.65,
          child: StatefulBuilder(
            builder: (context, update) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Change Account'),
                ),
                Expanded(
                  child: RadioGroup<String>(
                    groupValue: selected,
                    onChanged: (value) => update(() => selected = value),
                    child: ListView(
                      children: [
                        for (final account in accounts.data)
                          RadioListTile<String>(
                            value: account.id,
                            title: Text(account.bankName),
                            subtitle: Text(
                              '${account.accountNumber}\n${account.accountName}',
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context, ''),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Payment Method'),
                ),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(context, selected),
                  child: const Text('Confirm'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
  }
  if (accounts.data.isEmpty || selected == '') {
    final target = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (pageContext) => BindCardPage(
          productId: item.productId,
          orderNo: item.orderNo,
          isAccountChange: true,
          changeAccount: (order, bindId) async {
            final response = await repository.changeBindCard(
              orderNo: order,
              bindId: bindId,
            );
            if (!response.isSuccess || response.data.trim().isEmpty) {
              throw StateError(response.message);
            }
            if (pageContext.mounted) Navigator.pop(pageContext, response.data);
            return response.data;
          },
        ),
      ),
    );
    if (context.mounted && target != null) await navigate(target);
    return;
  }
  final dismiss = ToastHelper.showLoading();
  final response = await repository
      .changeBindCard(orderNo: item.orderNo, bindId: selected!)
      .whenComplete(dismiss);
  if (!response.isSuccess || response.data.trim().isEmpty) {
    throw StateError(response.message);
  }
  if (context.mounted) await navigate(response.data);
}
