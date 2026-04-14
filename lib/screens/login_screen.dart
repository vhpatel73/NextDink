import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    // 15 second slow breathing animation for the ambient glassmorphism orbs
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _signIn() async {
    setState(() => _isLoading = true);
    await _authService.signInWithGoogle();
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryNeon = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF050501),
      body: Stack(
        children: [
          // Ambient Background Layer 1: Moving Neon Green Orb
          if (_controller != null) AnimatedBuilder(
            animation: _controller!,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      -0.8 + (_controller!.value * 1.5),
                      -1.0 + (_controller!.value * 0.8),
                    ),
                    radius: 1.5,
                    colors: [
                      primaryNeon.withOpacity(0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Ambient Background Layer 2: Moving Amber Orb
          if (_controller != null) AnimatedBuilder(
            animation: _controller!,
            builder: (context, _) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      0.8 - (_controller!.value * 1.5),
                      1.2 - (_controller!.value * 0.5),
                    ),
                    radius: 1.2,
                    colors: [
                      Colors.amberAccent.withOpacity(0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),

          // Foreground UI
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  
                  // Premium 3D-esque branding (Shadowed icon)
                  Container(
                    decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: primaryNeon.withOpacity(0.2),
                           blurRadius: 40,
                           spreadRadius: 10,
                         )
                       ]
                    ),
                    child: Icon(
                      Icons.sports_tennis_rounded,
                      size: 90,
                      color: primaryNeon,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Aggressive Modern Typography
                  Text(
                    'NextDink',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2.5,
                      color: primaryNeon,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Clean Minimalist Punchline
                  Text(
                    'Schedule, play, and dominate\nthe pickleball court.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: Colors.white70,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const Spacer(flex: 4),
                  
                  // Glowing Neon Button
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryNeon.withOpacity(0.4),
                            blurRadius: 30,
                            spreadRadius: -5,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: primaryNeon.withOpacity(0.2),
                            blurRadius: 60,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _signIn,
                        icon: const Icon(Icons.login_rounded, color: Colors.black),
                        label: Text(
                          'Continue with Google',
                          style: GoogleFonts.inter(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNeon,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0, 
                        ),
                      ),
                    ),
                  const Spacer(flex: 1),
                ],
              ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
