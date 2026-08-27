class OrderListData {
  const OrderListData({
    required this.orders,
    required this.totalPages,
  });

  factory OrderListData.fromJson(Map<String, dynamic> json) {
    final mugg = json['mugg'] as Map<String, dynamic>? ?? {};
    return OrderListData(
      orders: (mugg['geochronologist'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: mugg['interstratified'] as int? ?? 1,
    );
  }

  final List<OrderItem> orders;
  final int totalPages;
}

class OrderItem {
  const OrderItem({
    required this.orderNo,
    required this.productName,
    required this.statusText,
    required this.statusColor,
    required this.amount,
    required this.amountLabel,
    required this.buttonText,
    required this.detailUrl,
    required this.dateLabel,
    required this.date,
    required this.overdueDays,
    required this.cardClickUrl,
    required this.buttonClickUrl,
    required this.supportEarlyRepay,
    required this.earlyRepayTip,
    required this.earlyRepayUrl,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderNo: json['superparasitism'] as String? ?? '',
      productName: json['reinters'] as String? ?? '',
      statusText: json['stalagmitic'] as String? ?? '',
      statusColor: json['pemmicans'] as String? ?? '',
      amount: json['desalting'] as String? ?? '',
      amountLabel: json['partition'] as String? ?? '',
      buttonText: json['haunts'] as String? ?? '',
      detailUrl: json['dicynodonts'] as String? ?? '',
      dateLabel: json['blimpishly'] as String? ?? '',
      date: json['loofa'] as String? ?? '',
      overdueDays: json['avifaunae'] as int? ?? 0,
      cardClickUrl: json['dysphonias'] as String? ?? '',
      buttonClickUrl: json['gruesomeness'] as String? ?? '',
      supportEarlyRepay: json['bass'] as bool? ?? false,
      earlyRepayTip: json['mistouched'] as String? ?? '',
      earlyRepayUrl: json['bornite'] as String? ?? '',
    );
  }

  final String orderNo;
  final String productName;
  final String statusText;
  final String statusColor;
  final String amount;
  final String amountLabel;
  final String buttonText;
  final String detailUrl;
  final String dateLabel;
  final String date;
  final int overdueDays;
  final String cardClickUrl;
  final String buttonClickUrl;
  final bool supportEarlyRepay;
  final String earlyRepayTip;
  final String earlyRepayUrl;
}
