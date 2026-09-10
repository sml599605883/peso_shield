import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/app_navigator.dart';
import '../../theme/layout_adapter.dart';
import '../../theme/app_assets.dart';
import '../../theme/app_colors.dart';
import 'recredit_polling_coordinator.dart';

class RecreditPage extends ConsumerStatefulWidget {
  const RecreditPage({
    super.key,
    this.progressDelayGenerator,
    this.progressIncrementGenerator,
    this.onStartRecredit,
  });

  final Duration Function()? progressDelayGenerator;
  final int Function(int currentProgress)? progressIncrementGenerator;
  final void Function(String productId, WidgetRef ref)? onStartRecredit;

  @override
  ConsumerState<RecreditPage> createState() => _RecreditPageState();
}

class _RecreditPageState extends ConsumerState<RecreditPage> {
  static final Random _random = Random();

  Timer? _progressTimer;
  int _progress = 0;
  RecreditPollingCoordinator? _coordinator;
  bool _hasStartedRecredit = false;

  @override
  void initState() {
    super.initState();
    _scheduleProgressUpdate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStartedRecredit) {
      _hasStartedRecredit = true;
      _startRecreditIfPossible();
    }
  }

  void _startRecreditIfPossible() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final productId = _extractProductId(arguments);
    if (productId.isEmpty) {
      return;
    }
    final callback = widget.onStartRecredit;
    if (callback != null) {
      callback(productId, ref);
      return;
    }
    _coordinator = RecreditPollingCoordinator(ref: ref);
    _coordinator!.start(productId);
  }

  String _extractProductId(Object? arguments) {
    if (arguments is! Map) {
      return '';
    }
    final nested = arguments['payload'];
    final nestedMap = nested is Map ? nested : null;
    for (final key in const ['highlands', 'productId']) {
      for (final source in [arguments, nestedMap]) {
        final value = source?[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return '';
  }

  void _scheduleProgressUpdate() {
    if (_progress >= 99) {
      return;
    }
    final delay = widget.progressDelayGenerator?.call() ??
        Duration(seconds: _random.nextInt(3) + 1);
    _progressTimer = Timer(delay, _advanceProgress);
  }

  void _advanceProgress() {
    if (!mounted) {
      return;
    }
    final increment = widget.progressIncrementGenerator?.call(_progress) ??
        _random.nextInt(11) + 5;
    setState(() {
      _progress = (_progress + increment).clamp(0, 99);
    });
    _scheduleProgressUpdate();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _coordinator?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => AppNavigator.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(top: layout.px(200)),
        children: [
          Column(
            children: [
              Image.asset(
                AppAssets.recreditIllustration,
                key: const Key('recredit-illustration'),
                width: layout.px(120),
                height: layout.px(102),
                fit: BoxFit.contain,
              ),
              SizedBox(height: layout.px(18)),
              _RecreditMessage(layout: layout),
              SizedBox(height: layout.px(11)),
              _RecreditProgress(progress: _progress, layout: layout),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecreditMessage extends StatelessWidget {
  const _RecreditMessage({required this.layout});

  final AppLayout layout;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: AppColors.recreditText,
      fontFamily: 'Helvetica',
      fontSize: layout.px(14),
      fontWeight: FontWeight.w400,
      height: 18 / 14,
      letterSpacing: 0,
    );
    return SizedBox(
      width: layout.px(279),
      height: layout.px(36),
      child: Column(
        children: [
          RichText(
            maxLines: 1,
            textAlign: TextAlign.center,
            text: TextSpan(
              style: style,
              children: [
                const TextSpan(text: 'Calculating your credit limit, just '),
                TextSpan(
                  text: '30 seconds',
                  style: style.copyWith(color: AppColors.coral),
                ),
              ],
            ),
          ),
          Text('Please wait patiently', maxLines: 1, style: style),
        ],
      ),
    );
  }
}

class _RecreditProgress extends StatelessWidget {
  const _RecreditProgress({
    required this.progress,
    required this.layout,
  });

  final int progress;
  final AppLayout layout;

  @override
  Widget build(BuildContext context) {
    final width = layout.px(287);
    return SizedBox(
      key: const Key('recredit-progress-section'),
      width: width,
      height: layout.px(42),
      child: Column(
        children: [
          SizedBox(
            key: const Key('recredit-progress-bar'),
            width: width,
            height: layout.px(12),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    AppAssets.recreditProgressTrack,
                    fit: BoxFit.fill,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.px(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(layout.px(4)),
                    child: SizedBox(
                      width: max(
                        0,
                        (width - layout.px(4)) * progress / 100,
                      ),
                      height: layout.px(8),
                      child: const ColoredBox(color: AppColors.coral),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: layout.px(10)),
          Text(
            '$progress%',
            key: const Key('recredit-progress-label'),
            style: TextStyle(
              color: AppColors.coral,
              fontSize: layout.px(14),
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
