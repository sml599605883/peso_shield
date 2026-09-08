import 'dart:async';
import 'dart:convert';

import 'package:adjust_sdk/adjust.dart';
import 'package:adjust_sdk/adjust_config.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/report_repository.dart';
import '../client/client_bridge.dart';
import '../device/device_metadata_store.dart';
import '../device/session_store.dart';
import '../face/face_liveness_bridge.dart';
import '../json/json.dart';
import 'peso_report_data.dart';
import 'peso_report_store.dart';

class PesoReportService {
  PesoReportService(
    this.repository, {
    required this.sessionStore,
    required this.deviceMetadataStore,
    required this.clientBridge,
    required this.encryptKey,
    required this.encryptIv,
    PesoReportStore? store,
    Stream<Json>? nativeEvents,
    int Function()? nowMillis,
    Future<void> Function(String)? initializeAdjust,
  }) : store = store ?? PesoReportStore(),
       _events = nativeEvents,
       _nowMillis = nowMillis ?? (() => DateTime.now().millisecondsSinceEpoch),
       _initializeAdjust = initializeAdjust ?? _startAdjust;

  static int nowSeconds() => DateTime.now().millisecondsSinceEpoch ~/ 1000;

  final ReportRepository repository;
  final SessionStore sessionStore;
  final DeviceMetadataStore deviceMetadataStore;
  final ClientBridge clientBridge;
  final String encryptKey;
  final String encryptIv;
  final PesoReportStore store;
  final Stream<Json>? _events;
  final int Function() _nowMillis;
  final Future<void> Function(String) _initializeAdjust;

  bool _started = false;
  bool _starting = false;
  bool _marketReporting = false;
  bool _waitingForTrackingDecision = false;
  bool _startupGoogleReportTriggered = false;
  bool _adjustInitialized = false;
  final Set<String> _reportingAppleTokens = <String>{};
  final Set<String> _reportedAppleTokens = <String>{};
  Future<PesoLocationSnapshot?>? _pendingLocation;
  StreamSubscription<Json>? _eventSubscription;

  Future<void> start() async {
    if (_started || _starting) return;
    _starting = true;
    try {
      await store.clearSessionReportState();
      final isFirstLaunch = await store.markAppOpened();
      _listenToNativeEvents();
      _waitingForTrackingDecision = isFirstLaunch;
      _started = true;
      if (!isFirstLaunch) unawaited(_reportStartupGoogleMarket());
      unawaited(reportLocationAndDevice());
    } catch (error) {
      _log(error);
    } finally {
      _starting = false;
    }
  }

  Future<void> resumed() async {}

  Future<void> startupPermissionsResolved() async {
    await _reportStartupGoogleMarket();
    await reportAppleToken();
  }

  Future<void> loginSucceeded() async {
    await store.saveLoginAt(_nowMillis());
    unawaited(reportGoogleMarket());
    unawaited(reportLocationAndDevice());
    unawaited(_reportAppleToken(force: true));
  }

  Future<PesoLocationSnapshot?> currentLocation() {
    final pending = _pendingLocation;
    if (pending != null) return pending;
    final request = _loadLocation();
    _pendingLocation = request;
    return request.whenComplete(() => _pendingLocation = null);
  }

  Future<PesoLocationSnapshot?> _loadLocation() async {
    try {
      final location = await clientBridge.getReportLocation();
      if (location == null || !location.isValid) return null;
      await store.saveLocation(location);
      return location;
    } catch (error) {
      _log(error);
      return null;
    }
  }

  Future<PesoLocationSnapshot?> _locationWithFallback() async {
    try {
      final location = await currentLocation().timeout(
        const Duration(seconds: 3),
      );
      if (location != null && location.isValid) return location;
    } catch (_) {}
    return store.cachedLocation();
  }

  Future<bool> _hasSession() async {
    final session = await sessionStore.restore();
    return session.isLoggedIn && (session.accessToken?.isNotEmpty ?? false);
  }

  Future<void> reportLocationAndDevice() async {
    try {
      if (!await _hasSession()) return;
      final location = await _locationWithFallback();
      if (location != null && location.isValid) {
        try {
          await repository.reportLocation(
            province: location.province,
            countryCode: location.countryCode,
            country: location.country,
            street: location.street,
            latitude: location.latitude,
            longitude: location.longitude,
            city: location.city,
          );
        } catch (error) {
          _log(error);
        }
      }
      await reportDevice();
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportGoogleMarket() async {
    final trackingStatus = await clientBridge.getTrackingStatus();
    if (!_isResolvedTrackingStatus(trackingStatus)) return;
    _waitingForTrackingDecision = false;
    await _reportResolvedGoogleMarket();
  }

  Future<void> _reportStartupGoogleMarket() async {
    if (_startupGoogleReportTriggered) return;
    final trackingStatus = await clientBridge.getTrackingStatus();
    if (!_isResolvedTrackingStatus(trackingStatus)) return;
    _startupGoogleReportTriggered = true;
    _waitingForTrackingDecision = false;
    await _reportResolvedGoogleMarket();
  }

  Future<void> _reportResolvedGoogleMarket() async {
    if (_marketReporting) return;
    _marketReporting = true;
    try {
      final snapshot = await clientBridge.getReportDeviceSnapshot();
      final idfv = await deviceMetadataStore.resolveStableDeviceId(
        snapshot.idfv,
      );
      if (idfv.isEmpty) return;
      final response = await repository.reportGoogleMarket(
        idfv: idfv,
        idfa: snapshot.idfa,
      );

      // SDK initialization belongs to each process, not a persisted install flag.
      if (!_adjustInitialized && response.data.isNotEmpty) {
        await _initializeAdjust(response.data);
        _adjustInitialized = true;
      }
    } catch (error) {
      _log(error);
    } finally {
      _marketReporting = false;
    }
  }

  Future<void> reportDevice() async {
    try {
      if (!await _hasSession()) return;
      final snapshot = await clientBridge.getReportDeviceSnapshot();

      final encrypted = encryptPesoDeviceReport(
        snapshot: snapshot,
        stableDeviceId: await deviceMetadataStore.resolveStableDeviceId(
          snapshot.idfv,
        ),
        deviceModel: await deviceMetadataStore.deviceName() ?? '',
        physicalSize: await deviceMetadataStore.physicalSize() ?? '',
        location: await _locationWithFallback(),
        lastLoginAtMillis: await store.loginAt(),
        nowMillis: _nowMillis(),
        key: encryptKey,
        iv: encryptIv,
      );
      await repository.reportDeviceInfo(encryptedData: encrypted);
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportAppleToken() async {
    await _reportAppleToken(force: false);
  }

  Future<void> _reportAppleToken({required bool force}) async {
    String? token;
    try {
      token = (await clientBridge.getPushToken()).trim();
      if ((!force && _reportedAppleTokens.contains(token)) ||
          !_reportingAppleTokens.add(token)) {
        return;
      }
      await repository.reportApplePushToken(token: token);
      _reportedAppleTokens.add(token);
    } catch (error) {
      _log(error);
    } finally {
      if (token != null) _reportingAppleTokens.remove(token);
    }
  }

  Future<void> reportRisk({
    required String productId,
    required String scene,
    String orderNo = '',
    required int startedAtSeconds,
  }) async {
    final endedAtSeconds = _nowMillis() ~/ 1000;
    try {
      final snapshot = await clientBridge.getReportDeviceSnapshot();
      final location = await _locationWithFallback();
      final resolvedOrderNo = orderNo.trim().isNotEmpty
          ? orderNo.trim()
          : sessionStore.productDetailOrderNo;
      await repository.reportRiskEvent(
        productId: productId.trim(),
        sceneType: scene.trim(),
        orderNo: resolvedOrderNo,
        newDeviceId: await deviceMetadataStore.resolveStableDeviceId(
          snapshot.idfv,
        ),
        advertisingId: pesoReportText(snapshot.idfa),
        longitude: double.tryParse(pesoReportText(location?.longitude)),
        latitude: double.tryParse(pesoReportText(location?.latitude)),
        startTime: '$startedAtSeconds',
        endTime: '$endedAtSeconds',
      );
    } catch (error) {
      _log(error);
    }
  }

  Future<void> reportTrustDecisionResult(FaceLivenessResult result) async {
    try {
      await repository.reportTrustDecisionResult(
        livenessId: result.livenessId,
        requestId: result.sequenceId,
        resultCode: '${result.code}',
        result: jsonEncode({
          'livenessId': result.livenessId,
          'requestId': result.sequenceId,
          'resultCode': '${result.code}',
          'resultMessage': result.message,
        }),
      );
    } catch (error) {
      _log(error);
    }
  }

  void _listenToNativeEvents() {
    final events = _events ?? clientBridge.reportEvents();
    _eventSubscription ??= events.listen((event) {
      final type = event['type'].stringValue;
      if (type == 'push_token') unawaited(reportAppleToken());
      if (type == 'tracking_status_changed' && _waitingForTrackingDecision) {
        final status = event['status'].stringValue;
        if (!_isResolvedTrackingStatus(status)) return;
        _waitingForTrackingDecision = false;
        if (_startupGoogleReportTriggered) return;
        _startupGoogleReportTriggered = true;
        unawaited(_reportResolvedGoogleMarket());
      }
    }, onError: _log);
  }

  bool _isResolvedTrackingStatus(String status) {
    final normalized = status.trim();
    return normalized.isNotEmpty && normalized != 'not_determined';
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  static void _log(Object error) {
    debugPrint('[PesoReport] ${error.runtimeType}');
  }

  static Future<void> _startAdjust(String token) async {
    Adjust.initSdk(AdjustConfig(token, AdjustEnvironment.production));
  }
}
