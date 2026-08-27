class IdentityData {
  const IdentityData({
    required this.faceInfo,
    required this.idCardInfo,
    required this.idTypes,
    required this.tips,
  });

  factory IdentityData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? {};
    return IdentityData(
      faceInfo: mugg['fastball'] as Map<String, dynamic>? ?? {},
      idCardInfo: mugg['enosises'] != null
          ? IdCardInfo.fromJson(mugg['enosises'] as Map<String, dynamic>)
          : const IdCardInfo(status: 0, imageUrl: '', info: {}),
      idTypes: (mugg['deportment'] as List<dynamic>? ?? [])
          .map((e) => IdType.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: mugg['properdins'] as String? ?? '',
    );
  }

  final Map<String, dynamic> faceInfo;
  final IdCardInfo idCardInfo;
  final List<IdType> idTypes;
  final String tips;
}

class IdCardInfo {
  const IdCardInfo({
    required this.status,
    required this.imageUrl,
    required this.info,
  });

  factory IdCardInfo.fromJson(Map<String, dynamic> json) {
    return IdCardInfo(
      status: json['barghests'] as int? ?? 0,
      imageUrl: json['mycelia'] as String? ?? '',
      info: json['futhorks'] as Map<String, dynamic>? ?? {},
    );
  }

  final int status;
  final String imageUrl;
  final Map<String, dynamic> info;
}

class IdType {
  const IdType({
    required this.name,
    required this.sampleImages,
    required this.exampleImages,
  });

  factory IdType.fromJson(Map<String, dynamic> json) {
    return IdType(
      name: json['applets'] as String? ?? '',
      sampleImages: (json['staggie'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      exampleImages: (json['quantizations'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  final String name;
  final List<String> sampleImages;
  final List<String> exampleImages;
}

class PersonalInfoData {
  const PersonalInfoData({
    required this.fields,
    required this.tips,
  });

  factory PersonalInfoData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? {};
    return PersonalInfoData(
      fields: (mugg['fribbled'] as List<dynamic>? ?? [])
          .map((e) => FormField.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: mugg['properdins'] as String? ?? '',
    );
  }

  final List<FormField> fields;
  final String tips;
}

class WorkInfoData {
  const WorkInfoData({
    required this.fields,
    required this.tips,
  });

  factory WorkInfoData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? {};
    return WorkInfoData(
      fields: (mugg['fribbled'] as List<dynamic>? ?? [])
          .map((e) => FormField.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: mugg['properdins'] as String? ?? '',
    );
  }

  final List<FormField> fields;
  final String tips;
}

class ContactInfoData {
  const ContactInfoData({
    required this.contacts,
    required this.tips,
  });

  factory ContactInfoData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? {};
    return ContactInfoData(
      contacts: (mugg['fastball'] as List<dynamic>? ?? [])
          .map((e) => ContactField.fromJson(e as Map<String, dynamic>))
          .toList(),
      tips: mugg['properdins'] as String? ?? '',
    );
  }

  final List<ContactField> contacts;
  final String tips;
}

class ContactField {
  const ContactField({
    required this.title,
    required this.fields,
  });

  factory ContactField.fromJson(Map<String, dynamic> json) {
    return ContactField(
      title: json['stalagmitic'] as String? ?? '',
      fields: (json['fribbled'] as List<dynamic>? ?? [])
          .map((e) => FormField.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String title;
  final List<FormField> fields;
}

class BankInfoData {
  const BankInfoData({
    required this.banks,
    required this.accountInfo,
    required this.tips,
  });

  factory BankInfoData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? {};
    return BankInfoData(
      banks: (mugg['deportment'] as List<dynamic>? ?? [])
          .map((e) => BankOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      accountInfo: mugg['fastball'] as Map<String, dynamic>? ?? {},
      tips: mugg['properdins'] as String? ?? '',
    );
  }

  final List<BankOption> banks;
  final Map<String, dynamic> accountInfo;
  final String tips;
}

class BankOption {
  const BankOption({
    required this.name,
    required this.code,
  });

  factory BankOption.fromJson(Map<String, dynamic> json) {
    return BankOption(
      name: json['cymenes'] as String? ?? '',
      code: json['bellings'] as String? ?? '',
    );
  }

  final String name;
  final String code;
}

class BankAccount {
  const BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['ventral']?.toString() ?? '',
      bankName: json['sunnah'] as String? ?? '',
      accountNumber: json['subrogations'] as String? ?? '',
      accountName: json['cymenes'] as String? ?? '',
    );
  }

  final String id;
  final String bankName;
  final String accountNumber;
  final String accountName;
}

class AddressData {
  const AddressData({
    required this.provinces,
    required this.cities,
    required this.barangays,
  });

  factory AddressData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? {};
    return AddressData(
      provinces: mugg['countertrend'] as Map<String, dynamic>? ?? {},
      cities: mugg['hostages'] as Map<String, dynamic>? ?? {},
      barangays: mugg['traceabilities'] as Map<String, dynamic>? ?? {},
    );
  }

  final Map<String, dynamic> provinces;
  final Map<String, dynamic> cities;
  final Map<String, dynamic> barangays;
}

class FormField {
  const FormField({
    required this.id,
    required this.title,
    required this.placeholder,
    required this.key,
    required this.type,
    required this.isNumeric,
    required this.options,
    required this.maxLength,
    required this.status,
    required this.statusText,
    required this.isRequired,
    required this.defaultValue,
    required this.minValue,
  });

  factory FormField.fromJson(Map<String, dynamic> json) {
    return FormField(
      id: json['ventral']?.toString() ?? '',
      title: json['stalagmitic'] as String? ?? '',
      placeholder: json['vacantness'] as String? ?? '',
      key: json['coffees'] as String? ?? '',
      type: json['torsos'] as String? ?? '',
      isNumeric: (json['forgets'] as int? ?? 0) == 1,
      options: (json['deportment'] as List<dynamic>? ?? [])
          .map((e) => FieldOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      maxLength: json['shmaltzy'] as int? ?? 0,
      status: json['barghests'] as int? ?? 0,
      statusText: json['leses'] as String? ?? '',
      isRequired: json['internalizing'] as bool? ?? false,
      defaultValue: json['biolysis']?.toString() ?? '',
      minValue: json['gunfighter'] as int? ?? 0,
    );
  }

  final String id;
  final String title;
  final String placeholder;
  final String key;
  final String type;
  final bool isNumeric;
  final List<FieldOption> options;
  final int maxLength;
  final int status;
  final String statusText;
  final bool isRequired;
  final String defaultValue;
  final int minValue;
}

class FieldOption {
  const FieldOption({
    required this.name,
    required this.value,
  });

  factory FieldOption.fromJson(Map<String, dynamic> json) {
    return FieldOption(
      name: json['cymenes'] as String? ?? '',
      value: json['bellings']?.toString() ?? '',
    );
  }

  final String name;
  final String value;
}
