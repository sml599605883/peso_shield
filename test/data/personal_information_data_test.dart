import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/certification_data.dart';

void main() {
  test(
    'personal information response renders and submits server field values',
    () {
      final data = PersonalInfoData.fromJson({
        'choired': [
          {
            'enterostomy': 'Education',
            'laggings': 'Please select education',
            'felicitous': 'education',
            'torsos': 'Stepped',
            'omegas': 0,
            'muscats': 0,
            'fyke': 'Undergraduate',
            'poolsides': [
              {'crocidolites': 'High School', 'sociologeses': 2},
              {'crocidolites': 'Undergraduate', 'sociologeses': 4},
            ],
          },
          {
            'enterostomy': 'Mobile number',
            'felicitous': 'mobile',
            'torsos': 'EmpathisedWombiest',
            'omegas': 1,
            'muscats': 1,
            'fyke': 9123456789,
          },
        ],
        'dextrorse': 'Complete your personal information.',
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

  test('personal information supports the response payload envelope', () {
    final data = PersonalInfoData.fromJson({
      'unsphered': {
        'choired': [
          {
            'enterostomy': 'Residential address',
            'felicitous': 'address',
            'torsos': 'Stage',
            'fyke': 'Manila',
          },
        ],
        'dextrorse': 'Address details are required.',
      },
    });

    expect(data.tips, 'Address details are required.');
    expect(data.fields.single.control, PersonalInformationControl.address);
    expect(data.fields.single.initialSubmitValue, 'Manila');
  });

  test('personal information supports nested protocol payloads', () {
    final data = PersonalInfoData.fromJson({
      'mugg': {
        'unsphered': {
          'choired': [
            {
              'enterostomy': 'Email address',
              'laggings': 'Enter your email',
              'felicitous': 'email',
              'torsos': 'EmpathisedWombiest',
              'fyke': 'person@example.com',
            },
          ],
          'dextrorse': 'Use a valid email address.',
        },
      },
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
        'choired': [
          {
            'stalagmitic': 'Employment type',
            'coffees': 'employmentType',
            'torsos': 'stepped',
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

  test('address data decodes the documented address response', () {
    final data = AddressData.fromJson({
      'mugg': {
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
      },
    });

    final region = data.nodes.single;
    final province = region.children.single;
    expect(region.label, 'Region One');
    expect(region.id, '1');
    expect(province.label, 'Province One');
    expect(province.id, 'p1');
    expect(province.children, isEmpty);
  });
}
