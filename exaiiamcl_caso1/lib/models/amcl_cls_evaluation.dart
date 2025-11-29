import 'package:cloud_firestore/cloud_firestore.dart';

class AMCLclsEvaluation {
  final String id;
  final String userId;
  final String unitId;
  final String courseId;
  final List<String> questionIds;
  final Map<String, String> userAnswers; // questionId -> answer
  final int score;
  final int totalQuestions;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? timeSpentSeconds;

  AMCLclsEvaluation({
    required this.id,
    required this.userId,
    required this.unitId,
    required this.courseId,
    required this.questionIds,
    required this.userAnswers,
    required this.score,
    required this.totalQuestions,
    required this.startedAt,
    this.completedAt,
    this.timeSpentSeconds,
  });

  // Convertir desde Firestore
  factory AMCLclsEvaluation.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsEvaluation(
      id: doc.id,
      userId: data['userId'] ?? '',
      unitId: data['unitId'] ?? '',
      courseId: data['courseId'] ?? '',
      questionIds: List<String>.from(data['questionIds'] ?? []),
      userAnswers: Map<String, String>.from(data['userAnswers'] ?? {}),
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
      timeSpentSeconds: data['timeSpentSeconds'],
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'unitId': unitId,
      'courseId': courseId,
      'questionIds': questionIds,
      'userAnswers': userAnswers,
      'score': score,
      'totalQuestions': totalQuestions,
      'startedAt': Timestamp.fromDate(startedAt),
      'completedAt': completedAt != null 
          ? Timestamp.fromDate(completedAt!) 
          : null,
      'timeSpentSeconds': timeSpentSeconds,
    };
  }

  // Calcular porcentaje
  double get percentage => totalQuestions > 0 
      ? (score / totalQuestions) * 100 
      : 0.0;

  // CopyWith para actualizaciones inmutables
  AMCLclsEvaluation copyWith({
    String? id,
    String? userId,
    String? unitId,
    String? courseId,
    List<String>? questionIds,
    Map<String, String>? userAnswers,
    int? score,
    int? totalQuestions,
    DateTime? startedAt,
    DateTime? completedAt,
    int? timeSpentSeconds,
  }) {
    return AMCLclsEvaluation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      unitId: unitId ?? this.unitId,
      courseId: courseId ?? this.courseId,
      questionIds: questionIds ?? this.questionIds,
      userAnswers: userAnswers ?? this.userAnswers,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
    );
  }
}
