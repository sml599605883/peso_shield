import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_deep_link.dart';

void main() {
  group('AppDeepLink order navigation', () {
    const parser = AppDeepLinkParser();

    test('parses order deep link without segregate parameter', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, isEmpty);
    });

    test('parses order deep link with segregate parameter for all orders', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes?segregate=4';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '4');
    });

    test('parses order deep link with segregate parameter for outstanding', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes?segregate=7';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '7');
    });

    test('parses order deep link with segregate parameter for overdue', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes?segregate=6';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '6');
    });

    test('parses order deep link with segregate parameter for settled', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes?segregate=5';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '5');
    });

    test('parses segregate from arguments when not in URL', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes';
      final link = parser.parse(target, arguments: {'segregate': '7'});

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '7');
    });

    test('prefers segregate from URL over arguments', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes?segregate=6';
      final link = parser.parse(target, arguments: {'segregate': '7'});

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '6');
    });

    test('handles whitespace in segregate parameter', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes?segregate= 7 ';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '7');
    });

    test('handles multiple query parameters', () {
      const target =
          'ph://peso-shield/ios/PermutesLinotypes?segregate=5&other=value';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, '5');
    });
  });
}
