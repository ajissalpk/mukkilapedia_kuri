import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive_utils.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Dark Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: responsive.sizeFromMinDimension(18),
              height: responsive.sizeFromMinDimension(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFFD700), 
                  width: responsive.spacing(3),
                ),
                image: const DecorationImage(
                  image: AssetImage('assets/images/app_logo.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: responsive.spacing(20),
                    spreadRadius: responsive.spacing(5),
                  )
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(30)),
            Text(
              "MUKKILAPEDIA",
              style: GoogleFonts.outfit(
                fontSize: responsive.fontSize(28),
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: const Color(0xFFFFD700),
              ),
            ),
            SizedBox(height: responsive.spacing(10)),
            Text(
              "LUCKY DRAW",
              style: GoogleFonts.outfit(
                fontSize: responsive.fontSize(16),
                letterSpacing: 4,
                color: Colors.white70
              ),
            ),
            SizedBox(height: responsive.spacing(100)),
            CircularProgressIndicator(
              color: const Color(0xFFFFD700),
              strokeWidth: responsive.spacing(3),
            ),
            const Spacer(),
            Text(
              "Powered by Mukkilapedia Team",
              style: TextStyle(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
                fontSize: responsive.fontSize(12),
              ),
            ),
            SizedBox(height: responsive.spacing(40)),
          ],
        ),
      ),
    );
  }
}
