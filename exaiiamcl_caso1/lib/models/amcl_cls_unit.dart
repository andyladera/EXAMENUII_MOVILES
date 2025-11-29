import 'package:cloud_firestore/cloud_firestore.dart';

class AMCLclsUnit {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final int order;
  final DateTime createdAt;

  AMCLclsUnit({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.order,
    required this.createdAt,
  });

  // Convertir desde Firestore
  factory AMCLclsUnit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsUnit(
      id: doc.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // CopyWith para actualizaciones inmutables
  AMCLclsUnit copyWith({
    String? id,
    String? courseId,
    String? title,
    String? description,
    int? order,
    DateTime? createdAt,
  }) {
    return AMCLclsUnit(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
