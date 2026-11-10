import '../domain/data_source.dart';
import '../models/connection_profile.dart';
import '../models/metric_config.dart';
import 'datasources/firebase_rest_data_source.dart';
import 'datasources/mqtt_data_source.dart';
import 'datasources/rest_data_source.dart';

DataSource createDataSource(ConnectionProfile profile, List<MetricConfig> metrics) =>
    switch (profile.type) {
      ConnectionType.firebaseRest => FirebaseRestDataSource(profile, metrics),
      ConnectionType.rest => RestDataSource(profile, metrics),
      ConnectionType.mqtt => MqttDataSource(profile, metrics),
    };
