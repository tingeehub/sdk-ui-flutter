# Changelog

## 1.0.0-beta.1

- Cung cấp `TingeeBankLink.open` và widget `TingeeBankLinkView` cho luồng Liên kết Ngân hàng (Bank Link).
- Cung cấp `TingeeCheckout.open` và widget `TingeeCheckoutView` cho luồng Cổng Thanh toán (Payment Gateway Checkout).
- Tự động tiêm JS Bridge bắt sự kiện `postMessage` từ WebView và chuyển thành đối tượng `TingeeResult`.
- Tự động hỗ trợ mở ứng dụng ngân hàng qua Deep Link (`url_launcher`) trên Android & iOS.
