import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/navigation/app_navigator.dart';
import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';
import 'home/widgets/widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _handleApply(BuildContext context, WidgetRef ref) async {
    await AppNavigator.applyProduct(
      context: context,
      ref: ref,
      productId: '1', // TODO: 从服务端获取产品ID
      apiRemind: 0, // 0: 默认
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = AppLayout.of(context);
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.homeBackground),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: layout.edgeInsets(bottom: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.maxContentWidth,
                  ),
                  child: Column(
                    children: [
                      const HomeHeader(),
                      SizedBox(height: layout.px(5)),
                      Padding(
                        padding: layout.edgeInsets(left: 10, right: 10),
                        child: LoanOfferCard(
                          onTap: () => _handleApply(context, ref),
                        ),
                      ),
                      Padding(
                        padding: layout.edgeInsets(left: 20, right: 20),
                        child: Image.asset(
                          AppAssets.instantFundsBanner,
                          width: double.infinity,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      SizedBox(height: layout.px(15)),
                      Image.asset(
                        AppAssets.loanProcessTitle,
                        width: layout.px(131),
                        height: layout.px(43),
                      ),
                      const LoanProcessCard(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
