import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/route.dart' as bus_route;
import '../providers/favorites_provider.dart';
import 'dart:math' as math;

class RouteDetailsScreen extends StatefulWidget {
  final bus_route.Route route;

  const RouteDetailsScreen({
    super.key,
    required this.route,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _isMapExpanded = false;
  late bus_route.Route _route;
  late FavoritesProvider _favoritesProvider;

  @override
  void initState() {
    super.initState();
    _route = widget.route;
    _favoritesProvider = context.read<FavoritesProvider>();
    _setupMap();
  }

  void _setupMap() {
    // Создаем полилинии для каждого шага маршрута
    _polylines = _route.steps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      return Polyline(
        polylineId: PolylineId('step_$index'),
        points: step.path,
        color: _getStepColor(step.type),
        width: 5,
      );
    }).toSet();

    // Создаем маркеры для начальной и конечной точек
    _markers = {
      Marker(
        markerId: const MarkerId('start'),
        position: _route.steps.first.path.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: _route.steps.last.path.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Color _getStepColor(String type) {
    switch (type) {
      case 'walk':
        return Colors.green;
      case 'bus':
        return Colors.blue;
      case 'metro':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _toggleMapSize() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  void _startTracking() {
    Navigator.pushNamed(context, AppRoutes.tracking);
  }

  void _shareRoute() {
    final text = _formatRouteForSharing();
    Share.share(text);
  }

  void _toggleFavorite() {
    if (_favoritesProvider.isRouteFavorite(_route.id)) {
      _favoritesProvider.removeRouteFromFavorites(_route.id);
    } else {
      _favoritesProvider.addRouteToFavorites(_route);
    }
  }

  String _formatRouteForSharing() {
    final dateFormat = DateFormat('HH:mm');
    final steps = _route.steps.map((step) {
      final departureTime = step.departureTime != null 
          ? dateFormat.format(step.departureTime!)
          : '';
      final arrivalTime = step.arrivalTime != null 
          ? dateFormat.format(step.arrivalTime!)
          : '';
      
      return '${step.description}\n'
          '${step.stopName != null ? 'Остановка: ${step.stopName}\n' : ''}'
          '${departureTime.isNotEmpty ? 'Отправление: $departureTime\n' : ''}'
          '${arrivalTime.isNotEmpty ? 'Прибытие: $arrivalTime\n' : ''}'
          'Время в пути: ${step.duration.inMinutes} мин\n'
          'Расстояние: ${step.distance} м';
    }).join('\n\n');

    return 'Маршрут:\n\n$steps\n\n'
        'Общее время в пути: ${_route.totalDuration.inMinutes} мин\n'
        'Общее расстояние: ${_route.totalDistance} м\n'
        'Пересадки: ${_route.transfers}\n'
        '${_route.cost != null ? 'Стоимость: ${_route.cost} ₽\n' : ''}';
  }

  void _fitMapToRoute() {
    if (_mapController != null) {
      LatLng southwest = _route.steps.first.path.first;
      LatLng northeast = _route.steps.first.path.first;

      for (final step in _route.steps) {
        for (final point in step.path) {
          southwest = LatLng(
            math.min(southwest.latitude, point.latitude),
            math.min(southwest.longitude, point.longitude),
          );
          northeast = LatLng(
            math.max(northeast.latitude, point.latitude),
            math.max(northeast.longitude, point.longitude),
          );
        }
      }

      final bounds = LatLngBounds(
        southwest: southwest,
        northeast: northeast,
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          bounds,
          50.0, // padding
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали маршрута'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRoute,
          ),
          IconButton(
            icon: Icon(
              _favoritesProvider.isRouteFavorite(_route.id) 
                  ? Icons.star 
                  : Icons.star_border,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isMapExpanded ? MediaQuery.of(context).size.height * 0.7 : 200,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _route.steps.first.path.first,
                    zoom: 13,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitMapToRoute();
                  },
                  polylines: _polylines,
                  markers: _markers,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: _fitMapToRoute,
                    child: const Icon(Icons.center_focus_strong),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Время в пути: ${_route.totalDuration.inMinutes} мин',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${_route.totalDistance} м',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        if (_route.cost != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Стоимость: ${_route.cost} ₽',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ..._route.steps.map((step) => _buildStepCard(step)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _startTracking,
                  child: const Text('Начать отслеживание'),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMapSize,
        child: Icon(_isMapExpanded ? Icons.arrow_downward : Icons.arrow_upward),
      ),
    );
  }

  Widget _buildStepCard(bus_route.RouteStep step) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getStepColor(step.type).withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStepIcon(step.type),
                color: _getStepColor(step.type),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.description,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (step.stopName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.stopName!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${step.duration.inMinutes} мин • ${step.distance} м',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (step.departureTime != null) ...[
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${step.departureTime!.hour}:${step.departureTime!.minute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (step.arrivalTime != null)
                    Text(
                      '${step.arrivalTime!.hour}:${step.arrivalTime!.minute.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStepIcon(String type) {
    switch (type) {
      case 'walk':
        return Icons.directions_walk;
      case 'bus':
        return Icons.directions_bus;
      case 'metro':
        return Icons.train;
      default:
        return Icons.directions;
    }
  }
} 