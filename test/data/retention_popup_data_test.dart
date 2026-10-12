import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/data/models/retention_popup_data.dart';

void main() {
  test('parses documented text + illustration response', () {
    final data = RetentionPopupData.fromJson({
      'abysmal': {
        'stalagmitic': 'Please wait, it only takes ',
        'closets': ' for you to complete all certifications and get a loan!',
        'desalting': 2000,
        'tallyhoing': 'Continue',
        'nonconventional': 'Exit',
        'mycelia': 'http://host/img/a.png',
      },
    });
    expect(data.shouldShow, true);
    expect(data.confirmText, 'Continue');
    expect(data.cancelText, 'Exit');
    expect(data.imageUrl, 'http://host/img/a.png');
  });

  test('shows popup when server sends only an illustration', () {
    // 工作信息/人脸等类型服务端下发的标题与正文为空，仅带插画。
    final work = RetentionPopupData.fromJson({
      'abysmal': {
        'stalagmitic': '',
        'closets': '',
        'desalting': 0,
        'tallyhoing': 'Continue',
        'nonconventional': 'Exit',
        'mycelia': 'http://host/img/d.png',
      },
    });
    expect(work.title, '');
    expect(work.message, '');
    expect(work.shouldShow, true);
  });

  test('does not show popup without an illustration', () {
    expect(RetentionPopupData.fromJson({'abysmal': null}).shouldShow, false);
    expect(RetentionPopupData.fromJson(const {}).shouldShow, false);
    expect(
      RetentionPopupData.fromJson({
        'abysmal': {'stalagmitic': 'Title', 'closets': 'Body'},
      }).shouldShow,
      false,
    );
  });
}
