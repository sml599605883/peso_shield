import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/client/client_bridge.dart';
import '../core/device/user_session.dart';
import '../core/report/peso_report_service.dart';
import '../core/report/peso_report_store.dart';
import '../core/permissions/permission_coordinator.dart';
import '../core/permissions/permission_lifecycle_observer.dart';
import 'network_provider.dart';
import 'repository_provider.dart';

final clientBridgeProvider = Provider<ClientBridge>((ref) {
  return ClientBridge.shared;
});

final reportStoreProvider = Provider<PesoReportStore>((ref) {
  return PesoReportStore();
});

final reportServiceProvider = Provider<PesoReportService>((ref) {
  final repository = ref.watch(reportRepositoryProvider);

  final networkConfig = ref.watch(networkConfigProvider);
  final sessionStore = ref.watch(sessionStoreProvider);
  final deviceMetadataStore = ref.watch(deviceMetadataStoreProvider);
  final clientBridge = ref.watch(clientBridgeProvider);
  final reportStore = ref.watch(reportStoreProvider);

  final service = PesoReportService(
    repository,
    sessionStore: sessionStore,
    deviceMetadataStore: deviceMetadataStore,
    clientBridge: clientBridge,
    encryptKey: networkConfig.aesKey,
    encryptIv: networkConfig.aesIv,
    store: reportStore,
  );
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final reportLifecycleProvider = Provider<PermissionLifecycleObserver>((ref) {
  final service = ref.watch(reportServiceProvider);
  final permissions = PermissionCoordinator.instance;
  final observer = PermissionLifecycleObserver(
    requestStartupPermissions: permissions.requestStartupPermissions,
    requestResumeTrackingPermission:
        permissions.requestResumeTrackingPermission,
    reportAppStarted: service.start,
    reportAppResumed: service.resumed,
    reportStartupPermissionsResolved: service.startupPermissionsResolved,
  );
  ref.onDispose(observer.dispose);
  return observer;
});
