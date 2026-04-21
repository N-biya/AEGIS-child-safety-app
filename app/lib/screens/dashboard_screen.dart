import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/vital_model.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/status_badge.dart';
import '../widgets/vital_card.dart';
import '../widgets/section_header.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  VitalModel? _latest;

  @override
  void initState() {
    super.initState();
    _latest = DummyDataService.currentVital;
    DummyDataService.vitalStream.listen((v) {
      if (mounted) setState(() => _latest = v);
    });
  }

  Color _heroGradientStart() {
    switch (_latest?.status) {
      case 'STRESS':
      case 'ALERT':   return aegisRoseLight;
      case 'ELEVATED': return aegisPeachLight;
      default:         return aegisMintLight;
    }
  }

  Color _heroGradientEnd() {
    switch (_latest?.status) {
      case 'STRESS':
      case 'ALERT':   return aegisRose.withOpacity(0.3);
      case 'ELEVATED': return aegisPeach.withOpacity(0.3);
      default:         return aegisMint.withOpacity(0.3);
    }
  }

  String _heroMessage() {
    switch (_latest?.status) {
      case 'STRESS':
      case 'ALERT':   return 'Immediate attention needed';
      case 'ELEVATED': return 'Slight elevation detected';
      default:         return 'All vitals normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = DummyDataService.dummyChild;
    final v = _latest;

    return Scaffold(
      backgroundColor: aegisPinkPale,
      body: SafeArea(
        child: Column(
          children: [
            // Custom app bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Good morning,', style: AppTextStyles.caption),
                      Text(child.name, style: AppTextStyles.h3),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: aegisCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.battery,
                                size: 14, color: statusSafe),
                            const SizedBox(width: 4),
                            Text('87%',
                                style: AppTextStyles.caption
                                    .copyWith(color: aegisText)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: aegisCard,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(LucideIcons.wifi,
                            size: 14, color: statusSafe),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Status hero card
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOut,
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_heroGradientStart(), _heroGradientEnd()],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: aegisPink.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusBadge(status: v?.status ?? 'NORMAL'),
                          const SizedBox(height: 12),
                          Text(
                            v?.status == 'NORMAL' ? 'Safe' :
                            v?.status == 'ELEVATED' ? 'Elevated' : 'Alert',
                            style: AppTextStyles.h2,
                          ),
                          const SizedBox(height: 4),
                          Text(_heroMessage(), style: AppTextStyles.body),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(LucideIcons.clock,
                                  size: 12, color: aegisTextSoft),
                              const SizedBox(width: 4),
                              Text(
                                'Updated just now',
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const SectionHeader(title: 'Live Vitals'),
                    const SizedBox(height: 12),

                    // Vitals 2x2 grid
                    if (v != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 160,
                              child: VitalCard(
                                vitalType: 'hr',
                                displayValue: '${v.heartRate}',
                                unit: 'bpm',
                                sparklineData:
                                    DummyDataService.sparklineFor('hr'),
                                cardColor: aegisPinkLight,
                                accentColor: aegisPinkDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 160,
                              child: VitalCard(
                                vitalType: 'spo2',
                                displayValue: '${v.spo2}',
                                unit: '%',
                                sparklineData:
                                    DummyDataService.sparklineFor('spo2'),
                                cardColor: aegisMintLight,
                                accentColor: statusSafe,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 160,
                              child: VitalCard(
                                vitalType: 'gsr',
                                displayValue: v.gsr.toStringAsFixed(1),
                                unit: 'µS',
                                sparklineData:
                                    DummyDataService.sparklineFor('gsr'),
                                cardColor: aegisLavenderLight,
                                accentColor: aegisLavender,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 160,
                              child: VitalCard(
                                vitalType: 'temp',
                                displayValue: v.temperature.toStringAsFixed(1),
                                unit: '°C',
                                sparklineData:
                                    DummyDataService.sparklineFor('temp'),
                                cardColor: aegisPeachLight,
                                accentColor: aegisPeach,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),
                    SectionHeader(
                      title: 'Last Location',
                      actionLabel: 'View map',
                      onAction: () {},
                    ),
                    const SizedBox(height: 12),

                    // Quick location card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: aegisCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: aegisPink.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: aegisMintLight,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(LucideIcons.mapPin,
                                size: 20, color: statusSafe),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Within safe zone',
                                    style: AppTextStyles.bodyMid),
                                const SizedBox(height: 2),
                                Text(
                                  v != null
                                      ? '${v.latitude.toStringAsFixed(4)}, ${v.longitude.toStringAsFixed(4)}'
                                      : 'Fetching location...',
                                  style: AppTextStyles.caption,
                                ),
                                const SizedBox(height: 2),
                                Text('42m from home',
                                    style: AppTextStyles.caption
                                        .copyWith(color: statusSafe)),
                              ],
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight,
                              size: 16, color: aegisTextSoft),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
