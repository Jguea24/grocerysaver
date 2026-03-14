// Pantalla para monitorear acelerometro, giroscopio y detectar sacudidas.
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/api_config.dart';
import '../services/device_sensors_api.dart';

/// Vista de lectura en tiempo real de sensores del dispositivo.
class SensorView extends StatefulWidget {
  const SensorView({super.key});

  @override
  State<SensorView> createState() => _SensorViewState();
}

class _SensorViewState extends State<SensorView> {
  static const double _shakeThreshold = 15;
  static const Duration _shakeCooldown = Duration(seconds: 1);
  static const Duration _shakeVisibleDuration = Duration(milliseconds: 600);

  UserAccelerometerEvent? _accelerometer;
  GyroscopeEvent? _gyroscope;
  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;

  bool _isShaking = false;
  bool _sending = false;
  String? _sensorError;
  DateTime? _lastShakeAt;
  Timer? _shakeResetTimer;

  @override
  void initState() {
    super.initState();
    _listenSensors();
  }

  @override
  void dispose() {
    _shakeResetTimer?.cancel();
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    super.dispose();
  }

  /// Suscribe ambos sensores y captura errores del plugin.
  void _listenSensors() {
    _accelerometerSub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen(_onAccelerometerEvent, onError: _onSensorError);

    _gyroscopeSub =
        gyroscopeEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen((event) {
          if (!mounted) return;
          setState(() {
            _gyroscope = event;
            _sensorError = null;
          });
        }, onError: _onSensorError);
  }

  /// Calcula la magnitud del movimiento para inferir una sacudida breve.
  void _onAccelerometerEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(
      (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
    );
    final now = DateTime.now();
    final isStrongMovement = magnitude > _shakeThreshold;
    final canTriggerShake =
        _lastShakeAt == null || now.difference(_lastShakeAt!) > _shakeCooldown;

    if (isStrongMovement && canTriggerShake) {
      _lastShakeAt = now;
      _shakeResetTimer?.cancel();
      _shakeResetTimer = Timer(_shakeVisibleDuration, () {
        if (!mounted) return;
        setState(() {
          _isShaking = false;
        });
      });
    }

    if (!mounted) return;
    setState(() {
      _accelerometer = event;
      _sensorError = null;
      if (isStrongMovement && canTriggerShake) {
        _isShaking = true;
      }
    });
  }

  /// Guarda un mensaje de error legible si el sensor no esta disponible.
  void _onSensorError(Object error) {
    if (!mounted) return;
    setState(() {
      _sensorError = 'No se pudo leer el sensor: $error';
    });
  }

  /// Envia la ultima lectura al backend configurado en `ApiConfig`.
  Future<void> _sendToApi() async {
    final accelerometer = _accelerometer;
    final gyroscope = _gyroscope;
    if (accelerometer == null || gyroscope == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Aun no hay lecturas completas para enviar.'),
          ),
        );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      await DeviceSensorsApi.submitReading(
        accelerometerX: accelerometer.x,
        accelerometerY: accelerometer.y,
        accelerometerZ: accelerometer.z,
        gyroscopeX: gyroscope.x,
        gyroscopeY: gyroscope.y,
        gyroscopeZ: gyroscope.z,
        isShaking: _isShaking,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Datos enviados.')));
    } on DeviceSensorsApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.toString())));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Fallo de red: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  String _formatValue(double? value) => value?.toStringAsFixed(2) ?? '-';

  @override
  Widget build(BuildContext context) {
    final baseUrl = ApiConfig.baseUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Sensores del dispositivo')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E6846),
                  Color(0xFF2F7D57),
                  Color(0xFF52A66C),
                ],
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.sensors_rounded, color: Colors.white, size: 30),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Lee acelerometro, giroscopio y detecta sacudidas para enviarlas a tu API.',
                    style: TextStyle(
                      color: Color(0xFFEAF9ED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFDDE3E8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Endpoint activo',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2A33),
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  '$baseUrl/device-sensors/',
                  style: const TextStyle(
                    color: Color(0xFF42505B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'En emulador Android usa 10.0.2.2. En celular fisico define API_BASE_URL con la IP local de tu PC.',
                  style: TextStyle(color: Color(0xFF6A7884), height: 1.35),
                ),
              ],
            ),
          ),
          if (_sensorError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEAEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _sensorError!,
                style: const TextStyle(
                  color: Color(0xFFAC2E2E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Acelerometro sin gravedad',
            icon: Icons.speed_rounded,
            x: _formatValue(_accelerometer?.x),
            y: _formatValue(_accelerometer?.y),
            z: _formatValue(_accelerometer?.z),
          ),
          const SizedBox(height: 12),
          _SensorCard(
            title: 'Giroscopio',
            icon: Icons.threesixty_rounded,
            x: _formatValue(_gyroscope?.x),
            y: _formatValue(_gyroscope?.y),
            z: _formatValue(_gyroscope?.z),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _isShaking
                  ? const Color(0xFFFFF1F1)
                  : const Color(0xFFF2FBF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isShaking
                    ? const Color(0xFFF2B4B4)
                    : const Color(0xFFCFE6D7),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isShaking
                      ? Icons.vibration_rounded
                      : Icons.check_circle_rounded,
                  color: _isShaking
                      ? const Color(0xFFC53939)
                      : const Color(0xFF2F7D57),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isShaking ? 'Sacudida detectada' : 'Sin sacudida',
                    style: TextStyle(
                      color: _isShaking
                          ? const Color(0xFFC53939)
                          : const Color(0xFF20573A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _sending ? null : _sendToApi,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(_sending ? 'Enviando...' : 'Enviar a API'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta simple para mostrar una lectura XYZ.
class _SensorCard extends StatelessWidget {
  const _SensorCard({
    required this.title,
    required this.icon,
    required this.x,
    required this.y,
    required this.z,
  });

  final String title;
  final IconData icon;
  final String x;
  final String y;
  final String z;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF2F7D57)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2A33),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AxisRow(axis: 'x', value: x),
          const SizedBox(height: 6),
          _AxisRow(axis: 'y', value: y),
          const SizedBox(height: 6),
          _AxisRow(axis: 'z', value: z),
        ],
      ),
    );
  }
}

/// Fila de apoyo para una coordenada individual del sensor.
class _AxisRow extends StatelessWidget {
  const _AxisRow({required this.axis, required this.value});

  final String axis;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            axis,
            style: const TextStyle(
              color: Color(0xFF6A7884),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1F2A33),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
