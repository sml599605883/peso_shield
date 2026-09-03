import 'package:flutter/material.dart';

import '../../data/models/certification_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/layout_adapter.dart';

enum _AddressLevel { region, province, municipality }

Future<String?> showPersonalInformationAddressSheet({
  required BuildContext context,
  required List<PersonalAddressNode> nodes,
  String initialValue = '',
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.personalInformationSelectionBarrier,
    isScrollControlled: true,
    builder: (_) => _PersonalInformationAddressSheet(
      nodes: nodes,
      initialValue: initialValue,
    ),
  );
}

class _PersonalInformationAddressSheet extends StatefulWidget {
  const _PersonalInformationAddressSheet({
    required this.nodes,
    required this.initialValue,
  });

  final List<PersonalAddressNode> nodes;
  final String initialValue;

  @override
  State<_PersonalInformationAddressSheet> createState() =>
      _PersonalInformationAddressSheetState();
}

class _PersonalInformationAddressSheetState
    extends State<_PersonalInformationAddressSheet> {
  PersonalAddressNode? _region;
  PersonalAddressNode? _province;
  PersonalAddressNode? _municipality;
  _AddressLevel _activeLevel = _AddressLevel.region;

  @override
  void initState() {
    super.initState();
    _restoreInitialValue();
  }

  List<PersonalAddressNode> get _options => switch (_activeLevel) {
    _AddressLevel.region => widget.nodes,
    _AddressLevel.province => _region?.children ?? const [],
    _AddressLevel.municipality => _province?.children ?? const [],
  };

  PersonalAddressNode? get _selectedNode => switch (_activeLevel) {
    _AddressLevel.region => _region,
    _AddressLevel.province => _province,
    _AddressLevel.municipality => _municipality,
  };

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        key: const Key('personalInformationAddressSheet'),
        width: double.infinity,
        height: layout.px(428) + bottomInset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(layout.px(30)),
            ),
          ),
          child: Padding(
            padding: layout
                .edgeInsets(left: 20, top: 22, right: 20, bottom: 20)
                .copyWith(bottom: layout.px(20) + bottomInset),
            child: Column(
              children: [
                _AddressSegments(
                  activeLevel: _activeLevel,
                  region: _region?.label ?? 'Region',
                  province: _province?.label ?? 'Province',
                  municipality: _municipality?.label ?? 'Municipality',
                  onSelected: _selectLevel,
                ),
                SizedBox(height: layout.px(22)),
                Expanded(
                  child: _AddressOptionList(
                    key: ValueKey('$_activeLevel-${_selectedNode?.id ?? ''}'),
                    options: _options,
                    selectedNode: _selectedNode,
                    onSelected: _selectNode,
                  ),
                ),
                SizedBox(height: layout.px(40)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: layout.px(167),
                      height: layout.px(48),
                      child: _AddressActionButton(
                        label: 'Cancel',
                        backgroundColor:
                            AppColors.personalInformationCancelButton,
                        foregroundColor:
                            AppColors.personalInformationCancelText,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SizedBox(
                      width: layout.px(158),
                      height: layout.px(48),
                      child: _AddressActionButton(
                        label: 'Done',
                        backgroundColor: AppColors.coral,
                        foregroundColor: AppColors.white,
                        emphasized: true,
                        onPressed: _completeSelection,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _restoreInitialValue() {
    final labels = widget.initialValue
        .split('-')
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) return;
    _region = _findByLabel(widget.nodes, labels[0]);
    if (_region == null || labels.length < 2) return;
    _province = _findByLabel(_region!.children, labels[1]);
    if (_province == null || labels.length < 3) {
      _activeLevel = _AddressLevel.province;
      return;
    }
    _municipality = _findByLabel(_province!.children, labels[2]);
    _activeLevel = _AddressLevel.municipality;
  }

  PersonalAddressNode? _findByLabel(
    List<PersonalAddressNode> nodes,
    String label,
  ) {
    for (final node in nodes) {
      if (node.label == label) return node;
    }
    return null;
  }

  void _selectLevel(_AddressLevel level) {
    if (level == _AddressLevel.province && _region == null) return;
    if (level == _AddressLevel.municipality && _province == null) return;
    setState(() {
      _activeLevel = level;
      switch (level) {
        case _AddressLevel.region:
          _province = null;
          _municipality = null;
        case _AddressLevel.province:
          _municipality = null;
        case _AddressLevel.municipality:
          break;
      }
    });
  }

  void _selectNode(PersonalAddressNode node) {
    switch (_activeLevel) {
      case _AddressLevel.region:
        setState(() {
          _region = node;
          _province = null;
          _municipality = null;
          _activeLevel = _AddressLevel.province;
        });
      case _AddressLevel.province:
        setState(() {
          _province = node;
          _municipality = null;
          _activeLevel = _AddressLevel.municipality;
        });
      case _AddressLevel.municipality:
        final region = _region;
        final province = _province;
        if (region == null || province == null) return;
        Navigator.of(context).pop('${region.label}-${province.label}-${node.label}');
    }
  }

  void _completeSelection() {
    final region = _region;
    final province = _province;
    final municipality = _municipality;
    if (region == null || province == null) return;
    final labels = [region.label, province.label];
    if (municipality != null) labels.add(municipality.label);
    Navigator.of(context).pop(labels.join('-'));
  }
}

class _AddressSegments extends StatelessWidget {
  const _AddressSegments({
    required this.activeLevel,
    required this.region,
    required this.province,
    required this.municipality,
    required this.onSelected,
  });

  final _AddressLevel activeLevel;
  final String region;
  final String province;
  final String municipality;
  final ValueChanged<_AddressLevel> onSelected;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Container(
      height: layout.px(36),
      margin: layout.edgeInsets(left: 8, right: 7),
      padding: layout.edgeInsets(left: 2, top: 2, right: 22, bottom: 2),
      decoration: BoxDecoration(
        color: AppColors.personalInformationAddressSegment,
        borderRadius: BorderRadius.circular(layout.px(18)),
      ),
      child: Row(
        children: [
          _AddressSegmentItem(
            label: region,
            active: activeLevel == _AddressLevel.region,
            onTap: () => onSelected(_AddressLevel.region),
          ),
          _AddressSegmentItem(
            label: province,
            active: activeLevel == _AddressLevel.province,
            onTap: () => onSelected(_AddressLevel.province),
          ),
          _AddressSegmentItem(
            label: municipality,
            active: activeLevel == _AddressLevel.municipality,
            onTap: () => onSelected(_AddressLevel.municipality),
          ),
        ],
      ),
    );
  }
}

class _AddressSegmentItem extends StatelessWidget {
  const _AddressSegmentItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(layout.px(18)),
        child: Container(
          height: layout.px(32),
          alignment: Alignment.center,
          decoration: active
              ? BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(layout.px(18)),
                )
              : null,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active
                  ? AppColors.white
                  : AppColors.personalInformationAddressInactive,
              fontFamily: active ? 'Helvetica-Bold' : 'Helvetica',
              fontSize: layout.px(12),
              fontWeight: active ? FontWeight.w700 : FontWeight.normal,
              height: 18 / 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressOptionList extends StatefulWidget {
  const _AddressOptionList({
    super.key,
    required this.options,
    required this.selectedNode,
    required this.onSelected,
  });

  final List<PersonalAddressNode> options;
  final PersonalAddressNode? selectedNode;
  final ValueChanged<PersonalAddressNode> onSelected;

  @override
  State<_AddressOptionList> createState() => _AddressOptionListState();
}

class _AddressOptionListState extends State<_AddressOptionList> {
  late int _selectedIndex;
  late final FixedExtentScrollController _controller;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _initialIndex();
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    
    if (widget.options.isEmpty) {
      return Center(
        child: Text(
          'No options available',
          style: TextStyle(
            color: AppColors.loginHint,
            fontSize: layout.px(16),
          ),
        ),
      );
    }

    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: layout.px(52),
      diameterRatio: 1000,
      perspective: 0.003,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => setState(() => _selectedIndex = index),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.options.length,
        builder: (context, index) {
          final node = widget.options[index];
          final distance = (index - _selectedIndex).abs();
          final selected = distance == 0;
          return InkWell(
            onTap: () => widget.onSelected(node),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: selected
                    ? Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.identityUploadDivider,
                          width: layout.px(1),
                        ),
                      )
                    : null,
              ),
              child: Center(
                child: Padding(
                  padding: layout.edgeInsets(left: 24, right: 24),
                  child: Text(
                    node.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.identityText
                          : distance == 1
                              ? AppColors.personalInformationLabel
                              : AppColors.loginHint,
                      fontFamily: selected ? 'Helvetica-Bold' : 'Helvetica',
                      fontSize: layout.px(18),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      height: 22 / 18,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _initialIndex() {
    final selected = widget.selectedNode;
    if (selected == null) return 0;
    final index = widget.options.indexWhere((node) => node.id == selected.id);
    return index < 0 ? 0 : index;
  }
}

class _AddressActionButton extends StatelessWidget {
  const _AddressActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
    this.emphasized = false,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(layout.px(24)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: emphasized ? 'Helvetica-Bold' : 'Helvetica',
          fontSize: layout.px(18),
          fontWeight: emphasized ? FontWeight.w700 : FontWeight.normal,
          height: 22 / 18,
        ),
      ),
    );
  }
}
