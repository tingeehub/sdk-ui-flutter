import 'package:flutter/material.dart';

import 'models/tingee_models.dart';
import 'widgets/tingee_bank_link_view.dart';

/// Lớp tiện ích mở cửa sổ Popup / Modal Liên kết Ngân hàng (Tingee Bank Link)
class TingeeBankLink {
  const TingeeBankLink._();

  /// Mở cửa sổ Modal Liên kết Ngân hàng và trả về [Future<TingeeResult>].
  static Future<TingeeResult> open(
    BuildContext context, {
    required String url,
    TingeeEnvironment environment = TingeeEnvironment.prod,
    String? baseUrl,
    TingeeThemeConfig? theme,
    String title = 'Liên kết ngân hàng',
    bool showHeader = true,
    bool enableDeepLink = true,
    double heightFactor = 0.92,
    ValueChanged<TingeeResult>? onSuccess,
    ValueChanged<TingeeResult>? onFailed,
    ValueChanged<TingeeResult>? onCancelled,
  }) async {
    final result = await showModalBottomSheet<TingeeResult>(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: heightFactor,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              children: [
                if (showHeader)
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 22),
                          tooltip: 'Đóng',
                          onPressed: () {
                            Navigator.of(sheetContext)
                                .pop(TingeeResult.userCancelled());
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: TingeeBankLinkView(
                    url: url,
                    environment: environment,
                    baseUrl: baseUrl,
                    theme: theme,
                    mode: 'modal',
                    enableDeepLink: enableDeepLink,
                    onResult: (res) {
                      if (Navigator.of(sheetContext).canPop()) {
                        Navigator.of(sheetContext).pop(res);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    final finalResult = result ?? TingeeResult.userCancelled();

    if (finalResult.isSuccess) {
      onSuccess?.call(finalResult);
    } else if (finalResult.isFailed) {
      onFailed?.call(finalResult);
    } else if (finalResult.isCancelled) {
      onCancelled?.call(finalResult);
    }

    return finalResult;
  }
}
