// lib/core/services/location_service.dart

import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LocationResult {
  final double latitude;
  final double longitude;
  final double? accuracy;
  const LocationResult({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  String get label =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Demande la permission et retourne la position actuelle.
  /// Retourne null si refusé ou non disponible.
  Future<LocationResult?> getCurrentLocation() async {
    try {
      // Vérifier si le service est activé
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Vérifier/demander permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      // Obtenir position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (_) {
      return null;
    }
  }

  /// Ouvre Google Maps avec les coordonnées
  static String googleMapsUrl(double lat, double lng) =>
      'https://www.google.com/maps?q=$lat,$lng';
}
