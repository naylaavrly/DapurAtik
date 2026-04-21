import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../landing/menu_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  int selectedIndex = 0;

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  String getUserName() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return "User";

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null) {
      return user.email!.split('@')[0];
    }

    return "User";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Stack(
        children: [

          // ================= CONTENT =================
          Positioned.fill(
            child: Column(
              children: [

                _buildNavbar(),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "${getGreeting()}, ${getUserName()} 👋🏻",
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        _quickActions(),

                        const SizedBox(height: 20),

                        _buildMenu(),

                        const SizedBox(height: 20),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Pesanan Aktif",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        _orderCard("Ayam Geprek", "Diproses"),
                        _orderCard("Paket Hemat", "Selesai"),

                        const SizedBox(height: 100), // biar ga ketutup navbar
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= NAVBAR FLOATING =================
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20,
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),

                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _navItem(Icons.home, 0),
                    _navItem(Icons.menu, 1),
                    _navItem(Icons.receipt_long, 2),
                    _navItem(Icons.person, 3),
                    _logoutItem(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= NAVBAR ATAS =================
  Widget _buildNavbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      color: const Color(0xFF61100D),
      child: Text(
        "Mbak Atik Catering",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  // ================= NAV ITEM =================
  Widget _navItem(IconData icon, int index) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });

        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MenuPage()),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF61100D).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          size: 26,
          color: isActive
              ? const Color(0xFF61100D)
              : Colors.grey,
        ),
      ),
    );
  }

  // ================= LOGOUT =================
  Widget _logoutItem() {
    return GestureDetector(
      onTap: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pop(context);
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.logout, color: Colors.grey),
      ),
    );
  }

  // ================= QUICK ACTION =================
  Widget _quickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [

          _quickItem(
            icon: Icons.restaurant,
            label: "Pesan\nsekarang",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuPage()),
              );
            },
          ),

          _quickItem(
            icon: Icons.menu_book,
            label: "Lihat menu",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuPage()),
              );
            },
          ),

          _quickItem(
            icon: Icons.access_time,
            label: "Status\npesanan",
            onTap: () {
              setState(() => selectedIndex = 2);
            },
          ),
        ],
      ),
    );
  }

  Widget _quickItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF61100D)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ================= MENU =================
  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Menu Pilihan",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('packages').snapshots(),
            builder: (context, snapshot) {

              if (!snapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final docs = snapshot.data!.docs;

              return SizedBox(
                height: 160,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: docs.map((doc) {

                    final data = doc.data() as Map<String, dynamic>;

                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [

                          if (data['image_url'] != "")
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                data['image_url'],
                                height: 80,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),

                          const SizedBox(height: 8),

                          Text(
                            data['name'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );

                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= ORDER =================
  Widget _orderCard(String title, String status) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            status,
            style: TextStyle(
              color: status == "Selesai" ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}