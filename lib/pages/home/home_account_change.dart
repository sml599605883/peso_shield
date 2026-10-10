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
  Future<void> Function(BuildContext context, String target)? replaceTarget,
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

  Future<void> pushBindCard() async {
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
  }

  if (accounts.data.isEmpty) {
    await pushBindCard();
    return;
  }

  final result = await Navigator.of(context).push<AccountListResult>(
    MaterialPageRoute(
      builder: (_) => AccountListPage(
        groups: accounts.data.groups,
        onSubmit: (pageContext, bindId) async {
          final dismiss = ToastHelper.showLoading();
          try {
            final response = await repository.changeBindCard(
              orderNo: item.orderNo,
              bindId: bindId,
            );
            dismiss();
            if (!response.isSuccess || response.data.trim().isEmpty) {
              ToastHelper.showError(
                response.message.isNotEmpty
                    ? response.message
                    : 'Unable to change account, please try again',
              );
              return;
            }
            // 在账户列表页面直接替换跳转，避免先返回首页再跳转。
            if (pageContext.mounted) {
              await replaceTarget?.call(pageContext, response.data);
            }
          } catch (_) {
            dismiss();
            ToastHelper.showError('Unable to change account, please try again');
          }
        },
      ),
    ),
  );
  if (result is AccountListAddPaymentMethod) {
    await pushBindCard();
  }
}
