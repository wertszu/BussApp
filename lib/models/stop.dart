import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stop {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final List<String> transportTypes; // ['bus', 'metro', 'tram', etc.]
  final bool isFavorite;
  final List<String> routeIds; // IDs of routes that pass through this stop

  Stop({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.transportTypes,
    this.isFavorite = false,
    this.routeIds = const [],
  });

  Stop copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? location,
    List<String>? transportTypes,
    bool? isFavorite,
    List<String>? routeIds,
  }) {
    return Stop(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      location: location ?? this.location,
      transportTypes: transportTypes ?? this.transportTypes,
      isFavorite: isFavorite ?? this.isFavorite,
      routeIds: routeIds ?? this.routeIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'location': {
        'latitude': location.latitude,
        'longitude': location.longitude,
      },
      'transportTypes': transportTypes,
      'isFavorite': isFavorite,
      'routeIds': routeIds,
    };
  }

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      location: LatLng(
        json['location']['latitude'] as double,
        json['location']['longitude'] as double,
      ),
      transportTypes: (json['transportTypes'] as List).cast<String>(),
      isFavorite: json['isFavorite'] as bool,
      routeIds: (json['routeIds'] as List).cast<String>(),
    );
  }
} 