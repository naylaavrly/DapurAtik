import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../user/user_home.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';

class Landingpage extends StatefulWidget {
  const Landingpage({super.key});

  @override
  State<Landingpage> createState() => _LandingpageState();
}

class _LandingpageState extends State<Landingpage> {

  final ScrollController _scrollController = ScrollController();

  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _kontakKey = GlobalKey();
  bool showDropdown = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  void _checkLogin() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const UserHome()),
        );
      });
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Column(
        children: [

          _buildNavbar(),

          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [

                  Container(key: _homeKey, child: _buildHero()),
                  Container(key: _menuKey, child: _buildMenu()),
                  Container(key: _kontakKey, child: _buildFooter()),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // ================= NAVBAR =================
  Widget _buildNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      color: const Color(0xFF61100D),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Mbak Atik Catering",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          Row(
            children: [
              TextButton(
                onPressed: () => _scrollToSection(_homeKey),
                child: const Text("Home", style: TextStyle(color: Colors.white)),
              ),

              // 🔥 FIX DI SINI
              TextButton(
                onPressed: () => _scrollToSection(_menuKey),
                child: const Text("Menu", style: TextStyle(color: Colors.white)),
              ),

              TextButton(
                onPressed: () => _scrollToSection(_kontakKey),
                child: const Text("Kontak", style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ================= HERO =================
  Widget _buildHero() {
  return Container(
    color: const Color(0xFFFFFFFF),
    padding: const EdgeInsets.all(30),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF61100D)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "Terpercaya Sejak 1996",
            style: TextStyle(
              color: Color(0xFF61100D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          "Catering rumahan berkualitas untuk setiap momen spesial Anda",
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        const Text(
          "Menu lezat dengan cita rasa rumahan, harga terjangkau, dan pelayanan terpercaya",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),

        const SizedBox(height: 20),

        // 🔥 BAGIAN BUTTON + DROPDOWN
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🔥 KIRI (PESAN + DROPDOWN)
            Column(
              children: [

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF61100D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      showDropdown = !showDropdown;
                    });
                  },
                  child: const Text("Pesan Sekarang"),
                ),

                const SizedBox(height: 8),

                if (showDropdown)
                  Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 6)
                      ],
                    ),
                    child: Column(
                      children: [

                        InkWell(
                          onTap: () {
                            setState(() => showDropdown = false);
                            showDialog(
                              context: context,
                              builder: (_) => const Dialog(
                                child: SizedBox(width: 400, child: LoginPage()),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.login, color: Color(0xFF61100D)),
                                SizedBox(width: 10),
                                Text("Login"),
                              ],
                            ),
                          ),
                        ),

                        const Divider(height: 1),

                        InkWell(
                          onTap: () {
                            setState(() => showDropdown = false);
                            showDialog(
                              context: context,
                              builder: (_) => const Dialog(
                                child: SizedBox(width: 400, child: RegisterPage()),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.person_add, color: Color(0xFF61100D)),
                                SizedBox(width: 10),
                                Text("Register"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
          ],
        ),
        const SizedBox(height: 30),
      ],
    ),
  );
}

  // ================= MENU (PREVIEW) =================
  Widget _buildMenu() {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Menu Pilihan",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('packages')
                .snapshots(),
            builder: (context, snapshot) {

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text("Belum ada menu");
              }

              final docs = snapshot.data!.docs;

              return SizedBox(
                height: 250,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 20),
                  children: [

                    // 🔥 MENU FIREBASE
                    ...docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 15),
                        child: _menuCard(
                          name: data['name'] ?? '',
                          description: data['description'] ?? '',
                          image: data['image_url'] ?? '',
                          include: List<String>.from(data['include'] ?? []),
                        ),
                      );
                    }).toList(),

                    // 🔥 BUTTON PANAH
                    Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 20),
                      child: Center(
                        child: InkWell(
                          onTap: () {
                            final user = FirebaseAuth.instance.currentUser;

                            if (user == null) {
                              showDialog(
                                context: context,
                                builder: (_) => const Dialog(
                                  child: SizedBox(width: 400, child: LoginPage()),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Masuk ke menu lengkap")),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            width: 45,
                            height: 45,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF61100D),
                            ),
                            child: const Icon(Icons.arrow_forward, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================= FOOTER =================
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF2E2E2E),
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [

          Text("Kontak Kami",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),

          SizedBox(height: 15),

          Row(
            children: [
              Icon(Icons.phone, color: Colors.white),
              SizedBox(width: 10),
              Text("0813-1583-7240", style: TextStyle(color: Colors.white)),
            ],
          ),

          SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Jl. Alun-Alun Selatan, Mustika Jaya, Bekasi, JaBar",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white),
              SizedBox(width: 10),
              Text("Buka setiap hari 08.00 - 20.00", style: TextStyle(color: Colors.white)),
            ],
          ),

          SizedBox(height: 20),

          Text(
            "© 2026 Mbak Atik Catering. All rights reserved.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= CARD =================
  Widget _menuCard({
    required String name,
    required String description,
    required String image,
    required List<String> include,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6DA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          if (image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                image,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.image, size: 40),
            ),

          const SizedBox(height: 10),

          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 5),

          Text(
            description,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 5,
            runSpacing: 6,
            children: include.map((item) {
              return Chip(
                label: Text(item, style: const TextStyle(fontSize: 10)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}