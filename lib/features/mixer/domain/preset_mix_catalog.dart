import 'package:flutter/material.dart';

import 'preset_mix.dart';

/// Uygulama ile birlikte gelen hazır mikslar. Yeni ses eklendikçe buraya satır eklenebilir.
const List<PresetMix> presetMixCatalog = [
  PresetMix(
    id: 'forest_camp_night',
    title: 'Ormanda kamp (gece)',
    subtitle: 'Orman + ateş',
    icon: Icons.night_shelter_rounded,
    levels: {
      'forest': 72,
      'fire': 58,
    },
  ),
  PresetMix(
    id: 'coastal_evening',
    title: 'Kıyı akşamı',
    subtitle: 'Dalga + hafif kuş',
    icon: Icons.beach_access_rounded,
    levels: {
      'ocean': 68,
      'birds': 22,
    },
  ),
  PresetMix(
    id: 'morning_forest',
    title: 'Kuşlu sabah',
    subtitle: 'Orman + kuşlar',
    icon: Icons.wb_twilight_rounded,
    levels: {
      'forest': 55,
      'birds': 48,
    },
  ),
  PresetMix(
    id: 'water_garden',
    title: 'Su bahçesi',
    subtitle: 'Şelale + orman',
    icon: Icons.water_rounded,
    levels: {
      'waterfall': 52,
      'forest': 48,
    },
  ),
  PresetMix(
    id: 'deep_focus',
    title: 'Derin odak',
    subtitle: 'Hafif su + dalga',
    icon: Icons.spa_rounded,
    levels: {
      'waterfall': 38,
      'ocean': 42,
    },
  ),
  PresetMix(
    id: 'fireside_read',
    title: 'Şömine başı',
    subtitle: 'Ateş + orman',
    icon: Icons.menu_book_rounded,
    levels: {
      'fire': 62,
      'forest': 35,
    },
  ),
  PresetMix(
    id: 'waterfall_fire_camp',
    title: 'Şelale kampı',
    subtitle: 'Su sesi + ateş',
    icon: Icons.local_fire_department_rounded,
    levels: {
      'waterfall': 58,
      'fire': 52,
    },
  ),
  PresetMix(
    id: 'ocean_beach_fire',
    title: 'Sahil ateşi',
    subtitle: 'Dalga + şömine hissi',
    icon: Icons.whatshot_rounded,
    levels: {
      'ocean': 62,
      'fire': 48,
    },
  ),
  PresetMix(
    id: 'waterfall_birds_chorus',
    title: 'Kuşlu dere',
    subtitle: 'Şelale + kuşlar',
    icon: Icons.waterfall_chart_rounded,
    levels: {
      'waterfall': 55,
      'birds': 50,
    },
  ),
  PresetMix(
    id: 'forest_ocean_horizon',
    title: 'Orman ve ufk',
    subtitle: 'Ağaçlar + uzak dalga',
    icon: Icons.landscape_rounded,
    levels: {
      'forest': 58,
      'ocean': 44,
    },
  ),
  PresetMix(
    id: 'nature_triad',
    title: 'Doğa üçlüsü',
    subtitle: 'Orman, deniz, kuş',
    icon: Icons.park_rounded,
    levels: {
      'forest': 45,
      'ocean': 40,
      'birds': 38,
    },
  ),
  PresetMix(
    id: 'misty_shore',
    title: 'Sisli kıyı',
    subtitle: 'Dalga + şelale + hafif kuş',
    icon: Icons.cloud_rounded,
    levels: {
      'ocean': 52,
      'waterfall': 40,
      'birds': 20,
    },
  ),
  PresetMix(
    id: 'warm_downpour',
    title: 'Ilık yağmur',
    subtitle: 'Şelale + orman + ateş',
    icon: Icons.water_drop_rounded,
    levels: {
      'waterfall': 62,
      'forest': 42,
      'fire': 28,
    },
  ),
  PresetMix(
    id: 'gull_coast',
    title: 'Martı kıyısı',
    subtitle: 'Dalga + kuşlar',
    icon: Icons.air_rounded,
    levels: {
      'ocean': 60,
      'birds': 55,
    },
  ),
];
