import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {

  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool isLoading = false;

  String? errorMessage; // 🔥 ERROR DI DALAM KOTAK

  Future<void> register() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null; // reset error
    });

    try {
      await _authService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      setState(() => isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );

    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;

        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = "Email sudah terdaftar";
            break;
          case 'invalid-email':
            errorMessage = "Format email tidak valid";
            break;
          case 'weak-password':
            errorMessage = "Password minimal 6 karakter";
            break;
          default:
            errorMessage = "Terjadi kesalahan, coba lagi";
        }
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error tidak diketahui";
      });
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                ),
              ],
            ),

            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Text(
                    "Register",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B0000),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 🔥 ERROR MESSAGE (CANTIK, GA DOUBLE)
                  if (errorMessage != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // 🔥 NAME
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: "Nama",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Nama wajib diisi";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🔥 EMAIL
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Email wajib diisi";
                      }
                      if (!v.contains('@')) {
                        return "Format email tidak valid";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // 🔥 PASSWORD
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return "Password wajib diisi";
                      }
                      if (v.length < 6) {
                        return "Minimal 6 karakter";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Register"),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Sudah punya akun? Login",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}