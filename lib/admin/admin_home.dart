import 'package:flutter/material.dart';
import 'admin_user_screen.dart';

// ================= ENUM HALAMAN =================
enum AdminPage { dashboard, users }

// ================= MAIN ADMIN =================
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  AdminPage activePage = AdminPage.dashboard;

  // ================= SIDEBAR ITEM =================
  Widget _sideItem(
      IconData icon, AdminPage page, Color primaryColor) {
    return IconButton(
      icon: Icon(
        icon,
        color: activePage == page
            ? Colors.white
            : Colors.white70,
      ),
      onPressed: () {
        setState(() {
          activePage = page;
        });
      },
    );
  }

  // ================= KONTEN HALAMAN =================
  Widget _buildContent() {
    switch (activePage) {
      case AdminPage.dashboard:
        return const Center(
          child: Text(
            "Dashboard Admin 👩‍🍳",
            style: TextStyle(fontSize: 18),
          ),
        );

      case AdminPage.users:
        return const AdminUserScreen(); // nanti kita pindah ke file lain
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final bgColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,

      // ================= MOBILE NAV =================
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: activePage.index,
              onTap: (i) {
                setState(() {
                  activePage = AdminPage.values[i];
                });
              },
              selectedItemColor: primary,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.people), label: "User"),
              ],
            )
          : null,

      // ================= BODY =================
      body: isMobile
          ? _buildContent()
          : Row(
              children: [
                // ================= SIDEBAR =================
                Container(
                  width: 80,
                  decoration: BoxDecoration(
                    color: primary, // 🔥 pakai warna theme
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _sideItem(Icons.home, AdminPage.dashboard, primary),
                      _sideItem(Icons.people, AdminPage.users, primary),
                    ],
                  ),
                ),

                // ================= CONTENT =================
                Expanded(child: _buildContent()),
              ],
            ),
    );
  }
}