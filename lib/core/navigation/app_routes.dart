/// 应用路由常量定义
class AppRoutes {
  AppRoutes._();

  /// 根页面（Tab 导航）
  static const String root = '/';

  /// 首页
  static const String home = '/home';

  /// 登录页
  static const String login = '/login';

  /// 征信页
  static const String credit = '/credit';

  /// 我的页面
  static const String mine = '/mine';

  static const String settings = '/settings';
  static const String identityType = '/identity-type';
  static const String identityUpload = '/identity-upload';
  static const String identityConfirmation = '/identity-confirmation';
  static const String faceRecognition = '/face-recognition';
  static const String personalInformation = '/personal-information';
  static const String workInformation = '/work-information';

  /// 所有路由名称列表（用于调试和验证）
  static const List<String> all = [
    root,
    home,
    login,
    credit,
    mine,
    settings,
    identityType,
    identityUpload,
    identityConfirmation,
    faceRecognition,
    personalInformation,
    workInformation,
  ];

  /// 验证路由名称是否有效
  static bool isValid(String? route) {
    return route != null && all.contains(route);
  }
}
