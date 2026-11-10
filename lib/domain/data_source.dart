import '../models/reading.dart';

abstract interface class DataSource {
  Future<void> probarConexion();
  Stream<List<Reading>> streamLecturas();
  Future<List<Reading>> obtenerHistorial(DateTime desde, DateTime hasta);
  Future<void> dispose();
}
