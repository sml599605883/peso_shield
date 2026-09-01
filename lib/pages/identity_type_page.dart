import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';

/// Static identity document selection shown before document capture.
class IdentityTypePage extends StatefulWidget {
  const IdentityTypePage({super.key});

  @override
  State<IdentityTypePage> createState() => _IdentityTypePageState();
}

class _IdentityTypePageState extends State<IdentityTypePage> {
  bool _showOtherOptions = false;

  static const _recommended = [
    'PRC ID',
    'SSS ID',
    'PHILIPPINE PASSPORT',
    'POSTAL ID',
    'UMID(Unified Multi-Purpose ID)',
  ];
  static const _other = [
    "DRIVER'S LICENSE",
    'STUDENT CARD',
    'TIN ID',
    "Voter's ID",
    'PhilHealth ID',
  ];

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final options = _showOtherOptions ? _other : _recommended;
    return Scaffold(
      body: DecoratedBox(
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
                SizedBox(height: layout.px(21)),
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
                SizedBox(height: layout.px(29)),
                SizedBox(
                  height: layout.px(117),
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: layout.px(113),
                        child: SizedBox(
                          height: layout.px(117),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: layout.px(14),
                                left: 0,
                                child: DecoratedBox(
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(15),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      layout.px(9),
                                      layout.px(5),
                                      layout.px(10),
                                      layout.px(6),
                                    ),
                                    child: Text(
                                      'Maximum Credit Amount',
                                      style: TextStyle(
                                        color: AppColors.black,
                                        fontFamily: 'Helvetica',
                                        fontSize: layout.px(12),
                                        fontWeight: FontWeight.w300,
                                        height: 14 / 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: layout.px(76),
                                left: 0,
                                child: Container(
                                  width: layout.px(226),
                                  height: layout.px(24),
                                  color: AppColors.identityHighlight,
                                ),
                              ),
                              Positioned(
                                top: layout.px(39),
                                left: 0,
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: AppColors.black,
                                      fontFamily: 'Helvetica',
                                      fontWeight: FontWeight.w700,
                                      height: 43 / 36,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: '₱',
                                        style: TextStyle(
                                          fontSize: layout.px(36),
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' 60,000',
                                        style: TextStyle(
                                          fontSize: layout.px(50),
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
                      Positioned(
                        right: 0,
                        child: Image.asset(
                          AppAssets.identityShieldIllustration,
                          width: layout.px(113),
                          height: layout.px(117),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: layout.px(7)),
                _buildTabs(layout),
                SizedBox(height: layout.px(7)),
                _buildOptions(layout, options),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(AppLayout layout) {
    return Container(
      key: const Key('identity-tabs'),
      width: layout.px(336),
      height: layout.px(40),
      padding: EdgeInsets.all(layout.px(3)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: layout.radius(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tab(layout, 'Recommended ID Type', !_showOtherOptions),
          ),
          Expanded(child: _tab(layout, 'Other Options', _showOtherOptions)),
        ],
      ),
    );
  }

  Widget _tab(AppLayout layout, String label, bool selected) {
    return GestureDetector(
      onTap: () => setState(() => _showOtherOptions = label == 'Other Options'),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : AppColors.white,
          borderRadius: layout.radius(20),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? AppColors.white : AppColors.identityUnselected,
            fontFamily: 'Helvetica',
            fontSize: layout.px(12),
            fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            height: 18 / 12,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(AppLayout layout, List<String> options) {
    return Container(
      key: const Key('identity-options-panel'),
      width: layout.px(355),
      height: layout.px(332),
      padding: EdgeInsets.fromLTRB(
        layout.px(27),
        layout.px(22),
        layout.px(27),
        layout.px(32),
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [AppColors.identityPanelEnd, AppColors.identityPanelStart],
        ),
        borderRadius: layout.radius(30),
      ),
      child: Column(
        children: [
          for (var index = 0; index < options.length; index++) ...[
            _option(layout, options[index]),
            if (index < options.length - 1) SizedBox(height: layout.px(7)),
          ],
        ],
      ),
    );
  }

  Widget _option(AppLayout layout, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(layout.px(10)),
          topRight: Radius.circular(layout.px(100)),
          bottomRight: Radius.circular(layout.px(100)),
          bottomLeft: Radius.circular(layout.px(10)),
        ),
        onTap: () => Navigator.of(context).pop(label),
        child: Container(
          width: layout.px(301),
          height: layout.px(50),
          padding: EdgeInsets.symmetric(horizontal: layout.px(8)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(layout.px(10)),
              topRight: Radius.circular(layout.px(100)),
              bottomRight: Radius.circular(layout.px(100)),
              bottomLeft: Radius.circular(layout.px(10)),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                AppAssets.identityDocumentIcon,
                width: layout.px(21),
                height: layout.px(19),
              ),
              SizedBox(width: layout.px(15)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.identityText,
                    fontFamily: 'Helvetica',
                    fontSize: layout.px(16),
                    height: 19 / 16,
                  ),
                ),
              ),
              Image.asset(
                AppAssets.identityOptionArrow,
                width: layout.px(20),
                height: layout.px(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
