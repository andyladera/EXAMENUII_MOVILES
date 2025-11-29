import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/amcl_cls_survey.dart';
import '../models/amcl_cls_question.dart';
import '../models/amcl_cls_response.dart';
import '../models/amcl_cls_survey_stats.dart';
import '../models/amcl_cls_user.dart';

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
}
