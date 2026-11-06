import { METRICS } from "./config.js";
import { formatDate, formatTime, statusForReading } from "./calculos.js";

const $ = selector => document.querySelector(selector);
export function renderMetricCards(latest, previous, change, thresholds, lastTimestamp) {
  const humidity = latest?.humidity;
  const cards = METRICS.filter(metric => metric.active).map(metric => {
    if (metric.id === "humidity") return `<article class="metric-card"><span class="metric-label">${metric.name}</span><span class="metric-spark">↗</span><div class="metric-value">${humidity == null ? "—" : humidity.toFixed(1)}<small> ${metric.unit}</small></div><span class="metric-meta">${lastTimestamp ? `Última lectura ${formatTime(lastTimestamp)}` : "Sin lecturas recibidas"}</span></article>`;
    const pressure = latest?.pressure;
    return `<article class="metric-card"><span class="metric-label">${metric.name}</span><div class="metric-value">${pressure == null ? "—" : pressure.toFixed(metric.decimals)}<small> ${metric.unit}</small></div><span class="metric-meta">${pressure == null ? "Sensor no conectado" : "Lectura actual"}</span></article>`;
  });
  cards.push(`<article class="metric-card"><span class="metric-label">Tasa de cambio</span><span class="metric-spark">${change != null && change >= 0 ? "↗" : "↘"}</span><div class="metric-value">${change == null ? "—" : `${change >= 0 ? "+" : ""}${change.toFixed(2)}`}<small> %/min</small></div><span class="metric-meta">${previous ? "Comparada con lectura anterior" : "Esperando segunda lectura"}</span></article>`);
  $("#metric-grid").innerHTML = cards.join("");
}
export function renderStatus(status, thresholds, lastTimestamp, isOffline) {
  const banner = $("#status-banner");
  banner.className = `status-banner status-${status.toLowerCase()}`;
  $("#status-text").textContent = isOffline ? "Sin señal del sensor" : status;
  $("#status-detail").textContent = isOffline ? "No se reciben datos hace más de 30 segundos" : status === "Normal" ? "Dentro de los parámetros esperados" : "Revisa la tendencia de humedad";
  $("#banner-prealert").textContent = `${thresholds.prealert}%`; $("#banner-alert").textContent = `${thresholds.alert}%`;
  $(".status-icon").textContent = isOffline ? "!" : status === "Alerta" ? "!" : status === "Prealerta" ? "!" : "✓";
  const signal = $("#signal-status"); signal.className = `signal-badge ${isOffline ? "offline" : lastTimestamp ? "live" : ""}`; signal.innerHTML = `<i></i> ${isOffline ? "Sin señal del sensor" : lastTimestamp ? "Sensor conectado" : "Esperando datos"}`;
  $("#connection-pill").className = `pill ${isOffline ? "pill-offline" : lastTimestamp ? "pill-live" : "pill-muted"}`; $("#connection-pill").innerHTML = `<i></i> ${isOffline ? "Sin señal" : lastTimestamp ? "En línea" : "Conectando"}`;
}
export function renderReadings(container, readings, thresholds, limit = null) {
  const rows = (limit ? readings.slice(0, limit) : readings).map(item => { const status = statusForReading(item, thresholds); return `<tr><td>${formatDate(item.timestamp)}</td><td><strong>${item.humidity.toFixed(1)}%</strong></td><td>${item.raw ?? "—"}</td><td><span class="state-tag ${status.toLowerCase()}">${status}</span></td></tr>`; }).join("");
  container.innerHTML = `<table class="reading-table"><thead><tr><th>Fecha y hora</th><th>Humedad</th><th>RAW</th><th>Estado</th></tr></thead><tbody>${rows || `<tr><td colspan="4" class="muted">No hay lecturas para mostrar.</td></tr>`}</tbody></table>`;
}
export function showToast(message, error = false) { const toast = document.createElement("div"); toast.className = `toast${error ? " error" : ""}`; toast.textContent = message; $("#toast-region").append(toast); setTimeout(() => toast.remove(), 4000); }
export function renderAlerts(alerts) { $("#alerts-list").innerHTML = alerts.length ? alerts.map(a => `<article class="alert-event"><span class="event-icon">${a.status === "Alerta" ? "🔴" : "🟡"}</span><div><strong>Estado: ${a.status}</strong><time>${formatDate(a.timestamp)} · Humedad ${a.humidity.toFixed(1)}%</time></div></article>`).join("") : `<div class="card form-card"><p class="muted">No hay eventos registrados.</p></div>`; $("#alert-count").textContent = alerts.length; }
