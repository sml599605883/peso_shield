import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/push/push_route_coordinator.dart';

final pushRouteCoordinatorProvider = Provider<PushRouteCoordinator>((ref) {
  final coordinator = PushRouteCoordinator();
  ref.onDispose(() => unawaited(coordinator.stop()));
  return coordinator;
});
