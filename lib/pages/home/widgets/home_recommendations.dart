import 'package:flutter/material.dart';
import '../../../data/models/home_modules.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/layout_adapter.dart';
import 'home_module_title.dart';
import 'home_product_logo.dart';

class HomeRecommendations extends StatelessWidget {
  const HomeRecommendations({
    super.key,
    required this.items,
    required this.onApply,
  });
  final List<HomeRecommendation> items;
  final ValueChanged<HomeRecommendation> onApply;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final layout = AppLayout.of(context);
    return Padding(
      padding: layout.edgeInsets(top: 16, left: 20, right: 20),
      child: Column(
        children: [
          const HomeModuleTitle(title: 'Recommendation', width: 158),
          for (final item in items)
            Padding(
              padding: layout.edgeInsets(bottom: 16),
              child: Semantics(
                button: true,
                child: GestureDetector(
                  key: ValueKey('recommendation-${item.id}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onApply(item),
                  child: Container(
                    height: layout.px(103),
                    decoration: BoxDecoration(
                      borderRadius: layout.radius(15),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.recommendationTop,
                          AppColors.recommendationBottom,
                        ],
                      ),
                      border: Border.all(color: AppColors.white),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.recommendationShadow,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: layout.px(36),
                          child: Padding(
                            padding: layout.edgeInsets(
                              left: 15,
                              right: 15,
                              top: 8,
                              bottom: 6,
                            ),
                            child: Row(
                              children: [
                                HomeProductLogo(
                                  url: item.logo,
                                  size: layout.px(22),
                                ),
                                SizedBox(width: layout.px(6)),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontFamily: 'Helvetica',
                                        fontSize: 14,
                                        color: AppColors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: layout.px(8)),
                                _tag(item.term, layout),
                                SizedBox(width: layout.px(3)),
                                _tag(item.rate, layout),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: layout.edgeInsets(
                              left: 15,
                              right: 15,
                              top: 8,
                              bottom: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: layout.radius(15),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            item.amount,
                                            style: const TextStyle(
                                              fontFamily: 'Helvetica',
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          item.amountLabel,
                                          style: const TextStyle(
                                            fontFamily: 'Helvetica',
                                            fontSize: 12,
                                            color:
                                                AppColors.recommendationCaption,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: layout.px(12)),
                                Container(
                                  width: layout.px(128),
                                  height: layout.px(36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: item.buttonState == -1
                                        ? AppColors.loginDisabled
                                        : AppColors.recommendationButton,
                                    borderRadius: layout.radius(18),
                                  ),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.buttonText,
                                      style: const TextStyle(
                                        fontFamily: 'Helvetica',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tag(String text, AppLayout layout) => Container(
    width: layout.px(85),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.recommendationTag,
      borderRadius: layout.radius(10),
    ),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Helvetica',
          fontSize: 12,
          color: AppColors.recommendationTagText,
        ),
      ),
    ),
  );
}
