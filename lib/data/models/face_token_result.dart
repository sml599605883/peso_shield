import '../../core/json/json.dart';

class FaceTokenResult {
  const FaceTokenResult({
    required this.resultCode,
    required this.token,
    required this.error,
  });

  factory FaceTokenResult.fromJson(Json json) => FaceTokenResult(
    resultCode: json['cullay'].intValue,
    token: json['legerity'].stringValue,
    error: json['trackable'].stringValue,
  );

  final int resultCode;
  final String token;
  final String error;
}
