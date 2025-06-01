import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/favorites_service.dart';
import '../models/route.dart' as bus_route;
import '../models/stop.dart';
import '../services/database_service.dart';

class FavoritesProvider extends ChangeNotifier {
  late final FavoritesService _service;
  bool _isInitialized = false;
  List<bus_route.Route> _favoriteRoutes = [];
  List<Stop> _favoriteStops = [];
  final DatabaseService _db;
  List<String> _favorites = [];
  bus_route.Route? _selectedRoute;
  Stop? _selectedStop;

  FavoritesProvider(this._db);

  FavoritesService get service {
    if (!_isInitialized) {
      throw StateError('FavoritesProvider не инициализирован');
    }
    return _service;
  }

  List<bus_route.Route> get favoriteRoutes => _favoriteRoutes;
  List<Stop> get favoriteStops => _favoriteStops;
  List<String> get favorites => _favorites;
  bus_route.Route? get selectedRoute => _selectedRoute;
  Stop? get selectedStop => _selectedStop;

  Future<void> initialize() async {
    if (_isInitialized) return;

    final prefs = await SharedPreferences.getInstance();
    _service = FavoritesService(prefs);
    await _loadFavorites();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadFavorites() async {
    _favoriteRoutes = await _service.getFavoriteRoutes();
    _favoriteStops = await _service.getFavoriteStops();
    notifyListeners();
  }

  bool isRouteFavorite(String routeId) {
    return _favorites.contains(routeId);
  }

  bool isStopFavorite(String stopId) {
    return _favoriteStops.any((stop) => stop.id == stopId);
  }

  Future<void> addRouteToFavorites(bus_route.Route route) async {
    if (!isRouteFavorite(route.id)) {
      _favorites.add(route.id);
      notifyListeners();
    }
  }

  Future<void> addStopToFavorites(Stop stop) async {
    if (!isStopFavorite(stop.id)) {
      await _service.addFavoriteStop(stop);
      _favoriteStops.add(stop);
      notifyListeners();
    }
  }

  Future<void> removeRouteFromFavorites(String routeId) async {
    await Future.delayed(Duration(milliseconds: 100));
    _favorites.remove(routeId);
    notifyListeners();
  }

  Future<void> removeStopFromFavorites(String stopId) async {
    await _service.removeFavoriteStop(stopId);
    _favoriteStops.removeWhere((stop) => stop.id == stopId);
    notifyListeners();
  }

  Future<void> loadFavorites(String userId) async {
    _favorites = await _db.getFavorites(userId);
    notifyListeners();
  }

  Future<void> addFavorite(String userId, String routeId) async {
    await _db.addFavorite(userId, routeId);
    _favorites.add(routeId);
    notifyListeners();
  }

  Future<void> removeFavorite(String userId, String routeId) async {
    await _db.removeFavorite(userId, routeId);
    _favorites.remove(routeId);
    notifyListeners();
  }

  void setSelectedRoute(bus_route.Route route) {
    _selectedRoute = route;
    notifyListeners();
  }

  void setSelectedStop(Stop stop) {
    _selectedStop = stop;
    notifyListeners();
  }

  void clearSelection() {
    _selectedRoute = null;
    _selectedStop = null;
    notifyListeners();
  }
} 