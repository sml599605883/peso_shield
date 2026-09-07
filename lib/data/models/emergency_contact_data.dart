class EmergencyContactOption {
  const EmergencyContactOption({required this.label, required this.value});

  factory EmergencyContactOption.fromJson(Map<String, dynamic> json) {
    return EmergencyContactOption(
      label: json['cymenes']?.toString().trim() ?? '',
      value: json['bellings']?.toString().trim() ?? '',
    );
  }

  final String label;
  final String value;
}

class EmergencyContact {
  const EmergencyContact({
    required this.number,
    required this.relationshipValue,
    required this.relationshipLabel,
    required this.name,
    required this.phone,
    required this.relationshipOptions,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    final options = (json['aquamarines'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(EmergencyContactOption.fromJson)
        .where((item) => item.label.isNotEmpty && item.value.isNotEmpty)
        .toList(growable: false);
    final relationshipValue = json['briner']?.toString().trim() ?? '';
    final selected = options
        .where((item) => item.value == relationshipValue)
        .firstOrNull;
    return EmergencyContact(
      number: json['searchers']?.toString().trim() ?? '',
      relationshipValue: relationshipValue,
      relationshipLabel: selected?.label ?? '',
      name: json['cymenes']?.toString().trim() ?? '',
      phone: json['injure']?.toString().trim() ?? '',
      relationshipOptions: options,
    );
  }

  final String number;
  final String relationshipValue;
  final String relationshipLabel;
  final String name;
  final String phone;
  final List<EmergencyContactOption> relationshipOptions;
}

class EmergencyContactData {
  const EmergencyContactData({required this.prompt, required this.contacts});

  factory EmergencyContactData.fromJson(Map<String, dynamic> json) {
    final payload = json['eavesdropped'] ?? json;
    return EmergencyContactData(
      prompt: json['properdins']?.toString().trim() ?? '',
      contacts: (payload['applicants'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(EmergencyContact.fromJson)
          .where((contact) => contact.number.isNotEmpty)
          .toList(growable: false),
    );
  }

  final String prompt;
  final List<EmergencyContact> contacts;

  static List<Map<String, String>> contactsToMap(
    Map<String, String> fields,
  ) {
    final numbers = <String>[];
    for (final key in fields.keys) {
      if (!key.endsWith('.briner')) continue;
      numbers.add(key.substring(0, key.length - '.briner'.length));
    }
    return numbers
        .where((number) => number.isNotEmpty)
        .map(
          (number) => {
            'injure': fields['$number.injure'] ?? '',
            'cymenes': fields['$number.cymenes'] ?? '',
            'briner': fields['$number.briner'] ?? '',
            'searchers': number,
          },
        )
        .toList(growable: false);
  }
}
