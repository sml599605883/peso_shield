import 'dart:io' show Platform;

import 'package:flutter/services.dart';

import '../json/json.dart';
import '../report/peso_report_data.dart';

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
  ClientBridge({
    MethodChannel? channel,
    EventChannel? eventChannel,
  }) : _channel = channel ?? const MethodChannel('peso_shield/client_bridge'),
       _eventChannel =
           eventChannel ?? const EventChannel('peso_shield/client_events');

  static final ClientBridge shared = ClientBridge();

  final MethodChannel _channel;
  final EventChannel _eventChannel;
  Stream<Json>? _reportEventStream;

  bool get supportsNativeBridge => Platform.isIOS;

  Future<TrustDecisionLivenessResult> showTrustDecisionLiveness(
    String license,
  ) async {
    if (!supportsNativeBridge) {
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

  Future<PesoLocationSnapshot?> getReportLocation() async {
    final result = await _safeInvokeMap('getReportLocation');
    if (result == null) return null;
    final location = PesoLocationSnapshot.fromMap(result);
    return location.isValid ? location : null;
  }

  Future<String> requestLocationPermission() =>
      _safeInvokeString('requestLocationPermission');

  Future<PesoDeviceSnapshot> getReportDeviceSnapshot() async {
    final result = await _safeInvokeMap('getReportDeviceSnapshot');
    return PesoDeviceSnapshot.fromMap(result ?? const <Object?, Object?>{});
  }

  Future<String> getPushToken() => _safeInvokeString('getPushToken');

  Future<void> registerForRemoteNotifications() async {
    if (!supportsNativeBridge) return;
    try {
      await _channel.invokeMethod<void>('registerForRemoteNotifications');
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
  }

  Future<String> getTrackingStatus() => _safeInvokeString('getTrackingStatus');

  Stream<Json> reportEvents() {
    if (!supportsNativeBridge) return const Stream<Json>.empty();
    return _reportEventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map(Json.new)
        .handleError((_) {})
        .asBroadcastStream();
  }

  Future<Map<Object?, Object?>?> _safeInvokeMap(String method) async {
    if (!supportsNativeBridge) return null;
    try {
      return await _channel.invokeMapMethod<Object?, Object?>(method);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  Future<String> _safeInvokeString(String method) async {
    if (!supportsNativeBridge) return '';
    try {
      final value = await _channel.invokeMethod<Object?>(method);
      return value?.toString().trim() ?? '';
    } on PlatformException {
      return '';
    } on MissingPluginException {
      return '';
    }
  }
}
