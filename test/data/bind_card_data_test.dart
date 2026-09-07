import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/json/json.dart';
import 'package:peso_shield/data/models/bind_card_data.dart';

void main() {
  test('bind-card text field decodes the server suggestion value', () {
    final data = BindCardData.fromJson(
      Json({
        'fribbled': [
          {
            'stalagmitic': 'Cash Pickup',
            'bellings': 3,
            'fribbled': [
              {
                'stalagmitic': 'First Name',
                'coffees': 'firstName',
                'vacantness': 'First Name',
                'torsos': 'txt',
                'shmaltzy': 0,
                'biolysis': '',
                'tracheophyte': 'Anna',
                'forgets': 0,
              },
            ],
          },
        ],
      }),
    );

    final field = data.groups.single.fields.single;
    expect(field.control, BindCardFieldControl.text);
    expect(field.initialValue, isEmpty);
    expect(field.suggestedValue, 'Anna');
  });
}
