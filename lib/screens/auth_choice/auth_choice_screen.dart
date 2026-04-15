import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/login_page.dart';
import '../../auth/register_page.dart';
import '../../user/user_home.dart';

class AuthChoiceScreen extends StatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  State<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends State<AuthChoiceScreen> {

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  // 🔥 AUTO LOGIN
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Center(
        child: Wrap(
          spacing: 30,
          runSpacing: 20,
          alignment: WrapAlignment.center,
          children: [

            // 🔥 REGISTER
            _buildCard(
              title: "Register",
              subtitle: "Buat akun baru",
              icon: Icons.person_add_alt_1,
              onTap: () => _showRegisterDialog(context),
            ),

            // 🔥 LOGIN
            _buildCard(
              title: "Login",
              subtitle: "Masuk ke akun",
              icon: Icons.login,
              onTap: () => _showLoginDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 CARD UI + ANIMASI
  Widget _buildCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return HoverScaleCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 220,
          height: 160,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),

            // 🔥 GRADIENT SOFT
            gradient: LinearGradient(
              colors: [
                Colors.white,
                const Color(0xFFF3E3DA),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Icon(
                icon,
                size: 40,
                color: const Color(0xFF7A1C1C),
              ),

              const SizedBox(height: 12),

              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E2E2E),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔥 LOGIN MODAL
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => const Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: SizedBox(
          width: 400,
          child: LoginPage(),
        ),
      ),
    );
  }

  // 🔥 REGISTER MODAL
  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => const Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: SizedBox(
          width: 400,
          child: RegisterPage(),
        ),
      ),
    );
  }
}

//////////////////////////////////////////////////////////////
// 🔥 HOVER + SCALE CLASS (SUDAH DIGABUNG DI FILE INI)
//////////////////////////////////////////////////////////////

class HoverScaleCard extends StatefulWidget {
  final Widget child;

  const HoverScaleCard({super.key, required this.child});

  @override
  State<HoverScaleCard> createState() => _HoverScaleCardState();
}

class _HoverScaleCardState extends State<HoverScaleCard> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    double scale = 1.0;

    if (isPressed) {
      scale = 0.95;
    } else if (isHovered) {
      scale = 1.05;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: scale,
          child: widget.child,
        ),
      ),
    );
  }
}