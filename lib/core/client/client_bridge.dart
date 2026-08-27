import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class TrustDecisionLivenessResult {
  const TrustDecisionLivenessResult({
    required this.success,
    required this.code,
    required this.message,
    required this.image,
    required this.sequenceId,
    required this.livenessId,
    required this.raw,
  });

  final bool success;
  final int code;
  final String message;
  final String image;
  final String sequenceId;
  final String livenessId;
  final Map<String, dynamic> raw;
}

class ClientBridge {
  ClientBridge({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('peso_shield/client_bridge');

  final MethodChannel _channel;

  Future<TrustDecisionLivenessResult> showTrustDecisionLiveness(
    String license,
  ) async {
    if (!Platform.isIOS) {
      return const TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is only available on iOS.',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{},
      );
    }
    try {
      final value = await _channel.invokeMethod<dynamic>(
        'showTrustDecisionLiveness',
        license,
      );
      final json = value is Map
          ? Map<String, dynamic>.from(value)
          : const <String, dynamic>{};
      return TrustDecisionLivenessResult(
        success: json['success'] == true,
        code: (json['code'] as num?)?.toInt() ?? -1,
        message: json['message']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        sequenceId: json['sequence_id']?.toString() ?? '',
        livenessId: json['liveness_id']?.toString() ?? '',
        raw: json,
      );
    } on PlatformException catch (error) {
      return TrustDecisionLivenessResult(
        success: false,
        code: -1,
        message: error.message ?? 'Failed to start liveness verification',
        image: '',
        sequenceId: '',
        livenessId: '',
        raw: <String, dynamic>{'code': error.code},
      );
    }
  }
}
