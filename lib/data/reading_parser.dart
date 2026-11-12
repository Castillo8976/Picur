import '../models/metric_config.dart';
import '../models/reading.dart';

class ReadingParser {
  const ReadingParser(this.metrics);
  final List<MetricConfig> metrics;

  List<Reading> parse(dynamic payload) {
    final entries = <Map<String, dynamic>>[];
    // Firebase responde "null" cuando el nodo todavía no existe.
    if (payload == null) return [];
    if (payload is List) {
      entries.addAll(payload.whereType<Map>().map(_map));
    } else if (payload is Map) {
      final map = _map(payload);
      final values = payload.values;
      if (values.isNotEmpty && values.every((v) => v is Map)) {
        entries.addAll(payload.entries.map((e) {
          final item = _map(e.value as Map);
          item['_id'] = e.key.toString();
          return item;
        }));
      } else {
        entries.add(map);
      }
    } else {
      throw const FormatException('La respuesta no contiene un objeto JSON o una lista.');
    }

    return [
      for (var index = 0; index < entries.length; index++)
        if (_tryParse(entries[index], 'reading-$index') case final value?) value,
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Map<String, dynamic> _map(Map value) =>
      value.map((key, value) => MapEntry(key.toString(), value));

  Reading? _tryParse(Map<String, dynamic> data, String fallbackId) {
    final timestamp = _timestamp(data);
    if (timestamp == null) return null;
    final values = <String, double>{};
    for (final metric in metrics.where((metric) => metric.active)) {
      final raw = _number(data[metric.field]);
      if (raw == null) continue;
      var value = raw * metric.factor + metric.offset;
      if (metric.dryRaw != null && metric.wetRaw != null && metric.dryRaw != metric.wetRaw) {
        value = ((metric.dryRaw! - raw) / (metric.dryRaw! - metric.wetRaw!) * 100).clamp(0, 100).toDouble();
      }
      values[metric.id] = value;
    }
    if (values.isEmpty) return null;
    return Reading(
      id: data['_id']?.toString() ?? data['id']?.toString() ?? fallbackId,
      timestamp: timestamp,
      values: values,
      raw: data,
    );
  }

  DateTime? _timestamp(Map<String, dynamic> data) {
    final metric = metrics.firstWhere(
      (m) => data[m.timeField] != null,
      orElse: () => metrics.first,
    );
    final value = data[metric.timeField] ?? data['timestamp'];
    if (value is num) {
      final number = value.toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        metric.timeFormat == 'epoch_s'
            ? number * 1000
            : metric.timeFormat == 'epoch_ms'
                ? (number < 100000000000 ? number * 1000 : number)
                : number < 100000000000
                    ? number * 1000
                    : number,
      );
    }
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  double? _number(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value');
}
