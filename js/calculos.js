import { DEFAULT_THRESHOLDS } from "./config.js";

export function normalizeReading(id, raw, calibration) {
  if (!raw || typeof raw !== "object") return null;
  const timestamp = Number(raw.timestamp);
  if (!Number.isFinite(timestamp) || timestamp <= 0) return null;
  let humidity = Number(raw.humedad_pct);
  if (!Number.isFinite(humidity) && Number.isFinite(Number(raw.humedad_raw))) humidity = rawToPercent(Number(raw.humedad_raw), calibration);
  if (!Number.isFinite(humidity)) return null;
  return { id: String(id), timestamp, humidity: clamp(humidity, 0, 100), raw: Number.isFinite(Number(raw.humedad_raw)) ? Number(raw.humedad_raw) : null, pressure: finiteOrNull(raw.u_kpa), reportedStatus: typeof raw.estado === "string" ? raw.estado : null };
}
export function rawToPercent(raw, calibration) {
  if (!calibration || calibration.dry === calibration.wet) return null;
  return clamp(((calibration.dry - raw) / (calibration.dry - calibration.wet)) * 100, 0, 100);
}
export function getStatus(value, thresholds = DEFAULT_THRESHOLDS) {
  if (value >= thresholds.alert) return "Alerta";
  if (value >= thresholds.prealert) return "Prealerta";
  return "Normal";
}
export function statusForReading(reading, thresholds) {
  return ["Normal", "Prealerta", "Alerta"].includes(reading.reportedStatus) ? reading.reportedStatus : getStatus(reading.humidity, thresholds);
}
export function changePerMinute(current, previous) {
  if (!current || !previous || current.timestamp <= previous.timestamp) return null;
  return ((current.humidity - previous.humidity) / ((current.timestamp - previous.timestamp) / 60000));
}
export function formatDate(timestamp) { return new Intl.DateTimeFormat("es-CO", { dateStyle: "short", timeStyle: "medium" }).format(new Date(timestamp)); }
export function formatTime(timestamp) { return new Intl.DateTimeFormat("es-CO", { hour: "2-digit", minute: "2-digit", second: "2-digit" }).format(new Date(timestamp)); }
export function clamp(value, min, max) { return Math.min(max, Math.max(min, value)); }
function finiteOrNull(value) { return Number.isFinite(Number(value)) ? Number(value) : null; }
