import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/payment_status_service.dart';
import '../courses/data/course_repository.dart';
import '../courses/data/course_model.dart';
import '../auth/data/auth_repository.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allCoursesAsync = ref.watch(allCoursesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroHeader(context),
            allCoursesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(50.0),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Center(child: Text('Error loading bundles: $e')),
              data: (courses) {
                final year1Combo = courses.firstWhere((c) => c.title == 'First Year Combo Package',
                    orElse: () => Course(id: '', title: 'First Year Combo', price: 800, year: 'First Year', fileUrl: '', createdAt: DateTime.now()));
                final year2Combo = courses.firstWhere((c) => c.title == 'Second Year Combo Package',
                    orElse: () => Course(id: '', title: 'Second Year Combo', price: 999, year: 'Second Year', fileUrl: '', createdAt: DateTime.now()));
                final finalYearCombo = courses.firstWhere((c) => c.title == 'Final Year Combo Package',
                    orElse: () => Course(id: '', title: 'Final Year Combo', price: 1500, year: 'Final Year', fileUrl: '', createdAt: DateTime.now()));

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                  child: Column(
                    children: [
                      _AnimatedBundleCard(
                        course: year1Combo,
                        subjects: const [
                          'Anatomy',
                          'Physiology',
                          'Tarika-e-Tibb',
                          'Umoor-e-Tabiya',
                          'Mantiq wa Falsafa',
                          'Urdu & Arabic',
                        ],
                        gradientColors: const [Color(0xFF2E3A8C), Color(0xFF5A67D8)],
                      ),
                      const SizedBox(height: 24),
                      _AnimatedBundleCard(
                        course: year2Combo,
                        subjects: const [
                          'Community Medicine',
                          'Pathology',
                          'Sariyath, Forensic & Toxicology',
                          'Ilmul Advia, Mufradat, Saidla',
                          'Murakkabat',
                          'Microbiology',
                        ],
                        gradientColors: const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
                      ),
                      const SizedBox(height: 24),
                      _AnimatedBundleCard(
                        course: finalYearCombo,
                        subjects: const [
                          'Moalijat',
                          'Gynecology & Obstruction',
                          'ENT & Ophthalmology',
                          'Pediatric',
                          'Research Methodology',
                          'IBT, Skin',
                          'Surgery 1 & 2',
                        ],
                        gradientColors: const [Color(0xFFB71C1C), Color(0xFFEF5350)],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 80, bottom: 40, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: const Column(
        children: [
          Text(
            'Unlock Full Potential',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Get bundle access & save more',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AnimatedBundleCard extends ConsumerStatefulWidget {
  final Course course;
  final List<String> subjects;
  final List<Color> gradientColors;

  const _AnimatedBundleCard({
    required this.course,
    required this.subjects,
    required this.gradientColors,
  });

  @override
  ConsumerState<_AnimatedBundleCard> createState() => _AnimatedBundleCardState();
}

class _AnimatedBundleCardState extends ConsumerState<_AnimatedBundleCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isUpdating = false;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(String paymentId, String orderId) async {
    // Sync with Supabase
    await ref.read(courseRepositoryProvider).purchaseBundle(
      yearMarker: 'ALL_${widget.course.year}',
      courseId: widget.course.id,
      paymentId: paymentId,
      amount: widget.course.price.toInt(),
      subjects: widget.subjects,
    );
    
    // Save locally for instant access/offline
    await ref.read(paymentStatusServiceProvider).savePurchase(
      paymentId: paymentId,
      orderId: orderId,
      bundleName: widget.course.title,
    );
    
    ref.invalidate(unlockedSubjectsProvider);

    if (mounted) {
      _showSuccessDialog(paymentId);
    }
  }

  void _handlePaymentError(String message) {
    if (mounted) {
      _showFailureDialog(message);
    }
  }

  void _onUnlock(WidgetRef ref) async {
    if (_isUpdating) return;
    
    setState(() => _isUpdating = true);

    final paymentService = ref.read(paymentServiceProvider);
    final profile = ref.read(userProfileProvider).value;

    paymentService.init(
      onSuccess: (paymentId, orderId) async {
         _handlePaymentSuccess(paymentId, orderId);
         if (mounted) setState(() => _isUpdating = false);
      },
      onFailure: (message) {
        _handlePaymentError(message);
        if (mounted) setState(() => _isUpdating = false);
      },
    );

    try {
      await paymentService.purchaseBundle(
        bundleId: widget.course.id,
        bundleName: widget.course.title,
        amount: widget.course.price.toDouble(),
        userEmail: profile?['email'] ?? '',
        userName: profile?['name'] ?? '',
      );
    } catch (e) {
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
         setState(() => _isUpdating = false);
       }
    }
  }

  void _showSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text('Payment Successful', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your course content has been unlocked for 30 days.', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text('Payment ID: $paymentId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                Navigator.pop(context);
                // Optional: navigate to home or content
              },
              child: const Text('Start Learning', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showFailureDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
            SizedBox(height: 16),
            Text('Payment Failed', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Okay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _onUnlock(ref);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unlockedAsync = ref.watch(unlockedSubjectsProvider);
    final expiryAsync = ref.watch(paymentStatusServiceProvider).getExpiryDate();
    
    final isAlreadyUnlocked = unlockedAsync.maybeWhen(
      data: (set) => set.contains('ALL_${widget.course.year}'),
      orElse: () => false,
    );

    return GestureDetector(
      onTapDown: (_) => !isAlreadyUnlocked ? _controller.forward() : null,
      onTapUp: (_) {
        _controller.reverse();
        if (!isAlreadyUnlocked) {
          _onUnlock(ref);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bundle already purchased! All subjects unlocked.')));
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.gradientColors.first.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: isAlreadyUnlocked ? Colors.green.withValues(alpha: 0.5) : widget.gradientColors.first.withValues(alpha: 0.1),
              width: 2.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isAlreadyUnlocked ? [Colors.green, Colors.greenAccent] : widget.gradientColors),
                  ),
                  child: Center(
                    child: Text(
                      isAlreadyUnlocked ? 'YEAR UNLOCKED ✓' : widget.course.title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'One-time Payment',
                            style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₹${widget.course.price.toInt()}',
                            style: TextStyle(
                              color: isAlreadyUnlocked ? Colors.green : widget.gradientColors.first,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      ...widget.subjects.map((subject) => _buildSubjectRow(subject, isAlreadyUnlocked)),
                      const SizedBox(height: 24),
                      // Razorpay Badge
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.security, color: Colors.blueAccent, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Secured by Razorpay — UPI, Cards, Net Banking, Wallets',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isAlreadyUnlocked)
                        FutureBuilder<DateTime?>(
                          future: expiryAsync,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final date = snapshot.data!;
                              final months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
                              final dateStr = "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Center(
                                  child: Text(
                                    'Access until: $dateStr',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: isAlreadyUnlocked ? null : AppTheme.primaryGradient,
                          color: isAlreadyUnlocked ? Colors.green.withValues(alpha: 0.1) : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isAlreadyUnlocked ? null : [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          border: isAlreadyUnlocked ? Border.all(color: Colors.green.withValues(alpha: 0.5), width: 1.5) : null,
                        ),
                        child: Center(
                          child: _isUpdating 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isAlreadyUnlocked)
                                    const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
                                  if (isAlreadyUnlocked)
                                    const SizedBox(width: 8),
                                  Text(
                                    isAlreadyUnlocked ? 'YEAR UNLOCKED' : (widget.course.title.toLowerCase().contains('combo') ? 'Subscribe Now' : 'Buy Now'),
                                    style: TextStyle(
                                      color: isAlreadyUnlocked ? Colors.green : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectRow(String title, bool isUnlocked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: (isUnlocked ? Colors.green : widget.gradientColors.first).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check, size: 14, color: isUnlocked ? Colors.green : widget.gradientColors.first),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
