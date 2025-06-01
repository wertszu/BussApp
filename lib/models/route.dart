import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteStep {
  final String type; // 'walk', 'bus', 'metro', etc.
  final String description;
  final String? vehicleNumber;
  final Duration duration;
  final double distance;
  final List<LatLng> path;
  final String? stopName;
  final DateTime? departureTime;
  final DateTime? arrivalTime;

  RouteStep({
    required this.type,
    required this.description,
    this.vehicleNumber,
    required this.duration,
    required this.distance,
    required this.path,
    this.stopName,
    this.departureTime,
    this.arrivalTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'duration': duration.inMinutes,
      'distance': distance,
      'path': path.map((point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
      }).toList(),
      'vehicleNumber': vehicleNumber,
      'stopName': stopName,
      'departureTime': departureTime?.toIso8601String(),
      'arrivalTime': arrivalTime?.toIso8601String(),
    };
  }

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    return RouteStep(
      type: json['type'] as String,
      description: json['description'] as String,
      duration: Duration(minutes: json['duration'] as int),
      distance: json['distance'] as double,
      path: (json['path'] as List).map((point) => LatLng(
        point['latitude'] as double,
        point['longitude'] as double,
      )).toList(),
      vehicleNumber: json['vehicleNumber'] as String?,
      stopName: json['stopName'] as String?,
      departureTime: json['departureTime'] != null
          ? DateTime.parse(json['departureTime'] as String)
          : null,
      arrivalTime: json['arrivalTime'] != null
          ? DateTime.parse(json['arrivalTime'] as String)
          : null,
    );
  }
}

class Route {
  final String id;
  final List<RouteStep> steps;
  final Duration totalDuration;
  final double totalDistance;
  final int transfers;
  final double? cost;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final bool isFavorite;

  const Route({
    required this.id,
    required this.steps,
    required this.totalDuration,
    required this.totalDistance,
    required this.transfers,
    this.cost,
    required this.departureTime,
    required this.arrivalTime,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'steps': steps.map((step) => step.toJson()).toList(),
      'totalDuration': totalDuration.inMinutes,
      'totalDistance': totalDistance,
      'transfers': transfers,
      'cost': cost,
      'departureTime': departureTime.toIso8601String(),
      'arrivalTime': arrivalTime.toIso8601String(),
    };
  }

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      id: json['id'] as String,
      steps: (json['steps'] as List)
          .map((step) => RouteStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      totalDuration: Duration(minutes: json['totalDuration'] as int),
      totalDistance: json['totalDistance'] as double,
      transfers: json['transfers'] as int,
      cost: json['cost'] as double?,
      departureTime: DateTime.parse(json['departureTime'] as String),
      arrivalTime: DateTime.parse(json['arrivalTime'] as String),
      isFavorite: json['isFavorite'] as bool,
    );
  }

  Route copyWith({
    String? id,
    List<RouteStep>? steps,
    Duration? totalDuration,
    double? totalDistance,
    int? transfers,
    double? cost,
    DateTime? departureTime,
    DateTime? arrivalTime,
    bool? isFavorite,
  }) {
    return Route(
      id: id ?? this.id,
      steps: steps ?? this.steps,
      totalDuration: totalDuration ?? this.totalDuration,
      totalDistance: totalDistance ?? this.totalDistance,
      transfers: transfers ?? this.transfers,
      cost: cost ?? this.cost,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
} 