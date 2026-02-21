import 'package:flutter/material.dart';

import '../services/ecuador_geo_api.dart';
import '../services/weather_api.dart';

class WeatherView extends StatefulWidget {
  const WeatherView({super.key, this.initialCity});

  final String? initialCity;

  @override
  State<WeatherView> createState() => _WeatherViewState();
}

class _WeatherViewState extends State<WeatherView> {
  late final WeatherApi _api;
  late final EcuadorGeoApi _geoApi;
  late final TextEditingController _cityController;

  bool _isLoading = false;
  bool _isGeoLoading = false;
  String? _errorMessage;
  String? _geoErrorMessage;
  WeatherSnapshot? _snapshot;
  List<Map<String, dynamic>> _provinces = const [];
  List<Map<String, dynamic>> _cantons = const [];
  int? _selectedProvinceId;
  int? _selectedCantonId;

  @override
  void initState() {
    super.initState();
    _api = WeatherApi();
    _geoApi = EcuadorGeoApi();
    _cityController = TextEditingController(
      text: _normalizeCity(widget.initialCity),
    );
    _loadProvinces();
    _loadWeather();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

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

  Future<void> _loadProvinces() async {
    setState(() {
      _isGeoLoading = true;
      _geoErrorMessage = null;
    });

    try {
      final provinces = await _geoApi.getProvinces();
      if (!mounted) return;
      setState(() {
        _provinces = provinces;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _geoErrorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeoLoading = false;
        });
      }
    }
  }

  Future<void> _onProvinceChanged(int? id) async {
    if (id == null) return;

    setState(() {
      _selectedProvinceId = id;
      _selectedCantonId = null;
      _cantons = const [];
      _isGeoLoading = true;
      _geoErrorMessage = null;
    });

    try {
      final cantons = await _geoApi.getCantonsByProvinceId(id);
      if (!mounted) return;
      setState(() {
        _cantons = cantons;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _geoErrorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGeoLoading = false;
        });
      }
    }
  }

  Future<void> _onCantonChanged(int? id) async {
    if (id == null) return;

    final selectedCanton = _cantons.cast<Map<String, dynamic>?>().firstWhere(
      (c) => _itemId(c) == id,
      orElse: () => null,
    );

    setState(() {
      _selectedCantonId = id;
      if (selectedCanton != null) {
        _cityController.text = _itemName(selectedCanton);
      }
    });

    await _loadWeather();
  }

  int? _itemId(Map<String, dynamic>? item) {
    final value = item?['id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString());
  }

  String _itemName(Map<String, dynamic>? item) {
    return (item?['name'] ?? '').toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Clima')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadProvinces();
          await _loadWeather();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            _GeoSelectorCard(
              provinces: _provinces,
              cantons: _cantons,
              selectedProvinceId: _selectedProvinceId,
              selectedCantonId: _selectedCantonId,
              isLoading: _isGeoLoading,
              onProvinceChanged: (value) {
                _onProvinceChanged(value);
              },
              onCantonChanged: (value) {
                _onCantonChanged(value);
              },
            ),
            if (_geoErrorMessage != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _geoErrorMessage!),
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

  String _normalizeCity(String? raw) {
    final text = (raw ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'tu ciudad') {
      return 'Quito';
    }
    return text.split(',').first.trim();
  }
}

class _GeoSelectorCard extends StatelessWidget {
  const _GeoSelectorCard({
    required this.provinces,
    required this.cantons,
    required this.selectedProvinceId,
    required this.selectedCantonId,
    required this.isLoading,
    required this.onProvinceChanged,
    required this.onCantonChanged,
  });

  final List<Map<String, dynamic>> provinces;
  final List<Map<String, dynamic>> cantons;
  final int? selectedProvinceId;
  final int? selectedCantonId;
  final bool isLoading;
  final ValueChanged<int?> onProvinceChanged;
  final ValueChanged<int?> onCantonChanged;

  @override
  Widget build(BuildContext context) {
    final provinceItems = provinces
        .map((p) {
          final id = _itemId(p);
          if (id == null) return null;
          final name = (p['name'] ?? '').toString();
          return DropdownMenuItem<int>(value: id, child: Text(name));
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    final cantonItems = cantons
        .map((c) {
          final id = _itemId(c);
          if (id == null) return null;
          final name = (c['name'] ?? '').toString();
          return DropdownMenuItem<int>(value: id, child: Text(name));
        })
        .whereType<DropdownMenuItem<int>>()
        .toList();

    final validProvinceValue =
        provinceItems.any((item) => item.value == selectedProvinceId)
        ? selectedProvinceId
        : null;
    final validCantonValue =
        cantonItems.any((item) => item.value == selectedCantonId)
        ? selectedCantonId
        : null;

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
            'Ubicacion por provincia y canton',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A242D),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: ValueKey(
              'province-${validProvinceValue ?? 0}-${provinceItems.length}',
            ),
            initialValue: validProvinceValue,
            hint: const Text('Provincia'),
            items: provinceItems,
            onChanged: isLoading ? null : onProvinceChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            key: ValueKey(
              'canton-${validCantonValue ?? 0}-${selectedProvinceId ?? 0}-${cantonItems.length}',
            ),
            initialValue: validCantonValue,
            hint: const Text('Canton'),
            items: cantonItems,
            onChanged: isLoading || selectedProvinceId == null
                ? null
                : onCantonChanged,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          if (isLoading) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
          ],
        ],
      ),
    );
  }

  int? _itemId(Map<String, dynamic> item) {
    final raw = item['id'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString());
  }
}

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

  String _friendlyDate(String date) {
    if (date.length >= 10) {
      final mmdd = date.substring(5, 10);
      return mmdd;
    }
    return date;
  }
}

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
          color: Colors.white.withValues(alpha: 0.16),
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
