import 'package:cloud_firestore/cloud_firestore.dart';

class AMCLclsCourse {
  final String id;
  final String title;
  final String description;
  final String category;
  final String ownerId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AMCLclsCourse({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.ownerId,
    required this.createdAt,
    this.updatedAt,
  });

  // Convertir desde Firestore
  factory AMCLclsCourse.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsCourse(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // CopyWith para actualizaciones inmutables
  AMCLclsCourse copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AMCLclsCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
