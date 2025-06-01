import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/route.dart' as bus_route;
import '../models/stop.dart';

class FavoritesService {
  static const String _routesKey = 'favorite_routes';
  static const String _stopsKey = 'favorite_stops';

  final SharedPreferences _prefs;

  FavoritesService(this._prefs);

  // Загрузка избранных маршрутов
  Future<List<bus_route.Route>> getFavoriteRoutes() async {
    final routesJson = _prefs.getStringList(_routesKey) ?? [];
    return routesJson
        .map((json) => bus_route.Route.fromJson(jsonDecode(json)))
        .toList();
  }

  // Загрузка избранных остановок
  Future<List<Stop>> getFavoriteStops() async {
    final stopsJson = _prefs.getStringList(_stopsKey) ?? [];
    return stopsJson.map((json) => Stop.fromJson(jsonDecode(json))).toList();
  }

  // Сохранение избранных маршрутов
  Future<void> saveFavoriteRoutes(List<bus_route.Route> routes) async {
    final routesJson = routes
        .map((route) => jsonEncode(route.toJson()))
        .toList();
    await _prefs.setStringList(_routesKey, routesJson);
  }

  // Сохранение избранных остановок
  Future<void> saveFavoriteStops(List<Stop> stops) async {
    final stopsJson = stops
        .map((stop) => jsonEncode(stop.toJson()))
        .toList();
    await _prefs.setStringList(_stopsKey, stopsJson);
  }

  // Добавление маршрута в избранное
  Future<void> addRouteToFavorites(bus_route.Route route) async {
    final routes = await getFavoriteRoutes();
    if (!routes.any((r) => r.id == route.id)) {
      routes.add(route);
      await saveFavoriteRoutes(routes);
    }
  }

  // Добавление остановки в избранное
  Future<void> addFavoriteStop(Stop stop) async {
    final stops = await getFavoriteStops();
    if (!stops.any((s) => s.id == stop.id)) {
      stops.add(stop);
      await saveFavoriteStops(stops);
    }
  }

  // Удаление маршрута из избранного
  Future<void> removeRouteFromFavorites(String routeId) async {
    final routes = await getFavoriteRoutes();
    routes.removeWhere((route) => route.id == routeId);
    await saveFavoriteRoutes(routes);
  }

  // Удаление остановки из избранного
  Future<void> removeFavoriteStop(String stopId) async {
    final stops = await getFavoriteStops();
    stops.removeWhere((s) => s.id == stopId);
    await saveFavoriteStops(stops);
  }
} 