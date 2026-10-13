import 'dart:async';

import '../client/client_bridge.dart';
import '../json/json.dart';

typedef PushRouteEvents = Stream<Json> Function();
typedef PushRouteOpener = Future<void> Function(String route);
typedef PushRouteDeferrer = void Function(void Function() callback);

/// 默认派发方式：微任务，不依赖新帧。
///
/// 不能用 addPostFrameCallback：它只登记回调、不请求新帧，App 空闲（无动画、
/// 无定时刷新）时不会有新帧，回调要等到用户操作等无关的帧才执行，表现就是
/// “收到推送没反应、点一下通知才跳”。原生事件在构建之外到达，微任务派发即可。
void dispatchPendingPushRoute(void Function() callback) {
  scheduleMicrotask(callback);
}

/// 消费 iOS 通知点击下发的 `push_route` 事件，按到达顺序交给导航层。
///
/// 冷启动点通知、或在启动页仍在探测网络时到达的通知，都会早于导航就绪，
/// 此时先把路由入队，等 [attach] 传入可用的导航入口后按到达顺序补发。
class PushRouteCoordinator {
  PushRouteCoordinator({PushRouteEvents? events, PushRouteDeferrer? defer})
    : _events = events ?? ClientBridge.shared.reportEvents,
      _defer = defer ?? dispatchPendingPushRoute;

  static const String eventType = 'push_route';
  static const String _routeKey = 'url';
  static const String _typeKey = 'type';

  final PushRouteEvents _events;
  final PushRouteDeferrer _defer;

  final List<String> _pending = <String>[];
  StreamSubscription<Json>? _subscription;
  PushRouteOpener? _opener;
  bool _closed = false;

  /// 开始监听原生事件；重复调用无副作用。
  void start() {
    if (_subscription != null || _closed) return;
    _subscription = _events().listen(_accept, onError: (_) {});
  }

  /// 导航层就绪（或销毁）时调用；传 null 表示暂时无法导航，路由继续排队。
  void attach(PushRouteOpener? opener) {
    _opener = opener;
    if (opener == null || _pending.isEmpty) return;
    _defer(_drain);
  }

  Future<void> stop() async {
    _closed = true;
    _opener = null;
    await _subscription?.cancel();
    _subscription = null;
    _pending.clear();
  }

  void _accept(Json event) {
    final payload = event.value;
    if (payload is! Map) return;
    if (payload[_typeKey]?.toString() != eventType) return;

    final route = payload[_routeKey]?.toString().trim() ?? '';
    if (route.isEmpty) return;

    _pending.add(route);
    if (_opener != null) _defer(_drain);
  }

  void _drain() {
    final opener = _opener;
    if (opener == null) return;
    while (_pending.isNotEmpty) {
      // 导航 Future 一般要等页面被 pop 才完成，这里只保证按到达顺序发起跳转，
      // 不等待页面生命周期结束，否则后续通知会被卡住。
      unawaited(_dispatch(opener, _pending.removeAt(0)));
    }
  }

  Future<void> _dispatch(PushRouteOpener opener, String route) async {
    try {
      await opener(route);
    } catch (_) {
      // 单条路由失败不能影响后续通知跳转。
    }
  }
}
