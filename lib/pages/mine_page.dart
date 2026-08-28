import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.homeBackground),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _ProfileHeader(layout: layout),
              const _ServiceTitle(),
              SizedBox(height: layout.px(11)),
              Padding(
                padding: layout.edgeInsets(left: 20, right: 20),
                child: const _ServiceList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.layout});

  final AppLayout layout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth - layout.px(20);
        final cardHeight = cardWidth * 235 / 355;
        return SizedBox(
          height: layout.px(84) + cardHeight + layout.px(10),
          child: Stack(
            children: [
              Positioned(
                top: layout.px(84),
                left: layout.px(10),
                width: cardWidth,
                height: cardHeight,
                child: const _ProfileCard(),
              ),
              Positioned(
                top: layout.px(49),
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    AppAssets.mineAvatar,
                    width: layout.px(81),
                    height: layout.px(81),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage(AppAssets.mineOrdersCard),
          fit: BoxFit.fill,
        ),
      ),
      child: Padding(
        padding: layout.edgeInsets(top: 52, left: 48, right: 48),
        child: Column(
          children: [
            Text(
              '960 **** 5854',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.black,
                fontSize: layout.px(22),
                fontWeight: FontWeight.w800,
                height: 26 / 22,
              ),
            ),
            SizedBox(height: layout.px(29)),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OrderItem('All order', AppAssets.mineOrderAll),
                _OrderItem('Outstanding', AppAssets.mineOrderOutstanding),
                _OrderItem('Settled', AppAssets.mineOrderSettled),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderItem extends StatelessWidget {
  const _OrderItem(this.label, this.asset);

  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      width: layout.px(65),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(asset, width: layout.px(53), height: layout.px(53)),
          SizedBox(height: layout.px(10)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              color: AppColors.black,
              fontSize: layout.px(12),
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTitle extends StatelessWidget {
  const _ServiceTitle();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: layout.px(42),
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.loanProcessTitle),
              fit: BoxFit.fitHeight,
            ),
          ),
          alignment: Alignment.topCenter,
          padding: layout.edgeInsets(top: 6, left: 13, right: 13),
          child: Text(
            'Our Service',
            style: TextStyle(
              color: AppColors.white,
              fontSize: layout.px(16),
              fontWeight: FontWeight.w700,
              height: 19 / 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceList extends StatelessWidget {
  const _ServiceList();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(layout.px(15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: layout.px(8),
            offset: Offset(0, layout.px(4)),
          ),
        ],
      ),
      child: Column(
        children: [
          const _ServiceRow(
            'Online Services',
            AppAssets.mineOnlineService,
            hasDivider: true,
          ),
          const _ServiceRow('Setting', AppAssets.mineSetting, hasDivider: true),
          const _ServiceRow('Privacy Agreement', AppAssets.minePrivacy),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow(this.label, this.asset, {this.hasDivider = false});

  final String label;
  final String asset;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: hasDivider
                ? const Border(
                    bottom: BorderSide(color: AppColors.mineServiceDivider),
                  )
                : null,
          ),
          child: SizedBox(
            height: layout.px(58),
            child: Padding(
              padding: layout.edgeInsets(left: 17, right: 17),
              child: Row(
                children: [
                  Image.asset(
                    asset,
                    width: layout.px(22),
                    height: layout.px(20),
                  ),
                  SizedBox(width: layout.px(20)),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: AppColors.mineServiceText,
                        fontSize: layout.px(16),
                        height: 20 / 16,
                      ),
                    ),
                  ),
                  Image.asset(
                    AppAssets.mineChevron,
                    width: layout.px(7),
                    height: layout.px(12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
