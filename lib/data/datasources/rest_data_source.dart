import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/data_source.dart';
import '../../models/connection_profile.dart';
import '../../models/metric_config.dart';
import '../../models/reading.dart';
import '../reading_parser.dart';
import '../secure_credentials.dart';

class RestDataSource implements DataSource {
  RestDataSource(this.profile, this.metrics, {http.Client? client, SecureCredentials? credentials})
      : _client = client ?? http.Client(),
        _credentials = credentials ?? const SecureCredentials();

  final ConnectionProfile profile;
  final List<MetricConfig> metrics;
  final http.Client _client;
  final SecureCredentials _credentials;
  Timer? _timer;
  final _controller = StreamController<List<Reading>>.broadcast();

  Uri get requestUri => Uri.parse('${profile.url.replaceFirst(RegExp(r'/$'), '')}/${profile.endpoint.replaceFirst(RegExp(r'^/'), '')}');

  @override
  Future<void> probarConexion() async {
    final response = await _client.get(requestUri, headers: await _headers());
    if (response.statusCode == 401 || response.statusCode == 403) throw const FormatException('Autenticación rechazada.');
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
    ReadingParser(metrics).parse(jsonDecode(response.body));
  }

  @override
  Stream<List<Reading>> streamLecturas() {
    _timer ??= Timer.periodic(Duration(seconds: profile.intervalSeconds.clamp(1, 3600)), (_) => _fetch());
    _fetch();
    return _controller.stream;
  }

  Future<void> _fetch() async {
    try {
      final response = await _client.get(requestUri, headers: await _headers());
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _controller.add(ReadingParser(metrics).parse(jsonDecode(response.body)));
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _controller.addError(const FormatException('Autenticación rechazada.'));
      }
    } catch (error, stack) {
      _controller.addError(error, stack);
    }
  }

  Future<Map<String, String>> _headers() async {
    final headers = Map<String, String>.from(profile.headers);
    final token = await _credentials.read(profile.tokenKey);
    if (token != null && token.isNotEmpty) headers['Authorization'] ??= 'Bearer $token';
    return headers;
  }

  @override
  Future<List<Reading>> obtenerHistorial(DateTime desde, DateTime hasta) async {
    final response = await _client.get(requestUri, headers: await _headers());
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
    return ReadingParser(metrics).parse(jsonDecode(response.body))
        .where((r) => !r.timestamp.isBefore(desde) && !r.timestamp.isAfter(hasta)).toList();
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
    _client.close();
  }
}
