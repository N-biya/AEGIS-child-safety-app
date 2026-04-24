import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/alert_model.dart';
import '../services/dummy_data_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/alert_tile.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  String _filter = 'All';
  static const _filters = ['All', 'Stress', 'Location', 'Resolved'];

  List<AlertModel> get _filtered {
    final all = DummyDataService.dummyAlerts;
    switch (_filter) {
      case 'Stress':   return all.where((a) => a.type == 'STRESS').toList();
      case 'Location': return all.where((a) => a.type == 'GEOFENCE').toList();
      case 'Resolved': return all.where((a) => a.resolved).toList();
      default:         return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _filtered;

    return Scaffold(
      backgroundColor: AegisColors.bg(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text('Alert History', style: AppTextStyles.h2),
            ),
            const SizedBox(height: 16),

            // ── Filter pills ────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final active = _filter == _filters[i];
                  return GestureDetector(
                    onTap: () => setState(() => _filter = _filters[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? aegisPink
                            : AegisColors.pinkLight(context),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _filters[i],
                        style: AppTextStyles.label.copyWith(
                          color: active
                              ? Colors.white
                              : AegisColors.textMid(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: alerts.isEmpty
                  ? _EmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: alerts.length,
                      itemBuilder: (_, i) => AlertTile(alert: alerts[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: aegisMintLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle,
                size: 40, color: statusSafe),
          ),
          const SizedBox(height: 16),
          Text('All clear', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          const Text(
            'No alerts recorded for this period',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
