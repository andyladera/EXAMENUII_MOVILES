import 'package:flutter/material.dart';
import '../models/amcl_cls_survey.dart';
import '../models/amcl_cls_question.dart';
import '../models/amcl_cls_response.dart';
import '../services/amcl_cls_firestore_service.dart';

class AMCLSurveyResponsesScreen extends StatefulWidget {
  final AMCLclsSurvey survey;

  const AMCLSurveyResponsesScreen({super.key, required this.survey});

  @override
  State<AMCLSurveyResponsesScreen> createState() => _AMCLSurveyResponsesScreenState();
}

class _AMCLSurveyResponsesScreenState extends State<AMCLSurveyResponsesScreen> {
  final _firestoreService = AMCLclsFirestoreService();
  List<AMCLclsQuestion> _questions = [];
  bool _isLoadingQuestions = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _firestoreService.getSurveyQuestionsOnce(widget.survey.id);
      setState(() {
        _questions = questions;
        _isLoadingQuestions = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingQuestions = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Respuestas: ${widget.survey.title}'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoadingQuestions
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<AMCLclsResponse>>(
              stream: _firestoreService.getSurveyResponses(widget.survey.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined, size: 100, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Sin respuestas aún',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Las respuestas aparecerán aquí cuando los encuestadores\napliquen esta encuesta',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final responses = snapshot.data!;

                return Column(
                  children: [
                    // Estadísticas generales
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.purple.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatCard(
                            icon: Icons.people,
                            label: 'Respuestas',
                            value: '${responses.length}',
                            color: Colors.purple,
                          ),
                          _StatCard(
                            icon: Icons.quiz,
                            label: 'Preguntas',
                            value: '${_questions.length}',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),

                    // Lista de respuestas
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: responses.length,
                        itemBuilder: (context, index) {
                          final response = responses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade100,
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.purple.shade900,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                response.respondentName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (response.respondentEmail != null)
                                    Text(response.respondentEmail!),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(response.completedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Información adicional
                                      if (response.location != null && response.location!.isNotEmpty)
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.only(bottom: 16),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 16),
                                              const SizedBox(width: 4),
                                              Text(response.location!),
                                            ],
                                          ),
                                        ),

                                      // Respuestas
                                      const Text(
                                        'Respuestas:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ..._questions.asMap().entries.map((entry) {
                                        final qIndex = entry.key;
                                        final question = entry.value;
                                        final answer = response.answers[question.id];
                                        return _buildAnswerItem(qIndex, question, answer);
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildAnswerItem(int index, AMCLclsQuestion question, dynamic answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${index + 1}. ',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: _buildAnswerDisplay(question, answer),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerDisplay(AMCLclsQuestion question, dynamic answer) {
    if (answer == null) {
      return Text(
        'Sin respuesta',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey.shade600,
        ),
      );
    }

    switch (question.type) {
      case AMCLQuestionType.multipleChoice:
        return Row(
          children: [
            Icon(Icons.check_circle, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                answer.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        );

      case AMCLQuestionType.rating:
        final ratingValue = answer is int ? answer : int.tryParse(answer.toString()) ?? 0;
        return Row(
          children: [
            ...List.generate(5, (index) {
              final rating = index + 1;
              return Icon(
                rating <= ratingValue ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24,
              );
            }),
            const SizedBox(width: 8),
            Text(
              '$ratingValue/5',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        );

      case AMCLQuestionType.openEnded:
        return Text(
          answer.toString(),
          style: const TextStyle(fontSize: 14),
        );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} - ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
