import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureCredentials {
  const SecureCredentials([this.storage = const FlutterSecureStorage()]);
  final FlutterSecureStorage storage;

  Future<void> save(String key, String? value) async {
    if (value == null || value.isEmpty) {
      await storage.delete(key: key);
    } else {
      await storage.write(key: key, value: value);
    }
  }

  Future<String?> read(String? key) => key == null ? Future.value(null) : storage.read(key: key);
}
