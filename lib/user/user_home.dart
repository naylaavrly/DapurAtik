import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final List<Widget> pages = [
    const Center(child: Text("Halaman Home")),
    const Center(child: Text("Halaman History")),
    const Center(child: Text("Halaman Profile")),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Column(
        children: [

          // 🔥 NAVBAR ATAS
          _buildNavbar(),

          Expanded(
            child: Stack(
              children: [

                // 🔥 CONTENT + GREETING
                Positioned.fill(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            "${getGreeting()}, ${getUserName()} 👋🏻",
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Expanded(
                        child: pages[selectedIndex],
                      ),
                    ],
                  ),
                ),

                // 🔥 DOCK BAWAH
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
                          _dockItem(Icons.history, 1, "History"),
                          _dockItem(Icons.person, 2, "Profile"),
                          _dockItem(Icons.logout, 3, "Logout"),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 NAVBAR ATAS
  Widget _buildNavbar() {
    return Container(
      width: double.infinity,
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
        onTap: () async {

          // 🔥 LOGOUT
          if (index == 3) {
            final confirm = await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Logout"),
                content: const Text("Yakin mau logout?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Batal"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Logout"),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            }

            return;
          }

          // 🔥 NAVIGASI BIASA
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