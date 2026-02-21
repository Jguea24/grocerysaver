import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherApiException implements Exception {
  WeatherApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code';
  }
}

class WeatherSnapshot {
  const WeatherSnapshot({
    required this.city,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
    required this.daily,
  });

  final String city;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final bool isDay;
  final List<WeatherDaily> daily;
}

class WeatherDaily {
  const WeatherDaily({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
  });

  final String date;
  final double maxTemp;
  final double minTemp;
  final int weatherCode;
}

class WeatherApi {
  Future<WeatherSnapshot> getCurrentByCity(String city) async {
    final normalizedCity = city.trim();
    if (normalizedCity.isEmpty) {
      throw WeatherApiException('Ingresa una ciudad para consultar el clima.');
    }

    final geoRes = await http.get(
      Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$normalizedCity&count=1&language=es&format=json',
      ),
    );
    final geoData = _decode(geoRes, endpoint: 'geocoding');
    final results = geoData['results'];
    if (results is! List || results.isEmpty) {
      throw WeatherApiException('No se encontro la ciudad "$normalizedCity".');
    }

    final first = results.first;
    if (first is! Map<String, dynamic>) {
      throw WeatherApiException('Respuesta invalida de geocodificacion.');
    }

    final lat = first['latitude'];
    final lon = first['longitude'];
    if (lat == null || lon == null) {
      throw WeatherApiException('No se pudo obtener latitud/longitud.');
    }

    final cityName = (first['name'] ?? normalizedCity).toString();
    final country = (first['country'] ?? '').toString();

    final forecastRes = await http.get(
      Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        '&forecast_days=5'
        '&timezone=auto',
      ),
    );

    final forecastData = _decode(forecastRes, endpoint: 'forecast');
    final current = forecastData['current'];
    if (current is! Map<String, dynamic>) {
      throw WeatherApiException('Respuesta invalida de clima actual.');
    }

    final dailyData = forecastData['daily'];
    final daily = _parseDaily(dailyData);

    return WeatherSnapshot(
      city: cityName,
      country: country,
      temperature: _asDouble(current['temperature_2m']),
      feelsLike: _asDouble(current['apparent_temperature']),
      humidity: _asInt(current['relative_humidity_2m']),
      windSpeed: _asDouble(current['wind_speed_10m']),
      weatherCode: _asInt(current['weather_code']),
      isDay: _asInt(current['is_day']) == 1,
      daily: daily,
    );
  }

  List<WeatherDaily> _parseDaily(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const [];

    final times = raw['time'];
    final maxTemps = raw['temperature_2m_max'];
    final minTemps = raw['temperature_2m_min'];
    final codes = raw['weather_code'];

    if (times is! List ||
        maxTemps is! List ||
        minTemps is! List ||
        codes is! List) {
      return const [];
    }

    final length = [
      times.length,
      maxTemps.length,
      minTemps.length,
      codes.length,
    ].reduce((a, b) => a < b ? a : b);

    final list = <WeatherDaily>[];
    for (var i = 0; i < length; i++) {
      list.add(
        WeatherDaily(
          date: times[i].toString(),
          maxTemp: _asDouble(maxTemps[i]),
          minTemp: _asDouble(minTemps[i]),
          weatherCode: _asInt(codes[i]),
        ),
      );
    }
    return list;
  }

  Map<String, dynamic> _decode(http.Response res, {required String endpoint}) {
    final body = res.body.trim();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw WeatherApiException(
        'Error consultando $endpoint.',
        statusCode: res.statusCode,
      );
    }
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw WeatherApiException('Respuesta invalida de $endpoint.');
    }
    return decoded;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }
}
