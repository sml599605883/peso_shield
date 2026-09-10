import 'package:flutter/material.dart';

import '../data/models/certification_data.dart';
import '../theme/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/layout_adapter.dart';
import '../widgets/app_back_button.dart';
import 'mine/widgets/service_title.dart';

sealed class AccountListResult {
  const AccountListResult();
}

class AccountListSelection extends AccountListResult {
  const AccountListSelection(this.bindId);

  final String bindId;
}

class AccountListAddPaymentMethod extends AccountListResult {
  const AccountListAddPaymentMethod();
}

class AccountListPage extends StatefulWidget {
  const AccountListPage({super.key, required this.groups});

  final List<BankAccountGroup> groups;

  @override
  State<AccountListPage> createState() => _AccountListPageState();
}

class _AccountListPageState extends State<AccountListPage> {
  late String _selectedId;

  @override
  void initState() {
    super.initState();
    final accounts = widget.groups.expand((group) => group.accounts).toList();
    if (accounts.isEmpty) {
      _selectedId = '';
      return;
    }
    _selectedId = accounts
        .firstWhere((account) => account.isMain, orElse: () => accounts.first)
        .id;
  }

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: layout.edgeInsets(top: 32, bottom: 20),
                child: Column(
                  children: [
                    Padding(
                      padding: layout.edgeInsets(left: 20, right: 20),
                      child: const _PageHeader(),
                    ),
                    SizedBox(height: layout.px(21)),
                    for (
                      var index = 0;
                      index < widget.groups.length;
                      index++
                    ) ...[
                      MineServiceTitle(title: widget.groups[index].title),
                      Padding(
                        padding: layout.edgeInsets(left: 20, right: 20),
                        child: Column(
                          children: [
                            for (final account in widget.groups[index].accounts)
                              Padding(
                                padding: layout.edgeInsets(bottom: 10),
                                child: _AccountCard(
                                  account: account,
                                  groupTitle: widget.groups[index].title,
                                  selected: account.id == _selectedId,
                                  onTap: () =>
                                      setState(() => _selectedId = account.id),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (index != widget.groups.length - 1)
                        SizedBox(height: layout.px(5)),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: layout.edgeInsets(top: 9, bottom: 20),
              child: Column(
                children: [
                  Padding(
                    padding: layout.edgeInsets(left: 34, right: 34),
                    child: GestureDetector(
                      key: const Key('account-list-add'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.pop(
                        context,
                        const AccountListAddPaymentMethod(),
                      ),
                      child: Image.asset(
                        AppAssets.accountAddPaymentMethod,
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                  SizedBox(height: layout.px(28)),
                  Padding(
                    padding: layout.edgeInsets(left: 57, right: 57),
                    child: SizedBox(
                      width: double.infinity,
                      height: layout.px(50),
                      child: FilledButton(
                        key: const Key('account-list-submit'),
                        onPressed: _selectedId.isEmpty
                            ? null
                            : () => Navigator.pop(
                                context,
                                AccountListSelection(_selectedId),
                              ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          disabledBackgroundColor: AppColors.coral,
                          shape: RoundedRectangleBorder(
                            borderRadius: layout.radius(25),
                          ),
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: layout.px(18),
                            fontWeight: FontWeight.w700,
                            height: 22 / 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return SizedBox(
      height: layout.px(24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(alignment: Alignment.centerLeft, child: AppBackButton()),
          Text(
            'Loan Application',
            style: TextStyle(
              color: AppColors.black,
              fontSize: layout.px(20),
              fontWeight: FontWeight.w700,
              height: 24 / 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.account,
    required this.groupTitle,
    required this.selected,
    required this.onTap,
  });

  final BankAccount account;
  final String groupTitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    final cashPickup = groupTitle.toLowerCase().contains('cash');
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        key: Key('account-${account.id}'),
        onTap: onTap,
        borderRadius: layout.radius(20),
        child: Container(
          height: layout.px(account.available ? 127 : 152),
          padding: layout.edgeInsets(left: 14, top: 13, right: 14, bottom: 14),
          decoration: BoxDecoration(
            borderRadius: layout.radius(20),
            image: const DecorationImage(
              image: AssetImage(AppAssets.accountCardBackground),
              fit: BoxFit.fill,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (account.logoUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: layout.radius(8),
                      child: Image.network(
                        account.logoUrl,
                        width: layout.px(30),
                        height: layout.px(30),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            SizedBox.square(dimension: layout.px(30)),
                      ),
                    ),
                    SizedBox(width: layout.px(15)),
                  ],
                  Expanded(
                    child: Text(
                      account.bankName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: layout.px(14),
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  Image.asset(
                    selected
                        ? AppAssets.accountSelected
                        : AppAssets.accountUnselected,
                    width: layout.px(20),
                    height: layout.px(20),
                  ),
                ],
              ),
              if (!account.available) ...[
                SizedBox(height: layout.px(4)),
                Text(
                  account.maintenanceMessage.isNotEmpty
                      ? account.maintenanceMessage
                      : 'The bank is under maintenance. Loans may be delayed. '
                          'Please wait or choose another option',
                  maxLines: 2,
                  style: TextStyle(
                    color: AppColors.accountMaintenance,
                    fontSize: layout.px(10),
                    fontWeight: FontWeight.w400,
                    height: 12 / 10,
                  ),
                ),
              ],
              SizedBox(height: layout.px(account.available ? 10 : 7)),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: cashPickup
                      ? layout.edgeInsets(left: 15, right: 15)
                      : layout.edgeInsets(left: 15, top: 7),
                  decoration: BoxDecoration(
                    color: AppColors.paleBlue,
                    borderRadius: layout.radius(15),
                    border: Border.all(color: AppColors.white),
                  ),
                  child: cashPickup
                      ? _NameFields(account: account)
                      : _AccountNumber(value: account.accountNumber),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountNumber extends StatelessWidget {
  const _AccountNumber({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Receipt Account',
          style: TextStyle(
            color: AppColors.accountSecondaryText,
            fontSize: layout.px(12),
            height: 14 / 12,
          ),
        ),
        SizedBox(height: layout.px(7)),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.black,
            fontSize: layout.px(20),
            fontWeight: FontWeight.w700,
            height: 24 / 20,
          ),
        ),
      ],
    );
  }
}

class _NameFields extends StatelessWidget {
  const _NameFields({required this.account});

  final BankAccount account;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NameField(label: 'First Name', value: account.firstName),
        _NameField(label: 'Middle Name', value: account.middleName),
        _NameField(label: 'Last Name', value: account.lastName),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: AppColors.accountSecondaryText,
              fontSize: layout.px(12),
              height: 18 / 12,
            ),
          ),
          SizedBox(height: layout.px(7)),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.black,
              fontSize: layout.px(20),
              fontWeight: FontWeight.w700,
              height: 18 / 20,
            ),
          ),
        ],
      ),
    );
  }
}
