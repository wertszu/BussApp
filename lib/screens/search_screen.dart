import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../routes/app_routes.dart';
import '../models/route.dart' as bus_route;
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
  final ApiService _apiService = ApiService();
  LatLng? _fromLocation;
  LatLng? _toLocation;
  List<bus_route.Route> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  Future<void> _searchRoutes() async {
    if (_fromLocation == null || _toLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите точки отправления и прибытия')),
      );
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final routes = await _apiService.searchRoutes(
        from: _fromLocation!,
        to: _toLocation!,
        departureTime: DateTime.now(),
      );
      
      if (!mounted) return;

      setState(() {
        _searchResults = routes;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при поиске маршрутов: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _selectLocation(bool isFrom) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.map,
      arguments: {
        'title': isFrom ? 'Выберите точку отправления' : 'Выберите точку прибытия',
        'initialLocation': isFrom ? _fromLocation : _toLocation,
      },
    );

    if (result != null && result is LatLng) {
      setState(() {
        if (isFrom) {
          _fromLocation = result;
          _fromController.text = 'Выбрано на карте';
        } else {
          _toLocation = result;
          _toController.text = 'Выбрано на карте';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск маршрута'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _fromController,
                  decoration: InputDecoration(
                    labelText: 'Откуда',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: () => _selectLocation(true),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectLocation(true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _toController,
                  decoration: InputDecoration(
                    labelText: 'Куда',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.map),
                      onPressed: () => _selectLocation(false),
                    ),
                  ),
                  readOnly: true,
                  onTap: () => _selectLocation(false),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSearching ? null : _searchRoutes,
                    child: _isSearching
                        ? const CircularProgressIndicator()
                        : const Text('Найти маршрут'),
                  ),
                ),
              ],
            ),
          ),
          if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final route = _searchResults[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        '${route.totalDuration.inMinutes} мин • ${route.totalDistance} м',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      subtitle: Text(
                        'Пересадки: ${route.transfers}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: Text(
                        '${route.cost} ₽',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.routeDetails,
                          arguments: route,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
} 