import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_home.dart';

class UserProfile extends StatefulWidget {
  const UserProfile({super.key});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final user = FirebaseAuth.instance.currentUser;

  String email = "";
  bool isLoading = true;

  /// 🔥 CONTROLLER BARU
  final addressController = TextEditingController();
  final phoneController = TextEditingController();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool isVerified = false;

  bool showOldPassword = false;
  bool showNewPassword = false;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  /// 🔥 AMBIL DATA USER
  Future<void> getUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final data = doc.data();

    setState(() {
      email = user!.email ?? "";
      addressController.text = data?['address'] ?? "";
      phoneController.text = data?['phone'] ?? "";
      isLoading = false;
    });
  }

  /// 🔥 UPDATE PROFILE (ALAMAT + TELEPON)
  Future<void> updateProfile() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        "address": addressController.text,
        "phone": phoneController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile berhasil diupdate")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  /// 🔥 VALIDASI PASSWORD LAMA
  Future<void> verifyPassword() async {
    try {
      final cred = EmailAuthProvider.credential(
        email: user!.email!,
        password: oldPasswordController.text,
      );

      await user!.reauthenticateWithCredential(cred);

      setState(() => isVerified = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password lama benar")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password lama salah")),
      );
    }
  }

  /// 🔥 UPDATE PASSWORD
  Future<void> updatePassword() async {
    try {
      await user!.updatePassword(newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password berhasil diubah")),
      );

      oldPasswordController.clear();
      newPasswordController.clear();

      setState(() => isVerified = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [

                  /// 🔥 HEADER
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    color: const Color(0xFF61100D),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const UserHome()),
                            );
                          },
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Profile",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  /// 🔥 BODY
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [

                            /// EMAIL
                            TextField(
                              controller:
                                  TextEditingController(text: email),
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Email",
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// 🔥 ALAMAT
                            TextField(
                              controller: addressController,
                              decoration: InputDecoration(
                                labelText: "Address",
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// 🔥 TELEPON
                            TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: "Phone Number",
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            /// 🔥 BUTTON UPDATE PROFILE
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: updateProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF61100D),
                                ),
                                child: const Text("Update Profile"),
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// PASSWORD LAMA
                            TextField(
                              controller: oldPasswordController,
                              obscureText: !showOldPassword,
                              decoration: InputDecoration(
                                labelText: "Password Lama",
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(showOldPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off),
                                  onPressed: () {
                                    setState(() {
                                      showOldPassword =
                                          !showOldPassword;
                                    });
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            ElevatedButton(
                              onPressed: verifyPassword,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF61100D),
                              ),
                              child: const Text("Verifikasi"),
                            ),

                            const SizedBox(height: 20),

                            if (isVerified) ...[
                              TextField(
                                controller: newPasswordController,
                                obscureText: !showNewPassword,
                                decoration: InputDecoration(
                                  labelText: "Password Baru",
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(showNewPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() {
                                        showNewPassword =
                                            !showNewPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              ElevatedButton(
                                onPressed: updatePassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF61100D),
                                ),
                                child: const Text("Ubah Password"),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}