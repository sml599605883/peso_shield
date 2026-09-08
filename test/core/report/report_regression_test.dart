import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peso_shield/core/client/client_bridge.dart';
import 'package:peso_shield/core/device/device_metadata_store.dart';
import 'package:peso_shield/core/device/session_store.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/face/face_liveness_bridge.dart';
import 'package:peso_shield/core/network/api_response.dart';
import 'package:peso_shield/core/network/data_encryptor.dart';
import 'package:peso_shield/core/network/http_client.dart';
import 'package:peso_shield/core/network/http_exception.dart';
import 'package:peso_shield/core/permissions/permission_lifecycle_observer.dart';
import 'package:peso_shield/core/report/peso_report_data.dart';
import 'package:peso_shield/core/report/peso_report_service.dart';
import 'package:peso_shield/core/report/peso_report_store.dart';
import 'package:peso_shield/data/repositories/report_repository.dart';
import 'package:peso_shield/data/repositories/certification_repository.dart';
import 'package:peso_shield/pages/identity_confirmation_page.dart';
import 'package:peso_shield/providers/report_provider.dart';
import 'package:peso_shield/providers/repository_provider.dart';
import 'package:peso_shield/core/product/product_providers.dart';

import '../../support/fake_session_persistence.dart';

class _Client implements HttpClient {
  int code = 0;
  Object? data = <String, Object?>{'fogeyish': 'test-adjust-token'};
  final requests = <({String path, Map<String, Object?> params})>[];

  @override
  Future<ApiResponse<T>> post<T>(
    String path, {
    required Map<String, Object?> params,
    required T Function(Object?) parse,
  }) async {
    requests.add((path: path, params: params));
    return ApiResponse(code: code, message: 'test response', data: parse(data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Metadata implements DeviceMetadataPersistence {
  String? id;
  @override
  Future<String?> readDeviceId() async => id;
  @override
  Future<void> writeDeviceId(String value) async {
    id = value;
  }

  @override
  Future<String?> readDeviceName() async => 'iPhone';
  @override
  Future<String?> readPhysicalSize() async => '6.1';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bridge extends ClientBridge {
  @override
  Future<String> getTrackingStatus() async => 'denied';
  @override
  Future<String> getPushToken() async => 'push-token';
  @override
  Future<PesoDeviceSnapshot> getReportDeviceSnapshot() async =>
      const PesoDeviceSnapshot(idfv: 'native-id', isUsingProxy: 1);
  @override
  Future<PesoLocationSnapshot?> getReportLocation() async => null;
}

class _Certification implements CertificationRepository {
  final response = Completer<ApiResponse<void>>();
  @override
  Future<ApiResponse<void>> saveIdentityInfo({
    required String birthDate,
    required String idNumber,
    required String fullName,
    required String type,
    required String cardType,
  }) => response.future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const key = '0123456789abcdef';
  const iv = 'abcdef0123456789';
  late _Client client;
  late ReportRepository repository;
  late PesoReportService service;
  late List<String> initialized;

  setUp(() {
    client = _Client();
    repository = ReportRepository(client);
    initialized = [];
    service = PesoReportService(
      repository,
      sessionStore: SessionStore(FakeSessionPersistence()),
      deviceMetadataStore: DeviceMetadataStore(_Metadata()..id = 'stored-id'),
      clientBridge: _Bridge(),
      encryptKey: key,
      encryptIv: iv,
      store: PesoReportStore.memory(),
      nativeEvents: const Stream.empty(),
      nowMillis: () => 200000,
      initializeAdjust: (token) async {
        initialized.add(token);
      },
    );
  });
  tearDown(() => service.dispose());

  for (final success in [true, false]) {
    testWidgets('scene 3 waits for identity save, success=$success', (
      tester,
    ) async {
      final certification = _Certification();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            certificationRepositoryProvider.overrideWith(
              (ref) async => certification,
            ),
            sessionStoreProvider.overrideWithValue(
              SessionStore(FakeSessionPersistence()),
            ),
            reportServiceProvider.overrideWithValue(service),
            productApplicationFlowProvider.overrideWith(
              (ref) async => throw StateError('end of test flow'),
            ),
          ],
          child: const MaterialApp(
            home: IdentityConfirmationPage(
              productId: 'p1',
              cardType: 'PRC',
              startedAtSeconds: 100,
              recognizedInfo: {
                'cymenes': 'Test User',
                'neighborhood': 'test-id',
                'sudaries': '1997/07/15',
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('identity-confirmation-submit')));
      await tester.pump();
      expect(client.requests, isEmpty);
      certification.response.complete(
        ApiResponse<void>(
          code: success ? 0 : 400,
          message: 'test response',
          data: null,
        ),
      );
      await tester.pumpAndSettle();
      expect(client.requests.length, success ? 1 : 0);
      if (success) {
        expect(client.requests.single.params['furioso'], '3');
        expect(client.requests.single.params['hypersecretions'], '100');
      }
    });
  }

  test('device payload encrypts Peso fields and uses shared stable ID', () {
    final encrypted = encryptPesoDeviceReport(
      snapshot: const PesoDeviceSnapshot(idfv: 'native-id', isUsingProxy: 1),
      stableDeviceId: 'stored-id',
      deviceModel: 'iPhone',
      physicalSize: '6.1',
      location: null,
      lastLoginAtMillis: 100,
      nowMillis: 200,
      key: key,
      iv: iv,
    );
    final payload = jsonDecode(
      DataEncryptor(key: key, iv: iv).decrypt(encrypted),
    );
    expect(
      payload.keys,
      unorderedEquals([
        'landaus',
        'tippytoe',
        'dullards',
        'peddlers',
        'widening',
        'mugwumps',
        'smothery',
        'ballpoint',
        'bargain',
      ]),
    );
    expect(payload['mugwumps']['trouncing'], 'stored-id');
    expect(payload['mugwumps']['epitomise'], 1);
    expect(payload['widening']['bedchairs'], '');
    expect(payload['smothery']['niobic'], '6.1');
  });

  test('business failure does not suppress a later push retry', () async {
    client.code = 400;
    await service.reportAppleToken();
    client.code = 0;
    await service.reportAppleToken();
    await service.reportAppleToken();
    expect(client.requests.length, 2);
  });

  test('repository rejects unsuccessful responses', () async {
    client.code = 400;
    await expectLater(
      repository.reportDeviceInfo(encryptedData: 'test'),
      throwsA(isA<HttpException>()),
    );
  });

  test('market reads Peso token and initializes once per service', () async {
    await service.store.markAdjustInitialized();
    await service.reportGoogleMarket();
    await service.reportGoogleMarket();
    expect(initialized, ['test-adjust-token']);
    expect(client.requests.length, 2);
    expect(client.requests.first.params['trouncing'], 'stored-id');
  });

  test(
    'missing location stays empty and end time excludes collection',
    () async {
      await service.reportRisk(
        productId: 'p1',
        scene: '3',
        startedAtSeconds: 100,
      );
      final params = client.requests.single.params;
      expect(params['sade'], '');
      expect(params['salivating'], '');
      expect(params['steamboats'], 'stored-id');
      expect(params['galoping'], '200');
    },
  );

  test('failed liveness still reports request ID without image data', () async {
    await service.reportTrustDecisionResult(
      const FaceLivenessResult(
        success: false,
        code: 42,
        message: 'cancelled',
        image: 'private-image',
        livenessId: 'l1',
        sequenceId: 'r1',
      ),
    );
    final request = client.requests.single;
    expect(request.path, '/outsmelled/contexts');
    expect(request.params['herrying'], 'r1');
    expect(request.params['cullay'], '42');
    expect(request.params['recklessly'], isNot(contains('private-image')));
  });

  test('startup completes after permissions and deduplicates calls', () async {
    final permission = Completer<void>();
    final completed = Completer<void>();
    final observer = PermissionLifecycleObserver(
      reportAppStarted: service.start,
      requestStartupPermissions: () => permission.future,
      requestResumeTrackingPermission: () async {},
      reportStartupPermissionsResolved: () async {
        await service.startupPermissionsResolved();
        completed.complete();
      },
    );
    addTearDown(observer.dispose);
    observer.start();
    observer.start();
    await Future<void>.delayed(Duration.zero);
    expect(client.requests, isEmpty);
    permission.complete();
    await completed.future;
    await service.startupPermissionsResolved();
    expect(client.requests.map((r) => r.path), [
      '/outsmelled/amoebaean',
      '/outsmelled/banisters',
    ]);
  });
}
