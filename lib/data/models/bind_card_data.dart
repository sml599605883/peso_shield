import '../../core/json/json.dart';

enum BindCardFieldControl { selection, text, address, unsupported }

class BindCardOption {
  const BindCardOption({
    required this.label,
    required this.value,
    required this.logoUrl,
    required this.available,
    required this.hint,
  });

  factory BindCardOption.fromJson(Json json) {
    return BindCardOption(
      label: json['cymenes'].stringValue.trim(),
      value: json['bellings'].stringValue.trim(),
      logoUrl: json['week'].stringValue.trim(),
      available: json['barghests'].intValue != 0,
      hint: json['lookalike'].stringValue.trim(),
    );
  }

  final String label;
  final String value;
  final String logoUrl;
  final bool available;
  final String hint;
}

class BindCardField {
  const BindCardField({
    required this.title,
    required this.key,
    required this.placeholder,
    required this.control,
    required this.options,
    required this.required,
    required this.numeric,
    required this.initialValue,
    required this.suggestedValue,
  });

  factory BindCardField.fromJson(Json json) {
    final type = json['torsos'].stringValue.trim().toLowerCase();
    final options = json['deportment'].listValue
        .map((item) => BindCardOption.fromJson(Json(item)))
        .where((option) => option.label.isNotEmpty && option.value.isNotEmpty)
        .toList(growable: false);

    // 根据 API 文档的值映射：
    // "Superorganisms" = "enum" (下拉选择)
    // "EmpathisedWombiest" = "txt" (文本输入)
    // "Browbeat" = "citySelect" (城市选择)
    return BindCardField(
      title: json['stalagmitic'].stringValue.trim(),
      key: json['coffees'].stringValue.trim(),
      placeholder: json['vacantness'].stringValue.trim(),
      control: switch (type) {
        'enum' || 'superorganisms' => BindCardFieldControl.selection,
        'txt' || 'empathisedwombiest' => BindCardFieldControl.text,
        'cityselect' || 'browbeat' => BindCardFieldControl.address,
        _ => BindCardFieldControl.unsupported,
      },
      options: options,
      required: json['shmaltzy'].intValue == 0,
      numeric: json['forgets'].intValue == 1,
      initialValue: json['biolysis'].stringValue.trim(),
      suggestedValue: json['tracheophyte'].stringValue.trim(),
    );
  }

  final String title;
  final String key;
  final String placeholder;
  final BindCardFieldControl control;
  final List<BindCardOption> options;
  final bool required;
  final bool numeric;
  final String initialValue;
  final String suggestedValue;
}

class BindCardGroup {
  const BindCardGroup({
    required this.label,
    required this.type,
    required this.fields,
  });

  factory BindCardGroup.fromJson(Json json) {
    return BindCardGroup(
      label: json['stalagmitic'].stringValue.trim(),
      type: json['bellings'].stringValue.trim(),
      fields: json['fribbled'].listValue
          .map((item) => BindCardField.fromJson(Json(item)))
          .where(
            (field) =>
                field.title.isNotEmpty &&
                field.key.isNotEmpty &&
                field.control != BindCardFieldControl.unsupported,
          )
          .toList(growable: false),
    );
  }

  final String label;
  final String type;
  final List<BindCardField> fields;
}

class BindCardData {
  const BindCardData({
    required this.groups,
    required this.prompt,
    required this.bottomPrompt,
  });

  factory BindCardData.fromJson(Json json) {
    // ResponseProtocol 已经提取了 mugg，所以 json 直接就是 mugg 的内容
    return BindCardData(
      groups: json['fribbled'].listValue
          .map((item) => BindCardGroup.fromJson(Json(item)))
          .where(
            (group) =>
                group.label.isNotEmpty &&
                group.type.isNotEmpty &&
                group.fields.isNotEmpty,
          )
          .toList(growable: false),
      prompt: json['properdins'].stringValue.trim(),
      bottomPrompt: json['biogeographies'].stringValue.trim(),
    );
  }

  final List<BindCardGroup> groups;
  final String prompt;
  final String bottomPrompt;
}
