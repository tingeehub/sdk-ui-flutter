# tingee_sdk_ui

Bộ thư viện **Tingee UI SDK** chính thức dành cho **Flutter (Android & iOS)** — giúp đối tác tích hợp nhanh giao diện **Liên kết ngân hàng (Bank Link)** và **Cổng thanh toán (Payment Gateway Checkout)** của Tingee ngay trong ứng dụng di động.

📖 **Tài liệu đầy đủ:** [developers.tingee.vn](https://developers.tingee.vn)

---

## Cài đặt

Thêm `tingee_sdk_ui` vào `pubspec.yaml`:

```yaml
dependencies:
  tingee_sdk_ui: ^1.1.0
```

Hoặc chạy lệnh:

```bash
flutter pub add tingee_sdk_ui
```

### Khai báo quyền Camera & Thư viện ảnh (tùy chọn — chỉ khi dùng tính năng quét QR)

> Chỉ cần khai báo khi phiên liên kết của bạn **bật tính năng quét mã QR** (quét bằng camera / tải ảnh QR từ thư viện). Nếu không sử dụng tính năng này, nút quét QR sẽ không hiển thị và ứng dụng **không cần** khai báo các quyền bên dưới.

Khi dùng tính năng quét QR, SDK đã tự xử lý xin quyền trong WebView, ứng dụng của bạn chỉ cần khai báo quyền:

**iOS** — `ios/Runner/Info.plist` (khi đã bật quét QR mà thiếu `NSCameraUsageDescription`, ứng dụng sẽ bị crash lúc mở camera):

```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền camera để quét mã QR tài khoản ngân hàng.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần quyền truy cập thư viện ảnh để tải ảnh mã QR tài khoản ngân hàng.</string>
```

Và bật quyền camera cho `permission_handler` trong `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
      ]
    end
  end
end
```

**Android** — `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

> Chọn ảnh từ thư viện trên Android dùng Photo Picker của hệ thống (qua `image_picker`), không cần khai báo thêm quyền đọc bộ nhớ.

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
    // 1. Gọi API Backend của bạn để lấy session URL và cấu hình màu sắc (nếu lưu ở Backend)
    const sessionUrl = 'https://bank-link.tingee.vn?token=...';
    const primaryColorFromBackend = '#1E88E5';

    // 2. Mở Modal Liên kết Ngân hàng kèm cấu hình động, customCss hoặc injectedJavaScript
    final result = await TingeeBankLink.open(
      context,
      url: sessionUrl,
      environment: TingeeEnvironment.prod,
      theme: const TingeeThemeConfig(
        primaryColor: primaryColorFromBackend,
        primaryHoverColor: '#1565C0',
        primarySoftColor: '#E3F2FD',
        cssVariables: {'--border-radius': '12px'},
      ),
      customCss: '''
        body { font-family: -apple-system, sans-serif !important; }
      ''',
      injectedJavaScript: '''
        console.log('Tingee Flutter WebView loaded');
      ''',
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

## 3. Tham số cấu hình (`TingeeBankLink.open` / `TingeeBankLinkView`)

| Tham số | Kiểu dữ liệu | Mặc định | Mô tả |
| :--- | :--- | :--- | :--- |
| `url` | `String` | *(bắt buộc)* | Đường dẫn session URL nhận từ API Backend. |
| `environment` | `TingeeEnvironment` | `TingeeEnvironment.prod` | Môi trường tích hợp (`uat` hoặc `prod`). |
| `theme` | `TingeeThemeConfig?` | `null` | Cấu hình màu sắc (`primaryColor`, `primaryHoverColor`, `primarySoftColor`, `cssVariables`, `customCss`). |
| `customCss` | `String?` | `null` | Chuỗi CSS tùy chỉnh sâu được tiêm trực tiếp (`<style>`) vào trong WebView. |
| `injectedJavaScript` | `String?` | `null` | Đoạn mã JavaScript tùy chỉnh được thực thi bên trong WebView sau khi tải trang. |
| `title` | `String` | `'Liên kết ngân hàng'` | Tiêu đề thanh Header của Bottom Sheet Modal. |
| `showHeader` | `bool` | `true` | Hiển thị thanh Header và nút đóng (`✕`). |
| `enableDeepLink` | `bool` | `true` | Tự động mở App Ngân hàng khi bấm vào liên kết Deep Link. |

---

## 4. Cấu trúc `TingeeResult`

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
