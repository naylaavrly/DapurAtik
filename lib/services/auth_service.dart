import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ LOGIN + AMBIL ROLE
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = result.user!.uid;

      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) return null;

      return userDoc['role'];
    } catch (e) {
      throw e.toString();
    }
  }

  // ✅ REGISTER + SIMPAN ROLE
  Future<User?> register({
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      UserCredential result =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(result.user!.uid).set({
        'email': email,
        'role': role,
        'created_at': Timestamp.now(),
      });

      return result.user;
    } catch (e) {
      throw e.toString();
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}