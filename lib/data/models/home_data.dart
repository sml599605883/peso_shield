class HomeData {
  const HomeData({
    required this.phoneIcon,
    required this.sections,
    required this.products,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    final phoneIcon = json['satinwood'] as Map<String, dynamic>?;
    final applicants = json['applicants'] as List<dynamic>? ?? [];

    return HomeData(
      phoneIcon: phoneIcon != null
          ? PhoneIcon.fromJson(phoneIcon)
          : const PhoneIcon(imageUrl: '', jumpUrl: ''),
      sections: applicants
          .map((e) => HomeSection.fromJson(e as Map<String, dynamic>))
          .toList(),
      products: _extractProducts(applicants),
    );
  }

  static List<ProductCard> _extractProducts(List<dynamic> applicants) {
    for (final section in applicants) {
      if (section is Map<String, dynamic> &&
          section['bellings'] == 'PRODUCT_LIST') {
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
}

class PhoneIcon {
  const PhoneIcon({
    required this.imageUrl,
    required this.jumpUrl,
  });

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
  const HomeSection({
    required this.type,
    required this.items,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final type = json['bellings'] as String? ?? '';
    final items = json['geochronologist'] as List<dynamic>? ?? [];

    return HomeSection(
      type: type,
      items: items.map((e) => e as Map<String, dynamic>).toList(),
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
  });

  factory ProductCard.fromJson(Map<String, dynamic> json) {
    return ProductCard(
      id: json['ventral']?.toString() ?? '',
      name: json['reinters'] as String? ?? '',
      maxAmount: json['homothallism'] as String? ?? '',
      interestRate: json['gipsies'] as String? ?? '',
      loanTerm: json['weakness'] as String? ?? '',
      buttonText: json['haunts'] as String? ?? '',
      buttonColor: json['pemmicans'] as String? ?? '',
      buttonState: json['exclusivity'] as int? ?? 0,
      jumpUrl: json['mycelia'] as String? ?? '',
      iconUrl: json['cramp'] as String? ?? '',
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
}
