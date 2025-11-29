import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/amcl_cls_user.dart';

class AMCLclsAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream del usuario actual
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  User? get currentUser => _auth.currentUser;

  // Registrar nuevo usuario
  Future<AMCLclsUser?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Enviar email de verificación
        await user.sendEmailVerification();

        // Crear documento de usuario en Firestore
        AMCLclsUser newUser = AMCLclsUser(
          id: user.uid,
          email: email,
          name: name,
          emailVerified: false,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('amcl_caso1_users')
            .doc(user.uid)
            .set(newUser.toMap());

        return newUser;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Iniciar sesión
  Future<AMCLclsUser?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        // Actualizar último login
        await _firestore.collection('amcl_caso1_users').doc(user.uid).update({
          'lastLogin': Timestamp.now(),
          'emailVerified': user.emailVerified,
        });

        // Obtener datos del usuario
        DocumentSnapshot doc = await _firestore
            .collection('amcl_caso1_users')
            .doc(user.uid)
            .get();

        return AMCLclsUser.fromFirestore(doc);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reenviar email de verificación
  Future<void> resendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Verificar si el email está verificado
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      user = _auth.currentUser;
      
      // Actualizar en Firestore
      if (user != null && user.emailVerified) {
        await _firestore.collection('amcl_caso1_users').doc(user.uid).update({
          'emailVerified': true,
        });
      }
      
      return user?.emailVerified ?? false;
    }
    return false;
  }

  // Recuperar contraseña
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Obtener datos del usuario desde Firestore
  Future<AMCLclsUser?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('amcl_caso1_users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return AMCLclsUser.fromFirestore(doc);
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  // Actualizar perfil de usuario
  Future<void> updateUserProfile({
    required String userId,
    String? name,
  }) async {
    Map<String, dynamic> updates = {};
    
    if (name != null) updates['name'] = name;
    
    if (updates.isNotEmpty) {
      await _firestore
          .collection('amcl_caso1_users')
          .doc(userId)
          .update(updates);
    }
  }
}
