import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/device/user_session.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'widgets/identity_upload_prompt.dart';

/// Static ID upload guidance page. Upload service integration is pending.
class IdentityUploadPage extends ConsumerWidget {
  const IdentityUploadPage({
    required this.productId,
    required this.cardType,
    super.key,
  });

  final String productId;
  final String cardType;

  /// 接口未下发 linocut 文案时的兜底展示。
  static const defaultPrompt =
      'Step 1 to fast cash! Upload ID for the express approval channel.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = AppLayout.of(context);
    
    // 优先使用产品详情缓存的 linocut 文案，为空时兜底
    final cachedPrompt = ref.watch(sessionStoreProvider).productDetailPrompt;
    final prompt = cachedPrompt.isNotEmpty ? cachedPrompt : defaultPrompt;
    
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.homeBackground),
              fit: BoxFit.fill,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: layout.edgeInsets(bottom: 20),
              child: Column(
                children: [
                  SizedBox(height: layout.px(16)),
                  SizedBox(
                    height: layout.px(24),
                    child: Stack(
                      children: [
                        Positioned(
                          left: layout.px(20),
                          child: const AppBackButton(),
                        ),
                        Center(
                          child: Text(
                            'Identity verification',
                            style: TextStyle(
                              color: AppColors.black,
                              fontFamily: 'Helvetica',
                              fontSize: layout.px(20),
                              fontWeight: FontWeight.w700,
                              height: 24 / 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: layout.px(33)),
                  IdentityUploadPrompt(message: prompt),
                  Image.asset(
                    AppAssets.identityUploadDemo,
                    width: layout.px(355),
                    height: layout.px(441),
                    fit: BoxFit.fill,
                    semanticLabel: 'Identity upload instructions',
                  ),
                  SizedBox(height: layout.px(14)),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: layout.edgeInsets(left: 56, right: 56, bottom: 10),
            child: SizedBox(
              height: layout.px(50),
              child: ElevatedButton(
                key: const Key('identity-upload-submit'),
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: layout.radius(25),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontFamily: 'Helvetica',
                    fontSize: layout.px(18),
                    fontWeight: FontWeight.w700,
                    height: 22 / 18,
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
