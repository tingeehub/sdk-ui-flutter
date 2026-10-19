# tingee_sdk_ui

Bộ thư viện **Tingee UI SDK** chính thức dành cho **Flutter (Android & iOS)** — giúp đối tác tích hợp nhanh giao diện **Liên kết ngân hàng (Bank Link)** và **Cổng thanh toán (Payment Gateway Checkout)** của Tingee ngay trong ứng dụng di động.

📖 **Tài liệu đầy đủ:** [developers.tingee.vn](https://developers.tingee.vn)

---

## Cài đặt

Thêm `tingee_sdk_ui` vào `pubspec.yaml`:

```yaml
dependencies:
  tingee_sdk_ui: ^1.0.0
```

Hoặc chạy lệnh:

```bash
flutter pub add tingee_sdk_ui
```

---

## Tính năng nổi bật

- **Hỗ trợ cả 2 dịch vụ**: Liên kết ngân hàng (`TingeeBankLink.open`, `TingeeBankLinkView`) và Cổng thanh toán (`TingeeCheckout.open`, `TingeeCheckoutView`).
- **Tự động kết nối JS Bridge**: Tự động bắt sự kiện `postMessage` từ giao diện Tingee Web và trả về `Future<TingeeResult>` hoặc các callback `onSuccess`, `onFailed`, `onCancelled`.
- **Tự động hỗ trợ Deep Link App Ngân hàng**: Tự động chuyển hướng mở ứng dụng ngân hàng (`bidvsmartbanking://`, `vcbdigibank://`, `intent://`, `vietqr://`, ...) qua `url_launcher`.

---

## 1. Tích hợp Liên kết Ngân hàng (Bank Link)

Trước khi mở giao diện trên Mobile App, Backend của bạn cần gọi API [Tạo phiên liên kết (`/v1/create-bank-link-session`)](https://developers.tingee.vn/docs/bank-link/create-session) để lấy đường dẫn `url`.

### 1.1. Mở dạng Modal Bottom Sheet (`TingeeBankLink.open`)

```dart
import 'package:flutter/material.dart';
import 'package:tingee_sdk_ui/tingee_sdk_ui.dart';

class BankLinkPage extends StatelessWidget {
  const BankLinkPage({super.key});

  Future<void> _startBankLink(BuildContext context) async {
    // 1. Gọi API Backend của bạn để lấy session URL
    const sessionUrl = 'https://bank-link.tingee.vn?token=...';

    // 2. Mở Modal Liên kết Ngân hàng và chờ kết quả trả về
    final result = await TingeeBankLink.open(
      context,
      url: sessionUrl,
      environment: TingeeEnvironment.prod,
      theme: const TingeeThemeConfig(primaryColor: '#1E88E5'),
      onSuccess: (res) {
        debugPrint('Liên kết thành công: ${res.bankName} - VA: ${res.vaAccountNumber}');
      },
      onFailed: (err) {
        debugPrint('Liên kết thất bại: ${err.errorCode} - ${err.errorMessage}');
      },
      onCancelled: (_) {
        debugPrint('Khách hàng đã đóng cửa sổ');
      },
    );

    if (result.isSuccess) {
      // Xử lý sau khi liên kết thành công
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên kết ngân hàng')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _startBankLink(context),
          child: const Text('Liên kết tài khoản ngân hàng'),
        ),
      ),
    );
  }
}
```

### 1.2. Nhúng trực tiếp vào màn hình (`TingeeBankLinkView`)

```dart
import 'package:flutter/material.dart';
import 'package:tingee_sdk_ui/tingee_sdk_ui.dart';

class BankLinkInlineScreen extends StatelessWidget {
  final String sessionUrl;

  const BankLinkInlineScreen({super.key, required this.sessionUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên kết ngân hàng')),
      body: TingeeBankLinkView(
        url: sessionUrl,
        theme: const TingeeThemeConfig(primaryColor: '#1E88E5'),
        onSuccess: (res) => debugPrint('Thành công: ${res.vaAccountNumber}'),
        onFailed: (err) => debugPrint('Thất bại: ${err.errorMessage}'),
        onCancelled: (_) => debugPrint('Đã hủy'),
      ),
    );
  }
}
```

---

## 2. Tích hợp Cổng Thanh toán (Payment Gateway Checkout)

Trước khi mở giao diện thanh toán, Backend của bạn gọi API [Tạo link thanh toán](https://developers.tingee.vn/docs/payment-gateway/create-payment-link) để lấy `checkoutUrl`.

```dart
import 'package:flutter/material.dart';
import 'package:tingee_sdk_ui/tingee_sdk_ui.dart';

Future<void> startPayment(BuildContext context, String checkoutUrl) async {
  final result = await TingeeCheckout.open(
    context,
    url: checkoutUrl,
    environment: TingeeEnvironment.prod,
    onSuccess: (res) {
      debugPrint('Thanh toán thành công đơn hàng: ${res.orderCode}');
    },
    onFailed: (err) {
      debugPrint('Thanh toán thất bại: ${err.errorMessage}');
    },
    onCancelled: (_) {
      debugPrint('Khách hàng hủy thanh toán');
    },
  );
}
```

---

## 3. Cấu trúc `TingeeResult`

| Thuộc tính | Kiểu dữ liệu | Mô tả |
| :--- | :--- | :--- |
| `status` | `TingeeStatus` | `success`, `failed`, `cancelled`, hoặc `error`. |
| `isSuccess` | `bool` | `true` nếu giao dịch / liên kết thành công. |
| `isFailed` | `bool` | `true` nếu giao dịch / liên kết thất bại. |
| `isCancelled` | `bool` | `true` nếu người dùng chủ động đóng cửa sổ. |
| `bankName` | `String?` | Tên ngân hàng (ví dụ: `'BIDV'`). |
| `vaAccountNumber` | `String?` | Số tài khoản VA được liên kết (Bank Link). |
| `merchantAccountNumberId` | `dynamic` | ID tài khoản ngân hàng của Merchant (Bank Link). |
| `shopId` | `dynamic` | ID cửa hàng (Bank Link). |
| `orderCode` | `String?` | Mã đơn hàng thanh toán (Checkout). |
| `transactionId` | `dynamic` | Mã giao dịch thanh toán (Checkout). |
| `amount` | `num?` | Số tiền thanh toán (Checkout). |
| `errorCode` | `String?` | Mã lỗi khi thất bại hoặc hủy. |
| `errorMessage` | `String?` | Thông báo lỗi chi tiết. |
| `raw` | `Map<String, dynamic>` | Toàn bộ dữ liệu JSON gốc nhận từ WebView. |

---

## Hỗ trợ & Liên hệ

- **Tài liệu OpenAPI & SDK:** [https://developers.tingee.vn](https://developers.tingee.vn)
- **Website chính thức:** [https://tingee.vn](https://tingee.vn)
- **Email hỗ trợ kỹ thuật:** [developer@heno.vn](mailto:developer@heno.vn)
- **Telegram:** [https://t.me/tingeesupport](https://t.me/tingeesupport)
- **GitHub:** [https://github.com/tingeehub](https://github.com/tingeehub)
