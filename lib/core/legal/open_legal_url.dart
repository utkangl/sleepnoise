import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/store_links.dart';

Future<void> openPrivacyPolicy(BuildContext context) {
  return _openConfiguredUrl(
    context,
    kPrivacyPolicyUrl,
    'Gizlilik politikası',
  );
}

Future<void> openTermsOfUse(BuildContext context) {
  return _openConfiguredUrl(
    context,
    kTermsOfUseUrl,
    'Kullanım şartları',
  );
}

Future<void> _openConfiguredUrl(
  BuildContext context,
  String url,
  String title,
) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Mağazaya yüklemeden önce gerçek sayfayı yayımlayıp '
          'lib/core/config/store_links.dart dosyasındaki bağlantıyı güncelleyin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
    return;
  }

  final uri = Uri.tryParse(trimmed);
  if (uri == null || (!uri.isScheme('https') && !uri.isScheme('http'))) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Geçersiz bağlantı.')),
    );
    return;
  }

  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bağlantı açılamadı.')),
    );
  }
}
