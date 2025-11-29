import 'package:cloud_firestore/cloud_firestore.dart';

class AMCLclsSurvey {
  final String id;
  final String title;
  final String description;
  final String createdBy; // userId del admin que lo creó
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final List<String> assignedTo; // Lista de userIds asignados

  AMCLclsSurvey({
    required this.id,
    required this.title,
    required this.description,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.assignedTo = const [],
  });

  // Convertir desde Firestore
  factory AMCLclsSurvey.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsSurvey(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      assignedTo: List<String>.from(data['assignedTo'] ?? []),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'assignedTo': assignedTo,
    };
  }

  // CopyWith
  AMCLclsSurvey copyWith({
    String? id,
    String? title,
    String? description,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? assignedTo,
  }) {
    return AMCLclsSurvey(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      assignedTo: assignedTo ?? this.assignedTo,
    );
  }
}
