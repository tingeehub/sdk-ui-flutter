/// Môi trường tích hợp Tingee SDK (`prod` hoặc `uat`)
enum TingeeEnvironment {
  /// Môi trường Production chính thức
  prod,

  /// Môi trường Sandbox / UAT để kiểm thử
  uat,
}

/// Trạng thái kết quả trả về từ Tingee SDK
enum TingeeStatus {
  /// Giao dịch hoặc liên kết ngân hàng thành công
  success,

  /// Giao dịch hoặc liên kết ngân hàng thất bại
  failed,

  /// Người dùng chủ động đóng cửa sổ giao dịch
  cancelled,

  /// Lỗi kỹ thuật khi tải trang hoặc cấu hình không hợp lệ
  error,
}

/// Cấu hình màu sắc chủ đạo cho giao diện Tingee
class TingeeThemeConfig {
  /// Mã màu HEX chủ đạo (ví dụ: `'#1E88E5'`)
  final String? primaryColor;

  /// Các thuộc tính giao diện bổ sung (nếu có)
  final Map<String, dynamic>? extra;

  const TingeeThemeConfig({
    this.primaryColor,
    this.extra,
  });

  Map<String, dynamic> toJson() {
    return {
      if (primaryColor != null && primaryColor!.isNotEmpty)
        'primaryColor': primaryColor,
      if (extra != null) ...extra!,
    };
  }
}

/// Kết quả trả về từ Tingee Bank Link hoặc Tingee Checkout
class TingeeResult {
  /// Trạng thái kết quả (`success`, `failed`, `cancelled`, `error`)
  final TingeeStatus status;

  /// Tên ngân hàng (ví dụ: `'BIDV'`, `'VIETCOMBANK'`)
  final String? bankName;

  /// ID tài khoản ngân hàng của Merchant (Bank Link)
  final dynamic merchantAccountNumberId;

  /// Số tài khoản VA vừa được khởi tạo/liên kết (Bank Link)
  final String? vaAccountNumber;

  /// ID cửa hàng (Shop ID)
  final dynamic shopId;

  /// Mã đơn hàng thanh toán (Payment Gateway Checkout)
  final String? orderCode;

  /// Mã giao dịch thanh toán (Payment Gateway Checkout)
  final dynamic transactionId;

  /// Số tiền thanh toán (Payment Gateway Checkout)
  final num? amount;

  /// Mã lỗi khi `status` là `failed`, `cancelled` hoặc `error`
  final String? errorCode;

  /// Thông báo lỗi chi tiết
  final String? errorMessage;

  /// Toàn bộ payload gốc nhận được từ WebView
  final Map<String, dynamic> raw;

  const TingeeResult({
    required this.status,
    this.bankName,
    this.merchantAccountNumberId,
    this.vaAccountNumber,
    this.shopId,
    this.orderCode,
    this.transactionId,
    this.amount,
    this.errorCode,
    this.errorMessage,
    this.raw = const {},
  });

  bool get isSuccess => status == TingeeStatus.success;
  bool get isFailed => status == TingeeStatus.failed;
  bool get isCancelled => status == TingeeStatus.cancelled;
  bool get isError => status == TingeeStatus.error;

  factory TingeeResult.fromMap(Map<String, dynamic> map) {
    final rawStatus =
        (map['status'] ?? map['event'] ?? map['action'] ?? '').toString().toLowerCase();

    TingeeStatus resolvedStatus;
    if (rawStatus == 'success' || rawStatus == 'completed') {
      resolvedStatus = TingeeStatus.success;
    } else if (rawStatus == 'failed' || rawStatus == 'expired') {
      resolvedStatus = TingeeStatus.failed;
    } else if (rawStatus == 'cancelled' ||
        rawStatus == 'canceled' ||
        rawStatus == 'close' ||
        rawStatus == 'closed') {
      resolvedStatus = TingeeStatus.cancelled;
    } else {
      resolvedStatus = TingeeStatus.error;
    }

    final rawAmount = map['amount'];
    final num? parsedAmount = rawAmount is num
        ? rawAmount
        : (rawAmount != null ? num.tryParse(rawAmount.toString()) : null);

    return TingeeResult(
      status: resolvedStatus,
      bankName: map['bankName']?.toString(),
      merchantAccountNumberId: map['merchantAccountNumberId'],
      vaAccountNumber: map['vaAccountNumber']?.toString(),
      shopId: map['shopId'],
      orderCode: map['orderCode']?.toString(),
      transactionId: map['transactionId'],
      amount: parsedAmount,
      errorCode: (map['errorCode'] ?? map['code'])?.toString(),
      errorMessage: (map['errorMessage'] ?? map['message'])?.toString(),
      raw: Map<String, dynamic>.from(map),
    );
  }

  factory TingeeResult.userCancelled() {
    return const TingeeResult(
      status: TingeeStatus.cancelled,
      errorCode: 'USER_CLOSED',
      raw: {'status': 'cancelled', 'errorCode': 'USER_CLOSED'},
    );
  }

  @override
  String toString() {
    return 'TingeeResult(status: $status, bankName: $bankName, vaAccountNumber: $vaAccountNumber, orderCode: $orderCode, errorCode: $errorCode, errorMessage: $errorMessage)';
  }
}
