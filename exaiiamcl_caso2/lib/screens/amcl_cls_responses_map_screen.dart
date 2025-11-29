import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/amcl_cls_dashboard_metrics.dart';
import '../services/amcl_cls_firestore_service.dart';

class AMCLclsResponsesMapScreen extends StatefulWidget {
  const AMCLclsResponsesMapScreen({super.key});

  @override
  State<AMCLclsResponsesMapScreen> createState() => _AMCLclsResponsesMapScreenState();
}

class _AMCLclsResponsesMapScreenState extends State<AMCLclsResponsesMapScreen> {
  final _firestoreService = AMCLclsFirestoreService();
  bool _isLoading = true;
  List<AMCLclsLocationData> _locations = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    
    try {
      List<AMCLclsLocationData> locations = await _firestoreService.getResponseLocations();
      
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ubicaciones: $e')),
        );
      }
    }
  }

  Future<void> _openInGoogleMaps(double lat, double lng, String title) async {
    final urlString = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir Google Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int locationsWithCoords = _locations.where((l) => l.latitude != null && l.longitude != null).length;
    
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.map, size: 24),
            SizedBox(width: 8),
            Text('Ubicaciones de Respuestas'),
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
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando ubicaciones...'),
                ],
              ),
            )
          : _locations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No hay respuestas con ubicación',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _loadLocations,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Recargar'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      color: Colors.purple.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatCard(
                            icon: Icons.location_on,
                            label: 'Con GPS',
                            value: '$locationsWithCoords',
                            color: Colors.green,
                          ),
                          _buildStatCard(
                            icon: Icons.list,
                            label: 'Total',
                            value: '${_locations.length}',
                            color: Colors.purple,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _locations.length,
                        itemBuilder: (context, index) {
                          AMCLclsLocationData location = _locations[index];
                          bool hasCoords = location.latitude != null && location.longitude != null;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasCoords ? Colors.purple.shade100 : Colors.grey.shade200,
                                child: Icon(
                                  hasCoords ? Icons.location_on : Icons.location_off,
                                  color: hasCoords ? Colors.purple.shade700 : Colors.grey,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                location.respondentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.assignment, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          location.surveyTitle,
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(location.completedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (hasCoords) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.my_location, size: 14, color: Colors.blue.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            '${location.latitude!.toStringAsFixed(6)}, ${location.longitude!.toStringAsFixed(6)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.blue.shade700,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (location.address != null && location.address!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.place, size: 14, color: Colors.orange.shade600),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location.address!,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: hasCoords
                                  ? IconButton(
                                      icon: const Icon(Icons.map),
                                      color: Colors.purple.shade700,
                                      tooltip: 'Ver en Google Maps',
                                      onPressed: () => _openInGoogleMaps(
                                        location.latitude!,
                                        location.longitude!,
                                        location.surveyTitle,
                                      ),
                                    )
                                  : null,
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
