import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/amcl_cls_survey.dart';
import '../models/amcl_cls_question.dart';
import '../models/amcl_cls_response.dart';
import '../models/amcl_cls_survey_stats.dart';
import '../models/amcl_cls_user.dart';
import '../models/amcl_cls_dashboard_metrics.dart';

class AMCLclsFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== SURVEYS ====================
  
  // Crear encuesta
  Future<String> createSurvey(AMCLclsSurvey survey) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso2_surveys')
        .add(survey.toMap());
    return docRef.id;
  }

  // Obtener todas las encuestas
  Stream<List<AMCLclsSurvey>> getAllSurveys() {
    return _firestore
        .collection('amcl_caso2_surveys')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsSurvey.fromFirestore(doc))
            .toList());
  }

  // Obtener encuestas activas
  Stream<List<AMCLclsSurvey>> getActiveSurveys() {
    return _firestore
        .collection('amcl_caso2_surveys')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsSurvey.fromFirestore(doc))
            .toList());
  }

  // Obtener encuestas asignadas a un usuario
  Stream<List<AMCLclsSurvey>> getAssignedSurveys(String userId) {
    return _firestore
        .collection('amcl_caso2_surveys')
        .where('isActive', isEqualTo: true)
        .where('assignedTo', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsSurvey.fromFirestore(doc))
            .toList());
  }

  // Asignar usuarios a una encuesta
  Future<void> assignUsersToSurvey(String surveyId, List<String> userIds) async {
    await updateSurvey(surveyId, {'assignedTo': userIds});
  }

  // Obtener todos los usuarios encuestadores
  Future<List<Map<String, dynamic>>> getSurveyors() async {
    QuerySnapshot snapshot = await _firestore
        .collection('amcl_caso2_users')
        .where('role', isEqualTo: 'surveyor')
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'name': data['name'] ?? '',
        'email': data['email'] ?? '',
      };
    }).toList();
  }

  // Obtener encuesta por ID
  Future<AMCLclsSurvey?> getSurveyById(String surveyId) async {
    DocumentSnapshot doc = await _firestore
        .collection('amcl_caso2_surveys')
        .doc(surveyId)
        .get();
    
    if (doc.exists) {
      return AMCLclsSurvey.fromFirestore(doc);
    }
    return null;
  }

  // Actualizar encuesta
  Future<void> updateSurvey(String surveyId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestore
        .collection('amcl_caso2_surveys')
        .doc(surveyId)
        .update(updates);
  }

  // Eliminar encuesta y todo su contenido
  Future<void> deleteSurvey(String surveyId) async {
    // Eliminar preguntas
    QuerySnapshot questions = await _firestore
        .collection('amcl_caso2_questions')
        .where('surveyId', isEqualTo: surveyId)
        .get();
    
    for (var question in questions.docs) {
      await question.reference.delete();
    }

    // Eliminar respuestas
    QuerySnapshot responses = await _firestore
        .collection('amcl_caso2_responses')
        .where('surveyId', isEqualTo: surveyId)
        .get();
    
    for (var response in responses.docs) {
      await response.reference.delete();
    }

    // Eliminar encuesta
    await _firestore.collection('amcl_caso2_surveys').doc(surveyId).delete();
  }

  // ==================== QUESTIONS ====================
  
  // Crear pregunta
  Future<String> createQuestion(AMCLclsQuestion question) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso2_questions')
        .add(question.toMap());
    return docRef.id;
  }

  // Obtener preguntas de una encuesta
  Stream<List<AMCLclsQuestion>> getSurveyQuestions(String surveyId) {
    return _firestore
        .collection('amcl_caso2_questions')
        .where('surveyId', isEqualTo: surveyId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsQuestion.fromFirestore(doc))
            .toList());
  }

  // Actualizar pregunta
  Future<void> updateQuestion(String questionId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('amcl_caso2_questions')
        .doc(questionId)
        .update(updates);
  }

  // Eliminar pregunta
  Future<void> deleteQuestion(String questionId) async {
    await _firestore.collection('amcl_caso2_questions').doc(questionId).delete();
  }

  // Obtener preguntas de una encuesta (Future para operaciones únicas)
  Future<List<AMCLclsQuestion>> getSurveyQuestionsOnce(String surveyId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('amcl_caso2_questions')
        .where('surveyId', isEqualTo: surveyId)
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => AMCLclsQuestion.fromFirestore(doc))
        .toList();
  }

  // ==================== RESPONSES ====================
  
  // Crear respuesta
  Future<String> createResponse(AMCLclsResponse response) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso2_responses')
        .add(response.toMap());
    return docRef.id;
  }

  // Obtener respuestas de una encuesta
  Stream<List<AMCLclsResponse>> getSurveyResponses(String surveyId) {
    return _firestore
        .collection('amcl_caso2_responses')
        .where('surveyId', isEqualTo: surveyId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsResponse.fromFirestore(doc))
            .toList());
  }

  // Obtener respuestas de un usuario
  Stream<List<AMCLclsResponse>> getUserResponses(String userId) {
    return _firestore
        .collection('amcl_caso2_responses')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsResponse.fromFirestore(doc))
            .toList());
  }

  // Contar respuestas de una encuesta
  Future<int> countSurveyResponses(String surveyId) async {
    QuerySnapshot snapshot = await _firestore
        .collection('amcl_caso2_responses')
        .where('surveyId', isEqualTo: surveyId)
        .get();
    return snapshot.docs.length;
  }

  // Eliminar respuesta
  Future<void> deleteResponse(String responseId) async {
    await _firestore.collection('amcl_caso2_responses').doc(responseId).delete();
  }

  // ==================== REPORTES Y ESTADÍSTICAS ====================
  
  // Obtener estadísticas completas de una encuesta
  Future<AMCLclsSurveyStats> getSurveyStatistics(String surveyId) async {
    // Obtener todas las respuestas
    QuerySnapshot responsesSnapshot = await _firestore
        .collection('amcl_caso2_responses')
        .where('surveyId', isEqualTo: surveyId)
        .orderBy('completedAt')
        .get();
    
    List<AMCLclsResponse> responses = responsesSnapshot.docs
        .map((doc) => AMCLclsResponse.fromFirestore(doc))
        .toList();
    
    // Obtener todas las preguntas
    QuerySnapshot questionsSnapshot = await _firestore
        .collection('amcl_caso2_questions')
        .where('surveyId', isEqualTo: surveyId)
        .orderBy('order')
        .get();
    
    List<AMCLclsQuestion> questions = questionsSnapshot.docs
        .map((doc) => AMCLclsQuestion.fromFirestore(doc))
        .toList();
    
    // Calcular estadísticas por pregunta
    Map<String, dynamic> questionStats = {};
    for (var question in questions) {
      questionStats[question.id!] = _calculateQuestionStats(question, responses);
    }
    
    // Calcular respuestas por fecha
    List<Map<String, dynamic>> responsesByDate = _groupResponsesByDate(responses);
    
    // Calcular tiempo promedio de completación (simulado por ahora)
    double avgTime = responses.isNotEmpty ? 5.0 : 0.0;
    
    return AMCLclsSurveyStats(
      totalResponses: responses.length,
      totalQuestions: questions.length,
      questionStats: questionStats,
      responsesByDate: responsesByDate,
      averageCompletionTime: avgTime,
    );
  }
  
  // Calcular estadísticas de una pregunta específica
  AMCLclsQuestionStats _calculateQuestionStats(
    AMCLclsQuestion question,
    List<AMCLclsResponse> responses,
  ) {
    int totalAnswers = 0;
    Map<String, int>? optionCounts;
    double? averageRating;
    List<String>? openEndedAnswers;
    
    // Obtener todas las respuestas a esta pregunta
    List<dynamic> answers = [];
    for (var response in responses) {
      if (response.answers.containsKey(question.id)) {
        answers.add(response.answers[question.id]);
        totalAnswers++;
      }
    }
    
    // Procesar según el tipo de pregunta
    switch (question.type) {
      case AMCLQuestionType.multipleChoice:
        optionCounts = {};
        for (var option in question.options) {
          optionCounts[option] = 0;
        }
        for (var answer in answers) {
          if (answer is String && optionCounts.containsKey(answer)) {
            optionCounts[answer] = optionCounts[answer]! + 1;
          }
        }
        break;
        
      case AMCLQuestionType.rating:
        if (answers.isNotEmpty) {
          double sum = 0;
          for (var answer in answers) {
            if (answer is int) {
              sum += answer;
            }
          }
          averageRating = sum / answers.length;
        }
        break;
        
      case AMCLQuestionType.openEnded:
        openEndedAnswers = answers
            .where((a) => a is String && a.isNotEmpty)
            .map((a) => a.toString())
            .toList();
        break;
    }
    
    return AMCLclsQuestionStats(
      questionId: question.id!,
      questionText: question.question,
      questionType: question.type.name,
      totalAnswers: totalAnswers,
      optionCounts: optionCounts,
      averageRating: averageRating,
      openEndedAnswers: openEndedAnswers,
    );
  }
  
  // Agrupar respuestas por fecha
  List<Map<String, dynamic>> _groupResponsesByDate(List<AMCLclsResponse> responses) {
    Map<String, int> dateGroups = {};
    
    for (var response in responses) {
      String dateKey = _formatDate(response.completedAt);
      dateGroups[dateKey] = (dateGroups[dateKey] ?? 0) + 1;
    }
    
    List<Map<String, dynamic>> result = [];
    dateGroups.forEach((date, count) {
      result.add({'date': date, 'count': count});
    });
    
    return result;
  }
  
  // Formatear fecha a string
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
  
  // ==================== DASHBOARD METRICS (REAL-TIME) ====================
  
  // Stream de métricas del dashboard
  Stream<AMCLclsDashboardMetrics> getDashboardMetrics() async* {
    // Combinar múltiples streams
    await for (var _ in Stream.periodic(const Duration(seconds: 2))) {
      AMCLclsDashboardMetrics metrics = await _fetchDashboardMetrics();
      yield metrics;
    }
  }
  
  // Obtener métricas actuales
  Future<AMCLclsDashboardMetrics> _fetchDashboardMetrics() async {
    try {
      // Total de encuestas
      QuerySnapshot surveysSnapshot = await _firestore
          .collection('amcl_caso2_surveys')
          .get();
      
      int totalSurveys = surveysSnapshot.docs.length;
      int activeSurveys = surveysSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == true)
          .length;
      
      Map<String, String> surveyTitles = {};
      for (var doc in surveysSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        surveyTitles[doc.id] = data['title'] ?? '';
      }
      
      // Total de respuestas
      QuerySnapshot responsesSnapshot = await _firestore
          .collection('amcl_caso2_responses')
          .get();
      
      int totalResponses = responsesSnapshot.docs.length;
      
      // Respuestas por encuesta
      Map<String, int> responsesBySurvey = {};
      for (var doc in responsesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String surveyId = data['surveyId'] ?? '';
        responsesBySurvey[surveyId] = (responsesBySurvey[surveyId] ?? 0) + 1;
      }
      
      // Total de usuarios
      QuerySnapshot usersSnapshot = await _firestore
          .collection('amcl_caso2_users')
          .get();
      
      int totalUsers = usersSnapshot.docs.length;
      int surveyors = usersSnapshot.docs
          .where((doc) => (doc.data() as Map<String, dynamic>)['role'] == 'surveyor')
          .length;
      
      // Respuestas recientes (últimas 5)
      QuerySnapshot recentResponsesSnapshot = await _firestore
          .collection('amcl_caso2_responses')
          .orderBy('completedAt', descending: true)
          .limit(5)
          .get();
      
      List<Map<String, dynamic>> recentResponses = recentResponsesSnapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'surveyId': data['surveyId'],
          'respondentName': data['respondentName'],
          'completedAt': (data['completedAt'] as Timestamp).toDate(),
        };
      }).toList();
      
      // Respuestas por día (últimos 7 días)
      DateTime now = DateTime.now();
      DateTime weekAgo = now.subtract(const Duration(days: 7));
      
      QuerySnapshot timeRangeSnapshot = await _firestore
          .collection('amcl_caso2_responses')
          .where('completedAt', isGreaterThan: weekAgo)
          .get();
      
      Map<String, int> responsesPerDay = {};
      for (int i = 0; i < 7; i++) {
        DateTime day = now.subtract(Duration(days: i));
        String dateKey = _formatDate(day);
        responsesPerDay[dateKey] = 0;
      }
      
      for (var doc in timeRangeSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        DateTime completedAt = (data['completedAt'] as Timestamp).toDate();
        String dateKey = _formatDate(completedAt);
        if (responsesPerDay.containsKey(dateKey)) {
          responsesPerDay[dateKey] = responsesPerDay[dateKey]! + 1;
        }
      }
      
      List<Map<String, dynamic>> responsesOverTime = responsesPerDay.entries.map((e) {
        return {'date': e.key, 'count': e.value};
      }).toList();
      
      return AMCLclsDashboardMetrics(
        totalSurveys: totalSurveys,
        activeSurveys: activeSurveys,
        totalResponses: totalResponses,
        totalUsers: totalUsers,
        surveyors: surveyors,
        responsesBySurvey: responsesBySurvey,
        surveyTitles: surveyTitles,
        recentResponses: recentResponses,
        responsesOverTime: responsesOverTime,
      );
    } catch (e) {
      return AMCLclsDashboardMetrics(
        totalSurveys: 0,
        activeSurveys: 0,
        totalResponses: 0,
        totalUsers: 0,
        surveyors: 0,
        responsesBySurvey: {},
        surveyTitles: {},
        recentResponses: [],
        responsesOverTime: [],
      );
    }
  }
  
  // Obtener ubicaciones de respuestas para mapa
  Future<List<AMCLclsLocationData>> getResponseLocations() async {
    try {
      // Consulta sin orderBy para evitar necesidad de índice compuesto
      QuerySnapshot responsesSnapshot = await _firestore
          .collection('amcl_caso2_responses')
          .limit(100)
          .get();
      
      List<AMCLclsLocationData> locations = [];
      
      for (var doc in responsesSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String? locationStr = data['location'];
        
        // Solo procesar respuestas con ubicación válida
        if (locationStr != null && locationStr.isNotEmpty && locationStr != 'N/A') {
          // Intentar extraer coordenadas del string
          double? lat;
          double? lng;
          
          // Si el formato es "lat, lng" o contiene coordenadas
          RegExp coordsPattern = RegExp(r'(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)');
          var match = coordsPattern.firstMatch(locationStr);
          
          if (match != null) {
            lat = double.tryParse(match.group(1) ?? '');
            lng = double.tryParse(match.group(2) ?? '');
          }
          
          // Obtener título de la encuesta
          String surveyId = data['surveyId'] ?? '';
          String surveyTitle = 'Encuesta';
          
          try {
            DocumentSnapshot surveyDoc = await _firestore
                .collection('amcl_caso2_surveys')
                .doc(surveyId)
                .get();
            if (surveyDoc.exists) {
              surveyTitle = (surveyDoc.data() as Map<String, dynamic>)['title'] ?? 'Encuesta';
            }
          } catch (e) {
            // Ignorar error al obtener título
          }
          
          locations.add(AMCLclsLocationData(
            surveyTitle: surveyTitle,
            respondentName: data['respondentName'] ?? '',
            latitude: lat,
            longitude: lng,
            address: locationStr,
            completedAt: (data['completedAt'] as Timestamp).toDate(),
          ));
        }
      }
      
      // Ordenar por fecha en memoria (más recientes primero)
      locations.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      
      return locations;
    } catch (e) {
      return [];
    }
  }
}
