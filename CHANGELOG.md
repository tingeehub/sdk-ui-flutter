# Changelog

## 1.1.0

- `TingeeBankLinkView` / `TingeeBankLink.open` hỗ trợ quét QR bằng camera và tải ảnh QR từ thư viện trong WebView:
  - Android: xin quyền `CAMERA` lúc chạy khi trang yêu cầu camera, mở bộ chọn ảnh cho `<input type="file">`, cho phép phát video không cần chạm.
  - iOS: bật `allowsInlineMediaPlayback`, phát video không cần chạm, cấp quyền camera cho WebView.
- Thêm phụ thuộc `webview_flutter_android`, `webview_flutter_wkwebview`, `image_picker`, `permission_handler`.
- Nếu sử dụng tính năng quét QR, ứng dụng tích hợp cần khai báo quyền camera / thư viện ảnh (tùy chọn, không dùng quét QR thì không cần) — xem mục "Khai báo quyền Camera & Thư viện ảnh" trong README.

## 1.0.0

Bản phát hành chính thức (stable) đầu tiên.

- `TingeeThemeConfig` hỗ trợ thêm `primaryHoverColor`, `primarySoftColor`, `customCss` và `cssVariables` (biến CSS tùy ý dạng `'--*'`).
- Thêm tham số `customCss`: tiêm CSS tùy chỉnh sâu (`<style>`) vào WebView.
- Thêm tham số `injectedJavaScript`: thực thi JavaScript tùy chỉnh trong WebView sau khi tải trang.
- Áp dụng cho `TingeeBankLink.open`, `TingeeCheckout.open`, `TingeeBankLinkView` và `TingeeCheckoutView`.
- Thêm hàm tiện ích `TingeeUrlUtils.buildWebViewBridgeScript`.

## 1.0.0-beta.1

- Cung cấp `TingeeBankLink.open` và widget `TingeeBankLinkView` cho luồng Liên kết Ngân hàng (Bank Link).
- Cung cấp `TingeeCheckout.open` và widget `TingeeCheckoutView` cho luồng Cổng Thanh toán (Payment Gateway Checkout).
- Tự động tiêm JS Bridge bắt sự kiện `postMessage` từ WebView và chuyển thành đối tượng `TingeeResult`.
- Tự động hỗ trợ mở ứng dụng ngân hàng qua Deep Link (`url_launcher`) trên Android & iOS.
