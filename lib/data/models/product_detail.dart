class ProductDetail {
  const ProductDetail({
    required this.basicInfo,
    required this.tips,
    required this.certifications,
    required this.nextStep,
    required this.agreements,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    // ResponseProtocol 已经提取了 mugg 字段，这里直接从 json 读取
    final certifications = json['redialling'] as List<dynamic>? ?? [];
    final agreements = json['assertively'] as List<dynamic>? ?? [];

    return ProductDetail(
      basicInfo: json['cutbacks'] != null
          ? ProductBasicInfo.fromJson(json['cutbacks'] as Map<String, dynamic>)
          : const ProductBasicInfo(),
      // deportment 与 cutbacks 平级，是各认证页面的文案
      tips: json['deportment'] != null
          ? ProductTips.fromJson(json['deportment'] as Map<String, dynamic>)
          : const ProductTips(),
      certifications: certifications
          .map((e) => CertificationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextStep: json['laminarias'] != null
          ? NextStep.fromJson(json['laminarias'] as Map<String, dynamic>)
          : const NextStep(),
      agreements: agreements
          .map((e) => Agreement.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final ProductBasicInfo basicInfo;
  final ProductTips tips;
  final List<CertificationItem> certifications;
  final NextStep nextStep;
  final List<Agreement> agreements;
}

/// 产品信息（cutbacks）
class ProductBasicInfo {
  const ProductBasicInfo({
    this.amountRange = const [],
    this.amount = '',
    this.terms = const [],
    this.amountDesc = '',
    this.termDesc = '',
    this.productId = '',
    this.productName = '',
    this.orderNo = '',
    this.orderId = 0,
    this.buttonText = '',
    this.columnText,
  });

  factory ProductBasicInfo.fromJson(Map<String, dynamic> json) {
    final amountRange = json['ghostiest'] as List<dynamic>? ?? [];
    final terms = json['armpits'] as List<dynamic>? ?? [];

    return ProductBasicInfo(
      amountRange: amountRange.map((e) => e.toString()).toList(),
      amount: json['desalting']?.toString() ?? '',
      terms: terms.map((e) => int.tryParse(e.toString()) ?? 0).toList(),
      amountDesc: json['impotent'] as String? ?? '',
      termDesc: json['concertino'] as String? ?? '',
      productId: json['ventral']?.toString() ?? '',
      productName: json['reinters'] as String? ?? '',
      orderNo: json['cysticercosis']?.toString() ?? '',
      orderId: json['cointerring'] as int? ?? 0,
      buttonText: json['haunts'] as String? ?? '',
      columnText: json['medicides'] != null
          ? ProductColumnText.fromJson(json['medicides'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 额度范围
  final List<String> amountRange;

  /// 金额
  final String amount;

  /// 借款期限
  final List<int> terms;

  /// 借款金额文案
  final String amountDesc;

  /// 借款期限文案
  final String termDesc;

  final String productId;
  final String productName;
  final String orderNo;
  final int orderId;
  final String buttonText;

  /// 详情栏位文案（额度、利率等）
  final ProductColumnText? columnText;
}

/// 详情栏位文案（medicides）
class ProductColumnText {
  const ProductColumnText({this.tag1, this.tag2});

  factory ProductColumnText.fromJson(Map<String, dynamic> json) {
    return ProductColumnText(
      tag1: json['convolved'] != null
          ? ProductColumnTag.fromJson(json['convolved'] as Map<String, dynamic>)
          : null,
      tag2: json['lipreading'] != null
          ? ProductColumnTag.fromJson(json['lipreading'] as Map<String, dynamic>)
          : null,
    );
  }

  final ProductColumnTag? tag1;
  final ProductColumnTag? tag2;
}

class ProductColumnTag {
  const ProductColumnTag({required this.title, required this.text});

  factory ProductColumnTag.fromJson(Map<String, dynamic> json) {
    return ProductColumnTag(
      title: json['stalagmitic'] as String? ?? '',
      text: json['lookalike'] as String? ?? '',
    );
  }

  final String title;
  final String text;
}

/// 各认证页面文案（deportment）
class ProductTips {
  const ProductTips({
    this.identity = '',
    this.identitySuccess = '',
    this.liveness = '',
    this.personal = '',
    this.work = '',
    this.contact = '',
    this.bank = '',
    this.bankBottom = '',
  });

  factory ProductTips.fromJson(Map<String, dynamic> json) {
    return ProductTips(
      identity: json['linocut'] as String? ?? '',
      identitySuccess: json['heterosexually'] as String? ?? '',
      liveness: json['printings'] as String? ?? '',
      personal: json['clubable'] as String? ?? '',
      work: json['hillbillies'] as String? ?? '',
      contact: json['kinema'] as String? ?? '',
      bank: json['nodalities'] as String? ?? '',
      bankBottom: json['biogeographies'] as String? ?? '',
    );
  }

  /// 身份认证页面顶部文案
  final String identity;

  /// 身份认证成功页面顶部文案
  final String identitySuccess;

  /// 活体认证页面顶部文案
  final String liveness;

  /// 个人信息认证页面顶部文案
  final String personal;

  /// 工作信息认证页面顶部文案
  final String work;

  /// 紧急联系人认证页面顶部文案
  final String contact;

  /// 绑卡页面顶部文案
  final String bank;

  /// 绑卡页面底部文案
  final String bankBottom;
}

/// 认证项（redialling）
class CertificationItem {
  const CertificationItem({
    required this.taskType,
    required this.title,
    this.subtitle = '',
    this.statusName = '',
    this.isCompleted = 0,
    this.canClick = 0,
    this.ifMust = 0,
    this.canClickMessage = '',
    this.iconUrl = '',
    this.url = '',
  });

  factory CertificationItem.fromJson(Map<String, dynamic> json) {
    return CertificationItem(
      taskType: json['histolyses'] as String? ?? '',
      title: json['stalagmitic'] as String? ?? '',
      subtitle: json['vacantness'] as String? ?? '',
      statusName: json['leses'] as String? ?? '',
      isCompleted: json['barghests'] as int? ?? 0,
      canClick: json['deity'] as int? ?? 0,
      ifMust: json['liftoffs'] as int? ?? 0,
      canClickMessage: json['satchelsful'] as String? ?? '',
      iconUrl: json['priggisms'] as String? ?? '',
      url: json['mycelia'] as String? ?? '',
    );
  }

  /// 认证类型（混淆后的值，见"产品详情认证项目列表"值映射）
  final String taskType;
  final String title;
  final String subtitle;
  final String statusName;

  /// 是否已完成
  final int isCompleted;
  final int canClick;
  final int ifMust;
  final String canClickMessage;
  final String iconUrl;
  final String url;
}

/// 下一步（laminarias）
class NextStep {
  const NextStep({this.taskType = '', this.url = '', this.title = ''});

  factory NextStep.fromJson(Map<String, dynamic> json) {
    return NextStep(
      taskType: json['histolyses'] as String? ?? '',
      url: json['mycelia'] as String? ?? '',
      title: json['stalagmitic'] as String? ?? '',
    );
  }

  /// 认证类型（混淆后的值，见"产品详情认证项目列表"值映射）
  final String taskType;
  final String url;
  final String title;
}

class Agreement {
  const Agreement({
    required this.productId,
    required this.scene,
    required this.position,
    required this.templateId,
    required this.title,
  });

  factory Agreement.fromJson(Map<String, dynamic> json) {
    return Agreement(
      productId: json['polarimetric'] as String? ?? '',
      scene: json['experimentalism'] as int? ?? 0,
      position: json['thrived'] as String? ?? '',
      templateId: json['cointerring'] as int? ?? 0,
      title: json['stalagmitic'] as String? ?? '',
    );
  }

  final String productId;
  final int scene;
  final String position;
  final int templateId;
  final String title;
}
