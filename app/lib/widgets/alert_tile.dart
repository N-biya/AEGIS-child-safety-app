import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/alert_model.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class AlertTile extends StatelessWidget {
  final AlertModel alert;

  const AlertTile({super.key, required this.alert});

  Color get _borderColor {
    switch (alert.type) {
      case 'STRESS':   return aegisRose;
      case 'GEOFENCE': return aegisPeach;
      case 'SPO2':     return aegisLavender;
      default:         return aegisPeach;
    }
  }

  IconData get _icon {
    switch (alert.type) {
      case 'STRESS':   return LucideIcons.brain;
      case 'GEOFENCE': return LucideIcons.mapPin;
      case 'SPO2':     return LucideIcons.wind;
      default:         return LucideIcons.alertTriangle;
    }
  }

  String _timeAgo() {
    final diff = DateTime.now().difference(alert.timestamp);
    if (diff.inDays > 0)  return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AegisColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(color: _borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: aegisPink.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _borderColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, size: 18, color: _borderColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.typeLabel, style: AppTextStyles.bodyMid),
                  const SizedBox(height: 2),
                  Text(
                    'HR ${alert.heartRate} bpm  •  SpO2 ${alert.spo2}%',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${alert.latitude.toStringAsFixed(4)}, '
                    '${alert.longitude.toStringAsFixed(4)}',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeAgo(), style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: alert.resolved ? aegisMintLight : aegisRoseLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert.resolved ? 'Resolved' : 'Active',
                    style: AppTextStyles.caption.copyWith(
                      color: alert.resolved ? statusSafe : statusAlert,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
