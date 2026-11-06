# PICUR Monitor · Flutter

Aplicación móvil nativa para Android e iOS. Consulta lecturas de humedad desde Firebase Realtime Database; no escribe datos de sensores. Incluye dashboard, estado sin señal después de 30 segundos, historial, alertas, umbrales locales, modo oscuro y modo demo.

## Requisitos

- Flutter 3.22 o superior
- Android Studio y/o Xcode
- Un proyecto Firebase propio

El SDK de Flutter no estaba instalado al preparar este repositorio, así que las carpetas generadas específicas de plataforma se crean localmente con Flutter.

## Preparar el proyecto

```bash
flutter create .
flutter pub get
dart pub global activate flutterfire_cli
flutterfire configure
flutter run
```

Selecciona el proyecto Firebase y las plataformas Android/iOS. El comando `flutterfire configure` reemplazará `lib/firebase_options.dart` con la configuración pública de tu propio proyecto. No se vincula ninguna cuenta Gmail automáticamente.

## Base de datos y ESP32

El ESP32 escribe en `lecturas/{id}`:

```json
{
  "timestamp": 1730851200000,
  "humedad_pct": 41.5,
  "humedad_raw": 512,
  "estado": "Normal",
  "u_kpa": null
}
```

La app se suscribe con `FirebaseDatabase.instance.ref('lecturas').onValue`. Si hay una lectura malformada, se ignora esa lectura y se conservan las válidas. Las reglas iniciales están en `firebase.rules.json`; en producción usa Firebase Authentication y restringe las lecturas a usuarios autenticados.

## Configuración modular

Las métricas están en `lib/config.dart`. Para activar presión de poros cuando el ESP32 envíe `u_kpa`, cambia `active: false` a `active: true` en la métrica correspondiente y ajusta la interfaz si quieres mostrar su tarjeta dedicada.

## Uso sin hardware

Desde el menú lateral activa **Modo demo**. Genera humedad progresiva para probar los estados de prealerta y alerta sin escribir nada en Firebase.
