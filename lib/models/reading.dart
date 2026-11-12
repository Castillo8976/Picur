class Reading {
  const Reading({
    required this.id,
    required this.timestamp,
    required this.values,
    this.raw = const {},
  });

  final String id;
  final DateTime timestamp;
  final Map<String, double> values;
  final Map<String, dynamic> raw;

  double? valueFor(String metricId) => values[metricId];

  /// Estado calculado por el ESP32 (campo "estado_codigo": 0, 1 o 2).
  AlertState? get deviceState => alertStateFromCode(raw['estado_codigo']);
}

/// normal = Seguro, prealerta = Evacuación temprana, alerta = Peligro.
enum AlertState { normal, prealerta, alerta, sinSenal }

extension AlertStateLabel on AlertState {
  String get label => switch (this) {
        AlertState.normal => 'Seguro',
        AlertState.prealerta => 'Evacuación temprana',
        AlertState.alerta => 'Peligro',
        AlertState.sinSenal => 'Sin señal',
      };
}

AlertState? alertStateFromCode(dynamic code) {
  final value = code is num ? code.toInt() : int.tryParse('$code');
  return switch (value) {
    0 => AlertState.normal,
    1 => AlertState.prealerta,
    2 => AlertState.alerta,
    _ => null,
  };
}

AlertState stateFor(double value, double prealert, double alert,
    {bool rises = true}) {
  final current = rises ? value : -value;
  final first = rises ? prealert : -prealert;
  final second = rises ? alert : -alert;
  if (current >= second) return AlertState.alerta;
  if (current >= first) return AlertState.prealerta;
  return AlertState.normal;
}
