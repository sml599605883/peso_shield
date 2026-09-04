import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/certification_data.dart';

void main() {
  test(
    'personal information response renders and submits server field values',
    () {
      final data = PersonalInfoData.fromJson({
        'fribbled': [
          {
            'stalagmitic': 'Education',
            'vacantness': 'Please select education',
            'coffees': 'education',
            'torsos': 'Superorganisms',
            'forgets': 0,
            'shmaltzy': 0,
            'biolysis': 'Undergraduate',
            'deportment': [
              {'cymenes': 'High School', 'bellings': 2},
              {'cymenes': 'Undergraduate', 'bellings': 4},
            ],
          },
          {
            'stalagmitic': 'Mobile number',
            'coffees': 'mobile',
            'torsos': 'EmpathisedWombiest',
            'forgets': 1,
            'shmaltzy': 1,
            'biolysis': 9123456789,
          },
        ],
        'properdins': 'Complete your personal information.',
      });

      expect(data.tips, 'Complete your personal information.');
      expect(data.fields, hasLength(2));
      expect(data.fields.first.control, PersonalInformationControl.selection);
      expect(data.fields.first.initialDisplayValue, 'Undergraduate');
      expect(data.fields.first.initialSubmitValue, '4');
      expect(data.fields.first.key, 'education');
      expect(data.fields.last.control, PersonalInformationControl.text);
      expect(data.fields.last.controlType, 'EmpathisedWombiest');
      expect(data.fields.last.isNumeric, isTrue);
      expect(data.fields.last.initialDisplayValue, '9123456789');
    },
  );

  test('personal information decodes the documented address field', () {
    final data = PersonalInfoData.fromJson({
      'fribbled': [
        {
          'stalagmitic': 'Residential address',
          'coffees': 'address',
          'torsos': 'Browbeat',
          'biolysis': 'Manila',
        },
      ],
      'properdins': 'Address details are required.',
    });

    expect(data.tips, 'Address details are required.');
    expect(data.fields.single.control, PersonalInformationControl.address);
    expect(data.fields.single.initialSubmitValue, 'Manila');
  });

  test('personal information decodes the documented text field', () {
    final data = PersonalInfoData.fromJson({
      'fribbled': [
        {
          'stalagmitic': 'Email address',
          'vacantness': 'Enter your email',
          'coffees': 'email',
          'torsos': 'EmpathisedWombiest',
          'biolysis': 'person@example.com',
        },
      ],
      'properdins': 'Use a valid email address.',
    });

    expect(data.tips, 'Use a valid email address.');
    expect(data.fields.single.title, 'Email address');
    expect(data.fields.single.placeholder, 'Enter your email');
    expect(data.fields.single.initialDisplayValue, 'person@example.com');
  });

  test(
    'personal information option supports its optional selection sheet data',
    () {
      final data = PersonalInfoData.fromJson({
        'fribbled': [
          {
            'stalagmitic': 'Employment type',
            'coffees': 'employmentType',
            'torsos': 'Superorganisms',
            'deportment': [
              {
                'cymenes': 'Salaried',
                'bellings': 'salaried',
                'leachate': 'https://example.com/logo.png',
                'barghests': 1,
              },
            ],
          },
        ],
      });

      final option = data.fields.single.options.single;
      expect(option.logoUrl, 'https://example.com/logo.png');
      expect(option.showsHint, isTrue);
      expect(option.hint, isEmpty);
    },
  );

  test('work information decodes text fields and nested payday selections', () {
    final data = WorkInfoData.fromJson({
      'fribbled': [
        {
          'stalagmitic': 'Company name',
          'vacantness': 'Enter company name',
          'coffees': 'companyName',
          'torsos': 'EmpathisedWombiest',
          'biolysis': 'Peso Shield',
        },
        {
          'stalagmitic': 'Monthly income',
          'vacantness': 'Enter monthly income',
          'coffees': 'monthlyIncome',
          'torsos': 'EmpathisedWombiest',
          'forgets': 1,
        },
        {
          'stalagmitic': 'Payday',
          'coffees': 'opportunities',
          'torsos': 'Superorganisms',
          'biolysis': 'Once a Month|1',
          'deportment': [
            {
              'cymenes': 'Once a Month',
              'bellings': 'monthly',
              'deportment': [
                {'cymenes': '1', 'bellings': 11},
                {'cymenes': '2', 'bellings': 12},
              ],
            },
          ],
        },
      ],
      'properdins': 'Complete your work information.',
    });

    expect(data.tips, 'Complete your work information.');
    expect(data.fields, hasLength(3));
    expect(data.fields.first.control, PersonalInformationControl.text);
    expect(data.fields.first.initialSubmitValue, 'Peso Shield');
    expect(data.fields[1].isNumeric, isTrue);

    final payday = data.fields.last;
    expect(payday.title, 'Payday');
    expect(payday.options.single.children, hasLength(2));
    expect(payday.initialDisplayValue, 'Once a Month|1');
    expect(payday.initialSubmitValue, '11');
  });

  test('address data decodes the documented address response', () {
    final data = AddressData.fromJson({
      'applicants': [
        {
          'ventral': 1,
          'cymenes': 'Region One',
          'applicants': [
            {
              'ventral': 'p1',
              'hardtacks': '0001',
              'cymenes': 'Province One',
              'applicants': [],
            },
          ],
        },
      ],
    });

    final region = data.nodes.single;
    final province = region.children.single;
    expect(region.label, 'Region One');
    expect(region.id, '1');
    expect(province.label, 'Province One');
    expect(province.id, 'p1');
    expect(province.children, isEmpty);
  });

  test('personal information ignores undocumented control values', () {
    final data = PersonalInfoData.fromJson({
      'fribbled': [
        {
          'stalagmitic': 'Undocumented field',
          'coffees': 'undocumented',
          'torsos': 'UndocumentedControl',
        },
      ],
    });

    expect(data.fields.single.control, PersonalInformationControl.unsupported);
  });
}
