import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../model/location_model.dart';

class LocationViewModel extends ChangeNotifier {
  GoogleMapController? _mapController;
  Timer? _timer;

  bool isLoading = true;
  Marker? currentMarker;
  Marker? destinationMarker;

  final List<LatLng> polylinePoints = [];
  final List<LatLng> routePoints = [];

  // Directions API এর জন্য API Key
  final String googleApiKey = 'AIzaSyDUqGem_JcBtXArUpQl5tT7bA7JCCmT_mA';

  //"AIzaSyAOVYRIgupAurZup5y1PRh8Ismb1A3lLao";

  final CameraPosition initialPosition = const CameraPosition(
    target: LatLng(23.7216771, 90.4165835),
    zoom: 16.0,
  );

  LocationViewModel() {
    _startTracking();
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    await _fetchLocation();

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchLocation();
    });
  }

  Future<void> _fetchLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      // ignore: deprecated_member_use
      desiredAccuracy: LocationAccuracy.high,
    );

    final locationData = LocationModel(
      coordinate: LatLng(position.latitude, position.longitude),
      latitudeText: position.latitude.toStringAsFixed(7),
      longitudeText: position.longitude.toStringAsFixed(7),
    );

    polylinePoints.add(locationData.coordinate);

    currentMarker = Marker(
      markerId: const MarkerId('current_location'),
      position: locationData.coordinate,
      infoWindow: InfoWindow(
        title: 'My Current Location',
        snippet: '${locationData.latitudeText},${locationData.longitudeText}',
      ),
    );

    isLoading = false;

    if (_mapController != null && destinationMarker == null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: locationData.coordinate, zoom: 17),
        ),
      );
    }

    if (destinationMarker != null) {
      _getRoute(locationData.coordinate, destinationMarker!.position);
    } else {
      notifyListeners();
    }
  }

  void onMapTapped(LatLng tapLocation) {
    destinationMarker = Marker(
      markerId: const MarkerId('destination'),
      position: tapLocation,
      infoWindow: const InfoWindow(title: 'Destination'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    if (polylinePoints.isNotEmpty) {
      _getRoute(polylinePoints.last, tapLocation);
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    PolylinePoints polylinePointsInstance = PolylinePoints(
      apiKey: googleApiKey,
    );

    PolylineResult result = await polylinePointsInstance
        .getRouteBetweenCoordinates(
          // ignore: deprecated_member_use
          request: PolylineRequest(
            origin: PointLatLng(start.latitude, start.longitude),
            destination: PointLatLng(end.latitude, end.longitude),
            mode: TravelMode.driving,
          ),
        );

    // এরর থাকলে টার্মিনালে দেখাবে
    if (result.status != 'OK') {
      debugPrint('Directions API Error: ${result.errorMessage}');
    }

    routePoints.clear();
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        routePoints.add(LatLng(point.latitude, point.longitude));
      }
    }
    notifyListeners();
  }

  void recenterMap() {
    if (polylinePoints.isNotEmpty && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: polylinePoints.last, zoom: 17),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}
