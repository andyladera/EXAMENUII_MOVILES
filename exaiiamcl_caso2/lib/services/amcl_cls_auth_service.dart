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

  // Registrar con email y contraseña
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required AMCLUserRole role,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Enviar verificación de email
      await userCredential.user?.sendEmailVerification();

      // Guardar datos adicionales en Firestore
      await _firestore.collection('amcl_caso2_users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'role': role.name,
        'emailVerified': false,
        'createdAt': Timestamp.now(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Iniciar sesión
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Actualizar último login
      await _firestore
          .collection('amcl_caso2_users')
          .doc(userCredential.user!.uid)
          .update({'lastLogin': Timestamp.now()});

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Verificar si el email está verificado
  Future<bool> checkEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Reenviar verificación de email
  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  // Restablecer contraseña
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Obtener datos del usuario desde Firestore
  Future<AMCLclsUser?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('amcl_caso2_users')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return AMCLclsUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Stream de datos del usuario
  Stream<AMCLclsUser?> getUserDataStream(String userId) {
    return _firestore
        .collection('amcl_caso2_users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? AMCLclsUser.fromFirestore(doc) : null);
  }

  // Actualizar email verificado en Firestore
  Future<void> updateEmailVerified(String userId, bool verified) async {
    await _firestore
        .collection('amcl_caso2_users')
        .doc(userId)
        .update({'emailVerified': verified});
  }
}
