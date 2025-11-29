import 'dart:io';
import 'package:flutter/material.dart';
import '../services/amcl_cls_firestore_service.dart';
import '../services/amcl_cls_storage_service.dart';
import '../models/amcl_cls_material.dart';
import '../models/amcl_cls_unit.dart';
import 'package:url_launcher/url_launcher.dart';

class AMCLclsMaterialsScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const AMCLclsMaterialsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Materiales - $courseTitle'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<AMCLclsUnit>>(
        stream: firestoreService.getCourseUnits(courseId),
        builder: (context, unitsSnapshot) {
          if (unitsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final units = unitsSnapshot.data ?? [];

          if (units.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_outlined,
                    size: 100,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay unidades',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea unidades primero',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              return _UnitMaterialsCard(
                unit: unit,
                courseId: courseId,
              );
            },
          );
        },
      ),
    );
  }
}

class _UnitMaterialsCard extends StatelessWidget {
  final AMCLclsUnit unit;
  final String courseId;

  const _UnitMaterialsCard({
    required this.unit,
    required this.courseId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade700,
          child: Text(
            '${unit.order}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          unit.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          StreamBuilder<List<AMCLclsMaterial>>(
            stream: firestoreService.getUnitMaterials(unit.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final materials = snapshot.data ?? [];

              return Column(
                children: [
                  if (materials.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No hay materiales',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    ...materials.map((material) => ListTile(
                          leading: Icon(
                            material.type == AMCLMaterialType.pdf
                                ? Icons.picture_as_pdf
                                : Icons.video_library,
                            color: material.type == AMCLMaterialType.pdf
                                ? Colors.red
                                : Colors.purple,
                          ),
                          title: Text(material.title),
                          subtitle: Text(material.description),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'open',
                                child: Row(
                                  children: [
                                    Icon(Icons.open_in_new),
                                    SizedBox(width: 8),
                                    Text('Abrir'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Eliminar',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) async {
                              if (value == 'open') {
                                final uri = Uri.parse(material.fileUrl);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              } else if (value == 'delete') {
                                _showDeleteDialog(context, material);
                              }
                            },
                          ),
                        )),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _showUploadDialog(
                            context,
                            unit.id,
                            AMCLMaterialType.pdf,
                          ),
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Subir PDF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showUploadDialog(
                            context,
                            unit.id,
                            AMCLMaterialType.video,
                          ),
                          icon: const Icon(Icons.videocam),
                          label: const Text('Subir Video'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUploadDialog(
    BuildContext context,
    String unitId,
    AMCLMaterialType type,
  ) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    File? selectedFile;
    final storageService = AMCLclsStorageService();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Subir ${type == AMCLMaterialType.pdf ? 'PDF' : 'Video'}'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      File? file;
                      if (type == AMCLMaterialType.pdf) {
                        file = await storageService.pickPDF();
                      } else {
                        file = await storageService.pickVideo();
                      }

                      if (file != null) {
                        setState(() {
                          selectedFile = file;
                        });
                      }
                    },
                    icon: const Icon(Icons.attach_file),
                    label: Text(selectedFile == null
                        ? 'Seleccionar archivo'
                        : 'Archivo seleccionado'),
                  ),
                  if (selectedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        selectedFile!.path.split('/').last,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selecciona un archivo'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Mostrar loading
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  Map<String, dynamic> uploadResult;

                  if (type == AMCLMaterialType.pdf) {
                    uploadResult = await storageService.uploadPDF(
                      unitId: unitId,
                      file: selectedFile!,
                      fileName: selectedFile!.path.split('/').last,
                    );
                  } else {
                    uploadResult = await storageService.uploadVideo(
                      unitId: unitId,
                      file: selectedFile!,
                      fileName: selectedFile!.path.split('/').last,
                    );
                  }

                  final material = AMCLclsMaterial(
                    id: '',
                    unitId: unitId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    type: type,
                    fileUrl: uploadResult['fileUrl'],
                    fileName: uploadResult['fileName'],
                    fileSize: uploadResult['fileSize'],
                    uploadedAt: DateTime.now(),
                  );

                  final firestoreService = AMCLclsFirestoreService();
                  await firestoreService.createMaterial(material);

                  if (!context.mounted) return;
                  Navigator.pop(context); // Cerrar loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Material subido exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  Navigator.pop(context); // Cerrar loading

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Subir'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AMCLclsMaterial material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Material'),
        content: Text('¿Eliminar "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                final firestoreService = AMCLclsFirestoreService();
                final storageService = AMCLclsStorageService();

                // Eliminar archivo de Storage
                await storageService.deleteFile(material.fileUrl);

                // Eliminar documento de Firestore
                await firestoreService.deleteMaterial(material.id);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Material eliminado'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
