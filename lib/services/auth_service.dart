import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> login(String email, String password) async {
    try {
      // LOGIN
      UserCredential result =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = result.user!.uid;

      // AMBIL DATA USER
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        print("User tidak ditemukan di Firestore");
        return null;
      }

      return userDoc['role'];
    } catch (e) {
      print("Error login: $e");
      return null;
    }
  }
}