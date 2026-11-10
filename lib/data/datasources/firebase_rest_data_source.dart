import 'package:http/http.dart' as http;
import '../../models/connection_profile.dart';
import '../../models/metric_config.dart';
import '../secure_credentials.dart';
import 'rest_data_source.dart';

class FirebaseRestDataSource extends RestDataSource {
  FirebaseRestDataSource(
    ConnectionProfile profile,
    List<MetricConfig> metrics, {
    http.Client? client,
    SecureCredentials? credentials,
  }) : super(profile, metrics, client: client, credentials: credentials);

  @override
  Uri get requestUri => Uri.parse(
        '${profile.url.replaceFirst(RegExp(r'/$'), '')}/${profile.path.replaceFirst(RegExp(r'^/'), '')}.json',
      );
}
