import 'package:flutter_test/flutter_test.dart';
import 'package:peso_shield/core/navigation/app_deep_link.dart';

void main() {
  group('AppDeepLink push url', () {
    const parser = AppDeepLinkParser();

    test('parses push order url without segregate parameter', () {
      const target = 'ph://peso-shield/ios/PermutesLinotypes';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.order);
      expect(link.segregate, isEmpty);
      expect(link.rawTarget, target);
    });

    test('parses push order url with every documented order status', () {
      for (final segregate in ['4', '7', '6', '5']) {
        final link = parser.parse(
          'ph://peso-shield/ios/PermutesLinotypes?segregate=$segregate',
        );

        expect(link.kind, AppDeepLinkKind.order);
        expect(link.segregate, segregate);
      }
    });

    test('parses push admission url parameters', () {
      const target = 'ph://peso-shield/ios/Equisetum?bombarder=12&parliament=2';
      final link = parser.parse(target);

      expect(link.kind, AppDeepLinkKind.admission);
      expect(link.productId, '12');
      expect(link.apiRemind, '2');
    });

    test('keeps every http url in the web page', () {
      for (final target in const [
        'http://8.212.131.176/#/PermutesLinotypes?segregate=4',
        'https://8.212.131.176/#/Staining',
        'https://example.com/order/detail?id=1',
      ]) {
        final link = parser.parse(target);

        expect(link.kind, AppDeepLinkKind.webView);
        expect(link.rawTarget, target);
      }
    });
  });
}
