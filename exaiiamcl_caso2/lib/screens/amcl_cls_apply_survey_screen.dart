import 'package:flutter/material.dart';
import '../models/amcl_cls_survey.dart';
import '../models/amcl_cls_question.dart';
import '../models/amcl_cls_response.dart';
import '../services/amcl_cls_firestore_service.dart';
import '../services/amcl_cls_local_storage_service.dart';
import '../services/amcl_cls_sync_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class AMCLApplySurveyScreen extends StatefulWidget {
  final AMCLclsSurvey survey;

  const AMCLApplySurveyScreen({super.key, required this.survey});

  @override
  State<AMCLApplySurveyScreen> createState() => _AMCLApplySurveyScreenState();
}

class _AMCLApplySurveyScreenState extends State<AMCLApplySurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _firestoreService = AMCLclsFirestoreService();
  final _localStorage = AMCLclsLocalStorageService();
  final _syncService = AMCLclsSyncService();
  
  List<AMCLclsQuestion> _questions = [];
  final Map<String, dynamic> _answers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _currentLocation = 'Obteniendo ubicación...';
  bool _locationError = false;
  bool _hasInternetConnection = true;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _getCurrentLocation();
    _checkConnection();
  }
  
  Future<void> _checkConnection() async {
    bool hasConnection = await _syncService.hasInternetConnection();
    setState(() {
      _hasInternetConnection = hasConnection;
    });
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _firestoreService.getSurveyQuestionsOnce(widget.survey.id);
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar preguntas: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Verificar si los servicios de ubicación están habilitados
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentLocation = 'Servicios de ubicación desactivados';
          _locationError = true;
        });
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Permisos de ubicación denegados';
            _locationError = true;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Permisos de ubicación denegados permanentemente';
          _locationError = true;
        });
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Convertir coordenadas a dirección
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';
          
          if (place.street != null && place.street!.isNotEmpty) {
            address += place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address += address.isEmpty ? place.subLocality! : ', ${place.subLocality}';
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            address += address.isEmpty ? place.locality! : ', ${place.locality}';
          }
          if (place.country != null && place.country!.isNotEmpty) {
            address += address.isEmpty ? place.country! : ', ${place.country}';
          }

          setState(() {
            _currentLocation = address.isEmpty 
              ? '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'
              : address;
            _locationController.text = _currentLocation;
            _locationError = false;
          });
        }
      } catch (e) {
        // Si falla la geocodificación, usar coordenadas
        setState(() {
          _currentLocation = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          _locationController.text = _currentLocation;
          _locationError = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Error al obtener ubicación';
        _locationError = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos requeridos')),
      );
      return;
    }

    // Validar que se respondieron todas las preguntas requeridas
    for (var question in _questions) {
      if (question.isRequired && !_answers.containsKey(question.id)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Responde todas las preguntas requeridas')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final response = AMCLclsResponse(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        surveyId: widget.survey.id,
        userId: user.uid,
        respondentName: _nameController.text.trim(),
        respondentEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        answers: _answers,
        completedAt: DateTime.now(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      );

      // Verificar conexión a Internet
      bool hasConnection = await _syncService.hasInternetConnection();
      
      if (hasConnection) {
        // Hay conexión, enviar directamente a Firestore
        try {
          await _firestoreService.createResponse(response);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Encuesta enviada exitosamente'),
                  ],
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } catch (e) {
          // Error al enviar, guardar localmente
          await _localStorage.savePendingResponse(response);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.save, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Error al enviar. Guardado localmente para sincronizar después'),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
            Navigator.pop(context, true);
          }
        }
      } else {
        // Sin conexión, guardar localmente
        await _localStorage.savePendingResponse(response);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.cloud_off, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sin conexión. Respuesta guardada localmente (${_localStorage.getPendingCount()} pendiente${_localStorage.getPendingCount() != 1 ? 's' : ''})',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Ver',
                textColor: Colors.white,
                onPressed: () {
                  // Mostrar dialog con respuestas pendientes
                  _showPendingResponsesDialog();
                },
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
  
  void _showPendingResponsesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pending_actions, color: Colors.orange),
            SizedBox(width: 8),
            Text('Respuestas Pendientes'),
          ],
        ),
        content: Text(
          'Tienes ${_localStorage.getPendingCount()} respuesta(s) guardada(s) localmente.\n\n'
          'Se sincronizarán automáticamente cuando recuperes la conexión a Internet, '
          'o puedes sincronizar manualmente desde el menú principal.',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.survey.title),
        backgroundColor: Colors.blue.shade700,
        actions: [
          // Indicador de conexión
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                children: [
                  Icon(
                    _hasInternetConnection ? Icons.cloud_done : Icons.cloud_off,
                    size: 20,
                    color: _hasInternetConnection ? Colors.white : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _hasInternetConnection ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: _hasInternetConnection ? Colors.white : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner de estado offline si no hay conexión
                if (!_hasInternetConnection)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sin conexión. Las respuestas se guardarán localmente.',
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Form(
                    key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Encabezado
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.survey.title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.survey.description,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Información del encuestado
                  Text(
                    'Información del Encuestado',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre completo *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: 'Ubicación',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.location_on),
                      suffixIcon: _locationError
                        ? IconButton(
                            icon: const Icon(Icons.refresh, color: Colors.orange),
                            onPressed: _getCurrentLocation,
                            tooltip: 'Reintentar obtener ubicación',
                          )
                        : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                    readOnly: true,
                  ),
                  const Divider(height: 32),

                  // Preguntas
                  Text(
                    'Preguntas de la Encuesta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return _buildQuestionWidget(index, question);
                  }),

                  const SizedBox(height: 24),

                  // Botón de envío
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitSurvey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Enviar Encuesta',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
                  ),
              ],
            ),
    );
  }

  Widget _buildQuestionWidget(int index, AMCLclsQuestion question) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.blue.shade700,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (question.isRequired)
                        const Text(
                          '* Requerida',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnswerInput(question),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerInput(AMCLclsQuestion question) {
    switch (question.type) {
      case AMCLQuestionType.multipleChoice:
        return Column(
          children: question.options.map((option) {
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: _answers[question.id],
              onChanged: (value) {
                setState(() {
                  _answers[question.id] = value;
                });
              },
              activeColor: Colors.blue.shade700,
            );
          }).toList(),
        );

      case AMCLQuestionType.rating:
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final rating = index + 1;
                final isSelected = _answers[question.id] == rating;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _answers[question.id] = rating;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade700 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade900 : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$rating',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Muy malo',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  'Excelente',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        );

      case AMCLQuestionType.openEnded:
        return TextFormField(
          decoration: const InputDecoration(
            hintText: 'Escribe tu respuesta aquí...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          onChanged: (value) {
            _answers[question.id] = value;
          },
          validator: question.isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Esta pregunta es requerida';
                  }
                  return null;
                }
              : null,
        );
    }
  }
}
