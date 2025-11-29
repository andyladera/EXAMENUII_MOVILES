import 'package:flutter/material.dart';
import '../services/amcl_cls_firestore_service.dart';
import '../models/amcl_cls_unit.dart';
import '../models/amcl_cls_question.dart';

class AMCLclsQuestionsScreen extends StatelessWidget {
  final String courseId;
  final String courseTitle;

  const AMCLclsQuestionsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text('Preguntas - $courseTitle'),
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
                    Icons.quiz_outlined,
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
              return _UnitQuestionsCard(
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

class _UnitQuestionsCard extends StatelessWidget {
  final AMCLclsUnit unit;
  final String courseId;

  const _UnitQuestionsCard({
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
          StreamBuilder<List<AMCLclsQuestion>>(
            stream: firestoreService.getUnitQuestions(unit.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final questions = snapshot.data ?? [];

              return Column(
                children: [
                  if (questions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No hay preguntas',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  else
                    ...questions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final question = entry.value;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(question.statement),
                        subtitle: Text(
                          'Tipo: ${question.type == AMCLQuestionType.multipleChoice ? 'Opción múltiple' : 'Verdadero/Falso'}',
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Editar'),
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
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showQuestionDialog(context, unit.id,
                                  question: question);
                            } else if (value == 'delete') {
                              _showDeleteDialog(context, question);
                            }
                          },
                        ),
                      );
                    }),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      onPressed: () => _showQuestionDialog(context, unit.id),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Pregunta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
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

  void _showQuestionDialog(BuildContext context, String unitId,
      {AMCLclsQuestion? question}) {
    final statementController =
        TextEditingController(text: question?.statement ?? '');
    AMCLQuestionType selectedType =
        question?.type ?? AMCLQuestionType.multipleChoice;
    final optionsControllers = question != null
        ? question.options.map((opt) => TextEditingController(text: opt)).toList()
        : [
            TextEditingController(),
            TextEditingController(),
            TextEditingController(),
            TextEditingController(),
          ];
    
    // Para opción múltiple, guardamos el índice seleccionado
    int? selectedCorrectIndex;
    if (question != null && selectedType == AMCLQuestionType.multipleChoice) {
      selectedCorrectIndex = question.options.indexOf(question.correctAnswer);
      if (selectedCorrectIndex == -1) selectedCorrectIndex = null;
    }
    
    String correctAnswer = question?.correctAnswer ?? '';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(question == null ? 'Nueva Pregunta' : 'Editar Pregunta'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Enunciado
                  TextFormField(
                    controller: statementController,
                    decoration: const InputDecoration(
                      labelText: 'Enunciado de la pregunta',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // Tipo de pregunta
                  DropdownButtonFormField<AMCLQuestionType>(
                    value: selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de pregunta',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AMCLQuestionType.multipleChoice,
                        child: Text('Opción múltiple'),
                      ),
                      DropdownMenuItem(
                        value: AMCLQuestionType.trueFalse,
                        child: Text('Verdadero/Falso'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedType = value;
                          correctAnswer = '';
                          selectedCorrectIndex = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Opciones
                  if (selectedType == AMCLQuestionType.multipleChoice) ...[
                    const Text(
                      'Opciones:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(4, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: selectedCorrectIndex,
                              onChanged: (value) {
                                setState(() {
                                  selectedCorrectIndex = value;
                                });
                              },
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: optionsControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Opción ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) => value?.isEmpty ?? true
                                    ? 'Requerido'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else ...[
                    const Text(
                      'Respuesta correcta:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    RadioListTile<String>(
                      title: const Text('Verdadero'),
                      value: 'Verdadero',
                      groupValue: correctAnswer,
                      onChanged: (value) {
                        setState(() {
                          correctAnswer = value!;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      title: const Text('Falso'),
                      value: 'Falso',
                      groupValue: correctAnswer,
                      onChanged: (value) {
                        setState(() {
                          correctAnswer = value!;
                        });
                      },
                    ),
                  ],
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

                // Validar respuesta correcta para opción múltiple
                if (selectedType == AMCLQuestionType.multipleChoice) {
                  if (selectedCorrectIndex == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecciona la respuesta correcta'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  // Actualizar correctAnswer con el texto de la opción seleccionada
                  correctAnswer = optionsControllers[selectedCorrectIndex!].text.trim();
                } else {
                  // Para verdadero/falso
                  if (correctAnswer.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecciona la respuesta correcta'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                }

                final firestoreService = AMCLclsFirestoreService();

                try {
                  final options = selectedType == AMCLQuestionType.multipleChoice
                      ? optionsControllers
                          .map((c) => c.text.trim())
                          .where((text) => text.isNotEmpty)
                          .toList()
                      : ['Verdadero', 'Falso'];

                  if (question == null) {
                    // Crear
                    final newQuestion = AMCLclsQuestion(
                      id: '',
                      unitId: unitId,
                      statement: statementController.text.trim(),
                      type: selectedType,
                      options: options,
                      correctAnswer: correctAnswer,
                      createdAt: DateTime.now(),
                    );
                    await firestoreService.createQuestion(newQuestion);
                  } else {
                    // Actualizar
                    await firestoreService.updateQuestion(question.id, {
                      'statement': statementController.text.trim(),
                      'type': selectedType == AMCLQuestionType.multipleChoice
                          ? 'multipleChoice'
                          : 'trueFalse',
                      'options': options,
                      'correctAnswer': correctAnswer,
                    });
                  }

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(question == null
                          ? 'Pregunta creada'
                          : 'Pregunta actualizada'),
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
              child: Text(question == null ? 'Crear' : 'Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AMCLclsQuestion question) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Pregunta'),
        content: const Text('¿Estás seguro de eliminar esta pregunta?'),
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
                await firestoreService.deleteQuestion(question.id);

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pregunta eliminada'),
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
