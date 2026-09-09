import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/home_provider.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/product/product_application_flow.dart';
import 'package:peso_shield/providers/repository_provider.dart';
import 'package:peso_shield/providers/report_provider.dart';

/// ProductApplicationFlow provider
final productApplicationFlowProvider = FutureProvider<ProductApplicationFlow>((
  ref,
) async {
  final repository = await ref.watch(productRepositoryProvider.future);
  final orderRepository = await ref.watch(orderRepositoryProvider.future);
  final userSession = ref.watch(userSessionProvider);
  final sessionStore = ref.watch(sessionStoreProvider);
  final reportService = ref.watch(reportServiceProvider);

  return ProductApplicationFlow(
    repository: repository,
    orderRepository: orderRepository,
    userSession: userSession,
    sessionStore: sessionStore,
    reportService: reportService,
    beginLocationPermissionRequest: () =>
        ref.read(homeDataProvider.notifier).beginLocationPermissionRequest(),
    endLocationPermissionRequest: () =>
        ref.read(homeDataProvider.notifier).endLocationPermissionRequest(),
  );
});
