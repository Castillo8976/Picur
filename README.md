# PICUR Monitor

Visor Flutter reutilizable para datos IoT. La aplicación solo lee datos: no escribe
lecturas en Firebase, MQTT ni APIs REST.

## Requisitos e instalación

- Flutter estable con Dart 3.3 o superior.
- Android Studio para Android; Xcode para iOS.

```bash
flutter pub get
flutter run
flutter build apk --release
```

La app no necesita `google-services.json`: Firebase Realtime Database se consume
por REST. En Android se declara `INTERNET` y `POST_NOTIFICATIONS` en
`android/app/src/main/AndroidManifest.xml`.

## Configuración desde la app

1. Abre **Conexiones** y crea un perfil.
2. Selecciona **Firebase REST**, **API REST genérica** o **MQTT**.
3. Prueba la conexión y selecciona el perfil activo.
4. En **Sensores / Métricas**, activa o crea métricas y asigna sus campos JSON,
   unidad, campo de tiempo, umbrales y dirección de alerta.

Los perfiles y métricas se guardan localmente. Las claves y contraseñas usan
`flutter_secure_storage`; el resto de la configuración usa `shared_preferences`.
El modelo `ConnectionProfile` permite exportar/importar JSON sin incluir secretos.

### Firebase Realtime Database REST

- `databaseURL`: por ejemplo `https://proyecto-default-rtdb.firebaseio.com`
- Ruta: `lecturas`
- La app consulta `lecturas.json` periódicamente y acepta un token Bearer.
- Un nodo puede ser un objeto indexado por id o una lista de objetos.

### API REST genérica

La respuesta debe ser un objeto JSON o una lista de objetos. Ejemplo:

```json
[
  {"id":"a1","timestamp":1730851200000,"humedad_pct":41.5},
  {"id":"a2","timestamp":"2026-11-10T15:00:00Z","humedad_pct":43.1}
]
```

Para MySQL/MariaDB se recomienda un backend propio de solo lectura que exponga
este JSON. Se soportan epoch en segundos o milisegundos e ISO 8601.

### MQTT

Configura broker, puerto, TLS y topic. Cada mensaje del topic debe ser JSON con
los campos definidos en **Sensores / Métricas**. MQTT no ofrece historial por sí
mismo; el historial mostrado corresponde a los mensajes recibidos durante la
sesión.

## PICUR y presión de poros

La plantilla **Humedad del suelo (PICUR)** usa `humedad_pct` y `timestamp`.
**Presión de poros (kPa)** usa `u_kpa`, está desactivada inicialmente y puede
activarse desde la interfaz. Para obtener altura equivalente de agua:

`h (m) = u (kPa) / 9.81`

La calibración raw → porcentaje admite dos puntos seco/saturado. Una métrica sin
valor se presenta como **Sensor no conectado**, no como error.

## Funciones

Dashboard en tiempo real, estado global Normal/Prealerta/Alerta/Sin señal,
gráficas con umbrales y zoom táctil de `fl_chart`, historial exportable a CSV,
registro de alertas, perfiles reutilizables, tema claro/oscuro y modo demo.

El analizador tolera lecturas inválidas, campos faltantes y respuestas vacías;
las lecturas válidas permanecen visibles.
