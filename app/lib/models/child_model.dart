class GeofenceModel {
  final double lat;
  final double lng;
  final double radiusMeters;

  const GeofenceModel({
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  factory GeofenceModel.fromMap(Map<String, dynamic> map) => GeofenceModel(
        lat:          (map['lat'] as num).toDouble(),
        lng:          (map['lng'] as num).toDouble(),
        radiusMeters: (map['radiusMeters'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'lat':          lat,
        'lng':          lng,
        'radiusMeters': radiusMeters,
      };
}

class ChildModel {
  final String id;
  final String name;
  final int age;
  final String deviceId;
  final GeofenceModel? geofence;
  final List<String> emergencyContacts;
  final bool calibrated;
  final int daysCollected;

  const ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.deviceId,
    this.geofence,
    required this.emergencyContacts,
    required this.calibrated,
    required this.daysCollected,
  });

  factory ChildModel.fromMap(String id, Map<String, dynamic> map) => ChildModel(
        id:                id,
        name:              map['name'] as String,
        age:               (map['age'] as num).toInt(),
        deviceId:          map['deviceId'] as String? ?? '',
        geofence:          map['geofence'] != null
            ? GeofenceModel.fromMap(map['geofence'] as Map<String, dynamic>)
            : null,
        emergencyContacts: List<String>.from(map['emergencyContacts'] ?? []),
        calibrated:        map['calibrated'] as bool? ?? false,
        daysCollected:     (map['daysCollected'] as num?)?.toInt() ?? 0,
      );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }
}
