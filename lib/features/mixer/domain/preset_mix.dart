import 'package:flutter/material.dart';

/// Tek bir hazır karışım: kanal [levels] ile (trackId → 0–100); tanımsız kanallar 0.
class PresetMix {
  const PresetMix({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.levels,
    this.icon = Icons.auto_awesome_mosaic_rounded,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Sadece sıfırdan büyük seviyeler; tanımsız kanallar o an miklenebilir kümede 0 kabul edilir.
  final Map<String, double> levels;
  final IconData icon;
}
