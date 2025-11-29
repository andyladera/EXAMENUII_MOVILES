import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/amcl_cls_auth_service.dart';
import '../services/amcl_cls_firestore_service.dart';
import '../models/amcl_cls_user.dart';
import '../models/amcl_cls_survey.dart';
import 'amcl_cls_create_survey_screen.dart';
import 'amcl_cls_apply_survey_screen.dart';
import 'amcl_cls_survey_responses_screen.dart';
import 'amcl_cls_assign_survey_screen.dart';
import 'amcl_cls_survey_report_screen.dart';

class AMCLclsHomeScreen extends StatefulWidget {
  const AMCLclsHomeScreen({super.key});

  @override
  State<AMCLclsHomeScreen> createState() => _AMCLclsHomeScreenState();
}

class _AMCLclsHomeScreenState extends State<AMCLclsHomeScreen> {
  final _authService = AMCLclsAuthService();

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: Usuario no autenticado')),
      );
    }

    return StreamBuilder<AMCLclsUser?>(
      stream: _authService.getUserDataStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Error al cargar usuario')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('SurveyApp'),
            backgroundColor: user.isAdmin ? Colors.purple.shade700 : Colors.blue.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.person),
                onPressed: () {
                  _showProfileDialog(context, user);
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  await _authService.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/welcome');
                },
              ),
            ],
          ),
          body: user.isAdmin 
              ? _AdminView(userId: userId)
              : _SurveyorView(userId: userId),
          floatingActionButton: user.isAdmin
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/create-survey',
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                  backgroundColor: Colors.purple.shade700,
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Encuesta'),
                )
              : null,
        );
      },
    );
  }

  void _showProfileDialog(BuildContext context, AMCLclsUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mi Perfil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileItem(icon: Icons.person, label: 'Nombre', value: user.name),
            const SizedBox(height: 12),
            _ProfileItem(icon: Icons.email, label: 'Email', value: user.email),
            const SizedBox(height: 12),
            _ProfileItem(
              icon: user.isAdmin ? Icons.admin_panel_settings : Icons.assignment_ind,
              label: 'Rol',
              value: user.isAdmin ? 'Administrador' : 'Encuestador',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminView extends StatelessWidget {
  final String userId;

  const _AdminView({required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();

    return StreamBuilder<List<AMCLclsSurvey>>(
      stream: firestoreService.getAllSurveys(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.poll_outlined, size: 100, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No hay encuestas',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tu primera encuesta',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        final surveys = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: surveys.length,
          itemBuilder: (context, index) {
            final survey = surveys[index];
            return StreamBuilder<int>(
              stream: firestoreService.getSurveyResponses(survey.id).map((responses) => responses.length),
              builder: (context, responseSnapshot) {
                final responseCount = responseSnapshot.data ?? 0;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Stack(
                      children: [
                        CircleAvatar(
                          backgroundColor: survey.isActive 
                              ? Colors.green.shade100 
                              : Colors.grey.shade300,
                          child: Icon(
                            Icons.poll,
                            color: survey.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        if (responseCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Text(
                                '$responseCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      survey.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(survey.description),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              survey.isActive ? 'Activa' : 'Inactiva',
                              style: TextStyle(
                                fontSize: 12,
                                color: survey.isActive ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person_add, size: 12, color: Colors.orange.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${survey.assignedTo.length} asignado${survey.assignedTo.length != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (responseCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people, size: 12, color: Colors.blue.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$responseCount respuesta${responseCount != 1 ? 's' : ''}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                    if (value == 'responses') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AMCLSurveyResponsesScreen(survey: survey),
                        ),
                      );
                    } else if (value == 'report') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AMCLclsSurveyReportScreen(survey: survey),
                        ),
                      );
                    } else if (value == 'assign') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AMCLclsAssignSurveyScreen(survey: survey),
                        ),
                      );
                    } else if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AMCLCreateSurveyScreen(survey: survey),
                        ),
                      );
                      if (result == true) {
                        // La lista se actualiza automáticamente por el Stream
                      }
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, firestoreService, survey);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'responses',
                      child: Row(
                        children: [
                          Icon(Icons.format_list_bulleted, size: 20),
                          SizedBox(width: 8),
                          Text('Ver Respuestas'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart, size: 20, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Ver Reporte'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, size: 20),
                          SizedBox(width: 8),
                          Text('Asignar Encuestadores'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AMCLSurveyResponsesScreen(survey: survey),
                    ),
                  );
                },
              ),
            );
              },
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, AMCLclsFirestoreService service, AMCLclsSurvey survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar encuesta'),
        content: Text('¿Estás seguro de eliminar "${survey.title}"? Esta acción eliminará todas las preguntas y respuestas asociadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await service.deleteSurvey(survey.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Encuesta eliminada')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

class _SurveyorView extends StatelessWidget {
  final String userId;

  const _SurveyorView({required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();

    return StreamBuilder<List<AMCLclsSurvey>>(
      stream: firestoreService.getAssignedSurveys(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 100, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No tienes encuestas asignadas',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Espera a que un administrador te asigne encuestas',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final surveys = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: surveys.length,
          itemBuilder: (context, index) {
            final survey = surveys[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.poll, color: Colors.blue),
                ),
                title: Text(
                  survey.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(survey.description),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AMCLApplySurveyScreen(survey: survey),
                      ),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Encuesta aplicada exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
