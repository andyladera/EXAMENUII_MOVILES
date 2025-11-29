import 'package:flutter/material.dart';
import '../models/amcl_cls_survey.dart';
import '../services/amcl_cls_firestore_service.dart';

class AMCLclsAssignSurveyScreen extends StatefulWidget {
  final AMCLclsSurvey survey;

  const AMCLclsAssignSurveyScreen({super.key, required this.survey});

  @override
  State<AMCLclsAssignSurveyScreen> createState() =>
      _AMCLclsAssignSurveyScreenState();
}

class _AMCLclsAssignSurveyScreenState extends State<AMCLclsAssignSurveyScreen> {
  final _firestoreService = AMCLclsFirestoreService();
  List<Map<String, dynamic>> _surveyors = [];
  Set<String> _selectedUserIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurveyors();
    _selectedUserIds = Set<String>.from(widget.survey.assignedTo);
  }

  Future<void> _loadSurveyors() async {
    try {
      final surveyors = await _firestoreService.getSurveyors();
      setState(() {
        _surveyors = surveyors;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar encuestadores: $e')),
        );
      }
    }
  }

  Future<void> _saveAssignments() async {
    try {
      await _firestoreService.assignUsersToSurvey(
        widget.survey.id,
        _selectedUserIds.toList(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Asignación guardada exitosamente')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar asignación: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Encuestadores'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveAssignments,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Información de la encuesta
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.purple.shade50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.survey.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.survey.description,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedUserIds.length} encuestador(es) asignado(s)',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lista de encuestadores
                Expanded(
                  child: _surveyors.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay encuestadores registrados',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _surveyors.length,
                          itemBuilder: (context, index) {
                            final surveyor = _surveyors[index];
                            final isSelected = _selectedUserIds.contains(surveyor['id']);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedUserIds.add(surveyor['id']);
                                  } else {
                                    _selectedUserIds.remove(surveyor['id']);
                                  }
                                });
                              },
                              title: Text(
                                surveyor['name'],
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(surveyor['email']),
                              secondary: CircleAvatar(
                                backgroundColor: isSelected 
                                    ? Colors.purple 
                                    : Colors.grey.shade300,
                                child: Icon(
                                  isSelected ? Icons.person : Icons.person_outline,
                                  color: isSelected ? Colors.white : Colors.grey.shade600,
                                ),
                              ),
                              activeColor: Colors.purple,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAssignments,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.save),
        label: const Text('Guardar'),
      ),
    );
  }
}
