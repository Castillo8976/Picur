import 'package:flutter_test/flutter_test.dart';
import 'package:picur_monitor/data/reading_parser.dart';
import 'package:picur_monitor/models/metric_config.dart';
import 'package:picur_monitor/models/reading.dart';

void main() {
  final metric = MetricConfig(
    id: 'humidity',
    name: 'Humedad',
    field: 'humedad_pct',
    unit: '%',
    active: true,
    prealert: 60,
    alert: 75,
  );

  test('parsea lista con epoch en segundos y descarta campos faltantes', () {
    final values = ReadingParser([metric]).parse([
      {'timestamp': 1730851200, 'humedad_pct': 42.5},
      {'timestamp': 1730851201},
    ]);
    expect(values, hasLength(1));
    expect(values.single.values['humidity'], 42.5);
    expect(values.single.timestamp.millisecondsSinceEpoch, 1730851200000);
  });

  test('calcula estados y dirección descendente', () {
    expect(stateFor(80, 60, 75), AlertState.alerta);
    expect(stateFor(30, 60, 75, rises: false), AlertState.alerta);
  });
}
