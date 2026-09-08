import 'dart:convert';

import '../network/data_encryptor.dart';

class PesoLocationSnapshot {
  const PesoLocationSnapshot({
    this.province = '',
    this.locality = '',
    this.fullAddress = '',
    this.countryCode = '',
    this.country = '',
    this.street = '',
    this.latitude = '',
    this.longitude = '',
    this.city = '',
    this.permissionStatus = '',
  });

  static const empty = PesoLocationSnapshot();

  final String province;
  final String locality;
  final String fullAddress;
  final String countryCode;
  final String country;
  final String street;
  final String latitude;
  final String longitude;
  final String city;
  final String permissionStatus;

  bool get isValid =>
      latitude.isNotEmpty ||
      longitude.isNotEmpty ||
      fullAddress.isNotEmpty ||
      street.isNotEmpty ||
      city.isNotEmpty ||
      country.isNotEmpty;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'province': province,
    'locality': locality,
    'fullAddress': fullAddress,
    'countryCode': countryCode,
    'country': country,
    'street': street,
    'latitude': latitude,
    'longitude': longitude,
    'city': city,
    'permissionStatus': permissionStatus,
  };

  factory PesoLocationSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return PesoLocationSnapshot(
      province: pesoReportText(map['province']),
      locality: pesoReportText(map['locality'] ?? map['subAdminArea']),
      fullAddress: pesoReportText(map['fullAddress']),
      countryCode: pesoReportText(map['countryCode']),
      country: pesoReportText(map['country']),
      street: pesoReportText(map['street']),
      latitude: pesoReportText(map['latitude']),
      longitude: pesoReportText(map['longitude']),
      city: pesoReportText(map['city']),
      permissionStatus: pesoReportText(map['permissionStatus']),
    );
  }
}

class PesoDeviceSnapshot {
  const PesoDeviceSnapshot({
    this.idfv = '',
    this.idfa = '',
    this.deviceId = '',
    this.riskDeviceId = '',
    this.batteryLevel = 0,
    this.isCharging = 0,
    this.elapsedMillis = 0,
    this.uptimeMillis = '0',
    this.isUsingProxy = 0,
    this.isUsingVpn = 0,
    this.isJailbroken = 0,
    this.isEmulator = 0,
    this.language = '',
    this.carrier = '',
    this.networkType = '',
    this.timeZoneName = '',
    this.cpuCoreCount = 0,
    this.brand = '',
    this.deviceName = '',
    this.model = '',
    this.modelName = '',
    this.systemVersion = '',
    this.packageName = '',
    this.screenHeight = 0,
    this.screenWidth = 0,
    this.screenSize = '',
    this.innerIp = '',
    this.currentWifiName = '',
    this.currentWifiBssid = '',
    this.wifiCount = 0,
    this.availableStorage = '0',
    this.totalStorage = '0',
    this.totalMemory = '0',
    this.availableMemory = '0',
    this.pushToken = '',
  });

  final String idfv;
  final String idfa;
  final String deviceId;
  final String riskDeviceId;
  final int batteryLevel;
  final int isCharging;
  final int elapsedMillis;
  final String uptimeMillis;
  final int isUsingProxy;
  final int isUsingVpn;
  final int isJailbroken;
  final int isEmulator;
  final String language;
  final String carrier;
  final String networkType;
  final String timeZoneName;
  final int cpuCoreCount;
  final String brand;
  final String deviceName;
  final String model;
  final String modelName;
  final String systemVersion;
  final String packageName;
  final int screenHeight;
  final int screenWidth;
  final String screenSize;
  final String innerIp;
  final String currentWifiName;
  final String currentWifiBssid;
  final int wifiCount;
  final String availableStorage;
  final String totalStorage;
  final String totalMemory;
  final String availableMemory;
  final String pushToken;

  factory PesoDeviceSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return PesoDeviceSnapshot(
      idfv: pesoReportText(map['idfv']),
      idfa: pesoReportText(map['idfa']),
      deviceId: pesoReportText(map['deviceId']),
      riskDeviceId: pesoReportText(map['riskDeviceId']),
      batteryLevel: _integer(map['batteryLevel']),
      isCharging: _integer(map['isCharging']),
      elapsedMillis: _integer(map['elapsedMillis']),
      uptimeMillis: pesoReportText(map['uptimeMillis'], fallback: '0'),
      isUsingProxy: _integer(map['isUsingProxy']),
      isUsingVpn: _integer(map['isUsingVpn']),
      isJailbroken: _integer(map['isJailbroken']),
      isEmulator: _integer(map['isEmulator']),
      language: pesoReportText(map['language']),
      carrier: pesoReportText(map['carrier']),
      networkType: pesoReportText(map['networkType']),
      timeZoneName: pesoReportText(map['timeZoneName']),
      cpuCoreCount: _integer(map['cpuCoreCount']),
      brand: pesoReportText(map['brand']),
      deviceName: pesoReportText(map['deviceName']),
      model: pesoReportText(map['model']),
      modelName: pesoReportText(map['modelName']),
      systemVersion: pesoReportText(map['systemVersion']),
      packageName: pesoReportText(map['packageName']),
      screenHeight: _integer(map['screenHeight']),
      screenWidth: _integer(map['screenWidth']),
      screenSize: pesoReportText(map['screenSize']),
      innerIp: pesoReportText(map['innerIp']),
      currentWifiName: pesoReportText(map['currentWifiName']),
      currentWifiBssid: pesoReportText(map['currentWifiBssid']),
      wifiCount: _integer(map['wifiCount']),
      availableStorage: pesoReportText(map['availableStorage'], fallback: '0'),
      totalStorage: pesoReportText(map['totalStorage'], fallback: '0'),
      totalMemory: pesoReportText(map['totalMemory'], fallback: '0'),
      availableMemory: pesoReportText(map['availableMemory'], fallback: '0'),
      pushToken: pesoReportText(map['pushToken']),
    );
  }
}

String encryptPesoDeviceReport({
  required PesoDeviceSnapshot snapshot,
  required String stableDeviceId,
  required String deviceModel,
  required String physicalSize,
  required PesoLocationSnapshot? location,
  required int lastLoginAtMillis,
  required int nowMillis,
  required String key,
  required String iv,
}) {
  final wifi = <String, dynamic>{
    'cymenes': pesoReportText(snapshot.currentWifiName),
    'advancing': pesoReportText(snapshot.currentWifiBssid),
    'ribbiest': pesoReportText(snapshot.currentWifiBssid),
    'aldols': pesoReportText(snapshot.currentWifiName),
  };
  final payload = <String, dynamic>{
    'landaus': pesoReportText(snapshot.systemVersion),
    'tippytoe': lastLoginAtMillis,
    'dullards': pesoReportText(snapshot.packageName),
    'peddlers': <String, dynamic>{
      'sperms': snapshot.batteryLevel,
      'dene': snapshot.isCharging,
    },
    'widening': <String, dynamic>{
      'bedchairs': pesoReportText(location?.longitude),
      'ungainlinesses': pesoReportText(location?.latitude),
      'hacksawed': pesoReportText(location?.fullAddress),
      'labeller': <String, dynamic>{
        'instituter': pesoReportText(location?.country),
        'nabob': pesoReportText(location?.countryCode),
        'countertrend': pesoReportText(location?.province),
        'hostages': pesoReportText(location?.city),
        'megalomaniac': pesoReportText(location?.locality),
        'traceabilities': pesoReportText(location?.street),
      },
    },
    'mugwumps': <String, dynamic>{
      'trouncing': pesoReportText(stableDeviceId),
      'tinged': pesoReportText(snapshot.idfa),
      'ribbiest': pesoReportText(snapshot.currentWifiBssid),
      'backache': nowMillis,
      'contraoctaves': pesoReportText(snapshot.uptimeMillis),
      'epitomise': snapshot.isUsingProxy,
      'jewel': snapshot.isUsingVpn,
      'invaginations': snapshot.isJailbroken,
      'sequiturs': snapshot.isEmulator,
      'decadents': pesoReportText(snapshot.language),
      'demobilizing': pesoReportText(snapshot.carrier),
      'earthquake': pesoReportText(snapshot.networkType),
      'gutlessnesses': const <dynamic>[],
      'benzimidazoles': pesoReportText(snapshot.timeZoneName),
      'amylopectins': snapshot.elapsedMillis,
    },
    'smothery': <String, dynamic>{
      'derailment': pesoReportText(snapshot.brand),
      'madtoms': snapshot.cpuCoreCount,
      'rogued': snapshot.screenHeight,
      'untread': pesoReportText(snapshot.deviceName),
      'aerospace': snapshot.screenWidth,
      'backspaced': pesoReportText(deviceModel),
      'niobic': pesoReportText(physicalSize),
      'blastier': pesoReportText(snapshot.systemVersion),
    },
    'ballpoint': <String, dynamic>{
      'berhymes': pesoReportText(snapshot.innerIp),
      'deverbative': <dynamic>[wifi],
      'boardmen': wifi,
      'epigenesis': snapshot.wifiCount,
    },
    'bargain': <String, dynamic>{
      'creasiest': pesoReportText(snapshot.availableStorage),
      'abstracters': pesoReportText(snapshot.totalStorage),
      'fatherland': pesoReportText(snapshot.totalMemory),
      'byway': pesoReportText(snapshot.availableMemory),
    },
  };
  return DataEncryptor(key: key, iv: iv).encrypt(jsonEncode(payload));
}

String pesoReportText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty || text == 'null' ? fallback : text;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
