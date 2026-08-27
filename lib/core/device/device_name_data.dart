class DeviceNameData {
  const DeviceNameData({required this.deviceName, required this.screenSize});

  factory DeviceNameData.fromJson(Map<String, dynamic> json) {
    // HttpClient passes the unwrapped response payload. Keep accepting a
    // complete response for callers/tests that invoke this model directly.
    final nested = json['mugg'];
    final data = nested is Map ? Map<String, dynamic>.from(nested) : json;
    final rawSize = data['niobic'];
    final screenSize = rawSize is num
        ? rawSize
        : num.tryParse(rawSize?.toString().trim() ?? '');

    return DeviceNameData(
      deviceName: (data['externalizes'] as String? ?? '').trim(),
      screenSize: screenSize,
    );
  }

  final String deviceName;
  final num? screenSize;
}
