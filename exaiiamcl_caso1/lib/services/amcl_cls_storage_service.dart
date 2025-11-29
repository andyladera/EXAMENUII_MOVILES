import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class AMCLclsStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Subir PDF
  Future<Map<String, dynamic>> uploadPDF({
    required String unitId,
    required File file,
    required String fileName,
  }) async {
    try {
      String path = 'caso1/materials/pdfs/$unitId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'application/pdf'),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      int fileSize = await file.length();

      return {
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'path': path,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Subir Video
  Future<Map<String, dynamic>> uploadVideo({
    required String unitId,
    required File file,
    required String fileName,
  }) async {
    try {
      String path = 'caso1/materials/videos/$unitId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      int fileSize = await file.length();

      return {
        'fileUrl': downloadUrl,
        'fileName': fileName,
        'fileSize': fileSize,
        'path': path,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Eliminar archivo
  Future<void> deleteFile(String fileUrl) async {
    try {
      Reference ref = _storage.refFromURL(fileUrl);
      await ref.delete();
    } catch (e) {
      rethrow;
    }
  }

  // Seleccionar PDF usando FilePicker
  Future<File?> pickPDF() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Seleccionar video usando FilePicker
  Future<File?> pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Obtener nombre de archivo desde FilePicker
  String? getFileName(FilePickerResult? result) {
    if (result != null && result.files.isNotEmpty) {
      return result.files.single.name;
    }
    return null;
  }

  // Formatear tamaño de archivo
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
