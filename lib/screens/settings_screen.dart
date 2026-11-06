import 'package:flutter/material.dart';
import '../services/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.initialPrealert, required this.initialAlert, required this.onSaved});
  final double initialPrealert;
  final double initialAlert;
  final void Function(double, double) onSaved;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final prealert = TextEditingController(text: widget.initialPrealert.toString());
  late final alert = TextEditingController(text: widget.initialAlert.toString());
  final prefs = PreferencesService();
  String message = '';

  @override
  void dispose() { prealert.dispose(); alert.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(18), children: [
    Text('Configuración', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 5), const Text('Umbrales experimentales guardados en este dispositivo.'),
    const SizedBox(height: 20),
    Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
      TextField(controller: prealert, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Prealerta (%)')),
      const SizedBox(height: 14),
      TextField(controller: alert, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Alerta (%)')),
      const SizedBox(height: 18),
      FilledButton(onPressed: _save, child: const Text('Guardar umbrales')),
      if (message.isNotEmpty) Text(message, style: const TextStyle(color: Colors.green)),
    ]))),
    const SizedBox(height: 18),
    Card(child: const ListTile(
      leading: Icon(Icons.sensors),
      title: Text('Presión de poros'),
      subtitle: Text('Sensor no conectado · activar en lib/config.dart cuando haya datos u_kpa'),
    )),
  ]);

  Future<void> _save() async {
    final a = double.tryParse(prealert.text), b = double.tryParse(alert.text);
    if (a == null || b == null || a < 0 || a >= b || b > 100) {
      setState(() => message = 'La alerta debe ser mayor que la prealerta y estar entre 0 y 100.');
      return;
    }
    await prefs.saveThresholds(a, b);
    widget.onSaved(a, b);
    setState(() => message = 'Umbrales guardados.');
  }
}
