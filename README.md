# PICUR · Monitor de ladera

Aplicación web estática en HTML, CSS y JavaScript para consultar lecturas de humedad desde Firebase Realtime Database. La aplicación **solo lee y visualiza** datos de sensores; la escritura la realiza el ESP32.

## Instalación y configuración

1. Copia el proyecto o clónalo.
2. En [js/config.js](./js/config.js), reemplaza los valores `REEMPLAZAR_*` por la configuración de una app web de Firebase. Esta configuración identifica el proyecto, no contiene una contraseña privada.
3. En Firebase Realtime Database, crea el nodo `lecturas`. El navegador se suscribe a ese nodo mediante `onValue`.
4. Publica los archivos como sitio estático. No se requiere `npm install` ni proceso de build.

Para desarrollo local, sirve la carpeta con cualquier servidor HTTP (por ejemplo, la extensión Live Server). Los módulos ES y el import dinámico del SDK no funcionan correctamente con `file://`.

## Formato enviado por ESP32

Cada lectura debe estar en `lecturas/{id}`:

```json
{
  "timestamp": 1730851200000,
  "humedad_pct": 41.5,
  "humedad_raw": 512,
  "estado": "Normal",
  "u_kpa": null
}
```

`timestamp` es epoch en milisegundos. `humedad_raw`, `estado` y `u_kpa` son opcionales. Si falta `estado`, el navegador lo calcula con los umbrales guardados localmente. Si falta `humedad_pct` pero existe `humedad_raw`, se utiliza la calibración local.

## Reglas de seguridad

Para una demo pública de solo lectura puede usarse el contenido de [firebase.rules.json](./firebase.rules.json). Antes de producción, no se recomienda dejar `.read: true`: usa Firebase Authentication y reglas que permitan leer solo a usuarios autenticados. El ESP32 debe escribir con credenciales o un mecanismo de servidor seguro; nunca expongas una clave privada en el frontend.

## GitHub Pages

En GitHub: **Settings → Pages → Deploy from a branch**, selecciona `main` y la carpeta `/ (root)`. `index.html` es el punto de entrada. Si el repositorio se sirve bajo una subruta, las rutas relativas de esta aplicación continúan funcionando.

## Funcionalidades

- Suscripción en tiempo real, indicador de señal después de 30 segundos sin lectura y manejo de base vacía.
- Dashboard, gráfica Chart.js con rangos de 1 h, 6 h, 24 h y todo.
- Umbrales de prealerta/alerta, modo oscuro, alertas visuales y vibración en dispositivos compatibles.
- Historial filtrable por fecha/estado, paginado y exportable a CSV.
- Calibración RAW seco/saturado, almacenada solo en `localStorage`.
- Modo demo para probar la interfaz sin hardware.

## Activar presión de poros

La arquitectura de métricas está en `METRICS` dentro de [js/config.js](./js/config.js). Cuando el ESP32 comience a enviar `u_kpa`, cambia `active: false` a `active: true` en la métrica `porePressure` y ajusta sus umbrales. El dashboard incorporará la tarjeta automáticamente sin cambiar `db.js` ni la estructura de la UI.
