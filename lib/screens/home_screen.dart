import 'dart:async';
import 'package:flutter/material.dart';
import '../models/reading.dart';
import '../services/database_service.dart';
import '../services/preferences_service.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.database,
    required this.firebaseReady,
    required this.themeMode,
    required this.onThemeChanged,
  });
  final DatabaseService database;
  final bool firebaseReady;
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final prefs = PreferencesService();
  StreamSubscription<List<Reading>>? subscription;
  List<Reading> readings = [];
  double prealert = 60, alert = 75;
  bool demo = false;
  Timer? demoTimer;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.firebaseReady) subscription = widget.database.readings.listen(_setReadings);
  }

  Future<void> _load() async {
    final values = await prefs.thresholds();
    if (mounted) setState(() { prealert = values.$1; alert = values.$2; });
  }

  void _setReadings(List<Reading> value) {
    if (mounted) setState(() => readings = value);
  }

  void toggleDemo() {
    if (demo) {
      demoTimer?.cancel();
      setState(() => demo = false);
      return;
    }
    var humidity = readings.isEmpty ? 42.0 : readings.last.humidity;
    void tick() {
      humidity = (humidity + (humidity > 72 ? 1.4 : .25)).clamp(0, 96);
      _setReadings([...readings, Reading(
        id: 'demo-${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        humidity: humidity,
      )]);
    }
    tick();
    demoTimer = Timer.periodic(const Duration(seconds: 3), (_) => tick());
    setState(() => demo = true);
  }

  @override
  void dispose() {
    subscription?.cancel();
    demoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['Dashboard', 'Historial', 'Alertas', 'Configuración'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('PICUR', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Icon(widget.firebaseReady ? Icons.cloud_done : Icons.cloud_off,
              color: widget.firebaseReady ? Colors.green : Colors.orange),
          const SizedBox(width: 14),
        ],
      ),
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(child: Text('Monitoreo de ladera',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          for (var i = 0; i < titles.length; i++)
            ListTile(
              leading: Icon([Icons.dashboard, Icons.table_chart, Icons.warning_amber, Icons.settings][i]),
              title: Text(titles[i]),
              selected: tab == i,
              onTap: () { setState(() => tab = i); Navigator.pop(context); },
            ),
          const Divider(),
          SwitchListTile(
            title: const Text('Modo oscuro'),
            value: widget.themeMode == ThemeMode.dark,
            onChanged: widget.onThemeChanged,
          ),
          ListTile(
            leading: Icon(demo ? Icons.stop_circle : Icons.play_circle),
            title: Text(demo ? 'Detener modo demo' : 'Activar modo demo'),
            onTap: toggleDemo,
          ),
        ]),
      ),
      body: tab == 0 ? _dashboard() : tab == 1 ? _history() : tab == 2 ? _alerts() : SettingsScreen(
        initialPrealert: prealert,
        initialAlert: alert,
        onSaved: (a, b) { setState(() { prealert = a; alert = b; }); },
      ),
    );
  }

  Widget _dashboard() {
    final latest = readings.isEmpty ? null : readings.last;
    final state = latest == null ? 'Normal' : readingStatus(latest, prealert, alert);
    final offline = latest == null || DateTime.now().difference(latest.timestamp).inSeconds > 30;
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(padding: const EdgeInsets.all(18), children: [
        Text('ESTADO DEL SISTEMA', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text('Monitoreo en tiempo real', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        Card(color: _stateColor(state).withValues(alpha: .14), child: ListTile(
          leading: CircleAvatar(backgroundColor: _stateColor(state), child: Icon(offline ? Icons.priority_high : Icons.check, color: Colors.white)),
          title: Text(offline ? 'Sin señal del sensor' : state, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(offline ? 'No llegan datos hace más de 30 segundos' : 'Prealerta ${prealert.toStringAsFixed(0)}% · Alerta ${alert.toStringAsFixed(0)}%'),
        )),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _metric('Humedad actual', latest == null ? '—' : '${latest.humidity.toStringAsFixed(1)}%', latest == null ? 'Sin lecturas' : _time(latest.timestamp))),
          const SizedBox(width: 10),
          Expanded(child: _metric('Tasa de cambio', readings.length < 2 ? '—' : '${_rate().toStringAsFixed(2)} %/min', 'Comparada con anterior')),
        ]),
        const SizedBox(height: 18),
        Text('Últimas lecturas', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...readings.reversed.take(6).map((r) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${r.humidity.toStringAsFixed(1)}%'),
          subtitle: Text(_time(r.timestamp)),
          trailing: Chip(label: Text(readingStatus(r, prealert, alert))),
        )),
      ]),
    );
  }

  Widget _metric(String title, String value, String subtitle) => Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: Theme.of(context).textTheme.labelMedium), const SizedBox(height: 8),
    Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)), Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
  ])));

  Widget _history() => ListView(padding: const EdgeInsets.all(18), children: [
    Text('Historial de lecturas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    ...readings.reversed.map((r) => Card(child: ListTile(title: Text('${r.humidity.toStringAsFixed(1)}%'), subtitle: Text(_time(r.timestamp)), trailing: Text(readingStatus(r, prealert, alert)))),
  ]);

  Widget _alerts() {
    final events = readings.where((r) => readingStatus(r, prealert, alert) != 'Normal').toList().reversed;
    return ListView(padding: const EdgeInsets.all(18), children: [
      Text('Registro de alertas', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      if (events.isEmpty) const Card(child: ListTile(title: Text('No hay eventos registrados.'))),
      ...events.map((r) => Card(child: ListTile(leading: const Icon(Icons.warning, color: Colors.red), title: Text(readingStatus(r, prealert, alert)), subtitle: Text('${r.humidity.toStringAsFixed(1)}% · ${_time(r.timestamp)}')))),
    ]);
  }

  double _rate() {
    final a = readings[readings.length - 2], b = readings.last;
    final minutes = b.timestamp.difference(a.timestamp).inMilliseconds / 60000;
    return minutes <= 0 ? 0 : (b.humidity - a.humidity) / minutes;
  }
  Color _stateColor(String state) => state == 'Alerta' ? Colors.red : state == 'Prealerta' ? Colors.orange : Colors.green;
  String _time(DateTime date) => '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
