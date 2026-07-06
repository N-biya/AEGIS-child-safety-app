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

/// A place the child must NOT go. The band checks these on-device and raises a
/// 'FORBIDDEN' alert if the child dwells inside one (a brief pass-through does
/// not count — dwell handling lives in the firmware).
class ForbiddenZoneModel {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  const ForbiddenZoneModel({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });

  factory ForbiddenZoneModel.fromMap(Map<String, dynamic> map) =>
      ForbiddenZoneModel(
        id:           map['id'] as String? ?? '',
        name:         map['name'] as String? ?? 'Restricted area',
        lat:          (map['lat'] as num).toDouble(),
        lng:          (map['lng'] as num).toDouble(),
        radiusMeters: (map['radiusMeters'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'id':           id,
        'name':         name,
        'lat':          lat,
        'lng':          lng,
        'radiusMeters': radiusMeters,
      };
}

class EmergencyContactModel {
  final String id;
  final String name;
  final String relation;
  final String phone;
  final int priority; // 1 = contacted first

  const EmergencyContactModel({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.priority,
  });

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) =>
      EmergencyContactModel(
        id:       map['id'] as String,
        name:     map['name'] as String,
        relation: map['relation'] as String? ?? '',
        phone:    map['phone'] as String? ?? '',
        priority: (map['priority'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toMap() => {
        'id':       id,
        'name':     name,
        'relation': relation,
        'phone':    phone,
        'priority': priority,
      };

  EmergencyContactModel copyWith({
    String? name,
    String? relation,
    String? phone,
    int? priority,
  }) => EmergencyContactModel(
        id:       id,
        name:     name     ?? this.name,
        relation: relation ?? this.relation,
        phone:    phone    ?? this.phone,
        priority: priority ?? this.priority,
      );
}

class ChildModel {
  final String id;
  final String name;
  final int age;
  final String deviceId;
  final String photoUrl;
  final GeofenceModel? geofence;
  final List<ForbiddenZoneModel> forbiddenZones;
  final List<EmergencyContactModel> emergencyContacts;
  final bool calibrated;
  final int daysCollected;

  const ChildModel({
    required this.id,
    required this.name,
    required this.age,
    required this.deviceId,
    this.photoUrl = '',
    this.geofence,
    this.forbiddenZones = const [],
    required this.emergencyContacts,
    required this.calibrated,
    required this.daysCollected,
  });

  factory ChildModel.fromMap(String id, Map<String, dynamic> map) => ChildModel(
        id:                id,
        name:              map['name'] as String,
        age:               (map['age'] as num).toInt(),
        deviceId:          map['deviceId'] as String? ?? '',
        photoUrl:          map['photoUrl'] as String? ?? '',
        geofence:          map['geofence'] != null
            ? GeofenceModel.fromMap(map['geofence'] as Map<String, dynamic>)
            : null,
        forbiddenZones:    (map['forbiddenZones'] as List<dynamic>? ?? [])
            .map((e) => ForbiddenZoneModel.fromMap(e as Map<String, dynamic>))
            .toList(),
        emergencyContacts: (map['emergencyContacts'] as List<dynamic>? ?? [])
            .map((e) => EmergencyContactModel.fromMap(e as Map<String, dynamic>))
            .toList(),
        calibrated:        map['calibrated'] as bool? ?? false,
        daysCollected:     (map['daysCollected'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {
        'name':              name,
        'age':               age,
        'deviceId':          deviceId,
        'photoUrl':          photoUrl,
        'geofence':          geofence?.toMap(),
        'forbiddenZones':    forbiddenZones.map((z) => z.toMap()).toList(),
        'emergencyContacts': emergencyContacts.map((c) => c.toMap()).toList(),
        'calibrated':        calibrated,
        'daysCollected':     daysCollected,
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'C';
  }

  /// Contacts ordered by priority (1 = highest, contacted first).
  List<EmergencyContactModel> get contactsByPriority =>
      [...emergencyContacts]..sort((a, b) => a.priority.compareTo(b.priority));
}
