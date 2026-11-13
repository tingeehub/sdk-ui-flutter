import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Tạo [WebViewController] hỗ trợ camera (quét QR) và chọn ảnh từ thư viện (tải ảnh QR)
/// cho giao diện Tingee chạy trong WebView.
///
/// - iOS: cho phép phát video inline (preview camera) và tự phát không cần chạm.
///   Hộp thoại xin quyền camera do hệ thống hiển thị (cần `NSCameraUsageDescription`).
/// - Android: xin quyền `CAMERA` lúc chạy khi trang yêu cầu camera, và mở bộ chọn ảnh
///   cho `<input type="file">` (mặc định `webview_flutter` trên Android không mở được).
class TingeeWebViewMedia {
  TingeeWebViewMedia._();

  static WebViewController createController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: _handlePermissionRequest,
    );

    final platformController = controller.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setMediaPlaybackRequiresUserGesture(false);
      platformController.setOnShowFileSelector(_handleAndroidFileSelector);
    }

    return controller;
  }

  static Future<void> _handlePermissionRequest(WebViewPermissionRequest request) async {
    final types = request.types;
    final isCameraOnly = types.isNotEmpty && types.every((type) => type == WebViewPermissionResourceType.camera);
    if (!isCameraOnly) {
      // Giao diện Tingee chỉ dùng camera (không dùng micro)
      await request.deny();
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        await request.deny();
        return;
      }
    }

    await request.grant();
  }

  static Future<List<String>> _handleAndroidFileSelector(FileSelectorParams params) async {
    try {
      final picker = ImagePicker();
      final acceptsImage = params.acceptTypes.isEmpty ||
          params.acceptTypes.any((type) => type.isEmpty || type.startsWith('image/'));
      if (!acceptsImage) return <String>[];

      if (params.isCaptureEnabled) {
        final status = await Permission.camera.request();
        if (!status.isGranted) return <String>[];
      }

      final file = await picker.pickImage(
        source: params.isCaptureEnabled ? ImageSource.camera : ImageSource.gallery,
      );
      if (file == null) return <String>[];
      return <String>[Uri.file(file.path).toString()];
    } catch (e) {
      debugPrint('TingeeWebViewMedia: chọn ảnh thất bại: $e');
      return <String>[];
    }
  }
}
