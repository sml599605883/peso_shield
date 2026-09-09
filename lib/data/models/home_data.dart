import 'home_modules.dart';

class HomeData {
  const HomeData({
    required this.phoneIcon,
    required this.sections,
    required this.products,
    this.banners = const [],
    this.progressItems = const [],
    this.recommendations = const [],
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final phoneIcon = json['satinwood'] as Map<String, dynamic>?;
    final applicants = json['applicants'] as List<dynamic>? ?? [];

    return HomeData(
      phoneIcon: phoneIcon != null
          ? PhoneIcon.fromJson(phoneIcon)
          : const PhoneIcon(imageUrl: '', jumpUrl: ''),
      sections: applicants
          .whereType<Map<String, dynamic>>()
          .map(HomeSection.fromJson)
          .toList(),
      products: _extractProducts(applicants),
      progressItems: _items(
        applicants,
        'Velarizing',
      ).map(HomeOrderProgress.fromJson).toList(growable: false),
      recommendations: _items(
        applicants,
        'RetaughtMazaedium',
      ).map(HomeRecommendation.fromJson).toList(growable: false),
      banners: [
        for (final section in applicants.whereType<Map<String, dynamic>>())
          if (section['bellings'] == 'CrassitudesSupercargos')
            for (final item
                in (section['geochronologist'] as List<dynamic>? ?? const [])
                    .whereType<Map<String, dynamic>>())
              HomeBannerData.fromJson(item),
      ],
    );
  }

  static List<ProductCard> _extractProducts(List<dynamic> applicants) {
    for (final section in applicants) {
      if (section is Map<String, dynamic> && section['bellings'] == 'Deoxy') {
        final products = section['geochronologist'] as List<dynamic>? ?? [];
        return products
            .map((e) => ProductCard.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }
    return [];
  }

  final PhoneIcon phoneIcon;
  final List<HomeSection> sections;
  final List<ProductCard> products;
  final List<HomeBannerData> banners;
  final List<HomeOrderProgress> progressItems;
  final List<HomeRecommendation> recommendations;

  static Iterable<Map<String, dynamic>> _items(
    List<dynamic> sections,
    String type,
  ) sync* {
    for (final section in sections.whereType<Map<String, dynamic>>()) {
      if (section['bellings']?.toString().trim() != type) continue;
      final items = section['geochronologist'];
      if (items is List) yield* items.whereType<Map<String, dynamic>>();
    }
  }
}

class HomeBannerData {
  const HomeBannerData({
    required this.id,
    required this.imageUrl,
    required this.targetUrl,
  });

  factory HomeBannerData.fromJson(Map<String, dynamic> json) => HomeBannerData(
    id: json['ventral']?.toString().trim() ?? '',
    imageUrl: json['succedanea']?.toString().trim() ?? '',
    targetUrl: json['mycelia']?.toString().trim() ?? '',
  );

  final String id;
  final String imageUrl;
  final String targetUrl;
}

class PhoneIcon {
  const PhoneIcon({required this.imageUrl, required this.jumpUrl});

  factory PhoneIcon.fromJson(Map<String, dynamic> json) {
    return PhoneIcon(
      imageUrl: json['wazoo'] as String? ?? '',
      jumpUrl: json['outduelled'] as String? ?? '',
    );
  }

  final String imageUrl;
  final String jumpUrl;
}

class HomeSection {
  const HomeSection({required this.type, required this.items});

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final type = json['bellings'] as String? ?? '';
    final rawItems = json['geochronologist'];
    final items = rawItems is List ? rawItems : const [];

    return HomeSection(
      type: type,
      items: items.whereType<Map<String, dynamic>>().toList(),
    );
  }

  final String type;
  final List<Map<String, dynamic>> items;
}

class ProductCard {
  const ProductCard({
    required this.id,
    required this.name,
    required this.maxAmount,
    required this.interestRate,
    required this.loanTerm,
    required this.buttonText,
    required this.buttonColor,
    required this.buttonState,
    required this.jumpUrl,
    required this.iconUrl,
    this.grummer = const [],
    this.shaved = const [],
  });

  factory ProductCard.fromJson(Map<String, dynamic> json) {
    return ProductCard(
      id: json['ventral']?.toString() ?? '',
      name: json['reinters'] as String? ?? '',
      maxAmount: json['contexts'] as String? ?? '',
      interestRate: json['amoebaean'] as String? ?? '',
      loanTerm: json['weakness'] as String? ?? '',
      buttonText: json['soreness'] as String? ?? '',
      buttonColor: '',
      buttonState: json['vrow'] as int? ?? 0,
      jumpUrl: json['mycelia'] as String? ?? '',
      iconUrl: json['crampfishes'] as String? ?? '',
      grummer: json['grummer'] is List
          ? (json['grummer'] as List)
                .whereType<Map<String, dynamic>>()
                .map(LoanProcessStep.fromJson)
                .toList(growable: false)
          : const [],
      shaved: (json['shaved'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LoanTermRow.fromJson)
          .toList(),
    );
  }

  final String id;
  final String name;
  final String maxAmount;
  final String interestRate;
  final String loanTerm;
  final String buttonText;
  final String buttonColor;
  final int buttonState;
  final String jumpUrl;
  final String iconUrl;
  final List<LoanProcessStep> grummer;
  final List<LoanTermRow> shaved;
}

class LoanProcessStep {
  const LoanProcessStep({
    required this.title,
    required this.amount,
    required this.active,
  });

  factory LoanProcessStep.fromJson(Map<String, dynamic> json) =>
      LoanProcessStep(
        title: json['stalagmitic']?.toString() ?? '',
        amount: json['unclogging']?.toString() ?? '',
        active: json['under'] == 1,
      );

  final String title;
  final String amount;
  final bool active;
}

class LoanTermRow {
  const LoanTermRow({required this.label, required this.value});
  factory LoanTermRow.fromJson(Map<String, dynamic> json) => LoanTermRow(
    label: json['strove']?.toString() ?? '',
    value: json['amoebaean']?.toString() ?? '',
  );
  final String label;
  final String value;
}
