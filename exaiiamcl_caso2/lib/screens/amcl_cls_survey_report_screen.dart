import 'package:flutter/material.dart';
import '../models/amcl_cls_survey.dart';
import '../models/amcl_cls_survey_stats.dart';
import '../services/amcl_cls_firestore_service.dart';

class AMCLclsSurveyReportScreen extends StatelessWidget {
  final AMCLclsSurvey survey;
  final _firestoreService = AMCLclsFirestoreService();

  AMCLclsSurveyReportScreen({super.key, required this.survey});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Encuesta'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<AMCLclsSurveyStats>(
        future: _firestoreService.getSurveyStatistics(survey.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(
              child: Text('No hay datos disponibles'),
            );
          }
          
          AMCLclsSurveyStats stats = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con información de la encuesta
                _buildSurveyHeader(context),
                const SizedBox(height: 24),
                
                // Estadísticas generales
                _buildGeneralStats(context, stats),
                const SizedBox(height: 24),
                
                // Respuestas por fecha
                if (stats.responsesByDate.isNotEmpty) ...[
                  _buildResponsesByDate(context, stats),
                  const SizedBox(height: 24),
                ],
                
                // Estadísticas por pregunta
                _buildQuestionStats(context, stats),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildSurveyHeader(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              survey.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              survey.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Chip(
              label: Text(survey.isActive ? 'Activa' : 'Inactiva'),
              backgroundColor: survey.isActive ? Colors.green : Colors.grey,
              labelStyle: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGeneralStats(BuildContext context, AMCLclsSurveyStats stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estadísticas Generales',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Respuestas',
                    stats.totalResponses.toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Preguntas',
                    stats.totalQuestions.toString(),
                    Icons.question_answer,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              'Tiempo Promedio',
              '${stats.averageCompletionTime.toStringAsFixed(1)} min',
              Icons.timer,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponsesByDate(BuildContext context, AMCLclsSurveyStats stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Respuestas por Fecha',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...stats.responsesByDate.map((data) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        data['date'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: data['count'] / stats.totalResponses,
                        backgroundColor: Colors.grey[200],
                        color: Colors.purple,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data['count']}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionStats(BuildContext context, AMCLclsSurveyStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estadísticas por Pregunta',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...stats.questionStats.entries.map((entry) {
          AMCLclsQuestionStats qStats = entry.value;
          return _buildQuestionStatCard(context, qStats, stats.totalResponses);
        }).toList(),
      ],
    );
  }
  
  Widget _buildQuestionStatCard(
    BuildContext context,
    AMCLclsQuestionStats qStats,
    int totalResponses,
  ) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              qStats.questionText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(_getQuestionTypeLabel(qStats.questionType)),
                  backgroundColor: Colors.blue[100],
                  labelStyle: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 8),
                Text(
                  '${qStats.totalAnswers} respuestas',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Mostrar estadísticas según el tipo
            if (qStats.questionType == 'multipleChoice' && qStats.optionCounts != null)
              _buildMultipleChoiceStats(context, qStats.optionCounts!, qStats.totalAnswers),
            
            if (qStats.questionType == 'rating' && qStats.averageRating != null)
              _buildRatingStats(context, qStats.averageRating!),
            
            if (qStats.questionType == 'openEnded' && qStats.openEndedAnswers != null)
              _buildOpenEndedStats(context, qStats.openEndedAnswers!),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMultipleChoiceStats(
    BuildContext context,
    Map<String, int> optionCounts,
    int totalAnswers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: optionCounts.entries.map((entry) {
        double percentage = totalAnswers > 0 ? (entry.value / totalAnswers) * 100 : 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[200],
                color: Colors.green,
                minHeight: 6,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildRatingStats(BuildContext context, double averageRating) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 32),
        const SizedBox(width: 8),
        Text(
          averageRating.toStringAsFixed(2),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.amber[700],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '/ 5.0',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(width: 16),
        ...List.generate(5, (index) {
          return Icon(
            index < averageRating.round() ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 24,
          );
        }),
      ],
    );
  }
  
  Widget _buildOpenEndedStats(BuildContext context, List<String> answers) {
    int displayCount = answers.length > 5 ? 5 : answers.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Respuestas recientes:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...answers.take(displayCount).map((answer) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                answer,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          );
        }).toList(),
        if (answers.length > displayCount)
          Text(
            '+ ${answers.length - displayCount} respuestas más',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }
  
  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multipleChoice':
        return 'Opción múltiple';
      case 'rating':
        return 'Calificación';
      case 'openEnded':
        return 'Abierta';
      default:
        return type;
    }
  }
}
