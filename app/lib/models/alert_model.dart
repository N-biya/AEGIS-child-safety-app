class AlertModel {
  final String id;
  final String type;
  final DateTime timestamp;
  final int heartRate;
  final int spo2;
  final double latitude;
  final double longitude;
  final bool resolved;

  const AlertModel({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.heartRate,
    required this.spo2,
    required this.latitude,
    required this.longitude,
    required this.resolved,
  });

  factory AlertModel.fromMap(String id, Map<String, dynamic> map) => AlertModel(
        id:        id,
        type:      map['type'] as String,
        timestamp: DateTime.parse(map['timestamp'] as String).toLocal(),
        heartRate: (map['vitals']['hr'] as num).toInt(),
        spo2:      (map['vitals']['spo2'] as num).toInt(),
        latitude:  (map['location']['lat'] as num).toDouble(),
        longitude: (map['location']['lng'] as num).toDouble(),
        resolved:  map['resolved'] as bool,
      );

  String get typeLabel {
    switch (type) {
      case 'STRESS':    return 'Stress Detected';
      case 'GEOFENCE':  return 'Location Breach';
      case 'FORBIDDEN': return 'Restricted Area';
      case 'SPO2':      return 'Low SpO2';
      case 'ELEVATED':  return 'Elevated Reading';
      default:          return type;
    }
  }
}
