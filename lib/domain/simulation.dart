import '../config.dart';
import '../models/reading.dart';

/// Rango de humedad y valores simulados para la maqueta de 25 cm.
/// Es la misma tabla de Picur_Esp32.ino: si cambias una, cambia la otra.
class RangoSimulacion {
  const RangoSimulacion(this.humedadMin, this.humedadMax, this.nivelCm, this.inclinacionDeg, this.estado);
  final int humedadMin; // incluido
  final int humedadMax; // excluido
  final double nivelCm;
  final double inclinacionDeg;
  final AlertState estado;
}

const rangosSimulacion = [
  RangoSimulacion(0, 5, 5, 0.0, AlertState.normal),
  RangoSimulacion(5, 25, 8, 0.5, AlertState.normal),
  RangoSimulacion(25, 45, 12, 1.5, AlertState.normal),
  RangoSimulacion(45, 65, 16, 3.0, AlertState.prealerta),
  RangoSimulacion(65, 85, 20, 6.0, AlertState.alerta),
  RangoSimulacion(85, 101, 24, 10.0, AlertState.alerta),
];

/// u = γw · h  ->  kPa (h en metros).
double presionPorosKpa(double nivelCm) => gammaAguaKnM3 * (nivelCm / 100);

/// Valores de la app (por id de métrica) simulados a partir de la humedad.
/// Se usa en el modo demo; con el ESP32 conectado los valores llegan de Firebase.
({Map<String, double> values, AlertState estado}) simularDesdeHumedad(double humedad) {
  final h = humedad.clamp(0, 100).round();
  final rango = rangosSimulacion.firstWhere(
    (r) => h >= r.humedadMin && h < r.humedadMax,
    orElse: () => rangosSimulacion.last,
  );
  final nivel = rango.nivelCm.clamp(0, alturaRecipienteCm).toDouble();
  return (
    values: {
      'humidity': h.toDouble(),
      'level': nivel,
      'pressure': presionPorosKpa(nivel),
      'inclination': rango.inclinacionDeg,
    },
    estado: rango.estado,
  );
}
