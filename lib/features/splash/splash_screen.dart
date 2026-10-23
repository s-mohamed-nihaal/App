import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/payment_status_service.dart';
import '../../core/widgets/expiry_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();

    // Handle navigation after splash animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkSessionAndNavigate();
      }
    });

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (!mounted) return;
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Delay slightly to avoid router conflicts during build
        Future.microtask(() {
          if (mounted) _checkSessionAndNavigate();
        });
      } else if (event == AuthChangeEvent.signedOut) {
        Future.microtask(() {
          if (mounted) context.go('/login');
        });
      }
    });
  }

  Future<void> _checkSessionAndNavigate() async {
    final payment = ref.read(paymentStatusServiceProvider);
    final currentUser = Supabase.instance.client.auth.currentSession?.user;
    
    if (currentUser == null) {
      context.go('/login');
    } else {
      // Check if plan was active but now expired
      final prefs = await payment.getPurchaseDetails();
      final isPurchased = prefs['is_purchased'] ?? false;
      
      if (isPurchased) {
        final expiryStr = prefs['expiry_date'];
        if (expiryStr != null) {
          final expiryDate = DateTime.parse(expiryStr);
          if (DateTime.now().isAfter(expiryDate)) {
            // Plan expired!
            if (mounted) {
              // We still go to home, but show the dialog immediately
              context.go('/home');
              Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                 showExpiryDialog(context, ref);
              }
              });
              return;
            }
          }
        }
      }
      
      // Either not purchased, or still active
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white, // White background to make the logo pop
        ),
        child: Stack(
          children: [
            // Subtle decorative elements
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFF3F51B5).withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // The Official Logo
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_rounded, size: 80, color: Color(0xFF3F51B5)),
                            SizedBox(height: 8),
                            Text('UNANI', style: TextStyle(color: Color(0xFF3F51B5), fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'UNANI ACADEMY',
                      style: TextStyle(
                        color: Color(0xFF3F51B5), // Matching the logo blue
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Learn BUMS the Smart Way',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3F51B5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

