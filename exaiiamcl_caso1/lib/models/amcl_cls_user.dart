import 'package:cloud_firestore/cloud_firestore.dart';

class AMCLclsUser {
  final String id;
  final String email;
  final String name;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;

  AMCLclsUser({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
    required this.createdAt,
    this.lastLogin,
  });

  // Convertir desde Firestore
  factory AMCLclsUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsUser(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLogin: data['lastLogin'] != null 
          ? (data['lastLogin'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  // CopyWith para actualizaciones inmutables
  AMCLclsUser copyWith({
    String? id,
    String? email,
    String? name,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return AMCLclsUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}
