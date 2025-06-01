import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'services/database_initializer.dart';

import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/home_screen.dart';
import 'screens/route_details_screen.dart';
import 'screens/stop_details_screen.dart';
import 'screens/search_screen.dart';
import 'theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'providers/favorites_provider.dart';
import 'screens/profile_screen.dart';
import 'screens/map_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/notifications_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database first
  await DatabaseInitializer.initialize();
  debugPrint('Database initialized successfully');

  // Initialize logger
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
  });

  try {
    // Then initialize services
    final databaseService = DatabaseService();
    final authService = AuthService(databaseService);
    debugPrint('Services initialized successfully');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => FavoritesProvider(databaseService)),
          Provider<AuthService>.value(value: authService),
          Provider<DatabaseService>.value(value: databaseService),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint('Error initializing app: $e\n$stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ошибка инициализации приложения',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bus App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.auth: (context) => const AuthScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.search: (context) => const SearchScreen(),
        AppRoutes.favorites: (context) => FavoritesScreen(
              favoritesService: context.read<FavoritesProvider>().service,
            ),
        AppRoutes.routeDetails: (context) {
          final route = context.read<FavoritesProvider>().selectedRoute;
          if (route == null) {
            return const Scaffold(
              body: Center(
                child: Text('Маршрут не найден'),
              ),
            );
          }
          return RouteDetailsScreen(route: route);
        },
        AppRoutes.stopDetails: (context) {
          final stop = context.read<FavoritesProvider>().selectedStop;
          if (stop == null) {
            return const Scaffold(
              body: Center(
                child: Text('Остановка не найдена'),
              ),
            );
          }
          return StopDetailsScreen(stop: stop);
        },
        AppRoutes.profile: (context) => const ProfileScreen(),
        AppRoutes.map: (context) => const MapScreen(),
        AppRoutes.notifications: (context) => const NotificationsScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
      },
    );
  }
}
