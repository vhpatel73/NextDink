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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    // 15 second slow breathing animation for the ambient glassmorphism orbs
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 15))
      ..repeat(reverse: true);

    _scrollController = ScrollController();
    
    // Smoothly center the middle card after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final viewportWidth = _scrollController.position.viewportDimension;
        // Calculation: Card1 (260) + Gap (16) + Half of Card2 (130) = 406
        final centerOffset = 406.0 - (viewportWidth / 2);
        _scrollController.jumpTo(centerOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scrollController.dispose();
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // ── Header ──────────────────────────────
                      Text(
                        'NextDink',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -2.0,
                          color: primaryNeon,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'EVOLVE YOUR GAME',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 4.0,
                          color: Colors.white38,
                        ),
                      ),
                      
                      const SizedBox(height: 60),

                      // ── Benefits Section ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Schedule ༚ Play ༚ Dominate',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Horizontal Scrollable Benefits
                      SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            _benefitCard(
                              'Pure Vitality',
                              'Low impact, high energy workouts for longevity.',
                              'assets/vitality.png',
                            ),
                            const SizedBox(width: 16),
                            _benefitCard(
                              'Instant Squad',
                              'The fastest growing community in sports.',
                              'assets/squad.png',
                            ),
                            const SizedBox(width: 16),
                            _benefitCard(
                              'Total Control',
                              'Sharpen your reflexes and dominate the kitchen.',
                              'assets/agility.png',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),

                      // ── Login Button ──────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryNeon.withOpacity(0.3),
                                      blurRadius: 40,
                                      spreadRadius: -5,
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _signIn,
                                  icon: const Icon(Icons.login_rounded, color: Colors.black),
                                  label: const Text('Continue with Google'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryNeon,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
                                    textStyle: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      
                      const SizedBox(height: 40),
                      Text(
                        'Join 10,000+ players worldwide',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white24,
                          fontSize: 12,
                        ),
                      ),
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

  Widget _benefitCard(String title, String desc, String assetPath) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              assetPath,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
