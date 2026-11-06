class MetricConfig {
  const MetricConfig({
    required this.id,
    required this.name,
    required this.field,
    required this.unit,
    required this.active,
  });
  final String id;
  final String name;
  final String field;
  final String unit;
  final bool active;
}

const metrics = [
  MetricConfig(
    id: 'humidity',
    name: 'Humedad del suelo',
    field: 'humedad_pct',
    unit: '%',
    active: true,
  ),
  MetricConfig(
    id: 'pressure',
    name: 'Presión de poros',
    field: 'u_kpa',
    unit: 'kPa',
    active: false,
  ),
];

const databasePath = 'lecturas';
const defaultPrealert = 60.0;
const defaultAlert = 75.0;
