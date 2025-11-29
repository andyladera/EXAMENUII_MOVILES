import 'package:flutter/material.dart';
import '../models/amcl_cls_survey.dart';
import '../models/amcl_cls_question.dart';
import '../services/amcl_cls_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AMCLCreateSurveyScreen extends StatefulWidget {
  final AMCLclsSurvey? survey;

  const AMCLCreateSurveyScreen({super.key, this.survey});

  @override
  State<AMCLCreateSurveyScreen> createState() => _AMCLCreateSurveyScreenState();
}

class _AMCLCreateSurveyScreenState extends State<AMCLCreateSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestoreService = AMCLclsFirestoreService();
  bool _isActive = true;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.survey != null) {
      _titleController.text = widget.survey!.title;
      _descriptionController.text = widget.survey!.description;
      _isActive = widget.survey!.isActive;
      _loadQuestions();
    }
  }

  Future<void> _loadQuestions() async {
    if (widget.survey != null) {
      final questions = await _firestoreService.getSurveyQuestionsOnce(widget.survey!.id);
      setState(() {
        for (var q in questions) {
          _questions.add({
            'id': q.id,
            'question': q.question,
            'type': q.type,
            'options': q.options,
            'isRequired': q.isRequired,
            'order': q.order,
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveSurvey() async {
    if (!_formKey.currentState!.validate()) return;
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una pregunta')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      String surveyId;
      
      if (widget.survey != null) {
        // Actualizar encuesta existente
        surveyId = widget.survey!.id;
        await _firestoreService.updateSurvey(surveyId, {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'isActive': _isActive,
        });
        
        // Actualizar preguntas
        final existingQuestions = await _firestoreService.getSurveyQuestionsOnce(surveyId);
        final existingIds = existingQuestions.map((q) => q.id).toSet();
        final currentIds = _questions.where((q) => q['id'] != null).map((q) => q['id'] as String).toSet();
        
        // Eliminar preguntas que ya no están
        for (var q in existingQuestions) {
          if (!currentIds.contains(q.id)) {
            await _firestoreService.deleteQuestion(q.id);
          }
        }
        
        // Actualizar o crear preguntas
        for (var i = 0; i < _questions.length; i++) {
          final qData = _questions[i];
          if (qData['id'] != null && existingIds.contains(qData['id'])) {
            await _firestoreService.updateQuestion(qData['id'], {
              'question': qData['question'],
              'type': (qData['type'] as AMCLQuestionType).toString().split('.').last,
              'options': qData['options'],
              'isRequired': qData['isRequired'],
              'order': i,
            });
          } else {
            final question = AMCLclsQuestion(
              id: '',
              surveyId: surveyId,
              question: qData['question'],
              type: qData['type'],
              options: List<String>.from(qData['options']),
              order: i,
              isRequired: qData['isRequired'],
            );
            await _firestoreService.createQuestion(question);
          }
        }
      } else {
        // Crear nueva encuesta
        final survey = AMCLclsSurvey(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          createdBy: user.uid,
          createdAt: DateTime.now(),
          isActive: _isActive,
        );
        surveyId = await _firestoreService.createSurvey(survey);
        
        // Crear preguntas
        for (var i = 0; i < _questions.length; i++) {
          final qData = _questions[i];
          final question = AMCLclsQuestion(
            id: '',
            surveyId: surveyId,
            question: qData['question'],
            type: qData['type'],
            options: List<String>.from(qData['options']),
            order: i,
            isRequired: qData['isRequired'],
          );
          await _firestoreService.createQuestion(question);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.survey != null 
            ? 'Encuesta actualizada' 
            : 'Encuesta creada')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        onSave: (questionData) {
          setState(() {
            _questions.add(questionData);
          });
        },
      ),
    );
  }

  void _editQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => _QuestionDialog(
        questionData: _questions[index],
        onSave: (questionData) {
          setState(() {
            _questions[index] = questionData;
          });
        },
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar pregunta'),
        content: const Text('¿Estás seguro de eliminar esta pregunta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _questions.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey != null ? 'Editar Encuesta' : 'Nueva Encuesta'),
        backgroundColor: Colors.purple,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveSurvey,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título de la encuesta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Encuesta activa'),
              subtitle: Text(_isActive 
                ? 'Los encuestadores pueden aplicar esta encuesta' 
                : 'Esta encuesta está inactiva'),
              value: _isActive,
              onChanged: (value) {
                setState(() => _isActive = value);
              },
              activeColor: Colors.purple,
            ),
            const Divider(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preguntas (${_questions.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_questions.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay preguntas',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...List.generate(_questions.length, (index) {
                final question = _questions[index];
                return Card(
                  key: ValueKey(question['question'] + index.toString()),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(question['question']),
                    subtitle: Text(
                      _getQuestionTypeLabel(question['type'] as AMCLQuestionType) +
                      (question['isRequired'] ? ' • Requerida' : ' • Opcional'),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editQuestion(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteQuestion(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  String _getQuestionTypeLabel(AMCLQuestionType type) {
    switch (type) {
      case AMCLQuestionType.multipleChoice:
        return 'Opción múltiple';
      case AMCLQuestionType.openEnded:
        return 'Respuesta abierta';
      case AMCLQuestionType.rating:
        return 'Calificación';
    }
  }
}

class _QuestionDialog extends StatefulWidget {
  final Map<String, dynamic>? questionData;
  final Function(Map<String, dynamic>) onSave;

  const _QuestionDialog({this.questionData, required this.onSave});

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  late AMCLQuestionType _selectedType;
  late bool _isRequired;
  final List<String> _options = [];
  final _optionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.questionData != null) {
      _textController.text = widget.questionData!['question'];
      _selectedType = widget.questionData!['type'];
      _isRequired = widget.questionData!['isRequired'];
      _options.addAll(List<String>.from(widget.questionData!['options']));
    } else {
      _selectedType = AMCLQuestionType.multipleChoice;
      _isRequired = true;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _optionController.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionController.text.trim().isNotEmpty) {
      setState(() {
        _options.add(_optionController.text.trim());
        _optionController.clear();
      });
    }
  }

  void _removeOption(int index) {
    setState(() {
      _options.removeAt(index);
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedType == AMCLQuestionType.multipleChoice && _options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos 2 opciones')),
      );
      return;
    }

    final questionData = {
      'id': widget.questionData?['id'],
      'question': _textController.text.trim(),
      'type': _selectedType,
      'options': _selectedType == AMCLQuestionType.multipleChoice ? List<String>.from(_options) : <String>[],
      'isRequired': _isRequired,
      'order': widget.questionData?['order'] ?? 0,
    };

    widget.onSave(questionData);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                widget.questionData != null ? 'Editar Pregunta' : 'Nueva Pregunta',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Pregunta',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa la pregunta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<AMCLQuestionType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de pregunta',
                  border: OutlineInputBorder(),
                ),
                items: AMCLQuestionType.values.map((type) {
                  String label;
                  switch (type) {
                    case AMCLQuestionType.multipleChoice:
                      label = 'Opción múltiple';
                      break;
                    case AMCLQuestionType.openEnded:
                      label = 'Respuesta abierta';
                      break;
                    case AMCLQuestionType.rating:
                      label = 'Calificación (1-5)';
                      break;
                  }
                  return DropdownMenuItem(value: type, child: Text(label));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    if (value != AMCLQuestionType.multipleChoice) {
                      _options.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              
              if (_selectedType == AMCLQuestionType.multipleChoice) ...[
                const Text('Opciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _optionController,
                        decoration: const InputDecoration(
                          hintText: 'Nueva opción',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addOption(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: _addOption,
                      color: Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ..._options.asMap().entries.map((entry) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 12,
                        child: Text('${entry.key + 1}'),
                      ),
                      title: Text(entry.value),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeOption(entry.key),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
              
              SwitchListTile(
                title: const Text('Respuesta requerida'),
                value: _isRequired,
                onChanged: (value) {
                  setState(() => _isRequired = value);
                },
                activeColor: Colors.purple,
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Guardar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
