import 'package:cloud_firestore/cloud_firestore.dart';

enum AMCLQuestionType { multipleChoice, trueFalse }

class AMCLclsQuestion {
  final String id;
  final String unitId;
  final String statement;
  final AMCLQuestionType type;
  final List<String> options;
  final String correctAnswer;
  final DateTime createdAt;

  AMCLclsQuestion({
    required this.id,
    required this.unitId,
    required this.statement,
    required this.type,
    required this.options,
    required this.correctAnswer,
    required this.createdAt,
  });

  // Convertir desde Firestore
  factory AMCLclsQuestion.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsQuestion(
      id: doc.id,
      unitId: data['unitId'] ?? '',
      statement: data['statement'] ?? '',
      type: data['type'] == 'multipleChoice' 
          ? AMCLQuestionType.multipleChoice 
          : AMCLQuestionType.trueFalse,
      options: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'unitId': unitId,
      'statement': statement,
      'type': type == AMCLQuestionType.multipleChoice 
          ? 'multipleChoice' 
          : 'trueFalse',
      'options': options,
      'correctAnswer': correctAnswer,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // CopyWith para actualizaciones inmutables
  AMCLclsQuestion copyWith({
    String? id,
    String? unitId,
    String? statement,
    AMCLQuestionType? type,
    List<String>? options,
    String? correctAnswer,
    DateTime? createdAt,
  }) {
    return AMCLclsQuestion(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      statement: statement ?? this.statement,
      type: type ?? this.type,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
