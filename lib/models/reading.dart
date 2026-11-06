class Reading {
  const Reading({
    required this.id,
    required this.timestamp,
    required this.humidity,
    this.raw,
    this.pressure,
    this.reportedStatus,
  });
  final String id;
  final DateTime timestamp;
  final double humidity;
  final int? raw;
  final double? pressure;
  final String? reportedStatus;

  factory Reading.fromMap(String id, Map<Object?, Object?> data,
      {int? dryRaw, int? wetRaw}) {
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      (data['timestamp'] as num).toInt(),
    );
    final raw = (data['humedad_raw'] as num?)?.toInt();
    final supplied = (data['humedad_pct'] as num?)?.toDouble();
    final humidity = supplied ??
        (raw != null && dryRaw != null && wetRaw != null && dryRaw != wetRaw
            ? (((dryRaw - raw) / (dryRaw - wetRaw)) * 100).clamp(0, 100)
            : null);
    if (humidity == null) {
      throw const FormatException('Lectura sin humedad válida');
    }
    return Reading(
      id: id,
      timestamp: timestamp,
      humidity: humidity,
      raw: raw,
      pressure: (data['u_kpa'] as num?)?.toDouble(),
      reportedStatus: data['estado'] as String?,
    );
  }
}

String readingStatus(Reading reading, double prealert, double alert) {
  if (reading.reportedStatus == 'Normal' ||
      reading.reportedStatus == 'Prealerta' ||
      reading.reportedStatus == 'Alerta') {
    return reading.reportedStatus!;
  }
  if (reading.humidity >= alert) return 'Alerta';
  if (reading.humidity >= prealert) return 'Prealerta';
  return 'Normal';
}
