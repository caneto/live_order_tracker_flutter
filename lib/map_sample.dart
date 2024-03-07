import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_mao/constants.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import 'components/rider_info.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer();
  PolylinePoints polylinePoints = PolylinePoints();

  //drawn routes on the map
  final Set<Polyline> _polylines = <Polyline>{};
  List<LatLng> polylineCoordinates = [];

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLicationIcon = BitmapDescriptor.defaultMarker;

  // Location
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  LocationData? currentLocation;

  static const LatLng sourceLocation = LatLng(37.33500926, -122.03272188);
  static const LatLng destination = LatLng(37.33429383, -122.06600055);
  Location location = Location();

  CameraPosition? initialCameraPosition;

  void initialLocation() async {
    
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    location.getLocation().then(
      (currentLoc) {
        currentLocation = currentLoc;
        initialCameraPosition = CameraPosition(
          target: LatLng(currentLoc.latitude!, currentLoc.longitude!),
          zoom: 14.5,
          tilt: 59,
          bearing: -70,
        );
        location.onLocationChanged.listen((LocationData newLoc) async {
          currentLocation = newLoc;

          final GoogleMapController controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(newLoc.latitude!, newLoc.longitude!),
                zoom: 14.5,
                tilt: 59,
                bearing: -70,
              ),
            ),
          );
          setState(() {});
        });
      },
    );
  }

  void getPolyPoints() async {
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey,
      PointLatLng(sourceLocation.latitude, sourceLocation.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      optimizeWaypoints: true,
    );
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      }
      setState(
        () {
          _polylines.add(
            Polyline(
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
              jointType: JointType.round,
              geodesic: true,
              polylineId: const PolylineId("line"),
              width: 6,
              color: primaryColor,
              points: polylineCoordinates,
            ),
          );
        },
      );
    }
  }

  void setSourceAndDestinationIcons() async {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(24, 24)),
            'assets/Pin_source.png')
        .then(
      (value) {
        sourceIcon = value;
      },
    );
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), 'assets/Pin_destination.png')
        .then(
      (value) {
        destinationIcon = value;
      },
    );
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(), 'assets/Badge.png')
        .then(
      (value) {
        currentLicationIcon = value;
      },
    );
  }

  @override
  void initState() {
    initialLocation();
    getPolyPoints();
    setSourceAndDestinationIcons();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Track order",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
      ),
      body: currentLocation == null
          ? const Center(child: Text("Loading..."))
          : Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: GoogleMap(
                      zoomControlsEnabled: true,
                      initialCameraPosition: initialCameraPosition!,
                      polylines: _polylines,
                      markers: {
                        Marker(
                          markerId: const MarkerId("currentLocation"),
                          icon: currentLicationIcon,
                          position: LatLng(currentLocation!.latitude!,
                              currentLocation!.longitude!),
                        ),
                        Marker(
                          markerId: const MarkerId("source"),
                          icon: sourceIcon,
                          position: sourceLocation,
                        ),
                        Marker(
                          markerId: const MarkerId("destination"),
                          icon: destinationIcon,
                          position: destination,
                        ),
                      },
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                  ),
                ),
                const RiderInfo(),
              ],
            ),
    );
  }
}
