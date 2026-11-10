import 'models/metric_config.dart';

const defaultMetrics = [
  MetricConfig(
    id: 'humidity',
    name: 'Humedad del suelo',
    field: 'humedad_pct',
    unit: '%',
    active: true,
    prealert: 60,
    alert: 75,
    colorValue: 0xff147d5a,
  ),
  MetricConfig(
    id: 'pressure',
    name: 'Presión de poros',
    field: 'u_kpa',
    unit: 'kPa',
    active: false,
    prealert: 10,
    alert: 20,
    colorValue: 0xff1769aa,
  ),
];

const defaultConnectionId = 'demo';
