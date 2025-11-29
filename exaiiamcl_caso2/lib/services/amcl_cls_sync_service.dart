import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/amcl_cls_response.dart';
import 'amcl_cls_local_storage_service.dart';
import 'amcl_cls_firestore_service.dart';

class AMCLclsSyncService {
  final AMCLclsLocalStorageService _localStorage = AMCLclsLocalStorageService();
  final AMCLclsFirestoreService _firestoreService = AMCLclsFirestoreService();
  final Connectivity _connectivity = Connectivity();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  
  // Stream controller para notificar cambios en el estado de sincronización
  final _syncStatusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;
  
  // Verificar si hay conexión a Internet
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      return connectivityResult.any((result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet);
    } catch (e) {
      return false;
    }
  }
  
  // Iniciar monitoreo de conectividad
  void startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> result) async {
        if (result.any((r) => 
            r == ConnectivityResult.mobile || 
            r == ConnectivityResult.wifi || 
            r == ConnectivityResult.ethernet)) {
          // Hay conexión, intentar sincronizar automáticamente
          await syncPendingResponses();
        }
      },
    );
  }
  
  // Detener monitoreo de conectividad
  void stopConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
  }
  
  // Sincronizar respuestas pendientes
  Future<SyncResult> syncPendingResponses() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: 'Sincronización en progreso...',
        syncedCount: 0,
        failedCount: 0,
      );
    }
    
    _isSyncing = true;
    _syncStatusController.add(SyncStatus.syncing);
    
    int syncedCount = 0;
    int failedCount = 0;
    List<String> failedKeys = [];
    
    try {
      // Verificar conexión
      bool hasConnection = await hasInternetConnection();
      if (!hasConnection) {
        _isSyncing = false;
        _syncStatusController.add(SyncStatus.offline);
        return SyncResult(
          success: false,
          message: 'Sin conexión a Internet',
          syncedCount: 0,
          failedCount: 0,
        );
      }
      
      // Obtener respuestas pendientes
      List<AMCLclsResponse> pendingResponses = _localStorage.getPendingResponses();
      
      if (pendingResponses.isEmpty) {
        _isSyncing = false;
        _syncStatusController.add(SyncStatus.completed);
        return SyncResult(
          success: true,
          message: 'No hay respuestas pendientes',
          syncedCount: 0,
          failedCount: 0,
        );
      }
      
      // Sincronizar cada respuesta
      List<String> keys = _localStorage.getPendingKeys();
      for (int i = 0; i < pendingResponses.length; i++) {
        try {
          AMCLclsResponse response = pendingResponses[i];
          String key = keys[i];
          
          // Subir a Firestore
          await _firestoreService.createResponse(response);
          
          // Eliminar de almacenamiento local
          await _localStorage.deletePendingResponse(key);
          
          syncedCount++;
        } catch (e) {
          failedCount++;
          failedKeys.add(keys[i]);
        }
      }
      
      _isSyncing = false;
      
      if (failedCount == 0) {
        _syncStatusController.add(SyncStatus.completed);
        return SyncResult(
          success: true,
          message: 'Sincronización completada: $syncedCount respuesta(s)',
          syncedCount: syncedCount,
          failedCount: 0,
        );
      } else {
        _syncStatusController.add(SyncStatus.partialError);
        return SyncResult(
          success: false,
          message: 'Sincronizadas: $syncedCount, Fallidas: $failedCount',
          syncedCount: syncedCount,
          failedCount: failedCount,
          failedKeys: failedKeys,
        );
      }
      
    } catch (e) {
      _isSyncing = false;
      _syncStatusController.add(SyncStatus.error);
      return SyncResult(
        success: false,
        message: 'Error al sincronizar: $e',
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
    }
  }
  
  // Liberar recursos
  void dispose() {
    stopConnectivityMonitoring();
    _syncStatusController.close();
  }
}

// Enum para estados de sincronización
enum SyncStatus {
  idle,
  syncing,
  completed,
  error,
  partialError,
  offline,
}

// Clase para resultado de sincronización
class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  final List<String>? failedKeys;
  
  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
    this.failedKeys,
  });
}
