import 'package:cloud_firestore/cloud_firestore.dart';

enum AMCLMaterialType { pdf, video }

class AMCLclsMaterial {
  final String id;
  final String unitId;
  final String title;
  final String description;
  final AMCLMaterialType type;
  final String fileUrl;
  final String fileName;
  final int fileSize;
  final DateTime uploadedAt;

  AMCLclsMaterial({
    required this.id,
    required this.unitId,
    required this.title,
    required this.description,
    required this.type,
    required this.fileUrl,
    required this.fileName,
    required this.fileSize,
    required this.uploadedAt,
  });

  // Convertir desde Firestore
  factory AMCLclsMaterial.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AMCLclsMaterial(
      id: doc.id,
      unitId: data['unitId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] == 'pdf' ? AMCLMaterialType.pdf : AMCLMaterialType.video,
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'] ?? '',
      fileSize: data['fileSize'] ?? 0,
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'unitId': unitId,
      'title': title,
      'description': description,
      'type': type == AMCLMaterialType.pdf ? 'pdf' : 'video',
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  // CopyWith para actualizaciones inmutables
  AMCLclsMaterial copyWith({
    String? id,
    String? unitId,
    String? title,
    String? description,
    AMCLMaterialType? type,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DateTime? uploadedAt,
  }) {
    return AMCLclsMaterial(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
