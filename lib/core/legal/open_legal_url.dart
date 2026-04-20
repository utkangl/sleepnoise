import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/store_links.dart';
import 'legal_document_sheet.dart';
import 'legal_documents.dart';

Future<void> openPrivacyPolicy(BuildContext context) {
  return _openConfiguredUrl(
    context,
    kPrivacyPolicyUrl,
    'Gizlilik politikası',
    fallbackBody: kPrivacyPolicyDocumentTr,
  );
}

Future<void> openTermsOfUse(BuildContext context) {
  return _openConfiguredUrl(
    context,
    kTermsOfUseUrl,
    'Kullanım şartları',
    fallbackBody: kTermsOfUseDocumentTr,
  );
}

Future<void> _openConfiguredUrl(
  BuildContext context,
  String url,
  String title, {
  required String fallbackBody,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    if (!context.mounted) return;
    await showLegalDocumentSheet(
      context,
      title: title,
      body: fallbackBody,
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
