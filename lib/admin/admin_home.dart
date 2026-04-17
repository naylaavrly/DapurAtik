import 'package:flutter/material.dart';

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

  final List<Widget> pages = [
    const AdminDashboard(), // 0 → Home
    const AdminPaketPage(), // 1 → Menu
    const Center(child: Text("Halaman Pengiriman")), // 2 → Pengiriman
    const AdminUserPage(), // 3 → User
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Stack(
        children: [

          // 🔥 CONTENT
          Positioned.fill(
            child: pages[selectedIndex],
          ),

          // 🔥 DOCK BAWAH (MACBOOK STYLE)
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
                    _dockItem(Icons.home, 0, "Home"),
                    _dockItem(Icons.restaurant, 1, "Menu"),
                    _dockItem(Icons.local_shipping, 2, "Pengiriman"),
                    _dockItem(Icons.people, 3, "User"),
                    _dockItem(Icons.logout, 4, "Logout"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 DOCK ITEM
  Widget _dockItem(IconData icon, int index, String label) {
    final isActive = selectedIndex == index;

    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: () {
          if (index == 4) {
            // 🔥 LOGOUT
            Navigator.pop(context);
            return;
          }

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
      ),
    );
  }
}