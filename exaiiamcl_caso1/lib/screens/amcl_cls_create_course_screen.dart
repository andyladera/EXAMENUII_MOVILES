import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/amcl_cls_firestore_service.dart';
import '../models/amcl_cls_course.dart';

class AMCLclsCreateCourseScreen extends StatefulWidget {
  final AMCLclsCourse? course; // Para edición

  const AMCLclsCreateCourseScreen({super.key, this.course});

  @override
  State<AMCLclsCreateCourseScreen> createState() => _AMCLclsCreateCourseScreenState();
}

class _AMCLclsCreateCourseScreenState extends State<AMCLclsCreateCourseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firestoreService = AMCLclsFirestoreService();
  
  String _selectedCategory = 'Programación';
  bool _isLoading = false;

  final List<String> _categories = [
    'Programación',
    'Matemáticas',
    'Ciencias',
    'Idiomas',
    'Arte',
    'Historia',
    'Negocios',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      _titleController.text = widget.course!.title;
      _descriptionController.text = widget.course!.description;
      _selectedCategory = widget.course!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      if (widget.course == null) {
        // Crear nuevo curso
        AMCLclsCourse newCourse = AMCLclsCourse(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          ownerId: user.uid,
          createdAt: DateTime.now(),
        );

        await _firestoreService.createCourse(newCourse);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Curso creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Actualizar curso existente
        await _firestoreService.updateCourse(
          widget.course!.id,
          {
            'title': _titleController.text.trim(),
            'description': _descriptionController.text.trim(),
            'category': _selectedCategory,
          },
        );
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Curso actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Curso' : 'Crear Curso'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Título del curso',
                prefixIcon: const Icon(Icons.title),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa el título';
                }
                if (value.length < 3) {
                  return 'El título debe tener al menos 3 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Descripción',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa una descripción';
                }
                if (value.length < 10) {
                  return 'La descripción debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Categoría
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoría',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            
            const SizedBox(height: 32),
            
            // Botón Guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCourse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      isEditing ? 'Actualizar Curso' : 'Crear Curso',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
