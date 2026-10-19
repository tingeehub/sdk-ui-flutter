import 'package:flutter_test/flutter_test.dart';
import 'package:tingee_sdk_ui/tingee_sdk_ui.dart';

void main() {
  group('TingeeUrlUtils & TingeeResult tests', () {
    test('resolves Bank Link and Checkout base URLs for prod and uat', () {
      expect(
        TingeeUrlUtils.resolveBankLinkBaseUrl(TingeeEnvironment.prod),
        'https://bank-link.tingee.vn',
      );
      expect(
        TingeeUrlUtils.resolveBankLinkBaseUrl(TingeeEnvironment.uat),
        'https://uat-bank-link.tingee.vn',
      );
      expect(
        TingeeUrlUtils.resolveCheckoutBaseUrl(TingeeEnvironment.prod),
        'https://pay.tingee.vn',
      );
      expect(
        TingeeUrlUtils.resolveCheckoutBaseUrl(TingeeEnvironment.uat),
        'https://uat-pay.tingee.vn',
      );
    });

    test('builds embed URI with mode and theme primaryColor', () {
      final uri = TingeeUrlUtils.buildEmbedUri(
        rawUrl: 'https://bank-link.tingee.vn?token=xyz987',
        baseUrl: 'https://bank-link.tingee.vn',
        mode: 'modal',
        theme: const TingeeThemeConfig(primaryColor: '#1E88E5'),
      );

      expect(uri.queryParameters['token'], 'xyz987');
      expect(uri.queryParameters['mode'], 'modal');
      expect(uri.queryParameters['primaryColor'], '#1E88E5');
    });

    test('detects banking app deep links accurately', () {
      expect(
        TingeeUrlUtils.isExternalDeepLink('https://bank-link.tingee.vn?token=1'),
        isFalse,
      );
      expect(
        TingeeUrlUtils.isExternalDeepLink('bidvsmartbanking://pay?qr=123'),
        isTrue,
      );
      expect(
        TingeeUrlUtils.isExternalDeepLink('vcbdigibank://open'),
        isTrue,
      );
    });

    test('parses bridge JSON message into TingeeResult', () {
      const jsonStr =
          '{"status":"success","bankName":"BIDV","vaAccountNumber":"123456789","shopId":88}';
      final result = TingeeUrlUtils.parseBridgeMessage(jsonStr);

      expect(result, isNotNull);
      expect(result!.isSuccess, isTrue);
      expect(result.bankName, 'BIDV');
      expect(result.vaAccountNumber, '123456789');
      expect(result.shopId, 88);
    });
  });
}
