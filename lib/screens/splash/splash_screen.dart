import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth_choice/auth_choice_screen.dart'; // 🔥 ganti ini

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  late AnimationController _iconController;
  late Animation<double> _iconAnimation;

  @override
  void initState() {
    super.initState();

    // 🔥 Animasi teks (slide)
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    // 🔥 Animasi icon
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconAnimation = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.elasticOut),
    );

    _slideController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      _iconController.forward();
    });

    // 🔥 PINDAH KE AUTH CHOICE
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return; // 🔥 biar aman
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
      );
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;

    // 🔥 Responsive
    final titleSize = screenWidth * 0.08;
    final subtitleSize = screenWidth * 0.035;
    final taglineSize = screenWidth * 0.02;
    final iconSize = screenWidth * 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF5E6DA),

      body: Center(
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // 🔥 LOGO TEXT + ICON
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  ScaleTransition(
                    scale: _iconAnimation,
                    child: Icon(
                      Icons.restaurant,
                      size: iconSize,
                      color: const Color(0xFF7A1C1C),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Text(
                    "Mbak Atik",
                    style: GoogleFonts.pacifico(
                      fontSize: titleSize,
                      color: const Color(0xFF7A1C1C),
                    ),
                  ),

                  const SizedBox(width: 10),

                  ScaleTransition(
                    scale: _iconAnimation,
                    child: Icon(
                      Icons.restaurant_menu,
                      size: iconSize,
                      color: const Color(0xFF7A1C1C),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenWidth * 0.03),

              // 🔥 Subtitle
              Text(
                "Catering",
                style: GoogleFonts.poppins(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F1F1F),
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: screenWidth * 0.02),

              // 🔥 Tagline
              Text(
                "Food Delivery Service",
                style: GoogleFonts.poppins(
                  fontSize: taglineSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3A3A3A),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}