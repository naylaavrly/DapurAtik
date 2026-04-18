import 'package:flutter/material.dart';

import 'admin_user_screen.dart';
import 'admin_dashboard.dart';
import 'admin_paket_page.dart';
import 'admin_user_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int selectedIndex = 0;

  // ================= LIST HALAMAN =================
  final List<Widget> pages = [
    const AdminDashboard(), // 0
    const AdminPaketPage(), // 1
    const Center(child: Text("Halaman Pengiriman")), // 2
    const AdminUserScreen(), // 3 → 🔥 PUNYA KAMU
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Stack(
        children: [
          // ================= CONTENT =================
          Positioned.fill(
            child: pages[selectedIndex],
          ),

          // ================= NAVIGATION =================
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
                    _navItem(Icons.restaurant, 1),
                    _navItem(Icons.local_shipping, 2),
                    _navItem(Icons.people, 3),
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

  // ================= NAV ITEM =================
  Widget _navItem(IconData icon, int index) {
    final isActive = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),

        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF7A1C1C).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Icon(
          icon,
          size: 26,
          color: isActive
              ? const Color(0xFF7A1C1C)
              : Colors.grey,
        ),
      ),
    );
  }

  // ================= LOGOUT =================
  Widget _logoutItem() {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.logout, color: Colors.grey),
      ),
    );
  }
}