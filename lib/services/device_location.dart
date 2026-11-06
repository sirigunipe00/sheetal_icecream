import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocationDetails {
  const DeviceLocationDetails({
    this.street,
    this.locality,
    this.subLocality,
    this.city,
    this.state,
    this.postalCode,
    this.landmark,
    this.latitude,
    this.longitude,
    required this.preview,
  });

  final String? street;
  final String? locality;
  final String? subLocality;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final String preview;
}

class DeviceLocation {
  const DeviceLocation._();

  static Future<String> currentLabel() async {
    try {
      final details = await currentDetails();
      return 'Delivering to ${details.preview}';
    } on DeviceLocationException catch (e) {
      return e.message;
    }
  }

  /// Resolves GPS → placemark fields for address autofill (Blinkit-style).
  static Future<DeviceLocationDetails> currentDetails() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const DeviceLocationException('Location is turned off');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException('Location permission needed');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        'Location permission blocked. Enable it in Settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    try {
      final marks = await Geocoding().placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (marks.isEmpty) {
        return DeviceLocationDetails(
          latitude: position.latitude,
          longitude: position.longitude,
          preview:
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        );
      }

      final place = marks.first;
      final street = _firstNonEmpty([
        place.thoroughfare,
        place.street,
        place.name,
      ]);
      final subLocality = _firstNonEmpty([place.subLocality]);
      final locality = _firstNonEmpty([
        place.subLocality,
        place.locality,
      ]);
      final city = _firstNonEmpty([
        place.locality,
        place.subAdministrativeArea,
      ]);
      final state = _firstNonEmpty([place.administrativeArea]);
      final postal = _firstNonEmpty([place.postalCode]);
      final landmark = _firstNonEmpty([
        place.name,
        place.thoroughfare,
      ]);

      final area = _firstNonEmpty([subLocality, locality, city]);
      final previewCity = _firstNonEmpty([city, state]);
      final preview = (area != null &&
              previewCity != null &&
              area.toLowerCase() != previewCity.toLowerCase())
          ? '$area, $previewCity'
          : (area ?? previewCity ?? 'Current location');

      return DeviceLocationDetails(
        street: street,
        locality: locality,
        subLocality: subLocality,
        city: city,
        state: state,
        postalCode: postal,
        landmark: landmark,
        latitude: position.latitude,
        longitude: position.longitude,
        preview: preview,
      );
    } catch (_) {
      return DeviceLocationDetails(
        latitude: position.latitude,
        longitude: position.longitude,
        preview:
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
      );
    }
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);
  final String message;

  @override
  String toString() => message;
}
