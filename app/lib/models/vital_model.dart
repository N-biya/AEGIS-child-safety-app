class VitalModel {
  final int heartRate;
  final int spo2;
  final double gsr;
  final double temperature;
  final double movement;
  final String status;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const VitalModel({
    required this.heartRate,
    required this.spo2,
    required this.gsr,
    required this.temperature,
    required this.movement,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory VitalModel.fromMap(Map<String, dynamic> map) => VitalModel(
        heartRate:   (map['hr'] as num).toInt(),
        spo2:        (map['spo2'] as num).toInt(),
        gsr:         (map['gsr'] as num).toDouble(),
        temperature: (map['temp'] as num).toDouble(),
        movement:    (map['movement'] as num).toDouble(),
        status:      map['status'] as String,
        latitude:    (map['lat'] as num).toDouble(),
        longitude:   (map['lng'] as num).toDouble(),
        timestamp:   DateTime.parse(map['timestamp'] as String),
      );

  Map<String, dynamic> toMap() => {
        'hr':        heartRate,
        'spo2':      spo2,
        'gsr':       gsr,
        'temp':      temperature,
        'movement':  movement,
        'status':    status,
        'lat':       latitude,
        'lng':       longitude,
        'timestamp': timestamp.toIso8601String(),
      };
}
