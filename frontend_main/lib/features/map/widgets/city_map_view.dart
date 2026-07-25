import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/map_business.dart';
import '../../../core/theme.dart';

class CityMapView extends StatefulWidget {
  const CityMapView({
    super.key,
    required this.businesses,
    required this.cart,
    required this.selectedId,
    required this.onPinTap,
  });

  final List<MapBusiness> businesses;
  final List<int> cart;
  final int? selectedId;
  final ValueChanged<int> onPinTap;

  @override
  State<CityMapView> createState() => _CityMapViewState();
}

class _CityMapViewState extends State<CityMapView> {
  GoogleMapController? _controller;

  static const _initial = CameraPosition(
    target: kStuttgartCenter,
    zoom: 14.8,
  );

  Set<Marker> get _markers {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('you'),
        position: kUserLocation,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        zIndexInt: 2,
      ),
    };

    for (final b in widget.businesses) {
      final inCart = widget.cart.contains(b.id);
      final selected = widget.selectedId == b.id;
      markers.add(
        Marker(
          markerId: MarkerId('biz-${b.id}'),
          position: b.latLng,
          infoWindow: InfoWindow(
            title: b.name,
            snippet: b.hasPerk
                ? '${b.perk} · ${b.perkVal}'
                : b.category,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            inCart
                ? BitmapDescriptor.hueRed
                : (selected ? BitmapDescriptor.hueOrange : b.markerHue),
          ),
          onTap: () => widget.onPinTap(b.id),
          zIndexInt: selected || inCart ? 3 : 1,
        ),
      );
    }
    return markers;
  }

  Set<Polyline> get _polylines {
    if (widget.cart.length < 2) return {};
    final byId = {for (final b in widget.businesses) b.id: b};
    final points = <LatLng>[kUserLocation];
    for (final id in widget.cart) {
      final b = byId[id];
      if (b != null) points.add(b.latLng);
    }
    return {
      Polyline(
        polylineId: const PolylineId('stroll'),
        points: points,
        color: StrollingColors.primary,
        width: 4,
        patterns: [PatternItem.dash(18), PatternItem.gap(10)],
      ),
    };
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: _initial,
      mapType: MapType.normal,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      trafficEnabled: false,
      markers: _markers,
      polylines: _polylines,
      padding: const EdgeInsets.only(top: 160, bottom: 120),
      onMapCreated: (controller) {
        _controller = controller;
      },
      onTap: (_) {
        // Deselect handled by parent when tapping empty map — optional.
      },
    );
  }
}
