import 'models/connection_profile.dart';
import 'models/metric_config.dart';

// ======================= FIREBASE =======================
/// URL de la Realtime Database, SIN "/" al final.
/// Firebase console -> Realtime Database -> pestaña "Datos" -> copiar la URL.
/// Debe ser la misma que FIREBASE_URL en Picur_Esp32.ino.
const firebaseDatabaseUrl = 'URL_DE_LA_BASE_DE_DATOS';

/// Nodo que el ESP32 actualiza con la última lectura.
const firebaseNodoActual = 'picur/actual';

const defaultConnectionId = 'firebase-picur';

const defaultFirebaseProfile = ConnectionProfile(
  id: defaultConnectionId,
  name: 'Firebase PICUR',
  type: ConnectionType.firebaseRest,
  url: firebaseDatabaseUrl,
  path: firebaseNodoActual,
  intervalSeconds: 2,
);

// ======================= MAQUETA =======================
/// Altura del recipiente de la maqueta.
const alturaRecipienteCm = 25.0;

/// Peso unitario del agua γw (kN/m³). u [kPa] = γw · h [m].
const gammaAguaKnM3 = 9.81;

// ======================= MÉTRICAS =======================
/// Los umbrales coinciden con la tabla de rangos de lib/domain/simulation.dart
/// y de Picur_Esp32.ino: prealerta = Evacuación temprana, alerta = Peligro.
const defaultMetrics = [
  MetricConfig(
    id: 'humidity',
    name: 'Humedad del suelo',
    field: 'humedad_pct',
    unit: '%',
    active: true,
    prealert: 45,
    alert: 65,
    colorValue: 0xff147d5a,
  ),
  MetricConfig(
    id: 'pressure',
    name: 'Presión de poros',
    field: 'u_kpa',
    unit: 'kPa',
    active: true,
    prealert: 1.5,
    alert: 1.9,
    colorValue: 0xff1769aa,
  ),
  MetricConfig(
    id: 'level',
    name: 'Nivel freático',
    field: 'nivel_cm',
    unit: 'cm',
    active: true,
    prealert: 14,
    alert: 18,
    colorValue: 0xff0288d1,
  ),
  MetricConfig(
    id: 'inclination',
    name: 'Inclinación del terreno',
    field: 'inclinacion_deg',
    unit: '°',
    active: true,
    prealert: 2,
    alert: 5,
    colorValue: 0xff8d6e63,
  ),
];
