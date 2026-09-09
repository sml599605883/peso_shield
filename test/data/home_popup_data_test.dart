import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/home_popup_data.dart';

void main() {
  test('parses documented no-popup and unknown types', () {
    expect(
      HomePopupData.fromJson({'bellings': 0, 'abysmal': null}).shouldShow,
      false,
    );
    expect(HomePopupData.fromJson({'bellings': 99}).shouldShow, false);
  });
  test('parses upgrade and marketing fields', () {
    final upgrade = HomePopupData.fromJson({
      'bellings': 1,
      'abysmal': {
        'woodhen': '2.0',
        'knucklers': 'Please update',
        'mycelia': 'https://example.com/update',
      },
    });
    expect(upgrade.type, HomePopupType.appUpgrade);
    expect(upgrade.version, '2.0');
    expect(upgrade.message, 'Please update');
    expect(upgrade.targetUrl, 'https://example.com/update');
    final marketing = HomePopupData.fromJson({
      'bellings': '3',
      'abysmal': {
        'rapaciousnesses': 'https://example.com/popup.png',
        'mycelia': 'https://example.com/offer',
      },
    });
    expect(marketing.imageUrl, 'https://example.com/popup.png');
    expect(marketing.shouldShow, true);
  });
  test('parses membership and tolerates malformed optional content', () {
    final popup = HomePopupData.fromJson({
      'bellings': 2,
      'abysmal': {
        'atabal': {'cymenes': 'Level I'},
        'riprap': {
          'cymenes': 'Level II',
          'week': 'https://example.com/level.png',
        },
        'acequias': [
          {'properdins': 'Increase loan amount'},
          null,
        ],
      },
    });
    expect(popup.previousLevel, 'Level I');
    expect(popup.currentLevel, 'Level II');
    expect(popup.benefits, ['Increase loan amount']);
    expect(popup.shouldShow, true);
    expect(
      HomePopupData.fromJson({'bellings': 3, 'abysmal': []}).shouldShow,
      false,
    );
  });
}
