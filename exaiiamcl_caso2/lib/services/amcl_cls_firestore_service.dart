import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/amcl_cls_survey.dart';
import '../models/amcl_cls_question.dart';
import '../models/amcl_cls_response.dart';

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
}
