import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationModel {
  final LatLng coordinate;
  final String latitudeText;
  final String longitudeText;

  LocationModel({
    required this.coordinate,
    required this.latitudeText,
    required this.longitudeText,
  });
}