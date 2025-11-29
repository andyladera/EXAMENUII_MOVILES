import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/amcl_cls_response.dart';
import '../services/amcl_cls_local_storage_service.dart';
import '../services/amcl_cls_sync_service.dart';

class AMCLclsPendingResponsesScreen extends StatefulWidget {
  const AMCLclsPendingResponsesScreen({super.key});

  @override
  State<AMCLclsPendingResponsesScreen> createState() => _AMCLclsPendingResponsesScreenState();
}

class _AMCLclsPendingResponsesScreenState extends State<AMCLclsPendingResponsesScreen> {
  final _localStorage = AMCLclsLocalStorageService();
  final _syncService = AMCLclsSyncService();
  bool _isSyncing = false;
  bool _hasConnection = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    bool hasConn = await _syncService.hasInternetConnection();
    setState(() {
      _hasConnection = hasConn;
    });
  }

  Future<void> _syncNow() async {
    setState(() => _isSyncing = true);

    SyncResult result = await _syncService.syncPendingResponses();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );

      setState(() {
        _isSyncing = false;
      });

      if (result.success) {
        // Recargar la lista
        setState(() {});
      }
    }
  }

  Future<void> _clearAll() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar'),
        content: const Text(
          '¿Estás seguro de eliminar TODAS las respuestas pendientes?\n\n'
          'Esta acción no se puede deshacer y perderás las respuestas que no se han sincronizado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar Todo'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _localStorage.clearAllPendingResponses();
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las respuestas pendientes fueron eliminadas'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<AMCLclsResponse> pendingResponses = _localStorage.getPendingResponses();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Respuestas Pendientes'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (pendingResponses.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Eliminar todas',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Banner de estado
          Container(
            width: double.infinity,
            color: _hasConnection ? Colors.green.shade100 : Colors.red.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  _hasConnection ? Icons.cloud_done : Icons.cloud_off,
                  color: _hasConnection ? Colors.green.shade800 : Colors.red.shade800,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasConnection ? 'Conexión disponible' : 'Sin conexión a Internet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _hasConnection ? Colors.green.shade900 : Colors.red.shade900,
                        ),
                      ),
                      if (_hasConnection)
                        Text(
                          'Puedes sincronizar ahora',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade800,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_hasConnection && pendingResponses.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _syncNow,
                    icon: _isSyncing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync),
                    label: Text(_isSyncing ? 'Sincronizando...' : 'Sincronizar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),

          // Lista de respuestas pendientes
          Expanded(
            child: pendingResponses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay respuestas pendientes',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Todas tus respuestas han sido sincronizadas',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: pendingResponses.length,
                    itemBuilder: (context, index) {
                      AMCLclsResponse response = pendingResponses[index];
                      return _buildResponseCard(response);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(AMCLclsResponse response) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Survey ID: ${response.surveyId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'PENDIENTE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildInfoRow(Icons.person, 'Encuestado', response.respondentName),
            if (response.respondentEmail != null)
              _buildInfoRow(Icons.email, 'Email', response.respondentEmail!),
            if (response.location != null)
              _buildInfoRow(Icons.location_on, 'Ubicación', response.location!),
            _buildInfoRow(
              Icons.access_time,
              'Fecha',
              DateFormat('dd/MM/yyyy HH:mm').format(response.completedAt),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.question_answer, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${response.answers.length} respuesta(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
