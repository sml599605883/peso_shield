import '../../core/json/json.dart';

String formatHomeMoney(String raw) {
  final match = RegExp(
    r'^(.*?)([0-9][0-9,]*)(\.[0-9]+)?$',
  ).firstMatch(raw.trim());
  if (match == null) return raw.trim();
  final digits = match.group(2)!.replaceAll(',', '');
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
    grouped.write(digits[i]);
  }
  return '${match.group(1)}$grouped${match.group(3) ?? ''}';
}

class HomeRecommendation {
  HomeRecommendation.fromJson(Map<String, dynamic> map) {
    final json = Json(map);
    id = json['ventral'].stringValue.trim();
    name = json['reinters'].stringValue.trim();
    logo = json['crampfishes'].stringValue.trim();
    amount = formatHomeMoney(json['contexts'].stringValue);
    amountLabel = json['corporeally'].stringValue.trim();
    term = json['weakness'].stringValue.trim();
    rate = json['gipsies'].stringValue.trim();
    buttonText = json['haunts'].stringValue.trim();
    buttonState = json['exclusivity'].intValue;
  }
  late final String id, name, logo, amount, amountLabel, term, rate, buttonText;
  late final int buttonState;
}

class HomeOrderAction {
  const HomeOrderAction(
    this.type,
    this.label, {
    this.badge = '',
    this.url = '',
  });
  final String type, label, badge, url;
}

class HomeOrderProgress {
  HomeOrderProgress.fromJson(Map<String, dynamic> map) {
    final json = Json(map);
    orderNo = json['superparasitism'].stringValue.trim();
    productId = json['bombarder'].stringValue.trim();
    name = json['sajou'].stringValue.trim();
    logo = json['keloids'].stringValue.trim();
    status = json['prutoth'].intValue;
    statusText = json['dissection'].stringValue.trim();
    final display = json['kaiserin'].stringValue.trim();
    amount = formatHomeMoney(
      display.isEmpty ? json['desalting'].stringValue : display,
    );
    amountLabel = json['smarmiest'].stringValue.trim();
    date = json['guessed'].stringValue.trim();
    dateLabel = json['airn'].stringValue.trim();
    target = json['mycelia'].stringValue.trim();
    actions = List.unmodifiable([
      for (final raw
          in json['pincushions'].listValue.whereType<Map<String, dynamic>>())
        if (Json(raw)['souvlakis'].intValue == 1)
          HomeOrderAction(
            Json(raw)['bellings'].stringValue.trim().toLowerCase(),
            Json(raw)['beatify'].stringValue.trim(),
            badge: Json(raw)['reinterpret'].stringValue.trim(),
            url: Json(raw)['vulgarest'].stringValue.trim(),
          ),
    ]);
  }
  late final String orderNo, productId, name, logo, statusText;
  late final String amount, amountLabel, date, dateLabel, target;
  late final int status;
  late final List<HomeOrderAction> actions;
  bool get isBlue => status == 1 || status == 4;
  String get label => statusText.isNotEmpty
      ? statusText
      : switch (status) {
          1 => 'Review in Progress',
          2 => 'Repayment Required',
          3 => 'Late Payment',
          4 => 'Disbursing Funds',
          5 || 6 => 'Payout Failed',
          _ => '',
        };
  List<HomeOrderAction> get displayActions => actions.isNotEmpty
      ? actions
      : const [HomeOrderAction('detail', 'Details')];
}
