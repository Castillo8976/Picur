class MetricConfig {
  const MetricConfig({
    required this.id,
    required this.name,
    required this.field,
    required this.unit,
    required this.active,
    required this.prealert,
    required this.alert,
    this.timeField = 'timestamp',
    this.timeFormat = 'epoch_ms',
    this.factor = 1,
    this.offset = 0,
    this.dryRaw,
    this.wetRaw,
    this.rises = true,
    this.colorValue = 0xff147d5a,
    this.iconCodePoint = 0xe7f4,
  });

  final String id, name, field, unit, timeField, timeFormat;
  final bool active, rises;
  final double prealert, alert, factor, offset;
  final double? dryRaw, wetRaw;
  final int colorValue, iconCodePoint;

  MetricConfig copyWith({
    String? id,
    String? name,
    String? field,
    String? unit,
    bool? active,
    double? prealert,
    double? alert,
    String? timeField,
    String? timeFormat,
    double? factor,
    double? offset,
    double? dryRaw,
    double? wetRaw,
    bool? rises,
    int? colorValue,
    int? iconCodePoint,
  }) =>
      MetricConfig(
        id: id ?? this.id,
        name: name ?? this.name,
        field: field ?? this.field,
        unit: unit ?? this.unit,
        active: active ?? this.active,
        prealert: prealert ?? this.prealert,
        alert: alert ?? this.alert,
        timeField: timeField ?? this.timeField,
        timeFormat: timeFormat ?? this.timeFormat,
        factor: factor ?? this.factor,
        offset: offset ?? this.offset,
        dryRaw: dryRaw ?? this.dryRaw,
        wetRaw: wetRaw ?? this.wetRaw,
        rises: rises ?? this.rises,
        colorValue: colorValue ?? this.colorValue,
        iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'field': field,
        'unit': unit,
        'active': active,
        'prealert': prealert,
        'alert': alert,
        'timeField': timeField,
        'timeFormat': timeFormat,
        'factor': factor,
        'offset': offset,
        'dryRaw': dryRaw,
        'wetRaw': wetRaw,
        'rises': rises,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
      };

  factory MetricConfig.fromJson(Map<String, dynamic> json) => MetricConfig(
        id: json['id'] as String? ?? 'metric-${DateTime.now().microsecondsSinceEpoch}',
        name: json['name'] as String? ?? 'Métrica',
        field: json['field'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        prealert: (json['prealert'] as num?)?.toDouble() ?? 60,
        alert: (json['alert'] as num?)?.toDouble() ?? 75,
        timeField: json['timeField'] as String? ?? 'timestamp',
        timeFormat: json['timeFormat'] as String? ?? 'epoch_ms',
        factor: (json['factor'] as num?)?.toDouble() ?? 1,
        offset: (json['offset'] as num?)?.toDouble() ?? 0,
        dryRaw: (json['dryRaw'] as num?)?.toDouble(),
        wetRaw: (json['wetRaw'] as num?)?.toDouble(),
        rises: json['rises'] as bool? ?? true,
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xff147d5a,
        iconCodePoint: (json['iconCodePoint'] as num?)?.toInt() ?? 0xe7f4,
      );
}
