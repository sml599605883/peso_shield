import 'dart:io' show Platform;

import 'package:flutter/services.dart';

class FaceLivenessResult {
  const FaceLivenessResult({
    required this.success,
    required this.code,
    required this.message,
    required this.image,
    required this.livenessId,
  });

  final bool success;
  final int code;
  final String message;
  final String image;
  final String livenessId;
}

class FaceLivenessBridge {
  FaceLivenessBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'peso_shield/client_bridge';
  static final instance = FaceLivenessBridge();

  final MethodChannel _channel;

  Future<FaceLivenessResult> start(String license) async {
    if (!Platform.isIOS) {
      return const FaceLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is only available on iOS.',
        image: '',
        livenessId: '',
      );
    }
    try {
      final result = await _channel.invokeMapMethod<Object?, Object?>(
        'showTrustDecisionLiveness',
        license,
      );
      if (result == null) {
        return const FaceLivenessResult(
          success: false,
          code: -1,
          message: 'Liveness returned no result.',
          image: '',
          livenessId: '',
        );
      }
      return FaceLivenessResult(
        success: _parseBool(result['success']),
        code: _parseInt(result['code']),
        message: _parseString(result['message']),
        image: _parseString(result['image']),
        livenessId: _parseString(result['liveness_id']),
      );
    } on PlatformException catch (error) {
      return FaceLivenessResult(
        success: false,
        code: -1,
        message: error.message ?? 'Unable to start liveness verification.',
        image: '',
        livenessId: '',
      );
    } on MissingPluginException {
      return const FaceLivenessResult(
        success: false,
        code: -1,
        message: 'Liveness verification is unavailable.',
        image: '',
        livenessId: '',
      );
    }
  }

  bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is String) return value.trim().toLowerCase() == 'true';
    return false;
  }

  int _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? -1;
    return -1;
  }

  String _parseString(Object? value) {
    if (value is String) return value.trim();
    return '';
  }
}
