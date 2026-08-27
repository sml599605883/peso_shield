class LoginResponse {
  const LoginResponse({
    required this.userId,
    required this.hasBasicInfo,
    required this.phone,
    required this.phonePrefix,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      userId: json['rackworks'] as int? ?? 0,
      hasBasicInfo: json['bale'] as int? ?? 0,
      phone: json['lobstering'] as String? ?? '',
      phonePrefix: json['slouchinesses'] as String? ?? '',
      token: json['pachysandra'] as String? ?? '',
    );
  }

  final int userId;
  final int hasBasicInfo;
  final String phone;
  final String phonePrefix;
  final String token;
}
