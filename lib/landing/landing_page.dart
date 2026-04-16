import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/auth_choice/auth_choice_screen.dart';
import 'menu_page.dart';
import '../user/user_home.dart';

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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MenuPage(),
                    ),
                  );
                },
                child: const Text("Menu", style: TextStyle(color: Colors.white)),
              ),

              TextButton(
                onPressed: () => _scrollToSection(_kontakKey),
                child: const Text("Kontak", style: TextStyle(color: Colors.white)),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthChoiceScreen(),
                    ),
                  );
                },
                child: const Text("Pesan", style: TextStyle(color: Colors.black)),
              )
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

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF61100D),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuthChoiceScreen(),
                    ),
                  );
                },
                child: const Text("Pesan Sekarang", style: TextStyle(color: Colors.white)),
              ),

              const SizedBox(width: 10),

              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MenuPage(),
                    ),
                  );
                },
                child: const Text("Lihat Menu"),
              ),
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

          Row(
            children: [
              Expanded(child: _menuCard("Ayam Geprek")),
              const SizedBox(width: 10),
              Expanded(child: _menuCard("Ayam Bakar")),
              const SizedBox(width: 10),
              Expanded(child: _menuCard("Nasi Goreng")),
              const SizedBox(width: 10),
              Expanded(child: _menuCard("Paket Hemat")),
            ],
          ),
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
              Text("0812-3456-7890", style: TextStyle(color: Colors.white)),
            ],
          ),

          SizedBox(height: 10),

          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Jl. Mawar No. 123, Bekasi Timur",
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
            "© 2024 Mbak Atik Catering. All rights reserved.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= CARD =================
  Widget _menuCard(String title) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(height: 10),
          Text(title),
        ],
      ),
    );
  }
}