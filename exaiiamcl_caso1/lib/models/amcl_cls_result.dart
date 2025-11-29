import 'package:cloud_firestore/cloud_firestore.dart';

class AMCLclsResult {
  final String id;
  final String userId;
  final String courseId;
  final int totalEvaluations;
  final double averageScore;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime lastEvaluationDate;
  final Map<String, int> scoresByUnit; // unitId -> score

  AMCLclsResult({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.totalEvaluations,
    required this.averageScore,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.lastEvaluationDate,
    required this.scoresByUnit,
  });

  // Convertir desde Firestore
  factory AMCLclsResult.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsResult(
      id: doc.id,
      userId: data['userId'] ?? '',
      courseId: data['courseId'] ?? '',
      totalEvaluations: data['totalEvaluations'] ?? 0,
      averageScore: (data['averageScore'] ?? 0).toDouble(),
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      lastEvaluationDate: (data['lastEvaluationDate'] as Timestamp).toDate(),
      scoresByUnit: Map<String, int>.from(data['scoresByUnit'] ?? {}),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'courseId': courseId,
      'totalEvaluations': totalEvaluations,
      'averageScore': averageScore,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'lastEvaluationDate': Timestamp.fromDate(lastEvaluationDate),
      'scoresByUnit': scoresByUnit,
    };
  }

  // Calcular porcentaje de respuestas correctas
  double get accuracyPercentage => totalQuestions > 0 
      ? (correctAnswers / totalQuestions) * 100 
      : 0.0;

  // CopyWith para actualizaciones inmutables
  AMCLclsResult copyWith({
    String? id,
    String? userId,
    String? courseId,
    int? totalEvaluations,
    double? averageScore,
    int? totalQuestions,
    int? correctAnswers,
    DateTime? lastEvaluationDate,
    Map<String, int>? scoresByUnit,
  }) {
    return AMCLclsResult(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      totalEvaluations: totalEvaluations ?? this.totalEvaluations,
      averageScore: averageScore ?? this.averageScore,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      lastEvaluationDate: lastEvaluationDate ?? this.lastEvaluationDate,
      scoresByUnit: scoresByUnit ?? this.scoresByUnit,
    );
  }
}
