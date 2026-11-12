import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../config.dart';
import '../data/datasource_factory.dart';
import '../data/preferences_repository.dart';
import '../domain/data_source.dart';
import '../domain/simulation.dart';
import '../models/connection_profile.dart';
import '../models/metric_config.dart';
import '../models/reading.dart';
import '../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeMode, required this.onThemeChanged});
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repository = PreferencesRepository();
  final readings = <Reading>[];
  List<MetricConfig> metrics = [...defaultMetrics];
  List<ConnectionProfile> profiles = [];
  DataSource? source;
  StreamSubscription<List<Reading>>? subscription;
  int page = 0;
  bool demo = false;
  Timer? demoTimer;
  Timer? uiTimer;
  String? activeId;
  String message = '';
  DateTime? lastData;
  final notifications = NotificationService();
  AlertState? notifiedState;

  final pageTitles = const ['Dashboard', 'Gráficas', 'Historial', 'Alertas', 'Conexiones', 'Sensores / Métricas', 'Ajustes'];

  @override
  void initState() {
    super.initState();
    notifications.initialize();
    _load();
    // Repinta cada 5 s para detectar "Sin señal" aunque no lleguen datos.
    uiTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    final loadedMetrics = await repository.metrics();
    final loadedProfiles = await repository.profiles();
    activeId = await repository.activeConnection();
    if (!mounted) return;
    setState(() {
      metrics = loadedMetrics;
      profiles = loadedProfiles;
    });
    if (activeId != null) _connect();
  }

  Future<void> _connect() async {
    final profile = profiles.where((p) => p.id == activeId).firstOrNull;
    if (profile == null) return;
    await subscription?.cancel();
    await source?.dispose();
    final next = createDataSource(profile, metrics);
    setState(() => message = 'Conectando con ${profile.name}...');
    source = next;
    subscription = next.streamLecturas().listen((items) {
      if (!mounted || demo) return;
      // Firebase se consulta cada pocos segundos y devuelve la misma lectura
      // hasta que el ESP32 la actualiza: solo se agregan lecturas nuevas.
      final newest = readings.lastOrNull?.timestamp;
      final fresh = items.where((r) => newest == null || r.timestamp.isAfter(newest)).toList();
      setState(() {
        message = '';
        if (fresh.isEmpty) return;
        readings.addAll(fresh);
        readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        if (readings.length > 1000) readings.removeRange(0, readings.length - 1000);
        lastData = DateTime.now();
      });
      if (fresh.isNotEmpty) _notifyIfNeeded();
    }, onError: (Object error) {
      if (mounted) setState(() => message = 'Error de conexión: $error');
    });
  }

  void toggleDemo() {
    if (demo) {
      demoTimer?.cancel();
      setState(() {
        demo = false;
        // Se quitan las lecturas de la demo para volver a los datos reales.
        readings.removeWhere((r) => r.id.startsWith('demo-'));
        lastData = readings.isEmpty ? null : DateTime.now();
      });
      return;
    }
    // Simula un suelo que se va saturando (0 % -> 100 %) y vuelve a empezar.
    double humidity = readings.lastOrNull?.values['humidity'] ?? 0.0;
    void tick() {
      humidity = humidity >= 100 ? 0.0 : (humidity + 4).clamp(0, 100).toDouble();
      final sim = simularDesdeHumedad(humidity);
      final now = DateTime.now();
      setState(() {
        readings.add(Reading(
          id: 'demo-${now.microsecondsSinceEpoch}',
          timestamp: now,
          values: sim.values,
          raw: {'estado_codigo': sim.estado.index},
        ));
        lastData = now;
      });
      _notifyIfNeeded();
    }
    tick();
    demoTimer = Timer.periodic(const Duration(seconds: 3), (_) => tick());
    setState(() => demo = true);
  }

  @override
  void dispose() {
    demoTimer?.cancel();
    uiTimer?.cancel();
    subscription?.cancel();
    source?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (page) {
      0 => _dashboard(),
      1 => _charts(),
      2 => _history(),
      3 => _alerts(),
      4 => _connections(),
      5 => _metrics(),
      _ => _settings(),
    };
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('PICUR', style: TextStyle(fontWeight: FontWeight.w800)),
          Text(' · ${pageTitles[page]}'),
        ]),
        actions: [
          if (demo) const Chip(label: Text('DEMO')),
          IconButton(onPressed: toggleDemo, tooltip: demo ? 'Detener demo' : 'Modo demo', icon: Icon(demo ? Icons.stop_circle : Icons.play_circle)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('PICUR Monitor\nVisor IoT reutilizable', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
            for (var i = 0; i < pageTitles.length; i++)
              ListTile(
                leading: Icon([Icons.dashboard, Icons.show_chart, Icons.table_chart, Icons.warning_amber, Icons.cloud, Icons.sensors, Icons.settings][i]),
                title: Text(pageTitles[i]),
                selected: page == i,
                onTap: () { setState(() => page = i); Navigator.pop(context); },
              ),
            const Divider(),
            SwitchListTile(title: const Text('Tema oscuro'), value: widget.themeMode == ThemeMode.dark, onChanged: widget.onThemeChanged),
            ListTile(leading: const Icon(Icons.play_circle), title: Text(demo ? 'Detener modo demo' : 'Activar modo demo'), onTap: toggleDemo),
          ],
        ),
      ),
      body: body,
    );
  }

  List<MetricConfig> get activeMetrics => metrics.where((m) => m.active).toList();
  Reading? latestFor(String id) => readings.lastWhereOrNull((r) => r.values[id] != null);
  AlertState stateForMetric(MetricConfig metric, Reading? reading) {
    if (reading == null || _signalLost) return AlertState.sinSenal;
    return stateFor(reading.values[metric.id]!, metric.prealert, metric.alert, rises: metric.rises);
  }
  void _notifyIfNeeded() {
    final nextState = globalState;
    if (nextState == AlertState.normal) notifiedState = null;
    if (nextState != AlertState.normal &&
        nextState != AlertState.sinSenal &&
        nextState != notifiedState) {
      notifiedState = nextState;
      notifications.alert(nextState.label);
    }
  }

  bool get _signalLost => lastData == null || DateTime.now().difference(lastData!).inSeconds > 30;

  AlertState get globalState {
    final latest = readings.lastOrNull;
    if (latest == null || _signalLost) return AlertState.sinSenal;
    // Si el ESP32 envía el estado, ese manda.
    if (latest.deviceState case final state?) return state;
    final states = activeMetrics.map((m) => stateForMetric(m, latestFor(m.id)));
    if (states.contains(AlertState.alerta)) return AlertState.alerta;
    if (states.contains(AlertState.prealerta)) return AlertState.prealerta;
    if (states.contains(AlertState.sinSenal)) return AlertState.sinSenal;
    return AlertState.normal;
  }

  // ============================ DASHBOARD ============================

  MetricConfig? _metric(String id) => metrics.where((m) => m.id == id).firstOrNull;
  double? _value(String id) => latestFor(id)?.values[id];

  Widget _dashboard() {
    final state = globalState;
    final latest = readings.lastOrNull;
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        if (source != null) await source!.probarConexion();
      },
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
        Text('ESTADO DEL SISTEMA', style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.2)),
        Text('Monitoreo en tiempo real',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        _stateBanner(state),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _valueTile('humidity', max: 100, decimals: 0, note: 'Sensor capacitivo')),
          const SizedBox(width: 12),
          Expanded(child: _valueTile('inclination', max: 15, decimals: 1, note: 'Simulada por humedad')),
        ]),
        const SizedBox(height: 12),
        _pressureCard(),
        const SizedBox(height: 12),
        _stateScale(state),
        const SizedBox(height: 14),
        Row(children: [
          Icon(demo ? Icons.science : Icons.cloud_done, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              latest == null
                  ? 'Esperando datos de ${demo ? 'la demo' : 'Firebase'}...'
                  : 'Última lectura: ${_formatTime(latest.timestamp)} · Fuente: ${demo ? 'modo demo' : 'Firebase'}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _stateBanner(AlertState state) {
    final color = _stateColor(state);
    final (IconData icon, String detail) = switch (state) {
      AlertState.normal => (Icons.verified_user, 'Condiciones estables. No se requiere ninguna acción.'),
      AlertState.prealerta => (Icons.directions_run, 'El nivel freático está subiendo. Prepare la evacuación preventiva.'),
      AlertState.alerta => (Icons.warning_rounded, 'Riesgo alto de deslizamiento. Evacúe la zona de inmediato.'),
      AlertState.sinSenal => (
          Icons.signal_wifi_off,
          message.isNotEmpty ? message : 'No llegan datos del ESP32 desde hace más de 30 segundos.'
        ),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: .35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 36),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Estado de alerta',
                style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(state.label,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(color: Colors.white, fontSize: 13.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _valueTile(String id, {required double max, required int decimals, String? note}) {
    final metric = _metric(id);
    if (metric == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final reading = latestFor(id);
    final value = reading?.values[id];
    final state = stateForMetric(metric, reading);
    final accent = state == AlertState.sinSenal ? Color(metric.colorValue) : _stateColor(state);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _metricIcon(metric),
            const SizedBox(width: 6),
            Expanded(
              child: Text(metric.name,
                  maxLines: 2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
            ),
          ]),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(
              text: value == null ? '--' : value.toStringAsFixed(decimals),
              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: ' ${metric.unit}', style: theme.textTheme.titleMedium),
          ])),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value == null ? 0 : (value / max).clamp(0, 1).toDouble(),
              minHeight: 6,
              color: accent,
              backgroundColor: accent.withValues(alpha: .15),
            ),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Expanded(child: Text(state.label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600))),
          ]),
          if (note != null)
            Text(note, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
        ]),
      ),
    );
  }

  /// Presión de poros con el recipiente de 25 cm y la fórmula u = γw · h.
  Widget _pressureCard() {
    final metric = _metric('pressure');
    if (metric == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final reading = latestFor('pressure');
    final pressure = reading?.values['pressure'];
    // Si no llega nivel_cm, se despeja de la presión: h = u / γw.
    final level = _value('level') ?? (pressure == null ? null : pressure / gammaAguaKnM3 * 100);
    final state = stateForMetric(metric, reading);
    final accent = state == AlertState.sinSenal ? Color(metric.colorValue) : _stateColor(state);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _tank(level),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                _metricIcon(metric),
                const SizedBox(width: 6),
                const Expanded(child: Text('Presión de poros', style: TextStyle(fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 6),
              Text.rich(TextSpan(children: [
                TextSpan(
                  text: pressure == null ? '--' : pressure.toStringAsFixed(2),
                  style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                TextSpan(text: ' kPa', style: theme.textTheme.titleMedium),
              ])),
              const SizedBox(height: 4),
              Text(
                level == null
                    ? 'Nivel freático: --'
                    : 'Nivel freático: ${level.toStringAsFixed(1)} de ${alturaRecipienteCm.toStringAsFixed(0)} cm',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(state.label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              ]),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('u = γw · h', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                  Text(
                    level == null
                        ? 'γw = 9,81 kN/m³ · h en metros'
                        : '9,81 kN/m³ × ${(level / 100).toStringAsFixed(3)} m = ${presionPorosKpa(level).toStringAsFixed(2)} kPa',
                    style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              Text('Simulada por rangos de humedad',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
            ]),
          ),
        ]),
      ),
    );
  }

  /// Recipiente de 25 cm con el agua a la altura h.
  Widget _tank(double? levelCm) {
    final theme = Theme.of(context);
    final double fraction = levelCm == null ? 0.0 : (levelCm / alturaRecipienteCm).clamp(0.0, 1.0).toDouble();
    const height = 150.0;
    return Column(children: [
      Text('${alturaRecipienteCm.toStringAsFixed(0)} cm', style: theme.textTheme.labelSmall),
      const SizedBox(height: 4),
      Container(
        width: 62,
        height: height,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: theme.colorScheme.outline, width: 2),
            right: BorderSide(color: theme.colorScheme.outline, width: 2),
            bottom: BorderSide(color: theme.colorScheme.outline, width: 2),
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
          child: Stack(alignment: Alignment.bottomCenter, children: [
            // Suelo de fondo
            Container(color: const Color(0xff6d4c41).withValues(alpha: .25)),
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              height: height * fraction,
              color: const Color(0xff1e88e5).withValues(alpha: .75),
            ),
            Positioned.fill(
              child: Center(
                child: Text(
                  levelCm == null ? '--' : '${levelCm.toStringAsFixed(0)} cm',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 4),
      Text('h', style: theme.textTheme.labelSmall?.copyWith(fontStyle: FontStyle.italic)),
    ]);
  }

  /// Escala de los tres estados con el actual resaltado.
  Widget _stateScale(AlertState current) {
    final theme = Theme.of(context);
    Widget item(AlertState state, String range) {
      final active = state == current;
      final color = _stateColor(state);
      return Expanded(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: [
            Text(state.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                  color: active ? Colors.white : color,
                )),
            const SizedBox(height: 2),
            Text(range,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: active ? Colors.white : theme.colorScheme.onSurfaceVariant)),
          ]),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Escala de alerta', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            item(AlertState.normal, 'Humedad < 45 %\nh ≤ 12 cm'),
            const SizedBox(width: 8),
            item(AlertState.prealerta, 'Humedad 45–64 %\nh = 16 cm'),
            const SizedBox(width: 8),
            item(AlertState.alerta, 'Humedad ≥ 65 %\nh ≥ 20 cm'),
          ]),
        ]),
      ),
    );
  }

  Widget _charts() => ListView(padding: const EdgeInsets.all(18), children: [
        Text('Series temporales', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...activeMetrics.map((metric) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(metric.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 220, child: LineChart(LineChartData(
            minY: 0, lineTouchData: const LineTouchData(enabled: true), gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(show: false),
            extraLinesData: ExtraLinesData(horizontalLines: [
              HorizontalLine(y: metric.prealert, color: Colors.orange, dashArray: [6, 4]),
              HorizontalLine(y: metric.alert, color: Colors.red, dashArray: [6, 4]),
            ]),
            lineBarsData: [LineChartBarData(isCurved: true, color: Color(metric.colorValue), spots: [
              for (final r in _lastN(readings.where((r) => r.values[metric.id] != null).toList(), 200))
                FlSpot(r.timestamp.millisecondsSinceEpoch.toDouble(), r.values[metric.id]!),
            ])],
          ))),
        ])))),
      ]);

  Widget _history() => ListView(padding: const EdgeInsets.all(18), children: [
        Row(children: [Expanded(child: Text('Historial', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))), IconButton(onPressed: readings.isEmpty ? null : _exportCsv, icon: const Icon(Icons.ios_share), tooltip: 'Exportar CSV')]),
        const SizedBox(height: 8),
        ...readings.reversed.map((r) => Card(child: ListTile(title: Text(r.values.entries.map((e) => '${e.value.toStringAsFixed(2)} (${e.key})').join(' · ')), subtitle: Text(_format(r.timestamp)), trailing: Text(_readingState(r).label)))),
      ]);

  Widget _alerts() {
    final events = readings.where((r) => _readingState(r) != AlertState.normal).toList().reversed;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text('Registro de alertas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (events.isEmpty) const Card(child: ListTile(title: Text('No hay eventos registrados.'))),
      ...events.map((r) => Card(child: ListTile(leading: Icon(Icons.warning, color: _stateColor(_readingState(r))), title: Text(_readingState(r).label), subtitle: Text('${r.values.entries.map((e) => '${e.value.toStringAsFixed(1)} ${e.key}').join(' · ')} · ${_format(r.timestamp)}')))),
    ]);
  }

  Widget _connections() => ListView(padding: const EdgeInsets.all(18), children: [
        Row(children: [
          Expanded(child: Text('Conexiones', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
          IconButton(onPressed: _importProfile, icon: const Icon(Icons.upload_file), tooltip: 'Importar JSON'),
          IconButton(onPressed: profiles.isEmpty ? null : () => _exportProfile(profiles.first), icon: const Icon(Icons.download), tooltip: 'Exportar JSON'),
          IconButton(onPressed: () => _editConnection(), icon: const Icon(Icons.add)),
        ]),
        const Text('Los perfiles se guardan en el dispositivo. Las credenciales se almacenan cifradas.'),
        const SizedBox(height: 12),
        ...profiles.map((profile) => Card(child: ListTile(
          leading: Icon(profile.type == ConnectionType.mqtt ? Icons.sensors : Icons.cloud),
          title: Text(profile.name), subtitle: Text(profile.type.label),
          trailing: Wrap(children: [
            Radio<String>(value: profile.id, groupValue: activeId, onChanged: (id) async { activeId = id; await repository.setActiveConnection(id!); setState(() {}); _connect(); }),
            IconButton(onPressed: () => _testConnection(profile), icon: const Icon(Icons.network_check)),
            IconButton(onPressed: () => _editConnection(profile), icon: const Icon(Icons.edit)),
            IconButton(onPressed: () => _removeConnection(profile), icon: const Icon(Icons.delete_outline)),
          ]),
        ))),
        if (profiles.isEmpty) const Card(child: ListTile(title: Text('Sin perfiles configurados'), subtitle: Text('Añade Firebase REST, una API REST o MQTT.'))),
      ]);

  Widget _metrics() => ListView(padding: const EdgeInsets.all(18), children: [
        Row(children: [Expanded(child: Text('Sensores / Métricas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))), IconButton(onPressed: () => _editMetric(), icon: const Icon(Icons.add))]),
        const Text('Define el campo JSON, tiempo, fórmula, calibración y umbrales sin recompilar.'),
        const SizedBox(height: 12),
        ...metrics.map((metric) => Card(child: SwitchListTile(
          value: metric.active, onChanged: (value) => _saveMetric(metric.copyWith(active: value)),
          secondary: _metricIcon(metric),
          title: Text(metric.name), subtitle: Text('${metric.field} · ${metric.unit} · ${metric.prealert}/${metric.alert}'),
        ))),
      ]);

  Widget _settings() => ListView(padding: const EdgeInsets.all(18), children: [
        Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        SwitchListTile(title: const Text('Tema oscuro'), value: widget.themeMode == ThemeMode.dark, onChanged: widget.onThemeChanged),
        const Card(child: ListTile(leading: Icon(Icons.language), title: Text('Idioma'), subtitle: Text('Español (predeterminado)'))),
        const Card(child: ListTile(leading: Icon(Icons.notifications_active), title: Text('Alertas locales'), subtitle: Text('Se registran los cambios de estado; habilita notificaciones en permisos del sistema.'))),
        const Card(child: ListTile(leading: Icon(Icons.info_outline), title: Text('Sin escritura de lecturas'), subtitle: Text('PICUR solo consulta fuentes de datos. Nunca modifica lecturas.'))),
      ]);

  AlertState _readingState(Reading reading) {
    if (reading.deviceState case final state?) return state;
    final states = activeMetrics.where((m) => reading.values[m.id] != null).map((m) => stateFor(reading.values[m.id]!, m.prealert, m.alert, rises: m.rises));
    if (states.contains(AlertState.alerta)) return AlertState.alerta;
    if (states.contains(AlertState.prealerta)) return AlertState.prealerta;
    return AlertState.normal;
  }
  double _rate(MetricConfig metric) {
    final values = readings.where((r) => r.values[metric.id] != null).toList();
    if (values.length < 2) return 0;
    final a = values[values.length - 2], b = values.last;
    final minutes = b.timestamp.difference(a.timestamp).inMilliseconds / 60000;
    return minutes <= 0 ? 0 : (b.values[metric.id]! - a.values[metric.id]!) / minutes;
  }
  Color _stateColor(AlertState state) => switch (state) {
        AlertState.alerta => const Color(0xffc62828),
        AlertState.prealerta => const Color(0xffef6c00),
        AlertState.sinSenal => const Color(0xff616161),
        AlertState.normal => const Color(0xff2e7d32),
      };
  IconData _iconFor(String metricId) => switch (metricId) {
        'pressure' => Icons.speed,
        'level' => Icons.waves,
        'inclination' => Icons.terrain,
        _ => Icons.water_drop,
      };
  Widget _metricIcon(MetricConfig metric) => Icon(_iconFor(metric.id), color: Color(metric.colorValue));
  List<T> _lastN<T>(List<T> items, int n) => items.length <= n ? items : items.sublist(items.length - n);
  String _formatTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';
  String _format(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  Future<void> _testConnection(ConnectionProfile profile) async {
    try { final test = createDataSource(profile, metrics); await test.probarConexion(); await test.dispose(); if (mounted) _snack('Conexión exitosa.'); }
    catch (error) { if (mounted) _snack('Error: $error'); }
  }

  Future<void> _exportProfile(ConnectionProfile profile) async {
    await Share.share(
      const JsonEncoder.withIndent('  ').convert(profile.toJson()),
      subject: 'Perfil de conexión PICUR',
    );
  }

  Future<void> _importProfile() async {
    final controller = TextEditingController();
    final imported = await showDialog<ConnectionProfile>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar perfil JSON'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(hintText: '{"name":"Mi API","type":"rest",...}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              try {
                Navigator.pop(context, ConnectionProfile.fromJson(jsonDecode(controller.text) as Map<String, dynamic>));
              } catch (_) {
                _snack('JSON inválido.');
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    );
    if (imported == null) return;
    final index = profiles.indexWhere((profile) => profile.id == imported.id);
    setState(() {
      if (index < 0) {
        profiles.add(imported);
      } else {
        profiles[index] = imported;
      }
    });
    await repository.saveProfiles(profiles);
  }
  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _removeConnection(ConnectionProfile profile) async {
    await repository.saveProfiles(profiles..remove(profile));
    if (activeId == profile.id) { activeId = null; await subscription?.cancel(); await source?.dispose(); }
    setState(() {});
  }
  Future<void> _saveMetric(MetricConfig metric) async {
    final index = metrics.indexWhere((m) => m.id == metric.id);
    setState(() { if (index < 0) metrics.add(metric); else metrics[index] = metric; });
    await repository.saveMetrics(metrics);
  }
  Future<void> _editConnection([ConnectionProfile? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final url = TextEditingController(text: existing?.url ?? '');
    final endpoint = TextEditingController(text: existing?.endpoint ?? existing?.path ?? '');
    var type = existing?.type ?? ConnectionType.rest;
    final result = await showDialog<ConnectionProfile>(context: context, builder: (context) => StatefulBuilder(builder: (context, set) => AlertDialog(
      title: Text(existing == null ? 'Nueva conexión' : 'Editar conexión'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
        DropdownButtonFormField(value: type, items: ConnectionType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(), onChanged: (v) => set(() => type = v!)),
        TextField(controller: url, decoration: InputDecoration(labelText: type == ConnectionType.mqtt ? 'Broker' : 'URL base / databaseURL')),
        TextField(controller: endpoint, decoration: InputDecoration(labelText: type == ConnectionType.firebaseRest ? 'Ruta del nodo' : type == ConnectionType.mqtt ? 'Topic' : 'Endpoint')),
        if (type != ConnectionType.mqtt) const Text('GET y consulta cada 5 segundos por defecto. Añade encabezados/token en la versión completa del perfil.', style: TextStyle(fontSize: 12)),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, ConnectionProfile(id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(), name: name.text.trim().isEmpty ? 'Conexión' : name.text.trim(), type: type, url: type == ConnectionType.mqtt ? '' : url.text.trim(), broker: type == ConnectionType.mqtt ? url.text.trim() : '', endpoint: type == ConnectionType.rest ? endpoint.text.trim() : '', path: type == ConnectionType.firebaseRest ? endpoint.text.trim() : '', topic: type == ConnectionType.mqtt ? endpoint.text.trim() : '')), child: const Text('Guardar'))],
    )));
    if (result == null) return;
    final index = profiles.indexWhere((p) => p.id == result.id);
    setState(() { if (index < 0) profiles.add(result); else profiles[index] = result; });
    await repository.saveProfiles(profiles);
  }

  Future<void> _editMetric([MetricConfig? existing]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final field = TextEditingController(text: existing?.field ?? '');
    final unit = TextEditingController(text: existing?.unit ?? '%');
    final pre = TextEditingController(text: '${existing?.prealert ?? 60}');
    final alert = TextEditingController(text: '${existing?.alert ?? 75}');
    final result = await showDialog<MetricConfig>(context: context, builder: (context) => AlertDialog(
      title: Text(existing == null ? 'Nueva métrica' : 'Editar métrica'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
        TextField(controller: field, decoration: const InputDecoration(labelText: 'Campo JSON')),
        TextField(controller: unit, decoration: const InputDecoration(labelText: 'Unidad')),
        TextField(controller: pre, decoration: const InputDecoration(labelText: 'Prealerta'), keyboardType: TextInputType.number),
        TextField(controller: alert, decoration: const InputDecoration(labelText: 'Alerta'), keyboardType: TextInputType.number),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, MetricConfig(id: existing?.id ?? 'metric-${DateTime.now().microsecondsSinceEpoch}', name: name.text, field: field.text, unit: unit.text, active: existing?.active ?? true, prealert: double.tryParse(pre.text) ?? 60, alert: double.tryParse(alert.text) ?? 75, timeField: existing?.timeField ?? 'timestamp')), child: const Text('Guardar'))],
    ));
    if (result != null) await _saveMetric(result);
  }

  Future<void> _exportCsv() async {
    final rows = <List<dynamic>>[['id', 'timestamp', ...activeMetrics.map((m) => '${m.id} (${m.unit})')], ...readings.map((r) => [r.id, r.timestamp.toIso8601String(), ...activeMetrics.map((m) => r.values[m.id] ?? '')])];
    final file = File('${Directory.systemTemp.path}/picur_historial.csv')..writeAsStringSync(ListToCsvConverter().convert(rows));
    await Share.shareXFiles([XFile(file.path)], text: 'Historial PICUR');
  }
}

// firstOrNull y lastOrNull ya vienen en dart:core (Dart 3); definirlos aquí
// otra vez provoca un conflicto de extensiones.
extension<T> on Iterable<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (final item in toList().reversed) { if (test(item)) return item; }
    return null;
  }
}
