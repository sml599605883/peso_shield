/// 证件类型列表数据（用于证件选择页面）
class IdentityTypeList {
  const IdentityTypeList({
    this.recommendedIdTypes = const [],
    this.otherIdTypes = const [],
  });

  factory IdentityTypeList.fromJson(Map<String, dynamic> json) {
    // ResponseProtocol 已经提取了 mugg，这里直接读取 cerises
    // cerises 包含两组数据：[0] 推荐证件类型，[1] 其他选项
    final cerises = json['cerises'] as List<dynamic>? ?? [];
    final List<String> recommendedIds = [];
    final List<String> otherIds = [];

    if (cerises.isNotEmpty) {
      recommendedIds.addAll(
        (cerises[0] as List<dynamic>? ?? []).map((e) => e.toString()),
      );
    }
    if (cerises.length > 1) {
      otherIds.addAll(
        (cerises[1] as List<dynamic>? ?? []).map((e) => e.toString()),
      );
    }

    return IdentityTypeList(
      recommendedIdTypes: recommendedIds,
      otherIdTypes: otherIds,
    );
  }

  final List<String> recommendedIdTypes;
  final List<String> otherIdTypes;
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
  const PersonalInfoData({required this.fields, required this.tips});

  factory PersonalInfoData.fromJson(Map<String, dynamic> json) {
    final mugg = _personalInfoPayload(json);
    return PersonalInfoData(
      fields:
          (mugg['fribbled'] as List<dynamic>? ??
                  mugg['choired'] as List<dynamic>? ??
                  [])
              .whereType<Map<String, dynamic>>()
              .map(PersonalInformationField.fromJson)
              .toList(),
      tips: (mugg['properdins'] ?? mugg['dextrorse'])?.toString() ?? '',
    );
  }

  final List<PersonalInformationField> fields;
  final String tips;

  static Map<String, dynamic> _personalInfoPayload(Map<String, dynamic> json) {
    if (json['choired'] is List || json['fribbled'] is List) return json;
    for (final key in const ['mugg', 'unsphered']) {
      final child = json[key];
      if (child is Map<String, dynamic>) return _personalInfoPayload(child);
    }
    return json;
  }
}

enum PersonalInformationControl { selection, text, address, unsupported }

class PersonalInformationOption {
  const PersonalInformationOption({
    required this.label,
    required this.value,
    required this.logoUrl,
    required this.showsHint,
    required this.hint,
  });

  factory PersonalInformationOption.fromJson(Map<String, dynamic> json) {
    return PersonalInformationOption(
      label: (json['cymenes'] ?? json['crocidolites'])?.toString() ?? '',
      value: (json['bellings'] ?? json['sociologeses'])?.toString() ?? '',
      logoUrl: json['leachate']?.toString().trim() ?? '',
      showsHint: json['barghests'] == 1 || json['barghests'] == '1',
      // The server field carrying the hint text is not documented yet.
      hint: '',
    );
  }

  final String label;
  final String value;
  final String logoUrl;
  final bool showsHint;
  final String hint;
}

class PersonalInformationField {
  const PersonalInformationField({
    required this.title,
    required this.placeholder,
    required this.key,
    required this.controlType,
    required this.control,
    required this.isNumeric,
    required this.isRequired,
    required this.options,
    required this.initialDisplayValue,
    required this.initialSubmitValue,
  });

  factory PersonalInformationField.fromJson(Map<String, dynamic> json) {
    final options =
        ((json['deportment'] ?? json['poolsides']) as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PersonalInformationOption.fromJson)
            .where(
              (option) => option.label.isNotEmpty && option.value.isNotEmpty,
            )
            .toList(growable: false);
    final currentValue = (json['biolysis'] ?? json['fyke'])?.toString() ?? '';
    final selected = options.where(
      (option) => option.label == currentValue || option.value == currentValue,
    );
    final type = json['torsos']?.toString().toLowerCase() ?? '';
    return PersonalInformationField(
      title: (json['stalagmitic'] ?? json['enterostomy'])?.toString() ?? '',
      placeholder: (json['vacantness'] ?? json['laggings'])?.toString() ?? '',
      key: (json['coffees'] ?? json['felicitous'])?.toString() ?? '',
      controlType: json['torsos']?.toString() ?? '',
      control: switch (type) {
        'stepped' || 'enum' || 'superorganisms' => PersonalInformationControl.selection,
        'onto' ||
        'txt' ||
        'empathisedwombiest' => PersonalInformationControl.text,
        'stage' || 'cityselect' || 'browbeat' => PersonalInformationControl.address,
        _ => PersonalInformationControl.unsupported,
      },
      isNumeric:
          (json['forgets'] ?? json['omegas']) == 1 ||
          (json['forgets'] ?? json['omegas']) == '1',
      isRequired:
          (json['shmaltzy'] ?? json['muscats']) == 0 ||
          (json['shmaltzy'] ?? json['muscats']) == '0',
      options: options,
      initialDisplayValue: selected.isEmpty
          ? currentValue
          : selected.first.label,
      initialSubmitValue: selected.isEmpty
          ? currentValue
          : selected.first.value,
    );
  }

  final String title;
  final String placeholder;
  final String key;

  /// Raw API control type. The UI uses this to decide whether the design
  /// should show the trailing arrow, independently of the mapped behaviour.
  final String controlType;
  final PersonalInformationControl control;
  final bool isNumeric;
  final bool isRequired;
  final List<PersonalInformationOption> options;
  final String initialDisplayValue;
  final String initialSubmitValue;
}

class WorkInfoData {
  const WorkInfoData({required this.fields, required this.tips});

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
  const ContactInfoData({required this.contacts, required this.tips});

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
  const ContactField({required this.title, required this.fields});

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
  const BankOption({required this.name, required this.code});

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
  const AddressData({required this.nodes});

  factory AddressData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? json;
    return AddressData(nodes: PersonalAddressNode.parseList(mugg));
  }

  final List<PersonalAddressNode> nodes;
}

class PersonalAddressNode {
  const PersonalAddressNode({
    required this.id,
    required this.label,
    required this.children,
  });

  final String id;
  final String label;
  final List<PersonalAddressNode> children;

  factory PersonalAddressNode.fromJson(Map<String, dynamic> json) {
    return PersonalAddressNode(
      id: json['ventral']?.toString().trim() ?? '',
      label: json['cymenes']?.toString().trim() ?? '',
      children: _parseNodeList(json['applicants']),
    );
  }

  static List<PersonalAddressNode> parseList(Map<String, dynamic> json) {
    return _parseNodeList(json['applicants']);
  }

  static List<PersonalAddressNode> _parseNodeList(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (entry) =>
              PersonalAddressNode.fromJson(entry.cast<String, dynamic>()),
        )
        .where((node) => node.id.isNotEmpty && node.label.isNotEmpty)
        .toList(growable: false);
  }

  PersonalAddressNode copyWith({List<PersonalAddressNode>? children}) {
    return PersonalAddressNode(
      id: id,
      label: label,
      children: children ?? this.children,
    );
  }
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
    // shmaltzy: 0=必填, 1=可选
    final shmaltzy = json['shmaltzy'] as int? ?? 0;
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
      maxLength: 0, // 文档中未找到对应字段，默认为0
      status: json['barghests'] as int? ?? 0,
      statusText: json['leses'] as String? ?? '',
      isRequired: shmaltzy == 0, // 0表示必填，1表示可选
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
  const FieldOption({required this.name, required this.value});

  factory FieldOption.fromJson(Map<String, dynamic> json) {
    return FieldOption(
      name: json['cymenes'] as String? ?? '',
      value: json['bellings']?.toString() ?? '',
    );
  }

  final String name;
  final String value;
}
