import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route.dart' as bus_route;

class ApiService {
  static const String _baseUrl = 'https://api.bus-app.com/v1'; // Замените на ваш реальный URL
  static const String _apiKey = '6ce49f78-f141-4f3f-b5a4-b3dc92381457';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<List<bus_route.Route>> searchRoutes({
    required LatLng from,
    required LatLng to,
    DateTime? departureTime,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/routes/search').replace(
          queryParameters: {
            'from_lat': from.latitude.toString(),
            'from_lng': from.longitude.toString(),
            'to_lat': to.latitude.toString(),
            'to_lng': to.longitude.toString(),
            if (departureTime != null)
              'departure_time': departureTime.toIso8601String(),
          },
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => bus_route.Route.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to load routes',
          response.statusCode,
          response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', null, null);
    } catch (e) {
      throw ApiException('Failed to search routes: $e', null, null);
    }
  }

  Future<List<bus_route.Route>> getFavoriteRoutes() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/routes/favorites'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => bus_route.Route.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Failed to load favorite routes',
          response.statusCode,
          response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', null, null);
    } catch (e) {
      throw ApiException('Failed to get favorite routes: $e', null, null);
    }
  }

  Future<void> addRouteToFavorites(String routeId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/routes/favorites'),
        headers: _headers,
        body: json.encode({'route_id': routeId}),
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to add route to favorites',
          response.statusCode,
          response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', null, null);
    } catch (e) {
      throw ApiException('Failed to add route to favorites: $e', null, null);
    }
  }

  Future<void> removeRouteFromFavorites(String routeId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/routes/favorites/$routeId'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to remove route from favorites',
          response.statusCode,
          response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', null, null);
    } catch (e) {
      throw ApiException('Failed to remove route from favorites: $e', null, null);
    }
  }

  Future<bus_route.Route> getRouteDetails(String routeId) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/routes/$routeId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return bus_route.Route.fromJson(data);
      } else {
        throw ApiException(
          'Failed to load route details',
          response.statusCode,
          response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', null, null);
    } catch (e) {
      throw ApiException('Failed to get route details: $e', null, null);
    }
  }

  Future<void> startRouteTracking(String routeId) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl/routes/$routeId/tracking'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to start route tracking',
          response.statusCode,
          response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', null, null);
    } catch (e) {
      throw ApiException('Failed to start route tracking: $e', null, null);
    }
  }

  Future<void> stopRouteTracking(String routeId) async {
    try {
      final response = await _client.delete(
        Uri.parse('$_baseUrl/routes/$routeId/tracking'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw ApiException(
          'Failed to stop route tracking',
          response.statusCode,
          response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw ApiException('Network error: ${e.message}', null, null);
    } catch (e) {
      throw ApiException('Failed to stop route tracking: $e', null, null);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiException(this.message, this.statusCode, this.responseBody);

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException: $message (Status: $statusCode)';
    }
    return 'ApiException: $message';
  }
} 