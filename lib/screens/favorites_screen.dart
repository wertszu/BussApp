import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import '../models/route.dart' as models;
import '../models/stop.dart';
import '../services/favorites_service.dart';
import 'stop_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final FavoritesService favoritesService;

  const FavoritesScreen({
    super.key,
    required this.favoritesService,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<models.Route> _favoriteRoutes = [];
  List<Stop> _favoriteStops = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await widget.favoritesService.getFavoriteRoutes();
      final stops = await widget.favoritesService.getFavoriteStops();
      
      setState(() {
        _favoriteRoutes = routes;
        _favoriteStops = stops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при загрузке избранного'),
          ),
        );
      }
    }
  }

  Future<void> _removeRoute(models.Route route) async {
    try {
      await widget.favoritesService.removeRouteFromFavorites(route.id);
      setState(() {
        _favoriteRoutes.removeWhere((r) => r.id == route.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при удалении маршрута'),
          ),
        );
      }
    }
  }

  Future<void> _removeStop(Stop stop) async {
    try {
      await widget.favoritesService.removeFavoriteStop(stop.id);
      setState(() {
        _favoriteStops.removeWhere((s) => s.id == stop.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при удалении остановки'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Маршруты'),
            Tab(text: 'Остановки'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRoutesList(),
                _buildStopsList(),
              ],
            ),
    );
  }

  Widget _buildRoutesList() {
    if (_favoriteRoutes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.star_border,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет избранных маршрутов',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.search);
              },
              child: const Text('Найти маршрут'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRoutes.length,
      itemBuilder: (context, index) {
        final route = _favoriteRoutes[index];
        return Dismissible(
          key: Key(route.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) => _removeRoute(route),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.directions_bus),
              title: Text(route.steps.first.description),
              subtitle: Text(
                '${route.totalDuration.inMinutes} мин • ${route.totalDistance} м',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.star),
                color: Colors.amber,
                onPressed: () => _removeRoute(route),
              ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.routeDetails,
                  arguments: route,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStopsList() {
    if (_favoriteStops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_off,
              size: 64,
              color: AppTheme.textSecondaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Нет избранных остановок',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.search);
              },
              child: const Text('Найти остановку'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteStops.length,
      itemBuilder: (context, index) {
        final stop = _favoriteStops[index];
        return Dismissible(
          key: Key(stop.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          onDismissed: (direction) => _removeStop(stop),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(stop.name),
              subtitle: Text(stop.address),
              trailing: IconButton(
                icon: const Icon(Icons.star),
                color: Colors.amber,
                onPressed: () => _removeStop(stop),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StopDetailsScreen(stop: stop),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
} 