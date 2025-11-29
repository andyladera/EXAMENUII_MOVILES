import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/amcl_cls_dashboard_metrics.dart';
import '../services/amcl_cls_firestore_service.dart';

class AMCLclsResponsesMapScreen extends StatefulWidget {
  const AMCLclsResponsesMapScreen({super.key});

  @override
  State<AMCLclsResponsesMapScreen> createState() => _AMCLclsResponsesMapScreenState();
}

class _AMCLclsResponsesMapScreenState extends State<AMCLclsResponsesMapScreen> {
  final _firestoreService = AMCLclsFirestoreService();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  List<AMCLclsLocationData> _locations = [];
  
  // Ubicación por defecto (La Paz, Bolivia)
  static const LatLng _defaultLocation = LatLng(-16.5000, -68.1500);

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    
    try {
      List<AMCLclsLocationData> locations = await _firestoreService.getResponseLocations();
      
      Set<Marker> markers = {};
      for (var location in locations) {
        if (location.latitude != null && location.longitude != null) {
          markers.add(
            Marker(
              markerId: MarkerId('${location.latitude}_${location.longitude}_${location.completedAt.millisecondsSinceEpoch}'),
              position: LatLng(location.latitude!, location.longitude!),
              infoWindow: InfoWindow(
                title: location.surveyTitle,
                snippet: '${location.respondentName} - ${DateFormat('dd/MM/yyyy HH:mm').format(location.completedAt)}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            ),
          );
        }
      }
      
      setState(() {
        _locations = locations;
        _markers = markers;
        _isLoading = false;
      });
      
      // Ajustar cámara para mostrar todos los marcadores
      if (markers.isNotEmpty && _mapController != null) {
        _fitMarkersInView();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ubicaciones: $e')),
        );
      }
    }
  }

  void _fitMarkersInView() {
    if (_markers.isEmpty || _mapController == null) return;
    
    double minLat = _markers.first.position.latitude;
    double maxLat = _markers.first.position.latitude;
    double minLng = _markers.first.position.longitude;
    double maxLng = _markers.first.position.longitude;
    
    for (var marker in _markers) {
      if (marker.position.latitude < minLat) minLat = marker.position.latitude;
      if (marker.position.latitude > maxLat) maxLat = marker.position.latitude;
      if (marker.position.longitude < minLng) minLng = marker.position.longitude;
      if (marker.position.longitude > maxLng) maxLng = marker.position.longitude;
    }
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map, size: 24),
            SizedBox(width: 8),
            Text('Mapa de Respuestas'),
          ],
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocations,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 12,
            ),
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              if (_markers.isNotEmpty) {
                Future.delayed(const Duration(milliseconds: 500), _fitMarkersInView);
              }
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            mapType: MapType.normal,
            zoomControlsEnabled: true,
          ),
          
          // Indicador de carga
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando ubicaciones...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          
          // Panel de información
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.purple.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${_markers.length} ubicación${_markers.length != 1 ? 'es' : ''} encontrada${_markers.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Lista de ubicaciones (colapsable)
          if (_locations.isNotEmpty)
            DraggableScrollableSheet(
              initialChildSize: 0.15,
              minChildSize: 0.15,
              maxChildSize: 0.6,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Icon(Icons.list, color: Colors.purple.shade700, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Listado de Ubicaciones',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _locations.length,
                          itemBuilder: (context, index) {
                            AMCLclsLocationData location = _locations[index];
                            bool hasCoords = location.latitude != null && location.longitude != null;
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasCoords ? Colors.purple.shade100 : Colors.grey.shade200,
                                child: Icon(
                                  hasCoords ? Icons.location_on : Icons.location_off,
                                  color: hasCoords ? Colors.purple.shade700 : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                location.respondentName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(location.surveyTitle),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(location.completedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  if (location.address != null)
                                    Text(
                                      location.address!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                              trailing: hasCoords
                                  ? IconButton(
                                      icon: const Icon(Icons.my_location),
                                      onPressed: () {
                                        _mapController?.animateCamera(
                                          CameraUpdate.newLatLngZoom(
                                            LatLng(location.latitude!, location.longitude!),
                                            15,
                                          ),
                                        );
                                      },
                                    )
                                  : null,
                              isThreeLine: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
