import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
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
                      const _HomeHeader(),
                      SizedBox(height: layout.px(5)),
                      Padding(
                        padding: layout.edgeInsets(left: 10, right: 10),
                        child: _LoanOfferCard(),
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
                      const _LoanProcessCard(),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Padding(
      padding: layout.edgeInsets(left: 20, top: 24, right: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Hi!  Welcome',
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(22),
                fontWeight: FontWeight.w700,
                height: 30 / 22,
              ),
            ),
          ),
          Semantics(
            button: true,
            label: 'Messages',
            child: Image.asset(
              AppAssets.notification,
              width: layout.px(30),
              height: layout.px(32),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoanOfferCard extends StatelessWidget {
  const _LoanOfferCard();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return AspectRatio(
      aspectRatio: 335 / 330,
      child: Container(
        padding: layout.edgeInsets(left: 44, top: 23, right: 44, bottom: 24),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.loanOfferCard),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CardHeader(),
            SizedBox(height: layout.px(6)),
            Text(
              'Maximum Credit Amount',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(12),
                fontWeight: FontWeight.w300,
                height: 14 / 12,
              ),
            ),
            SizedBox(height: layout.px(6)),
            const _CreditDivider(),
            const _CreditAmount(),
            const _CreditDivider(),
            SizedBox(height: layout.px(8)),
            const _LoanTerms(),
            const Spacer(),
            Semantics(
              button: true,
              label: 'Apply Now',
              child: Center(
                child: SizedBox(
                  height: layout.px(33),
                  child: Center(
                    child: Text(
                      'Apply Now',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: layout.px(18),
                        fontWeight: FontWeight.w700,
                        height: 22 / 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(44),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [const _AppIdentity(), const Spacer()],
      ),
    );
  }
}

class _AppIdentity extends StatelessWidget {
  const _AppIdentity();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      padding: layout.edgeInsets(left: 5, top: 4, right: 6, bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: layout.px(11),
            backgroundColor: AppColors.avatarGray,
          ),
          SizedBox(width: layout.px(6)),
          Text(
            'App Name',
            style: TextStyle(
              color: AppColors.black,
              fontSize: layout.px(16),
              fontWeight: FontWeight.w700,
              height: 19 / 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditDivider extends StatelessWidget {
  const _CreditDivider();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(height: layout.px(1), color: AppColors.dividerBlue);
  }
}

class _CreditAmount extends StatelessWidget {
  const _CreditAmount();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '₱',
            style: TextStyle(
              fontSize: layout.px(36),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: ' 60,000',
            style: TextStyle(
              fontSize: layout.px(50),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
      style: TextStyle(color: AppColors.black, height: 60 / 50),
    );
  }
}

class _LoanTerms extends StatelessWidget {
  const _LoanTerms();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      height: layout.px(85),
      padding: layout.edgeInsets(left: 17, top: 13, right: 17, bottom: 13),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: layout.radius(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _LoanTerm(label: 'Loan Term', value: '91-180 Days'),
          ),
          SizedBox(width: layout.px(12)),
          Expanded(
            child: _LoanTerm(label: 'Low Interest', value: '≤ 0.05% / Day'),
          ),
        ],
      ),
    );
  }
}

class _LoanTerm extends StatelessWidget {
  const _LoanTerm({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: AppColors.mutedBlue,
            fontSize: layout.px(14),
            height: 17 / 14,
          ),
        ),
        SizedBox(height: layout.px(6)),
        SizedBox(
          height: layout.px(19),
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(16),
                fontWeight: FontWeight.w700,
                height: 19 / 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoanProcessCard extends StatelessWidget {
  const _LoanProcessCard();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      key: const Key('loan-process-card'),
      width: double.infinity,
      height: layout.px(121),
      margin: layout.edgeInsets(left: 20, right: 20),
      padding: layout.edgeInsets(left: 19, top: 17, right: 19, bottom: 19),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(15),
      ),
      child: Image.asset(AppAssets.loanProcessSteps, fit: BoxFit.fill),
    );
  }
}
