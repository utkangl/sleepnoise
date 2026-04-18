import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../application/sleep_timer_controller.dart';

/// `mm:ss` gösterimi (sleep timer pill / sheet).
String formatSleepTimerMmSs(Duration d) {
  final totalSeconds = d.inSeconds.clamp(0, 359999);
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

Future<void> showSleepTimerBottomSheet(
  BuildContext context,
  WidgetRef ref, {
  String idleSubtitle = 'Çalma seçtiğin sürede otomatik dursun.',
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => _SleepTimerSheetBody(idleSubtitle: idleSubtitle),
  );
}

class _SleepTimerSheetBody extends ConsumerStatefulWidget {
  const _SleepTimerSheetBody({required this.idleSubtitle});

  final String idleSubtitle;

  @override
  ConsumerState<_SleepTimerSheetBody> createState() =>
      _SleepTimerSheetBodyState();
}

class _SleepTimerSheetBodyState extends ConsumerState<_SleepTimerSheetBody> {
  final _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _applyCustomMinutes() {
    final raw = _customCtrl.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1 || parsed > 24 * 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('1 ile 1440 dakika arasında bir sayı gir.'),
        ),
      );
      return;
    }
    ref.read(sleepTimerControllerProvider.notifier).start(
          Duration(minutes: parsed),
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final timerCtl = ref.read(sleepTimerControllerProvider.notifier);
    final timerState = ref.watch(sleepTimerControllerProvider);
    const presets = <int>[15, 30, 45, 60];

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Sleep Timer',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            timerState.active
                ? 'Kalan süre: ${formatSleepTimerMmSs(timerState.remaining)}'
                : widget.idleSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          for (final minutes in presets)
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text('$minutes dakika'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                timerCtl.start(Duration(minutes: minutes));
                Navigator.of(context).pop();
              },
            ),
          const Divider(height: 24),
          Text(
            'Özel süre',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _customCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: 'Dakika (örn. 90)',
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (_) => _applyCustomMinutes(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _applyCustomMinutes,
                child: const Text('Uygula'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text('Timer kapat'),
            trailing: const Icon(Icons.close_rounded),
            onTap: () {
              timerCtl.cancel();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
