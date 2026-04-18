import 'package:flutter/material.dart';

Future<String?> showMixSaveNameDialog(
  BuildContext context, {
  String initialName = 'Karışımım',
}) async {
  final controller = TextEditingController(text: initialName);
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Karışımı kaydet'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'İsim',
            hintText: 'Örn. Gece kampı',
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      );
    },
  );
}
