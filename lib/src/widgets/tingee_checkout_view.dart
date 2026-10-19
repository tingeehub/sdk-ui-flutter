import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/tingee_models.dart';
import '../utils/tingee_url_utils.dart';

/// Widget nhúng trực tiếp giao diện Cổng Thanh toán (Tingee Payment Gateway Checkout) vào màn hình Flutter
class TingeeCheckoutView extends StatefulWidget {
  /// Đường dẫn `checkoutUrl` nhận từ API Backend tạo link thanh toán
  final String url;

  /// Môi trường tích hợp (`prod` hoặc `uat`). Mặc định: `TingeeEnvironment.prod`
  final TingeeEnvironment environment;

  /// Base URL tùy chỉnh (nếu không dùng mặc định theo `environment`)
  final String? baseUrl;

  /// Cấu hình màu sắc chủ đạo của giao diện
  final TingeeThemeConfig? theme;

  /// Chế độ hiển thị (`'embed'` hoặc `'modal'`). Mặc định: `'embed'`
  final String mode;

  /// Tự động mở ứng dụng ngân hàng qua Deep Link. Mặc định: `true`
  final bool enableDeepLink;

  /// Hiển thị vòng xoay loading khi đang tải trang. Mặc định: `true`
  final bool showLoading;

  /// Callback khi thanh toán thành công
  final ValueChanged<TingeeResult>? onSuccess;

  /// Callback khi thanh toán thất bại hoặc hết hạn
  final ValueChanged<TingeeResult>? onFailed;

  /// Callback khi người dùng đóng / hủy thanh toán
  final ValueChanged<TingeeResult>? onCancelled;

  /// Callback tổng nhận mọi kết quả trả về (`success`, `failed`, `cancelled`, `error`)
  final ValueChanged<TingeeResult>? onResult;

  const TingeeCheckoutView({
    super.key,
    required this.url,
    this.environment = TingeeEnvironment.prod,
    this.baseUrl,
    this.theme,
    this.mode = 'embed',
    this.enableDeepLink = true,
    this.showLoading = true,
    this.onSuccess,
    this.onFailed,
    this.onCancelled,
    this.onResult,
  });

  @override
  State<TingeeCheckoutView> createState() => _TingeeCheckoutViewState();
}

class _TingeeCheckoutViewState extends State<TingeeCheckoutView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _resultHandled = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final resolvedBase = TingeeUrlUtils.resolveCheckoutBaseUrl(
      widget.environment,
      widget.baseUrl,
    );

    final targetUri = TingeeUrlUtils.buildEmbedUri(
      rawUrl: widget.url,
      baseUrl: resolvedBase,
      mode: widget.mode,
      theme: widget.theme,
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(false)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        TingeeUrlUtils.jsChannelName,
        onMessageReceived: (JavaScriptMessage message) {
          _handleBridgeMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
            _controller.runJavaScript(TingeeUrlUtils.webViewBridgeScript);
          },
          onPageFinished: (_) {
            _controller.runJavaScript(TingeeUrlUtils.webViewBridgeScript);
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onNavigationRequest: (NavigationRequest request) async {
            if (widget.enableDeepLink &&
                TingeeUrlUtils.isExternalDeepLink(request.url)) {
              final uri = Uri.tryParse(request.url);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(targetUri);
  }

  void _handleBridgeMessage(String rawMessage) {
    if (_resultHandled) return;
    final result = TingeeUrlUtils.parseBridgeMessage(rawMessage);
    if (result == null) return;

    _resultHandled = true;
    widget.onResult?.call(result);

    if (result.isSuccess) {
      widget.onSuccess?.call(result);
    } else if (result.isFailed) {
      widget.onFailed?.call(result);
    } else if (result.isCancelled) {
      widget.onCancelled?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (widget.showLoading && _isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
