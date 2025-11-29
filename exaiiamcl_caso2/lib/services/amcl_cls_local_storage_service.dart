import 'package:hive_flutter/hive_flutter.dart';
import '../models/amcl_cls_response.dart';
import '../adapters/amcl_cls_response_adapter.dart';

class AMCLclsLocalStorageService {
  static const String _pendingResponsesBox = 'pending_responses';
  
  // Inicializar Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Registrar adaptadores
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AMCLclsResponseAdapter());
    }
    
    // Abrir box
    await Hive.openBox<AMCLclsResponse>(_pendingResponsesBox);
  }
  
  // Obtener box de respuestas pendientes
  Box<AMCLclsResponse> get _responsesBox {
    return Hive.box<AMCLclsResponse>(_pendingResponsesBox);
  }
  
  // Guardar respuesta localmente
  Future<void> savePendingResponse(AMCLclsResponse response) async {
    // Usar timestamp como key única
    String key = '${response.surveyId}_${response.completedAt.millisecondsSinceEpoch}';
    await _responsesBox.put(key, response);
  }
  
  // Obtener todas las respuestas pendientes
  List<AMCLclsResponse> getPendingResponses() {
    return _responsesBox.values.toList();
  }
  
  // Obtener respuestas pendientes por encuesta
  List<AMCLclsResponse> getPendingResponsesBySurvey(String surveyId) {
    return _responsesBox.values
        .where((response) => response.surveyId == surveyId)
        .toList();
  }
  
  // Obtener cantidad de respuestas pendientes
  int getPendingCount() {
    return _responsesBox.length;
  }
  
  // Eliminar respuesta pendiente específica
  Future<void> deletePendingResponse(String key) async {
    await _responsesBox.delete(key);
  }
  
  // Eliminar respuesta por timestamp
  Future<void> deletePendingResponseByTimestamp(String surveyId, int timestamp) async {
    String key = '${surveyId}_$timestamp';
    await _responsesBox.delete(key);
  }
  
  // Limpiar todas las respuestas pendientes
  Future<void> clearAllPendingResponses() async {
    await _responsesBox.clear();
  }
  
  // Obtener keys de respuestas pendientes
  List<String> getPendingKeys() {
    return _responsesBox.keys.cast<String>().toList();
  }
  
  // Verificar si hay respuestas pendientes
  bool hasPendingResponses() {
    return _responsesBox.isNotEmpty;
  }
}
