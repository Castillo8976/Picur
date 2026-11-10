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
}

enum AlertState { normal, prealerta, alerta, sinSenal }

extension AlertStateLabel on AlertState {
  String get label => switch (this) {
        AlertState.normal => 'Normal',
        AlertState.prealerta => 'Prealerta',
        AlertState.alerta => 'Alerta',
        AlertState.sinSenal => 'Sin señal',
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
