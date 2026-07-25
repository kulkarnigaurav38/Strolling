import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/config.dart';
import '../../../core/models/map_business.dart';
import '../../../core/theme.dart';

/// The city map. Two renderers behind one widget:
///
/// * **Raster tiles** (`flutter_map`) — the DEFAULT, and always renders. Uses
///   **Mapbox** when `--dart-define=MAPBOX_TOKEN=pk.…` is set, otherwise
///   **OpenStreetMap**, which needs no token at all.
/// * **Google Maps** — used when built with `--dart-define=USE_GOOGLE_MAPS=true`
///   AND the key is present *and* the Maps JavaScript API / Maps SDK for Android
///   are enabled on the Cloud project. Without activation Google paints its own
///   "Oops! Something went wrong" overlay over the whole screen, which is why it
///   is not the default.
class CityMapView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Config.useGoogleMaps
        ? _GoogleCityMap(
            businesses: businesses,
            cart: cart,
            selectedId: selectedId,
            onPinTap: onPinTap,
          )
        : _OsmCityMap(
            businesses: businesses,
            cart: cart,
            selectedId: selectedId,
            onPinTap: onPinTap,
          );
  }
}

// ---------------------------------------------------------------------------
// Raster-tile renderer (default): Mapbox when a token is set, else OSM
// ---------------------------------------------------------------------------

class _OsmCityMap extends StatelessWidget {
  const _OsmCityMap({
    required this.businesses,
    required this.cart,
    required this.selectedId,
    required this.onPinTap,
  });

  final List<MapBusiness> businesses;
  final List<int> cart;
  final int? selectedId;
  final ValueChanged<int> onPinTap;

  static ll.LatLng _ll(gmaps.LatLng p) => ll.LatLng(p.latitude, p.longitude);

  List<ll.LatLng> get _routePoints {
    if (cart.length < 2) return const [];
    final byId = {for (final b in businesses) b.id: b};
    return [
      _ll(kUserLocation),
      for (final id in cart)
        if (byId[id] != null) _ll(byId[id]!.latLng),
    ];
  }

  /// The basemap. Mapbox when a token is configured, otherwise one of the
  /// keyless presets in [Config.mapStyle] — no account, no billing, no key.
  fm.TileLayer _tileLayer() {
    if (Config.useMapbox) {
      return fm.TileLayer(
        urlTemplate:
            'https://api.mapbox.com/styles/v1/${Config.mapboxStyle}/tiles/512/{z}/{x}/{y}@2x'
            '?access_token=${Config.mapboxToken}',
        tileDimension: 512,
        zoomOffset: -1,
        userAgentPackageName: 'dev.strolling.app',
      );
    }
    return switch (Config.mapStyle) {
      // CARTO basemaps: free, keyless, and much calmer than raw OSM.
      'carto-positron' => fm.TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'dev.strolling.app',
        ),
      'carto-dark' => fm.TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'dev.strolling.app',
        ),
      'esri-satellite' => fm.TileLayer(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'dev.strolling.app',
        ),
      'osm' => fm.TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dev.strolling.app',
        ),
      _ => fm.TileLayer(
          urlTemplate:
              'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          userAgentPackageName: 'dev.strolling.app',
        ),
    };
  }

  String get _attribution {
    if (Config.useMapbox) return '© Mapbox © OpenStreetMap';
    return switch (Config.mapStyle) {
      'esri-satellite' => 'Imagery © Esri',
      'osm' => '© OpenStreetMap',
      _ => '© OpenStreetMap © CARTO',
    };
  }

  @override
  Widget build(BuildContext context) {
    final route = _routePoints;
    return fm.FlutterMap(
      options: fm.MapOptions(
        initialCenter: _ll(kStuttgartCenter),
        initialZoom: 14.6,
        // Leave the top/bottom chrome tappable rather than eating gestures.
        interactionOptions: const fm.InteractionOptions(
          flags: fm.InteractiveFlag.drag |
              fm.InteractiveFlag.pinchZoom |
              fm.InteractiveFlag.doubleTapZoom |
              fm.InteractiveFlag.scrollWheelZoom,
        ),
      ),
      children: [
        _tileLayer(),
        if (route.length >= 2)
          fm.PolylineLayer(
            polylines: [
              fm.Polyline(
                points: route,
                strokeWidth: 4,
                color: StrollingColors.primary,
                pattern: const fm.StrokePattern.dotted(),
              ),
            ],
          ),
        fm.MarkerLayer(
          markers: [
            fm.Marker(
              point: _ll(kUserLocation),
              width: 30,
              height: 30,
              child: const _YouAreHereDot(),
            ),
            for (final b in businesses)
              fm.Marker(
                point: _ll(b.latLng),
                width: 74,
                height: 62,
                alignment: Alignment.topCenter,
                child: _OsmPin(
                  business: b,
                  inCart: cart.contains(b.id),
                  selected: selectedId == b.id,
                  onTap: () => onPinTap(b.id),
                ),
              ),
          ],
        ),
        // Both Mapbox and OpenStreetMap require visible attribution.
        fm.RichAttributionWidget(
          alignment: fm.AttributionAlignment.bottomLeft,
          showFlutterMapAttribution: false,
          attributions: [
            fm.TextSourceAttribution(_attribution),
          ],
        ),
      ],
    );
  }
}

class _YouAreHereDot extends StatelessWidget {
  const _YouAreHereDot();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF2B7FFF),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _OsmPin extends StatelessWidget {
  const _OsmPin({
    required this.business,
    required this.inCart,
    required this.selected,
    required this.onTap,
  });

  final MapBusiness business;
  final bool inCart;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = business;
    final accent = inCart
        ? StrollingColors.success
        : (selected ? StrollingColors.primary : b.perkColor);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (b.hasPerk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (inCart)
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Icon(Icons.check, size: 10, color: Colors.white),
                    ),
                  Text(
                    b.perkVal ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: b.hasPerk ? Colors.white : const Color(0xFFA8A39B),
              shape: BoxShape.circle,
              border: Border.all(
                color: b.hasPerk ? accent : Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              b.hasPerk ? '★' : '·',
              style: TextStyle(
                color: b.hasPerk ? accent : Colors.white,
                fontSize: b.hasPerk ? 15 : 20,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Google Maps renderer (opt-in via USE_GOOGLE_MAPS)
// ---------------------------------------------------------------------------

class _GoogleCityMap extends StatefulWidget {
  const _GoogleCityMap({
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
  State<_GoogleCityMap> createState() => _GoogleCityMapState();
}

class _GoogleCityMapState extends State<_GoogleCityMap> {
  gmaps.GoogleMapController? _controller;

  static const _initial = gmaps.CameraPosition(
    target: kStuttgartCenter,
    zoom: 14.8,
  );

  Set<gmaps.Marker> get _markers {
    final markers = <gmaps.Marker>{
      gmaps.Marker(
        markerId: const gmaps.MarkerId('you'),
        position: kUserLocation,
        infoWindow: const gmaps.InfoWindow(title: 'You are here'),
        icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
          gmaps.BitmapDescriptor.hueAzure,
        ),
        zIndexInt: 2,
      ),
    };

    for (final b in widget.businesses) {
      final inCart = widget.cart.contains(b.id);
      final selected = widget.selectedId == b.id;
      markers.add(
        gmaps.Marker(
          markerId: gmaps.MarkerId('biz-${b.id}'),
          position: b.latLng,
          infoWindow: gmaps.InfoWindow(
            title: b.name,
            snippet: b.hasPerk ? '${b.perk} · ${b.perkVal}' : b.category,
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
            inCart
                ? gmaps.BitmapDescriptor.hueRed
                : (selected ? gmaps.BitmapDescriptor.hueOrange : b.markerHue),
          ),
          onTap: () => widget.onPinTap(b.id),
          zIndexInt: selected || inCart ? 3 : 1,
        ),
      );
    }
    return markers;
  }

  Set<gmaps.Polyline> get _polylines {
    if (widget.cart.length < 2) return {};
    final byId = {for (final b in widget.businesses) b.id: b};
    final points = <gmaps.LatLng>[kUserLocation];
    for (final id in widget.cart) {
      final b = byId[id];
      if (b != null) points.add(b.latLng);
    }
    return {
      gmaps.Polyline(
        polylineId: const gmaps.PolylineId('stroll'),
        points: points,
        color: StrollingColors.primary,
        width: 4,
        patterns: [gmaps.PatternItem.dash(18), gmaps.PatternItem.gap(10)],
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
    return gmaps.GoogleMap(
      initialCameraPosition: _initial,
      mapType: gmaps.MapType.normal,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      buildingsEnabled: true,
      trafficEnabled: false,
      markers: _markers,
      polylines: _polylines,
      padding: const EdgeInsets.only(top: 160, bottom: 120),
      onMapCreated: (controller) => _controller = controller,
    );
  }
}
