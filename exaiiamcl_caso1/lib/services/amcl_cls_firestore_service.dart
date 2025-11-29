import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/amcl_cls_course.dart';
import '../models/amcl_cls_unit.dart';
import '../models/amcl_cls_material.dart';
import '../models/amcl_cls_question.dart';
import '../models/amcl_cls_evaluation.dart';
import '../models/amcl_cls_result.dart';

class AMCLclsFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== COURSES ====================
  
  // Crear curso
  Future<String> createCourse(AMCLclsCourse course) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso1_courses')
        .add(course.toMap());
    return docRef.id;
  }

  // Obtener cursos del usuario
  Stream<List<AMCLclsCourse>> getUserCourses(String userId) {
    return _firestore
        .collection('amcl_caso1_courses')
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsCourse.fromFirestore(doc))
            .toList());
  }

  // Obtener curso por ID
  Future<AMCLclsCourse?> getCourseById(String courseId) async {
    DocumentSnapshot doc = await _firestore
        .collection('amcl_caso1_courses')
        .doc(courseId)
        .get();
    
    if (doc.exists) {
      return AMCLclsCourse.fromFirestore(doc);
    }
    return null;
  }

  // Actualizar curso
  Future<void> updateCourse(String courseId, Map<String, dynamic> updates) async {
    updates['updatedAt'] = Timestamp.now();
    await _firestore
        .collection('amcl_caso1_courses')
        .doc(courseId)
        .update(updates);
  }

  // Eliminar curso (y todo su contenido)
  Future<void> deleteCourse(String courseId) async {
    // Eliminar unidades asociadas
    QuerySnapshot units = await _firestore
        .collection('amcl_caso1_units')
        .where('courseId', isEqualTo: courseId)
        .get();
    
    for (var unit in units.docs) {
      await deleteUnit(unit.id);
    }

    // Eliminar curso
    await _firestore.collection('amcl_caso1_courses').doc(courseId).delete();
  }

  // ==================== UNITS ====================
  
  // Crear unidad
  Future<String> createUnit(AMCLclsUnit unit) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso1_units')
        .add(unit.toMap());
    return docRef.id;
  }

  // Obtener unidades de un curso
  Stream<List<AMCLclsUnit>> getCourseUnits(String courseId) {
    return _firestore
        .collection('amcl_caso1_units')
        .where('courseId', isEqualTo: courseId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsUnit.fromFirestore(doc))
            .toList());
  }

  // Alias para mantener compatibilidad
  Stream<List<AMCLclsUnit>> getUnitsStream(String courseId) {
    return getCourseUnits(courseId);
  }

  // Obtener unidad por ID
  Future<AMCLclsUnit?> getUnitById(String courseId, String unitId) async {
    DocumentSnapshot doc = await _firestore
        .collection('amcl_caso1_units')
        .doc(unitId)
        .get();
    
    if (doc.exists) {
      return AMCLclsUnit.fromFirestore(doc);
    }
    return null;
  }

  // Actualizar unidad
  Future<void> updateUnit(String unitId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('amcl_caso1_units')
        .doc(unitId)
        .update(updates);
  }

  // Eliminar unidad (y todo su contenido)
  Future<void> deleteUnit(String unitId) async {
    // Eliminar materiales asociados
    QuerySnapshot materials = await _firestore
        .collection('amcl_caso1_materials')
        .where('unitId', isEqualTo: unitId)
        .get();
    
    for (var material in materials.docs) {
      await _firestore.collection('amcl_caso1_materials').doc(material.id).delete();
    }

    // Eliminar preguntas asociadas
    QuerySnapshot questions = await _firestore
        .collection('amcl_caso1_questions')
        .where('unitId', isEqualTo: unitId)
        .get();
    
    for (var question in questions.docs) {
      await _firestore.collection('amcl_caso1_questions').doc(question.id).delete();
    }

    // Eliminar unidad
    await _firestore.collection('amcl_caso1_units').doc(unitId).delete();
  }

  // ==================== MATERIALS ====================
  
  // Crear material
  Future<String> createMaterial(AMCLclsMaterial material) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso1_materials')
        .add(material.toMap());
    return docRef.id;
  }

  // Obtener materiales de una unidad
  Stream<List<AMCLclsMaterial>> getUnitMaterials(String unitId) {
    return _firestore
        .collection('amcl_caso1_materials')
        .where('unitId', isEqualTo: unitId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsMaterial.fromFirestore(doc))
            .toList());
  }

  // Eliminar material
  Future<void> deleteMaterial(String materialId) async {
    await _firestore.collection('amcl_caso1_materials').doc(materialId).delete();
  }

  // ==================== QUESTIONS ====================
  
  // Crear pregunta
  Future<String> createQuestion(AMCLclsQuestion question) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso1_questions')
        .add(question.toMap());
    return docRef.id;
  }

  // Obtener preguntas de una unidad
  Stream<List<AMCLclsQuestion>> getUnitQuestions(String unitId) {
    return _firestore
        .collection('amcl_caso1_questions')
        .where('unitId', isEqualTo: unitId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsQuestion.fromFirestore(doc))
            .toList());
  }

  // Alias para compatibilidad
  Stream<List<AMCLclsQuestion>> getQuestionsByUnit(String courseId, String unitId) {
    return getUnitQuestions(unitId);
  }

  // Obtener preguntas aleatorias para evaluación
  Future<List<AMCLclsQuestion>> getRandomQuestions(String unitId, int count) async {
    QuerySnapshot snapshot = await _firestore
        .collection('amcl_caso1_questions')
        .where('unitId', isEqualTo: unitId)
        .get();
    
    List<AMCLclsQuestion> questions = snapshot.docs
        .map((doc) => AMCLclsQuestion.fromFirestore(doc))
        .toList();
    
    questions.shuffle();
    return questions.take(count).toList();
  }

  // Actualizar pregunta
  Future<void> updateQuestion(String questionId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('amcl_caso1_questions')
        .doc(questionId)
        .update(updates);
  }

  // Eliminar pregunta
  Future<void> deleteQuestion(String questionId) async {
    await _firestore.collection('amcl_caso1_questions').doc(questionId).delete();
  }

  // ==================== EVALUATIONS ====================
  
  // Crear evaluación
  Future<String> createEvaluation(AMCLclsEvaluation evaluation) async {
    DocumentReference docRef = await _firestore
        .collection('amcl_caso1_evaluations')
        .add(evaluation.toMap());
    return docRef.id;
  }

  // Actualizar evaluación
  Future<void> updateEvaluation(String evaluationId, Map<String, dynamic> updates) async {
    await _firestore
        .collection('amcl_caso1_evaluations')
        .doc(evaluationId)
        .update(updates);
  }

  // Obtener evaluaciones de un usuario
  Stream<List<AMCLclsEvaluation>> getUserEvaluations(String userId) {
    return _firestore
        .collection('amcl_caso1_evaluations')
        .where('userId', isEqualTo: userId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsEvaluation.fromFirestore(doc))
            .toList());
  }

  // Obtener evaluaciones por curso
  Stream<List<AMCLclsEvaluation>> getCourseEvaluations(String userId, String courseId) {
    return _firestore
        .collection('amcl_caso1_evaluations')
        .where('userId', isEqualTo: userId)
        .where('courseId', isEqualTo: courseId)
        .orderBy('startedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsEvaluation.fromFirestore(doc))
            .toList());
  }

  // Alias para mantener compatibilidad
  Stream<List<AMCLclsEvaluation>> getEvaluationsByCourse(String courseId, String userId) {
    return getCourseEvaluations(userId, courseId);
  }

  // ==================== RESULTS ====================
  
  // Actualizar o crear resultados
  Future<void> updateResults(AMCLclsResult result) async {
    await _firestore
        .collection('amcl_caso1_results')
        .doc('${result.userId}_${result.courseId}')
        .set(result.toMap(), SetOptions(merge: true));
  }

  // Obtener resultados de un usuario por curso
  Future<AMCLclsResult?> getCourseResults(String userId, String courseId) async {
    DocumentSnapshot doc = await _firestore
        .collection('amcl_caso1_results')
        .doc('${userId}_$courseId')
        .get();
    
    if (doc.exists) {
      return AMCLclsResult.fromFirestore(doc);
    }
    return null;
  }

  // Obtener todos los resultados de un usuario
  Stream<List<AMCLclsResult>> getUserResults(String userId) {
    return _firestore
        .collection('amcl_caso1_results')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AMCLclsResult.fromFirestore(doc))
            .toList());
  }
}
