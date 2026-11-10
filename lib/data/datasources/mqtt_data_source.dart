import 'dart:async';
import 'dart:convert';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../../domain/data_source.dart';
import '../../models/connection_profile.dart';
import '../../models/metric_config.dart';
import '../../models/reading.dart';
import '../reading_parser.dart';
import '../secure_credentials.dart';

class MqttDataSource implements DataSource {
  MqttDataSource(this.profile, this.metrics, {SecureCredentials? credentials})
      : _credentials = credentials ?? const SecureCredentials();
  final ConnectionProfile profile;
  final List<MetricConfig> metrics;
  final SecureCredentials _credentials;
  MqttServerClient? _client;
  final _controller = StreamController<List<Reading>>.broadcast();

  @override
  Future<void> probarConexion() async {
    await _connect();
    _client?.disconnect();
  }

  Future<void> _connect() async {
    final client = MqttServerClient.withPort(profile.broker, 'picur-${DateTime.now().millisecondsSinceEpoch}', profile.port);
    client.secure = profile.tls;
    client.keepAlivePeriod = 30;
    client.logging(on: false);
    final password = await _credentials.read(profile.passwordKey);
    client.connect(profile.username, password);
    if (client.connectionStatus?.state != MqttConnectionState.connected) {
      throw Exception('No fue posible conectar al broker MQTT.');
    }
    client.subscribe(profile.topic, MqttQos.atMostOnce);
    client.updates?.listen((events) {
      for (final event in events) {
        if (event.payload is MqttPublishMessage) {
          final payload = MqttPublishPayload.bytesToStringAsString(
              (event.payload as MqttPublishMessage).payload.message);
          try {
            _controller.add(ReadingParser(metrics).parse(jsonDecode(payload)));
          } catch (error, stack) {
            _controller.addError(error, stack);
          }
        }
      }
    });
    _client = client;
  }

  @override
  Stream<List<Reading>> streamLecturas() {
    _connect().catchError(_controller.addError);
    return _controller.stream;
  }

  @override
  Future<List<Reading>> obtenerHistorial(DateTime desde, DateTime hasta) async =>
      const <Reading>[];

  @override
  Future<void> dispose() async {
    _client?.disconnect();
    await _controller.close();
  }
}
