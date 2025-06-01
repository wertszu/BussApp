import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../theme/app_theme.dart';
import '../models/stop.dart';
import '../providers/favorites_provider.dart';
import '../routes/app_routes.dart';
import '../models/route.dart' as bus_route;

class StopDetailsScreen extends StatefulWidget {
  final Stop stop;

  const StopDetailsScreen({
    super.key,
    required this.stop,
  });

  @override
  State<StopDetailsScreen> createState() => _StopDetailsScreenState();
}

class _StopDetailsScreenState extends State<StopDetailsScreen> {
  Completer<GoogleMapController>? _mapController;
  final Set<Marker> _markers = {};
  bool _isMapExpanded = false;

  @override
  void initState() {
    super.initState();
    _setupMap();
  }

  void _setupMap() {
    _markers.add(
      Marker(
        markerId: MarkerId(widget.stop.id),
        position: widget.stop.location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    _mapController = Completer<GoogleMapController>();
    _fitMapToStop();
  }

  Future<void> _fitMapToStop() async {
    if (_mapController == null) return;
    final controller = await _mapController!.future;
    final bounds = LatLngBounds(
      southwest: LatLng(
        widget.stop.location.latitude - 0.001,
        widget.stop.location.longitude - 0.001,
      ),
      northeast: LatLng(
        widget.stop.location.latitude + 0.001,
        widget.stop.location.longitude + 0.001,
      ),
    );
    controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _toggleMapSize() {
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.stop.name),
        actions: [
          IconButton(
            icon: Icon(
              favoritesProvider.isStopFavorite(widget.stop.id)
                  ? Icons.star
                  : Icons.star_border,
            ),
            onPressed: () {
              if (favoritesProvider.isStopFavorite(widget.stop.id)) {
                favoritesProvider.removeStopFromFavorites(widget.stop.id);
              } else {
                favoritesProvider.addStopToFavorites(widget.stop);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isMapExpanded ? MediaQuery.of(context).size.height * 0.7 : 200,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.stop.location,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController?.complete(controller),
              markers: _markers,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
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
                        Text(
                          'Адрес',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.stop.address,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Типы транспорта',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: widget.stop.transportTypes.map((type) {
                            return Chip(
                              label: Text(type.toUpperCase()),
                              backgroundColor: AppTheme.primaryColor.withAlpha(26),
                              labelStyle: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 12,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (widget.stop.routeIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Проходящие маршруты',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.stop.routeIds.length,
                            itemBuilder: (context, index) {
                              final routeId = widget.stop.routeIds[index];
                              return ListTile(
                                leading: const Icon(Icons.directions_bus),
                                title: Text('Маршрут $routeId'),
                                onTap: () {
                                  final route = bus_route.Route(
                                    id: routeId,
                                    steps: [],
                                    totalDuration: const Duration(minutes: 0),
                                    totalDistance: 0,
                                    transfers: 0,
                                    departureTime: DateTime.now(),
                                    arrivalTime: DateTime.now().add(const Duration(minutes: 30)),
                                  );
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.routeDetails,
                                    arguments: route,
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
} 