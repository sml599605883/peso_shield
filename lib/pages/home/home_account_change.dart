import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/toast_helper.dart';
import '../../data/models/home_modules.dart';
import '../../providers/repository_provider.dart';
import '../account_list_page.dart';
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
  AccountListResult? result;
  if (!accounts.data.isEmpty) {
    result = await Navigator.of(context).push<AccountListResult>(
      MaterialPageRoute(
        builder: (_) => AccountListPage(groups: accounts.data.groups),
      ),
    );
    if (result == null || !context.mounted) return;
  }
  if (accounts.data.isEmpty || result is AccountListAddPaymentMethod) {
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
  final selected = (result as AccountListSelection).bindId;
  final dismiss = ToastHelper.showLoading();
  final response = await repository
      .changeBindCard(orderNo: item.orderNo, bindId: selected)
      .whenComplete(dismiss);
  if (!response.isSuccess || response.data.trim().isEmpty) {
    throw StateError(response.message);
  }
  if (context.mounted) await navigate(response.data);
}
