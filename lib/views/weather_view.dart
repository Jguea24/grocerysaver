// Pantalla de clima con consulta manual por ciudad.
import 'package:flutter/material.dart';

import '../services/weather_api.dart';

/// Permite consultar clima ingresando una ciudad.
class WeatherView extends StatefulWidget {
  const WeatherView({super.key, this.initialCity});

  final String? initialCity;

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  late final WeatherApi _api;
  late final TextEditingController _cityController;

  bool _isLoading = false;
  String? _errorMessage;
  String? _weatherCacheStatus;
  WeatherSnapshot? _snapshot;

  @override
  void initState() {
    super.initState();
    _api = WeatherApi();
    // La ciudad inicial se normaliza porque a veces llega como direccion larga.
    _cityController = TextEditingController(
      text: _normalizeCity(widget.initialCity),
    );
    _loadWeather();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  /// Carga el clima de la ciudad actualmente seleccionada.
  Future<void> _loadWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) {
      setState(() {
        _errorMessage = 'Ingresa una ciudad.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _api.getCurrentByCity(city);
      if (!mounted) return;
      setState(() {
        _snapshot = data;
        _weatherCacheStatus = _api.lastCacheStatus;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Ejecuta una nueva busqueda y oculta el teclado antes de consultar.
  Future<void> _submitWeatherSearch() async {
    FocusScope.of(context).unfocus();
    await _loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Clima')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadWeather();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _CitySearchCard(
              controller: _cityController,
              isLoading: _isLoading,
              onSearch: _submitWeatherSearch,
            ),
            if (_weatherCacheStatus != null) ...[
              const SizedBox(height: 10),
              _CacheStatusCard(
                weatherCacheStatus: _weatherCacheStatus!,
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _errorMessage!),
            ],
            if (_isLoading && snapshot == null) ...[
              const SizedBox(height: 30),
              const Center(child: CircularProgressIndicator()),
            ] else if (snapshot != null) ...[
              const SizedBox(height: 14),
              _CurrentWeatherCard(snapshot: snapshot),
              const SizedBox(height: 14),
              _ForecastCard(days: snapshot.daily),
            ],
          ],
        ),
      ),
    );
  }

  /// Ajusta el texto recibido para usarlo como ciudad inicial.
  String _normalizeCity(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'tu ciudad') {
      return 'Quito';
    }
    return text.split(',').first.trim();
  }
}

/// Tarjeta para ingresar manualmente la ciudad a consultar.
class _CitySearchCard extends StatelessWidget {
  const _CitySearchCard({
    required this.controller,
    required this.isLoading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final bool isLoading;
  final Future<void> Function() onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buscar clima por ciudad',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A242D),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            enabled: !isLoading,
            textInputAction: TextInputAction.search,
            onFieldSubmitted: (_) {
              onSearch();
            },
            decoration: const InputDecoration(
              hintText: 'Ejemplo: Quito',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onSearch,
              icon: const Icon(Icons.search_rounded),
              label: Text(isLoading ? 'Consultando...' : 'Consultar clima'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta que resume el estado de cache del modulo de clima.
class _CacheStatusCard extends StatelessWidget {
  const _CacheStatusCard({
    required this.weatherCacheStatus,
  });

  final String weatherCacheStatus;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CacheChip(
          label: 'Clima',
          value: weatherCacheStatus,
        ),
      ],
    );
  }
}

/// Chip individual de cache para un modulo concreto.
class _CacheChip extends StatelessWidget {
  const _CacheChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F5ED),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label cache: $value',
        style: const TextStyle(
          color: Color(0xFF20573A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Tarjeta principal con la condicion meteorologica actual.
class _CurrentWeatherCard extends StatelessWidget {
  const _CurrentWeatherCard({required this.snapshot});

  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final icon = _iconForCode(snapshot.weatherCode, snapshot.isDay);
    final desc = _descriptionForCode(snapshot.weatherCode);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${snapshot.city}${snapshot.country.isEmpty ? '' : ', ${snapshot.country}'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(icon, color: Colors.white, size: 36),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${snapshot.temperature.toStringAsFixed(1)} C',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              color: Color(0xFFEAF9ED),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricChip(
                icon: Icons.thermostat_rounded,
                text: 'Sensacion ${snapshot.feelsLike.toStringAsFixed(1)} C',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.water_drop_rounded,
                text: 'Humedad ${snapshot.humidity}%',
              ),
              const SizedBox(width: 8),
              _MetricChip(
                icon: Icons.air_rounded,
                text: 'Viento ${snapshot.windSpeed.toStringAsFixed(0)} km/h',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mapea codigos meteorologicos a iconos locales.
  IconData _iconForCode(int code, bool isDay) {
    if (code == 0) {
      return isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round;
    }
    if (code == 1 || code == 2) return Icons.cloud_queue_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return Icons.umbrella_rounded;
    }
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) {
      return Icons.ac_unit_rounded;
    }
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.cloud_outlined;
  }

  /// Traduce codigos meteorologicos a texto amigable.
  String _descriptionForCode(int code) {
    switch (code) {
      case 0:
        return 'Despejado';
      case 1:
      case 2:
        return 'Parcialmente nublado';
      case 3:
        return 'Nublado';
      case 45:
      case 48:
        return 'Niebla';
      case 51:
      case 53:
      case 55:
      case 56:
      case 57:
        return 'Llovizna';
      case 61:
      case 63:
      case 65:
      case 66:
      case 67:
      case 80:
      case 81:
      case 82:
        return 'Lluvia';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'Nieve';
      case 95:
      case 96:
      case 99:
        return 'Tormenta';
      default:
        return 'Condicion variable';
    }
  }
}

/// Tarjeta con el pronostico diario resumido.
class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.days});

  final List<WeatherDaily> days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pronostico',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A242D),
            ),
          ),
          const SizedBox(height: 8),
          if (days.isEmpty)
            const Text(
              'Sin pronostico disponible.',
              style: TextStyle(color: Color(0xFF7A8A97)),
            )
          else
            ...days.map(
              (day) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _friendlyDate(day.date),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      '${day.maxTemp.toStringAsFixed(0)} / ${day.minTemp.toStringAsFixed(0)} C',
                      style: const TextStyle(color: Color(0xFF42505B)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Reduce la fecha a MM-DD para una lectura mas compacta.
  String _friendlyDate(String date) {
    if (date.length >= 10) {
      final mmdd = date.substring(5, 10);
      return mmdd;
    }
    return date;
  }
}

/// Chip visual de metricas dentro de la tarjeta de clima actual.
class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner de error reutilizable en la pantalla de clima.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCEAEA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFAC2E2E),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

