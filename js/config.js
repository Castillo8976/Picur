export const FIREBASE_CONFIG = {
  apiKey: "REEMPLAZAR_API_KEY",
  authDomain: "REEMPLAZAR_PROJECT.firebaseapp.com",
  databaseURL: "https://REEMPLAZAR_PROJECT-default-rtdb.firebaseio.com",
  projectId: "REEMPLAZAR_PROJECT",
  storageBucket: "REEMPLAZAR_PROJECT.firebasestorage.app",
  messagingSenderId: "REEMPLAZAR_SENDER_ID",
  appId: "REEMPLAZAR_APP_ID"
};

// Agregar una métrica aquí permite que las tarjetas y gráficas futuras sean configurables.
export const METRICS = [
  { id: "humidity", name: "Humedad del suelo", field: "humedad_pct", unit: "%", active: true, decimals: 1, prealertThreshold: 60, alertThreshold: 75 },
  { id: "porePressure", name: "Presión de poros", field: "u_kpa", unit: "kPa", active: false, decimals: 2, prealertThreshold: 15, alertThreshold: 25 }
];

export const DB_PATH = "lecturas";
export const SETTINGS_KEYS = { thresholds: "picur.thresholds.v1", calibration: "picur.calibration.v1", theme: "picur.theme.v1", alerts: "picur.alerts.v1" };
export const DEFAULT_THRESHOLDS = { prealert: 60, alert: 75 };
export const SIGNAL_TIMEOUT_MS = 30_000;
