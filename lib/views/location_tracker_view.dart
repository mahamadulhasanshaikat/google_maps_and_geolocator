import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodel/location_view_model.dart';

class LocationTrackerView extends StatelessWidget {
  const LocationTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Real-Time Location Tracker',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black38,
      ),
      body: Consumer<LocationViewModel>(
        builder: (context, viewModel, child) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: viewModel.initialPosition,
                onMapCreated: viewModel.onMapCreated,
                onTap: viewModel.onMapTapped, 
                padding: const EdgeInsets.only(bottom: 90, right: 10), 
                
                markers: {
                  if (viewModel.currentMarker != null) viewModel.currentMarker!,
                  if (viewModel.destinationMarker != null) viewModel.destinationMarker!,
                },
                
                polylines: {
                  // রিয়েল-টাইম লোকেশন ট্র্যাকিং লাইন (নীল)
                  Polyline(
                    polylineId: const PolylineId('tracking_route'),
                    color: Colors.blueAccent,
                    width: 5,
                    points: viewModel.polylinePoints,
                    jointType: JointType.round,
                  ),
                  // গন্তব্যের রাস্তা দেখানোর লাইন (লাল ড্যাশ লাইন)
                  if (viewModel.routePoints.isNotEmpty)
                    Polyline(
                      polylineId: const PolylineId('destination_route'),
                      color: Colors.redAccent,
                      width: 4,
                      points: viewModel.routePoints,
                      patterns: [PatternItem.dash(20), PatternItem.gap(10)],
                    ),
                },
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),
              
              if (viewModel.isLoading)
                Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 20.0, horizontal: 30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.blueAccent),
                          SizedBox(height: 16),
                          Text(
                            'Fetching Location...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<LocationViewModel>(
        builder: (context, viewModel, child) {
          return viewModel.isLoading 
              ? const SizedBox.shrink() 
              : FloatingActionButton(
                  onPressed: viewModel.recenterMap,
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  child: const Icon(Icons.my_location),
                );
        },
      ),
    );
  }
}