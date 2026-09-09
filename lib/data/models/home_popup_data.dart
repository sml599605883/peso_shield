enum HomePopupType {
  none,
  appUpgrade,
  membershipUpgrade,
  marketing,
  unsupported,
}

class HomePopupData {
  const HomePopupData({
    this.type = HomePopupType.none,
    this.version = '',
    this.message = '',
    this.imageUrl = '',
    this.targetUrl = '',
    this.previousLevel = '',
    this.currentLevel = '',
    this.levelImageUrl = '',
    this.benefits = const [],
  });

  factory HomePopupData.fromJson(Map<String, dynamic> json) {
    final content = _map(json['abysmal']);
    final previous = _map(content['atabal']);
    final current = _map(content['riprap']);
    final benefits = content['acequias'];
    return HomePopupData(
      type: switch (int.tryParse('${json['bellings']}')) {
        0 => HomePopupType.none,
        1 => HomePopupType.appUpgrade,
        2 => HomePopupType.membershipUpgrade,
        3 => HomePopupType.marketing,
        _ => HomePopupType.unsupported,
      },
      version: _text(content['woodhen']),
      message: _text(content['knucklers']),
      imageUrl: _text(content['rapaciousnesses']),
      targetUrl: _text(content['mycelia']),
      previousLevel: _text(previous['cymenes']),
      currentLevel: _text(current['cymenes']),
      levelImageUrl: _text(current['week']),
      benefits: benefits is List
          ? benefits
                .map((item) => _text(_map(item)['properdins']))
                .where((text) => text.isNotEmpty)
                .toList()
          : const [],
    );
  }

  final HomePopupType type;
  final String version;
  final String message;
  final String imageUrl;
  final String targetUrl;
  final String previousLevel;
  final String currentLevel;
  final String levelImageUrl;
  final List<String> benefits;

  bool get shouldShow => switch (type) {
    HomePopupType.appUpgrade => message.isNotEmpty || version.isNotEmpty,
    HomePopupType.membershipUpgrade => currentLevel.isNotEmpty,
    HomePopupType.marketing => imageUrl.isNotEmpty,
    _ => false,
  };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map<String, dynamic> ? value : const {};
  static String _text(Object? value) => value?.toString().trim() ?? '';
}
