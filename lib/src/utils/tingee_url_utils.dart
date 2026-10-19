import 'dart:convert';
import '../models/tingee_models.dart';

/// Các hằng số Base URL và công cụ xử lý URL / JS Bridge cho Tingee Flutter SDK
class TingeeUrlUtils {
  static const String bankLinkProdUrl = 'https://bank-link.tingee.vn';
  static const String bankLinkUatUrl = 'https://uat-bank-link.tingee.vn';

  static const String checkoutProdUrl = 'https://pay.tingee.vn';
  static const String checkoutUatUrl = 'https://uat-pay.tingee.vn';

  /// Tên JavaScript channel dùng để giao tiếp từ WebView sang Flutter
  static const String jsChannelName = 'TingeeFlutterBridge';

  static String resolveBankLinkBaseUrl(
    TingeeEnvironment environment, [
    String? customBaseUrl,
  ]) {
    if (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) {
      return customBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return environment == TingeeEnvironment.uat
        ? bankLinkUatUrl
        : bankLinkProdUrl;
  }

  static String resolveCheckoutBaseUrl(
    TingeeEnvironment environment, [
    String? customBaseUrl,
  ]) {
    if (customBaseUrl != null && customBaseUrl.trim().isNotEmpty) {
      return customBaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    }
    return environment == TingeeEnvironment.uat
        ? checkoutUatUrl
        : checkoutProdUrl;
  }

  /// Chuẩn hóa và gắn tham số `mode`, `primaryColor`, `theme` vào URL
  static Uri buildEmbedUri({
    required String rawUrl,
    required String baseUrl,
    String mode = 'modal',
    TingeeThemeConfig? theme,
  }) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('[Tingee SDK] URL không được để trống.');
    }

    final fullUrl = RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)
        ? trimmed
        : '${baseUrl.replaceAll(RegExp(r'/+$'), '')}/${trimmed.replaceAll(RegExp(r'^/+'), '')}';

    final parsed = Uri.parse(fullUrl);
    if (parsed.scheme != 'http' && parsed.scheme != 'https') {
      throw ArgumentError('[Tingee SDK] Giao thức không hợp lệ: ${parsed.scheme}');
    }

    final queryParams = Map<String, String>.from(parsed.queryParameters);
    queryParams['mode'] = mode;

    if (theme != null) {
      if (theme.primaryColor != null && theme.primaryColor!.isNotEmpty) {
        queryParams['primaryColor'] = theme.primaryColor!;
      }
      final themeMap = theme.toJson();
      if (themeMap.isNotEmpty) {
        queryParams['theme'] = jsonEncode(themeMap);
      }
    }

    return parsed.replace(queryParameters: queryParams);
  }

  /// Kiểm tra xem URL có phải là Deep Link mở App Ngân hàng bên ngoài không
  static bool isExternalDeepLink(String url) {
    final trimmed = url.trim().toLowerCase();
    if (trimmed.isEmpty ||
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('about:') ||
        trimmed.startsWith('blob:') ||
        trimmed.startsWith('data:')) {
      return false;
    }
    return RegExp(r'^[a-z][a-z0-9+.-]*:').hasMatch(trimmed);
  }

  /// Giải mã chuỗi JSON gửi từ WebView Bridge thành [TingeeResult]
  static TingeeResult? parseBridgeMessage(String rawMessage) {
    final trimmed = rawMessage.trim();
    if (!trimmed.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;
      var map = Map<String, dynamic>.from(decoded);

      final msgType = map['type']?.toString();
      if ((msgType == 'TINGEE_BANK_LINK_RESULT' ||
              msgType == 'TINGEE_PAYMENT_RESULT') &&
          map['data'] is Map) {
        final innerMap = Map<String, dynamic>.from(map['data'] as Map);
        if (innerMap['action'] == 'account-config-register') {
          return null;
        }
        map = innerMap;
      }

      final rawStatus =
          (map['status'] ?? map['event'] ?? map['action'] ?? '').toString();
      if (rawStatus.isEmpty) return null;
      return TingeeResult.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  /// Đoạn mã JavaScript tự động tiêm vào WebView để bắt mọi sự kiện
  /// `window.parent.postMessage`, `window.opener.postMessage` và `window.postMessage`
  /// rồi chuyển thẳng về `TingeeFlutterBridge.postMessage(...)`.
  static const String webViewBridgeScript = '''
(function() {
  if (window.__tingeeFlutterBridgeInstalled) return;
  window.__tingeeFlutterBridgeInstalled = true;

  var lastPayload = '';
  var lastTime = 0;

  function replyTingeeConfig() {
    try {
      var params = new URLSearchParams(window.location.search);
      var rawTheme = params.get('theme');
      var parsedTheme = null;
      if (rawTheme) {
        try {
          parsedTheme = JSON.parse(rawTheme);
        } catch (e) {
          parsedTheme = rawTheme;
        }
      }
      window.postMessage({
        type: 'TINGEE_CONFIG',
        payload: {
          displayMode: 'mobile',
          isDesktopParent: false,
          isMobileParent: true,
          parentViewport: {
            width: window.innerWidth || 375,
            height: window.innerHeight || 812
          },
          immediateResult: false,
          isEmbedded: true,
          theme: parsedTheme
        }
      }, '*');
    } catch (e) {}
  }

  function forwardToFlutter(data) {
    try {
      if (!data) return;
      var parsed = typeof data === 'string' ? JSON.parse(data) : data;
      if (!parsed || typeof parsed !== 'object') return;

      if (parsed.type === 'TINGEE_READY') {
        replyTingeeConfig();
        return;
      }
      if (parsed.type === 'TINGEE_CONFIG') return;

      if (!parsed.status && !parsed.type && !parsed.action && !parsed.event) return;

      var serialized = JSON.stringify(parsed);
      var now = Date.now();
      if (serialized === lastPayload && now - lastTime < 300) return;
      lastPayload = serialized;
      lastTime = now;

      if (window.TingeeFlutterBridge && typeof window.TingeeFlutterBridge.postMessage === 'function') {
        window.TingeeFlutterBridge.postMessage(serialized);
      }
    } catch (err) {}
  }

  window.addEventListener('message', function(event) {
    if (event && event.data) {
      forwardToFlutter(event.data);
    }
  });

  try {
    var bridgeTarget = {
      postMessage: function(data) {
        forwardToFlutter(data);
      }
    };
    Object.defineProperty(window, 'parent', {
      get: function() { return bridgeTarget; },
      configurable: true
    });
    if (!window.opener) {
      Object.defineProperty(window, 'opener', {
        get: function() { return bridgeTarget; },
        configurable: true
      });
    }
  } catch (e) {}

  function disableIosInputZoom() {
    try {
      var doc = document;
      if (!doc || !doc.head) return;

      var viewportContent = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, shrink-to-fit=no';
      var meta = doc.querySelector('meta[name="viewport"]');
      if (meta) {
        if (meta.getAttribute('content') !== viewportContent) {
          meta.setAttribute('content', viewportContent);
        }
      } else {
        meta = doc.createElement('meta');
        meta.name = 'viewport';
        meta.content = viewportContent;
        doc.head.appendChild(meta);
      }

      if (!doc.getElementById('__tingee_ios_no_zoom_style')) {
        var style = doc.createElement('style');
        style.id = '__tingee_ios_no_zoom_style';
        style.innerHTML = 'input, select, textarea { font-size: 16px !important; -webkit-text-size-adjust: 100%; }';
        doc.head.appendChild(style);
      }
    } catch (e) {}
  }

  disableIosInputZoom();
  document.addEventListener('DOMContentLoaded', disableIosInputZoom);
  window.addEventListener('load', disableIosInputZoom);
  document.addEventListener('focusin', disableIosInputZoom, true);
  document.addEventListener('gesturestart', function(e) {
    e.preventDefault();
  }, { passive: false });
})();
''';
}
