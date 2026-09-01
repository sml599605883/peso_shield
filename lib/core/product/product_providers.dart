import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peso_shield/core/device/user_session.dart';
import 'package:peso_shield/core/product/product_application_flow.dart';
import 'package:peso_shield/providers/repository_provider.dart';

/// ProductApplicationFlow provider
final productApplicationFlowProvider =
    FutureProvider<ProductApplicationFlow>((ref) async {
  final repository = await ref.watch(productRepositoryProvider.future);
  final userSession = ref.watch(userSessionProvider);
  
  return ProductApplicationFlow(
    repository: repository,
    userSession: userSession,
  );
});
