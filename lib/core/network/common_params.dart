import 'dart:math';

class CommonParams {
  static Map<String, Object?> create({
    required String deviceId,
    required String market,
    required String appVersion,
    required String deviceName,
    required String osVersion,
    required String gpsAdId,
    String? token,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return {
      'longicorn': appVersion,
      'externalizes': deviceName,
      'dissuaders': deviceId,
      'cognizable': osVersion,
      'wazoos': market,
      'pachysandra': token ?? '',
      'sorboses': gpsAdId,
      'suasion': '$timestamp',
    };
  }

  static String randomDigits(int length) {
    final random = Random.secure();
    return List.generate(length, (_) => random.nextInt(10)).join();
  }
}
