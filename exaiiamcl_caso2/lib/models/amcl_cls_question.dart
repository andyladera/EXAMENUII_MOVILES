import 'package:cloud_firestore/cloud_firestore.dart';

enum AMCLQuestionType {
  multipleChoice, // Opción múltiple
  openEnded, // Respuesta abierta
  rating, // Calificación (1-5 estrellas)
}

class AMCLclsQuestion {
  final String id;
  final String surveyId;
  final String question;
  final AMCLQuestionType type;
  final List<String> options; // Para multiple choice
  final int order;
  final bool isRequired;

  AMCLclsQuestion({
    required this.id,
    required this.surveyId,
    required this.question,
    required this.type,
    this.options = const [],
    required this.order,
    this.isRequired = true,
  });

  // Convertir desde Firestore
  factory AMCLclsQuestion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsQuestion(
      id: doc.id,
      surveyId: data['surveyId'] ?? '',
      question: data['question'] ?? '',
      type: AMCLQuestionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AMCLQuestionType.openEnded,
      ),
      options: List<String>.from(data['options'] ?? []),
      order: data['order'] ?? 0,
      isRequired: data['isRequired'] ?? true,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'surveyId': surveyId,
      'question': question,
      'type': type.name,
      'options': options,
      'order': order,
      'isRequired': isRequired,
    };
  }

  // CopyWith
  AMCLclsQuestion copyWith({
    String? id,
    String? surveyId,
    String? question,
    AMCLQuestionType? type,
    List<String>? options,
    int? order,
    bool? isRequired,
  }) {
    return AMCLclsQuestion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      question: question ?? this.question,
      type: type ?? this.type,
      options: options ?? this.options,
      order: order ?? this.order,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}
