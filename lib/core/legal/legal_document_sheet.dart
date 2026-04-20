import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Uzun yasal metinleri kaydırılabilir bottom sheet içinde gösterir.
Future<void> showLegalDocumentSheet(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      final bottom = MediaQuery.paddingOf(ctx).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.ghostBorder.withValues(alpha: 0.35),
            ),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Kapat',
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: SelectableText(
                      body.trim(),
                      style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            color: AppColors.onSurface,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
