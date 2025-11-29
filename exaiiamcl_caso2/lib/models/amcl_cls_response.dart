import 'package:cloud_firestore/cloud_firestore.dart';

class AMCLclsResponse {
  final String id;
  final String surveyId;
  final String userId; // encuestador que aplicó la encuesta
  final String respondentName; // nombre del encuestado
  final String? respondentEmail; // opcional
  final Map<String, dynamic> answers; // questionId -> respuesta
  final DateTime completedAt;
  final String? location; // ubicación opcional

  AMCLclsResponse({
    required this.id,
    required this.surveyId,
    required this.userId,
    required this.respondentName,
    this.respondentEmail,
    required this.answers,
    required this.completedAt,
    this.location,
  });

  // Convertir desde Firestore
  factory AMCLclsResponse.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsResponse(
      id: doc.id,
      surveyId: data['surveyId'] ?? '',
      userId: data['userId'] ?? '',
      respondentName: data['respondentName'] ?? '',
      respondentEmail: data['respondentEmail'],
      answers: Map<String, dynamic>.from(data['answers'] ?? {}),
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      location: data['location'],
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'surveyId': surveyId,
      'userId': userId,
      'respondentName': respondentName,
      'respondentEmail': respondentEmail,
      'answers': answers,
      'completedAt': Timestamp.fromDate(completedAt),
      'location': location,
    };
  }

  // CopyWith
  AMCLclsResponse copyWith({
    String? id,
    String? surveyId,
    String? userId,
    String? respondentName,
    String? respondentEmail,
    Map<String, dynamic>? answers,
    DateTime? completedAt,
    String? location,
  }) {
    return AMCLclsResponse(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      userId: userId ?? this.userId,
      respondentName: respondentName ?? this.respondentName,
      respondentEmail: respondentEmail ?? this.respondentEmail,
      answers: answers ?? this.answers,
      completedAt: completedAt ?? this.completedAt,
      location: location ?? this.location,
    );
  }
}
