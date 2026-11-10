enum ConnectionType { firebaseRest, rest, mqtt }

extension ConnectionTypeLabel on ConnectionType {
  String get label => switch (this) {
        ConnectionType.firebaseRest => 'Firebase Realtime Database (REST)',
        ConnectionType.rest => 'API REST genérica',
        ConnectionType.mqtt => 'MQTT',
      };
}

class ConnectionProfile {
  const ConnectionProfile({
    required this.id,
    required this.name,
    required this.type,
    this.url = '',
    this.endpoint = '',
    this.path = '',
    this.method = 'GET',
    this.headers = const {},
    this.intervalSeconds = 5,
    this.broker = '',
    this.port = 1883,
    this.topic = '',
    this.username = '',
    this.passwordKey,
    this.tokenKey,
    this.tls = false,
  });

  final String id, name, url, endpoint, path, method, broker, topic;
  final ConnectionType type;
  final Map<String, String> headers;
  final int intervalSeconds, port;
  final bool tls;
  final String? username, passwordKey, tokenKey;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'url': url,
        'endpoint': endpoint,
        'path': path,
        'method': method,
        'headers': headers,
        'intervalSeconds': intervalSeconds,
        'broker': broker,
        'port': port,
        'topic': topic,
        'username': username,
        'tls': tls,
      };

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) =>
      ConnectionProfile(
        id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'Conexión',
        type: ConnectionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => ConnectionType.rest,
        ),
        url: json['url'] as String? ?? '',
        endpoint: json['endpoint'] as String? ?? '',
        path: json['path'] as String? ?? '',
        method: json['method'] as String? ?? 'GET',
        headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
        intervalSeconds: (json['intervalSeconds'] as num?)?.toInt() ?? 5,
        broker: json['broker'] as String? ?? '',
        port: (json['port'] as num?)?.toInt() ?? 1883,
        topic: json['topic'] as String? ?? '',
        username: json['username'] as String?,
        tls: json['tls'] as bool? ?? false,
      );
}
