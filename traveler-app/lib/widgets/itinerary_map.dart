import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/theme/locallens_design_system.dart';
import '../models/itinerary_model.dart';
import '../services/google_maps_service.dart';
import 'common/locallens_components.dart';

/// Interactive Google Map displaying the final itinerary route and numbered markers
class ItineraryMapWidget extends StatefulWidget {
  final List<ItineraryItem> items;
  final LatLng? startLocation;
  final String startAddress;
  final int? selectedIndex;
  final double height;
  final ValueChanged<int>? onExperienceSelected;

  const ItineraryMapWidget({
    super.key,
    required this.items,
    this.startLocation,
    this.startAddress = 'Starting Point',
    this.selectedIndex,
    this.height = 300,
    this.onExperienceSelected,
  });

  @override
  State<ItineraryMapWidget> createState() => ItineraryMapWidgetState();
}

class ItineraryMapWidgetState extends State<ItineraryMapWidget> {
  GoogleMapController? _mapController;
  final Completer<GoogleMapController> _controllerCompleter = Completer();

  Map<MarkerId, Marker> _markers = {};
  Set<Polyline> _polylines = {};
  MapType _currentMapType = MapType.normal;
  int? _activeSelectedIndex;

  @override
  void initState() {
    super.initState();
    _activeSelectedIndex = widget.selectedIndex;
    _buildMapElementsSync();
    _loadCustomMarkersAsync();
  }

  @override
  void didUpdateWidget(covariant ItineraryMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items ||
        oldWidget.startLocation != widget.startLocation ||
        oldWidget.selectedIndex != widget.selectedIndex) {
      _activeSelectedIndex = widget.selectedIndex;
      _buildMapElementsSync();
      _loadCustomMarkersAsync();
      if (widget.selectedIndex != null && widget.selectedIndex != oldWidget.selectedIndex) {
        animateToExperienceIndex(widget.selectedIndex!);
      }
    }
  }

  /// Synchronous map element construction guarantees markers and polylines are instantly present
  void _buildMapElementsSync() {
    final validItems = widget.items.where((i) => i.latitude != null && i.longitude != null).toList();
    final markersMap = <MarkerId, Marker>{};

    // 1. Start Marker
    if (widget.startLocation != null) {
      const startMarkerId = MarkerId('marker_start_location');
      markersMap[startMarkerId] = Marker(
        markerId: startMarkerId,
        position: widget.startLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        zIndexInt: 2,
        infoWindow: InfoWindow(
          title: 'Trip Starting Location',
          snippet: widget.startAddress.isNotEmpty ? widget.startAddress : 'Origin',
        ),
        onTap: () {
          setState(() {
            _activeSelectedIndex = null;
          });
        },
      );
    }

    // 2. Experience Markers
    for (int i = 0; i < validItems.length; i++) {
      final item = validItems[i];
      final isSelected = _activeSelectedIndex == i;
      final visitOrder = i + 1;
      final markerId = MarkerId('exp_${item.id}_$visitOrder');

      markersMap[markerId] = Marker(
        markerId: markerId,
        position: LatLng(item.latitude!, item.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueCyan,
        ),
        zIndexInt: isSelected ? 10 : (5 + i),
        infoWindow: InfoWindow(
          title: '$visitOrder. ${item.experienceName}',
          snippet: '${item.startTime} – ${item.endTime} • ${item.category}',
          onTap: () {
            widget.onExperienceSelected?.call(i);
          },
        ),
        onTap: () {
          setState(() {
            _activeSelectedIndex = i;
          });
          widget.onExperienceSelected?.call(i);
        },
      );
    }

    // 3. Route Polyline
    final routePoints = GoogleMapsService.buildItineraryRoutePoints(
      startLocation: widget.startLocation,
      items: widget.items,
    );

    final polylinesSet = <Polyline>{};
    if (routePoints.length >= 2) {
      polylinesSet.add(
        Polyline(
          polylineId: const PolylineId('itinerary_main_route'),
          points: routePoints,
          color: LocalLensColors.primaryTeal,
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
    }

    _markers = markersMap;
    _polylines = polylinesSet;
  }

  /// Asynchronously upgrade markers to custom numbered canvas badges
  Future<void> _loadCustomMarkersAsync() async {
    try {
      final validItems = widget.items.where((i) => i.latitude != null && i.longitude != null).toList();
      final upgradedMarkers = <MarkerId, Marker>{};

      // Start Marker
      if (widget.startLocation != null) {
        final startIcon = await GoogleMapsService.createCustomNumberedMarker(
          text: 'START',
          backgroundColor: LocalLensColors.successGreen,
          textColor: Colors.white,
          isStart: true,
          isSelected: false,
        );

        const startMarkerId = MarkerId('marker_start_location');
        upgradedMarkers[startMarkerId] = Marker(
          markerId: startMarkerId,
          position: widget.startLocation!,
          icon: startIcon,
          zIndexInt: 2,
          infoWindow: InfoWindow(
            title: 'Trip Starting Location',
            snippet: widget.startAddress.isNotEmpty ? widget.startAddress : 'Origin',
          ),
          onTap: () {
            setState(() {
              _activeSelectedIndex = null;
            });
          },
        );
      }

      // Numbered markers
      for (int i = 0; i < validItems.length; i++) {
        final item = validItems[i];
        final isSelected = _activeSelectedIndex == i;
        final visitOrder = i + 1;

        final icon = await GoogleMapsService.createCustomNumberedMarker(
          text: '$visitOrder',
          backgroundColor: isSelected
              ? LocalLensColors.accentOrange
              : (item.isSelected ? LocalLensColors.primaryTeal : Colors.grey),
          textColor: Colors.white,
          isStart: false,
          isSelected: isSelected,
        );

        final markerId = MarkerId('exp_${item.id}_$visitOrder');
        upgradedMarkers[markerId] = Marker(
          markerId: markerId,
          position: LatLng(item.latitude!, item.longitude!),
          icon: icon,
          zIndexInt: isSelected ? 10 : (5 + i),
          infoWindow: InfoWindow(
            title: '$visitOrder. ${item.experienceName}',
            snippet: '${item.startTime} – ${item.endTime} • ${item.category}',
            onTap: () {
              widget.onExperienceSelected?.call(i);
            },
          ),
          onTap: () {
            setState(() {
              _activeSelectedIndex = i;
            });
            widget.onExperienceSelected?.call(i);
          },
        );
      }

      if (mounted && upgradedMarkers.isNotEmpty) {
        setState(() {
          _markers = upgradedMarkers;
        });
      }
    } catch (e) {
      debugPrint('[ItineraryMapWidget] Custom marker upgrade error: $e');
    }
  }

  /// Center and fit all markers on camera
  void fitAllBounds() {
    if (_mapController == null) return;
    final bounds = GoogleMapsService.calculateBounds(
      startLocation: widget.startLocation,
      items: widget.items,
    );
    if (bounds != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 48),
      );
    }
  }

  /// Focus and animate camera to a specific itinerary item
  void animateToExperienceIndex(int index) {
    if (index < 0 || index >= widget.items.length) return;
    final item = widget.items[index];
    if (item.latitude != null && item.longitude != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(item.latitude!, item.longitude!),
            zoom: 15.5,
          ),
        ),
      );
      setState(() {
        _activeSelectedIndex = index;
      });
      _buildMapElementsSync();
      _loadCustomMarkersAsync();
    }
  }

  @override
  Widget build(BuildContext context) {
    final validItems = widget.items.where((i) => i.latitude != null && i.longitude != null).toList();
    if (_markers.isEmpty && (validItems.isNotEmpty || widget.startLocation != null)) {
      _buildMapElementsSync();
    }
    final initialPos = (validItems.isNotEmpty)
        ? LatLng(validItems.first.latitude!, validItems.first.longitude!)
        : (widget.startLocation ?? const LatLng(18.9894, 73.1175));

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
        border: Border.all(color: LocalLensColors.border),
        boxShadow: LocalLensDimensions.softCardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LocalLensDimensions.radiusLarge),
        child: Stack(
          children: [
            // GOOGLE MAP VIEW
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPos,
                zoom: 12.0,
              ),
              mapType: _currentMapType,
              markers: Set<Marker>.of(_markers.values),
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                if (!_controllerCompleter.isCompleted) {
                  _controllerCompleter.complete(controller);
                }
                setState(() {
                  _buildMapElementsSync();
                });
                _loadCustomMarkersAsync();
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) fitAllBounds();
                });
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) fitAllBounds();
                });
              },
              onTap: (_) {
                setState(() {
                  _activeSelectedIndex = null;
                });
              },
            ),

            // Top Header Overlay Badge
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(LocalLensDimensions.radiusFull),
                  boxShadow: LocalLensDimensions.softCardShadow,
                  border: Border.all(color: LocalLensColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.route_rounded, size: 14, color: LocalLensColors.primaryTeal),
                    const SizedBox(width: 6),
                    Text(
                      '${validItems.length} Stops in Visit Order',
                      style: LocalLensTypography.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LocalLensColors.primaryTealDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-Right Map Controls Toolbar
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  // Fit All Bounds Button
                  _buildMapActionButton(
                    icon: Icons.crop_free_rounded,
                    tooltip: 'Fit all stops',
                    onTap: fitAllBounds,
                  ),
                  const SizedBox(height: 6),
                  // Center Start Button
                  if (widget.startLocation != null) ...[
                    _buildMapActionButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Center on start',
                      onTap: () {
                        if (_mapController != null && widget.startLocation != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(widget.startLocation!, 14.5),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Layer Toggle Button
                  _buildMapActionButton(
                    icon: _currentMapType == MapType.normal ? Icons.layers_outlined : Icons.map_rounded,
                    tooltip: 'Toggle map type',
                    onTap: () {
                      setState(() {
                        _currentMapType = _currentMapType == MapType.normal ? MapType.terrain : MapType.normal;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Bottom Selected Experience Info Preview Overlay
            if (_activeSelectedIndex != null && _activeSelectedIndex! < widget.items.length)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: _buildSelectedMarkerPreviewCard(widget.items[_activeSelectedIndex!], _activeSelectedIndex! + 1),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        shape: BoxShape.circle,
        boxShadow: LocalLensDimensions.softCardShadow,
        border: Border.all(color: LocalLensColors.border),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 18,
        icon: Icon(icon, color: LocalLensColors.textPrimary),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildSelectedMarkerPreviewCard(ItineraryItem item, int visitOrder) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: LocalLensDimensions.floatingShadow,
        border: Border.all(color: LocalLensColors.accentOrange, width: 1.5),
      ),
      child: Row(
        children: [
          // Order Badge
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: LocalLensColors.accentOrange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$visitOrder',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Experience Image
          LocalLensNetworkImage(
            imageUrl: item.image,
            width: 44,
            height: 44,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(width: 10),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.experienceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LocalLensTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${item.startTime} – ${item.endTime}',
                      style: LocalLensTypography.caption.copyWith(color: LocalLensColors.primaryTeal, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                    const SizedBox(width: 6),
                    Text('•', style: TextStyle(color: LocalLensColors.textMuted, fontSize: 10)),
                    const SizedBox(width: 6),
                    Text(
                      item.price > 0 ? '₹${item.price.toInt()}' : 'Free',
                      style: LocalLensTypography.caption.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Close button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded, size: 18, color: LocalLensColors.textMuted),
            onPressed: () {
              setState(() {
                _activeSelectedIndex = null;
              });
            },
          ),
        ],
      ),
    );
  }
}
