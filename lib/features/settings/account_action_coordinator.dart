import '../../data/repositories/auth_repository.dart';

enum AccountAction { logout, deleteAccount }

/// 账户操作协调器
///
/// 只负责调用对应的服务端接口。本地会话由调用方通过
/// UserSessionNotifier.clearSession() 清除，避免两处重复写存储。
class AccountActionCoordinator {
  const AccountActionCoordinator({required this.authRepository});

  final AuthRepository authRepository;

  Future<void> execute(AccountAction action) async {
    if (action == AccountAction.logout) {
      await authRepository.logout();
    } else {
      await authRepository.deleteAccount();
    }
  }
}
