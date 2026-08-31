import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../core/navigation/app_navigator.dart';
import '../core/ui/toast_helper.dart';
import '../theme/app_assets.dart';
import '../theme/layout_adapter.dart';
import 'home/widgets/widgets.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _handleApply(WidgetRef ref) async {
    final session = ref.read(userSessionProvider);

    // 未登录时先跳转登录页
    if (!session.isLoggedIn) {
      final result = await AppNavigator.toLogin();
      // 登录取消或失败，不继续
      if (result != true) return;
    }

    // 已登录，继续申请流程
    // TODO: 跳转到产品详情页或授信申请页
    ToastHelper.showMessage('Apply flow coming soon...');
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
                        child: LoanOfferCard(onTap: () => _handleApply(ref)),
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
