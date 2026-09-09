import '../data/models/home_modules.dart';

class HomeOrderController {
  HomeOrderController({
    required this.navigate,
    required this.apply,
    required this.retry,
    required this.changeAccount,
    required this.showLoading,
    required this.showError,
  });
  final Future<void> Function(String, HomeOrderProgress) navigate;
  final Future<void> Function(String) apply;
  final Future<String> Function(String) retry;
  final Future<void> Function(HomeOrderProgress) changeAccount;
  final void Function() Function() showLoading;
  final void Function(String) showError;
  bool _busy = false;

  Future<void> open(HomeOrderProgress item, [HomeOrderAction? action]) async {
    if (_busy) return;
    final type = action?.type ?? 'detail';
    if (!const [
      'detail',
      'fallback',
      'repay',
      'retry',
      'change',
      'early_repay',
    ].contains(type)) {
      return;
    }
    _busy = true;
    void Function()? close;
    try {
      if (type == 'retry') {
        if (item.orderNo.isEmpty) throw StateError('Missing order number');
        close = showLoading();
        final target = (await retry(item.orderNo)).trim();
        if (target.isEmpty) throw StateError('Missing retry result');
        close();
        close = null;
        await navigate(target, item);
      } else if (type == 'change') {
        if (item.orderNo.isEmpty || item.productId.isEmpty) {
          throw StateError('Missing account information');
        }
        await changeAccount(item);
      } else if (type == 'early_repay') {
        final target = action!.url;
        final uri = Uri.tryParse(target);
        final base = Uri.tryParse(item.target);
        if (uri == null || target.isEmpty) {
          throw StateError('Missing repayment link');
        }
        final resolved = !uri.hasScheme && base != null && base.hasScheme
            ? base.resolveUri(uri).toString()
            : target;
        await navigate(resolved, item);
      } else if (item.target.isNotEmpty) {
        await navigate(item.target, item);
      } else if (item.productId.isNotEmpty) {
        await apply(item.productId);
      }
    } catch (_) {
      close?.call();
      close = null;
      showError('Unable to complete action, please try again');
    } finally {
      close?.call();
      _busy = false;
    }
  }
}
