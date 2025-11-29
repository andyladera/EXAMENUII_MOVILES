import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/amcl_cls_unit.dart';
import '../models/amcl_cls_question.dart';
import '../models/amcl_cls_evaluation.dart';
import '../services/amcl_cls_firestore_service.dart';

class AMCLclsEvaluationsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;

  const AMCLclsEvaluationsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  State<AMCLclsEvaluationsScreen> createState() =>
      _AMCLclsEvaluationsScreenState();
}

class _AMCLclsEvaluationsScreenState extends State<AMCLclsEvaluationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluaciones - ${widget.courseTitle}'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.play_arrow), text: 'Rendir'),
            Tab(icon: Icon(Icons.history), text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RenderTab(courseId: widget.courseId),
          _HistoryTab(courseId: widget.courseId),
        ],
      ),
    );
  }
}

class _RenderTab extends StatelessWidget {
  final String courseId;

  const _RenderTab({required this.courseId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();

    return StreamBuilder<List<AMCLclsUnit>>(
      stream: firestoreService.getUnitsStream(courseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.topic_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay unidades creadas',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final units = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: units.length,
          itemBuilder: (context, index) {
            final unit = units[index];
            return _UnitEvaluationCard(
              unit: unit,
              courseId: courseId,
              firestoreService: firestoreService,
            );
          },
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final String courseId;

  const _HistoryTab({required this.courseId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = AMCLclsFirestoreService();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      return const Center(child: Text('Usuario no autenticado'));
    }

    return StreamBuilder<List<AMCLclsEvaluation>>(
      stream: firestoreService.getEvaluationsByCourse(courseId, userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No has rendido evaluaciones',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final evaluations = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: evaluations.length,
          itemBuilder: (context, index) {
            final evaluation = evaluations[index];
            return _EvaluationHistoryCard(
              evaluation: evaluation,
              firestoreService: firestoreService,
            );
          },
        );
      },
    );
  }
}

class _UnitEvaluationCard extends StatelessWidget {
  final AMCLclsUnit unit;
  final String courseId;
  final AMCLclsFirestoreService firestoreService;

  const _UnitEvaluationCard({
    required this.unit,
    required this.courseId,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unit.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unit.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                unit.description,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
            const SizedBox(height: 16),
            StreamBuilder<List<AMCLclsQuestion>>(
              stream: firestoreService.getQuestionsByUnit(courseId, unit.id),
              builder: (context, snapshot) {
                final questionCount = snapshot.data?.length ?? 0;
                
                return Row(
                  children: [
                    Icon(Icons.quiz, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text('$questionCount preguntas disponibles'),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: questionCount < 5
                          ? null
                          : () => _startEvaluation(context, unit.id, snapshot.data!),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _startEvaluation(BuildContext context, String unitId, List<AMCLclsQuestion> allQuestions) async {
    // Preguntar si desea límite de tiempo
    final timeLimitMinutes = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configurar Evaluación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Deseas establecer un límite de tiempo?'),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Sin límite'),
              leading: Radio<int?>(
                value: null,
                groupValue: null,
                onChanged: (value) => Navigator.pop(context, null),
              ),
              onTap: () => Navigator.pop(context, null),
            ),
            ListTile(
              title: const Text('10 minutos'),
              leading: Radio<int?>(
                value: 10,
                groupValue: null,
                onChanged: (value) {},
              ),
              onTap: () => Navigator.pop(context, 10),
            ),
            ListTile(
              title: const Text('15 minutos'),
              leading: Radio<int?>(
                value: 15,
                groupValue: null,
                onChanged: (value) {},
              ),
              onTap: () => Navigator.pop(context, 15),
            ),
            ListTile(
              title: const Text('20 minutos'),
              leading: Radio<int?>(
                value: 20,
                groupValue: null,
                onChanged: (value) {},
              ),
              onTap: () => Navigator.pop(context, 20),
            ),
            ListTile(
              title: const Text('30 minutos'),
              leading: Radio<int?>(
                value: 30,
                groupValue: null,
                onChanged: (value) {},
              ),
              onTap: () => Navigator.pop(context, 30),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    // Seleccionar 10 preguntas aleatorias (o todas si hay menos de 10)
    final random = Random();
    final shuffled = List<AMCLclsQuestion>.from(allQuestions)..shuffle(random);
    final selectedQuestions = shuffled.take(min(10, shuffled.length)).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EvaluationTakingScreen(
          courseId: courseId,
          unitId: unitId,
          questions: selectedQuestions,
          firestoreService: firestoreService,
          timeLimitSeconds: timeLimitMinutes != null ? timeLimitMinutes * 60 : null,
        ),
      ),
    );
  }
}

class _EvaluationTakingScreen extends StatefulWidget {
  final String courseId;
  final String unitId;
  final List<AMCLclsQuestion> questions;
  final AMCLclsFirestoreService firestoreService;
  final int? timeLimitSeconds;

  const _EvaluationTakingScreen({
    required this.courseId,
    required this.unitId,
    required this.questions,
    required this.firestoreService,
    this.timeLimitSeconds,
  });

  @override
  State<_EvaluationTakingScreen> createState() =>
      _EvaluationTakingScreenState();
}

class _EvaluationTakingScreenState extends State<_EvaluationTakingScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, String> _userAnswers = {};
  Timer? _timer;
  int _secondsElapsed = 0;
  final DateTime _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        
        // Si hay límite de tiempo y se alcanzó, finalizar automáticamente
        if (widget.timeLimitSeconds != null && 
            _secondsElapsed >= widget.timeLimitSeconds!) {
          _timer?.cancel();
          _finishEvaluation(timedOut: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / widget.questions.length;
    
    // Calcular tiempo restante si hay límite
    final remainingSeconds = widget.timeLimitSeconds != null 
        ? widget.timeLimitSeconds! - _secondsElapsed 
        : null;
    final isTimeRunningOut = remainingSeconds != null && remainingSeconds <= 60;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Abandonar Evaluación'),
            content: const Text(
              '¿Estás seguro de que deseas abandonar la evaluación?\n'
              'Perderás todo tu progreso.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Abandonar'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pregunta ${_currentQuestionIndex + 1} de ${widget.questions.length}'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          actions: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.timer),
                    const SizedBox(width: 8),
                    Text(
                      widget.timeLimitSeconds != null && remainingSeconds != null
                          ? _formatTime(remainingSeconds)
                          : _formatTime(_secondsElapsed),
                      style: TextStyle(
                        fontSize: 16,
                        color: isTimeRunningOut ? Colors.red : Colors.white,
                        fontWeight: isTimeRunningOut ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      question.statement,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...question.options.map((option) {
                      final isSelected = _userAnswers[question.id] == option;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _userAnswers[question.id] = option;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Anterior'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _userAnswers.containsKey(question.id)
                          ? () {
                              if (_currentQuestionIndex <
                                  widget.questions.length - 1) {
                                setState(() {
                                  _currentQuestionIndex++;
                                });
                              } else {
                                _finishEvaluation();
                              }
                            }
                          : null,
                      icon: Icon(_currentQuestionIndex <
                              widget.questions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check),
                      label: Text(_currentQuestionIndex <
                              widget.questions.length - 1
                          ? 'Siguiente'
                          : 'Finalizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _finishEvaluation({bool timedOut = false}) async {
    // Si se acabó el tiempo, no preguntar
    if (!timedOut) {
      // Verificar que todas las preguntas estén respondidas
      final unanswered = widget.questions
          .where((q) => !_userAnswers.containsKey(q.id))
          .length;

      if (unanswered > 0) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Preguntas sin responder'),
            content: Text(
              'Tienes $unanswered pregunta${unanswered > 1 ? 's' : ''} sin responder.\n'
              '¿Deseas finalizar de todos modos?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Revisar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Finalizar'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) return;
      }
    }

    // Calcular puntaje
    int score = 0;
    for (final question in widget.questions) {
      final userAnswer = _userAnswers[question.id];
      if (userAnswer == question.correctAnswer) {
        score++;
      }
    }

    // Guardar evaluación
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final evaluation = AMCLclsEvaluation(
        id: '',
        userId: userId,
        unitId: widget.unitId,
        courseId: widget.courseId,
        questionIds: widget.questions.map((q) => q.id).toList(),
        userAnswers: _userAnswers,
        score: score,
        totalQuestions: widget.questions.length,
        startedAt: _startTime,
        completedAt: DateTime.now(),
        timeSpentSeconds: _secondsElapsed,
        timeLimitSeconds: widget.timeLimitSeconds,
      );

      await widget.firestoreService.createEvaluation(evaluation);

      if (!mounted) return;

      // Mostrar resultado
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _EvaluationResultScreen(
            evaluation: evaluation,
            questions: widget.questions,
            timedOut: timedOut,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _EvaluationResultScreen extends StatelessWidget {
  final AMCLclsEvaluation evaluation;
  final List<AMCLclsQuestion> questions;
  final bool timedOut;

  const _EvaluationResultScreen({
    required this.evaluation,
    required this.questions,
    this.timedOut = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = evaluation.percentage;
    final isPassed = percentage >= 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (timedOut) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade700, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_off, color: Colors.orange.shade700, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¡Se acabó el tiempo!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Icon(
              isPassed ? Icons.check_circle : Icons.cancel,
              size: 120,
              color: isPassed ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              isPassed ? '¡Aprobado!' : 'No Aprobado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isPassed ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _ResultRow(
                      label: 'Puntaje',
                      value: '${evaluation.score} / ${evaluation.totalQuestions}',
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      label: 'Porcentaje',
                      value: '${percentage.toStringAsFixed(1)}%',
                    ),
                    const Divider(height: 24),
                    _ResultRow(
                      label: 'Tiempo',
                      value: _formatTime(evaluation.timeSpentSeconds ?? 0),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Volver a evaluaciones
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _EvaluationHistoryCard extends StatelessWidget {
  final AMCLclsEvaluation evaluation;
  final AMCLclsFirestoreService firestoreService;

  const _EvaluationHistoryCard({
    required this.evaluation,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = evaluation.percentage;
    final isPassed = percentage >= 60;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPassed ? Colors.green : Colors.red,
          child: Text(
            '${percentage.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: FutureBuilder<AMCLclsUnit?>(
          future: firestoreService.getUnitById(
            evaluation.courseId,
            evaluation.unitId,
          ),
          builder: (context, snapshot) {
            final unitTitle = snapshot.data?.title ?? 'Cargando...';
            return Text(unitTitle);
          },
        ),
        subtitle: Text(
          '${evaluation.score}/${evaluation.totalQuestions} correctas • '
          '${_formatDate(evaluation.completedAt ?? evaluation.startedAt)}',
        ),
        trailing: Icon(
          isPassed ? Icons.check_circle : Icons.cancel,
          color: isPassed ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoy';
    } else if (diff.inDays == 1) {
      return 'Ayer';
    } else if (diff.inDays < 7) {
      return 'Hace ${diff.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
