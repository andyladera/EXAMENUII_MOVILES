import 'package:flutter/material.dart';
import '../services/amcl_cls_firestore_service.dart';
import '../models/amcl_cls_course.dart';
import 'amcl_cls_create_course_screen.dart';
import 'amcl_cls_units_screen.dart';
import 'amcl_cls_materials_screen.dart';
import 'amcl_cls_questions_screen.dart';
import 'amcl_cls_evaluations_screen.dart';

class AMCLclsCourseDetailScreen extends StatelessWidget {
  final String courseId;

  const AMCLclsCourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();

    return FutureBuilder<AMCLclsCourse?>(
      future: firestoreService.getCourseById(courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Cargando...'),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            body: const Center(
              child: Text('No se pudo cargar el curso'),
            ),
          );
        }

        final course = snapshot.data!;

        return Scaffold(
          appBar: AppBar(
            title: Text(course.title),
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            actions: [
              // Editar
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AMCLclsCreateCourseScreen(
                        course: course,
                      ),
                    ),
                  );
                },
              ),
              // Eliminar
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(context, course),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header del curso
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade700,
                        Colors.purple.shade700,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          course.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        course.description,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),

                // Secciones
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionCard(
                        icon: Icons.topic,
                        title: 'Unidades',
                        subtitle: 'Organiza tus temas de estudio',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AMCLclsUnitsScreen(
                                courseId: course.id,
                                courseTitle: course.title,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.folder,
                        title: 'Materiales',
                        subtitle: 'PDFs y videos de estudio',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AMCLclsMaterialsScreen(
                                courseId: course.id,
                                courseTitle: course.title,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.quiz,
                        title: 'Preguntas',
                        subtitle: 'Banco de preguntas para evaluaciones',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AMCLclsQuestionsScreen(
                                courseId: course.id,
                                courseTitle: course.title,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        icon: Icons.assignment,
                        title: 'Evaluaciones',
                        subtitle: 'Rendir y ver evaluaciones',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AMCLclsEvaluationsScreen(
                                courseId: course.id,
                                courseTitle: course.title,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, AMCLclsCourse course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Curso'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${course.title}"?\n\n'
          'Esta acción eliminará también todas las unidades, materiales, '
          'preguntas y evaluaciones asociadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              
              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final firestoreService = AMCLclsFirestoreService();
                await firestoreService.deleteCourse(course.id);
                
                if (!context.mounted) return;
                
                Navigator.pop(context); // Cerrar loading
                Navigator.pop(context); // Volver a home
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Curso eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                
                Navigator.pop(context); // Cerrar loading
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: ${e.toString()}'),
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

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade700,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
