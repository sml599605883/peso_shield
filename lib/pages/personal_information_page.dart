import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/models/certification_data.dart' as model;
import '../providers/repository_provider.dart';
import '../theme/app_assets.dart';
import '../core/navigation/app_navigator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalInformationPage extends ConsumerStatefulWidget {
  const PersonalInformationPage({super.key, required this.productId});
  final String productId;
  @override
  ConsumerState<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState
    extends ConsumerState<PersonalInformationPage> {
  model.PersonalInfoData? _data;
  final _values = <String, String>{};
  final _controllers = <String, TextEditingController>{};
  bool _loading = true, _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final repo = await ref.read(certificationRepositoryProvider.future);
      final response = await repo.getPersonalInfo(productId: widget.productId);
      if (!response.isSuccess) throw Exception(response.message);
      setState(() {
        _data = response.data;
        _loading = false;
      });
      for (final field in response.data.fields) {
        _values[field.key] = field.defaultValue;
        _controllers[field.key] = TextEditingController(
          text: field.defaultValue,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Unable to load information';
        });
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final List<model.FormField> fields = _data?.fields ?? const [];
    for (final f in fields) {
      if (f.isRequired && (_values[f.key] ?? '').trim().isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please enter ${f.title}')));
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      final repo = await ref.read(certificationRepositoryProvider.future);
      final response = await repo.savePersonalInfo(
        productId: widget.productId,
        formData: _values,
      );
      if (!response.isSuccess) throw Exception(response.message);
      if (mounted) {
        AppNavigator.pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submission failed, please try again')),
        );
      }
    }
    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<model.FormField> fields = _data?.fields ?? const [];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 221,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff9fd5fb), Color(0xffefffff)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 20,
                      top: 18,
                      child: IconButton(
                        key: const Key('personalInformationBack'),
                        icon: Image.asset(
                          AppAssets.personalInformationBack,
                          width: 24,
                        ),
                        onPressed: () => AppNavigator.pop(),
                      ),
                    ),
                    const Positioned(
                      top: 45,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'Personal information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 21,
                      top: 130,
                      child: SizedBox(
                        width: 220,
                        child: Text(
                          _data?.tips.isNotEmpty == true
                              ? _data!.tips
                              : 'Step 1 to fast cash! Upload ID for the express approval channel.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            color: Color(0xff32636e),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      top: 88,
                      child: Image.asset(
                        AppAssets.identityShieldIllustration,
                        width: 120,
                        height: 125,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                      ? Center(child: Text(_error!))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: const LinearProgressIndicator(
                                value: .25,
                                minHeight: 14,
                                backgroundColor: Color(0xffe8eeef),
                                valueColor: AlwaysStoppedAnimation(
                                  Color(0xffffc56f),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...fields.map(_field),
                            const SizedBox(height: 30),
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _submitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xff6ad1ff),
                                  shape: const StadiumBorder(),
                                ),
                                child: _submitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        'Submit',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
    );
  }

  Widget _field(model.FormField field) {
    final selectable =
        field.options.isNotEmpty || field.type.toLowerCase().contains('select');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            field.title,
            style: const TextStyle(color: Color(0xff999999), fontSize: 14),
          ),
          const SizedBox(height: 7),
          GestureDetector(
            onTap: selectable ? () => _pick(field) : null,
            child: AbsorbPointer(
              absorbing: selectable,
              child: TextField(
                controller: _controllers[field.key],
                keyboardType: field.isNumeric
                    ? TextInputType.phone
                    : TextInputType.text,
                inputFormatters: field.maxLength > 0
                    ? [LengthLimitingTextInputFormatter(field.maxLength)]
                    : null,
                onChanged: (v) => _values[field.key] = v,
                decoration: InputDecoration(
                  hintText: field.placeholder,
                  suffixIcon: selectable
                      ? const Icon(
                          Icons.arrow_forward,
                          color: Color(0xffdddddd),
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xffeceded)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Color(0xffeceded)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(model.FormField field) async {
    final chosen = await showModalBottomSheet<model.FieldOption>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          children: field.options
              .map(
                (o) => ListTile(
                  title: Text(o.name),
                  onTap: () => Navigator.pop(context, o),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (chosen != null) {
      setState(() {
        _values[field.key] = chosen.value;
        _controllers[field.key]!.text = chosen.name;
      });
    }
  }
}
