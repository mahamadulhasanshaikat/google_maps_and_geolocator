import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../model/location_model.dart';

class LocationViewModel extends ChangeNotifier {
  GoogleMapController? _mapController;
  Timer? _timer;
  
  bool isLoading = true;
  Marker? currentMarker;
  final List<LatLng> polylinePoints = []; 
  
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
        snippet: '${locationData.latitudeText}, ${locationData.longitudeText}',
      ),
    );

    isLoading = false;
    
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: locationData.coordinate, zoom: 17),
        ),
      );
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