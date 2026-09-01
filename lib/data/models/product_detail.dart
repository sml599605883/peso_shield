class ProductDetail {
  const ProductDetail({
    required this.basicInfo,
    required this.certifications,
    required this.nextStep,
    required this.agreements,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // ResponseProtocol 已经提取了 mugg 字段，这里直接从 json 读取
    final certifications = json['redialling'] as List<dynamic>? ?? [];
    final agreements = json['assertively'] as List<dynamic>? ?? [];

    return ProductDetail(
      basicInfo: json['fastball'] != null
          ? ProductBasicInfo.fromJson(json['fastball'] as Map<String, dynamic>)
          : const ProductBasicInfo(
              maxAmount: '',
              loanTerm: '',
              interestRate: '',
              tips: ProductTips(
                identity: '',
                work: '',
                contact: '',
                bank: '',
                bankBottom: '',
              ),
            ),
      certifications: certifications
          .map((e) => CertificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextStep: json['laminarias'] != null
          ? NextStep.fromJson(json['laminarias'] as Map<String, dynamic>)
          : const NextStep(type: '', url: '', status: 0, title: ''),
      agreements: agreements
          .map((e) => Agreement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final ProductBasicInfo basicInfo;
  final List<CertificationItem> certifications;
  final NextStep nextStep;
  final List<Agreement> agreements;
}

class ProductBasicInfo {
  const ProductBasicInfo({
    required this.maxAmount,
    required this.loanTerm,
    required this.interestRate,
    required this.tips,
  });

  factory ProductBasicInfo.fromJson(Map<String, dynamic> json) {
    return ProductBasicInfo(
      maxAmount: json['homothallism'] as String? ?? '',
      loanTerm: json['weakness'] as String? ?? '',
      interestRate: json['gipsies'] as String? ?? '',
      tips: json['acrostics'] != null
          ? ProductTips.fromJson(json['acrostics'] as Map<String, dynamic>)
          : const ProductTips(
              identity: '',
              work: '',
              contact: '',
              bank: '',
              bankBottom: '',
            ),
    );
  }

  final String maxAmount;
  final String loanTerm;
  final String interestRate;
  final ProductTips tips;
}

class ProductTips {
  const ProductTips({
    required this.identity,
    required this.work,
    required this.contact,
    required this.bank,
    required this.bankBottom,
  });

  factory ProductTips.fromJson(Map<String, dynamic> json) {
    return ProductTips(
      identity: json['enosises'] as String? ?? '',
      work: json['dicynodonts'] as String? ?? '',
      contact: json['kinema'] as String? ?? '',
      bank: json['nodalities'] as String? ?? '',
      bankBottom: json['biogeographies'] as String? ?? '',
    );
  }

  final String identity;
  final String work;
  final String contact;
  final String bank;
  final String bankBottom;
}

class CertificationItem {
  const CertificationItem({
    required this.type,
    required this.title,
    required this.status,
    required this.url,
  });

  factory CertificationItem.fromJson(Map<String, dynamic> json) {
    return CertificationItem(
      type: json['histolyses'] as String? ?? '',
      title: json['stalagmitic'] as String? ?? '',
      status: json['bellings'] as int? ?? 0,
      url: json['mycelia'] as String? ?? '',
    );
  }

  final String type;
  final String title;
  final int status;
  final String url;
}

class NextStep {
  const NextStep({
    required this.type,
    required this.url,
    required this.status,
    required this.title,
  });

  factory NextStep.fromJson(Map<String, dynamic> json) {
    return NextStep(
      type: json['histolyses'] as String? ?? '',
      url: json['mycelia'] as String? ?? '',
      status: json['bellings'] as int? ?? 0,
      title: json['stalagmitic'] as String? ?? '',
    );
  }

  final String type;
  final String url;
  final int status;
  final String title;
}

class Agreement {
  const Agreement({
    required this.id,
    required this.isRequired,
    required this.position,
    required this.templateId,
    required this.title,
  });

  factory Agreement.fromJson(Map<String, dynamic> json) {
    return Agreement(
      id: json['polarimetric'] as String? ?? '',
      isRequired: json['experimentalism'] as int? ?? 0,
      position: json['thrived'] as String? ?? '',
      templateId: json['cointerring'] as int? ?? 0,
      title: json['stalagmitic'] as String? ?? '',
    );
  }

  final String id;
  final int isRequired;
  final String position;
  final int templateId;
  final String title;
}
