import '../../core/network/api_response.dart';
import '../../data/repositories/auth_repository.dart';

enum AccountAction { logout, deleteAccount }

/// 账户操作协调器
///
/// 只负责调用对应的服务端接口并原样返回结果，业务失败由调用方提示。
/// 本地会话由调用方通过 UserSessionNotifier.clearSession() 清除，
/// 避免两处重复写存储。
class AccountActionCoordinator {
  const AccountActionCoordinator({required this.authRepository});

  final AuthRepository authRepository;

  Future<ApiResponse<void>> execute(AccountAction action) {
    if (action == AccountAction.logout) {
      return authRepository.logout();
    }
    return authRepository.deleteAccount();
  }
}
