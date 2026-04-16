import 'package:flutter/material.dart';
import '../services/auth_service.dart';

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
    const AdminDashboard(),
    const Center(child: Text("Halaman Pengiriman")),
    const AdminPaketPage(),
    const AdminUserPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Row(
        children: [

          // 🔥 SIDEBAR (FIX WARNA)
          Container(
            width: 90,
            color: const Color(0xFF7A1C1C),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                _menuItem(Icons.home, 0),
                _menuItem(Icons.local_shipping, 1),
                _menuItem(Icons.restaurant_menu, 2),
                _menuItem(Icons.people, 3),

                const SizedBox(height: 40),

                IconButton(
                  onPressed: () async {
                    await AuthService().logout();
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          // 🔥 CONTENT (TANPA HEADER MERAH)
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: IconButton(
        onPressed: () {
          setState(() {
            selectedIndex = index;
          });
        },
        icon: Icon(
          icon,
          size: 30,
          color: selectedIndex == index
              ? Colors.white
              : Colors.white70,
        ),
      ),
    );
  }
}