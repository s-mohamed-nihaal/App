import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_data.dart';
import '../../core/widgets/premium_image.dart';
import 'data/course_repository.dart';
import 'data/course_model.dart';
import '../../core/services/payment_status_service.dart';
import '../auth/data/auth_repository.dart';
import '../../core/providers/payment_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildPremiumHeader(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildYearList('First Year'),
                _buildYearList('Second Year'),
                _buildYearList('Final Year'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 60, bottom: 20, left: 24, right: 24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Study Materials',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Master your BUMS subjects with expert notes',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'First Year'),
                Tab(text: 'Second Year'),
                Tab(text: 'Final Year'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearList(String year) {
    final coursesAsync = ref.watch(coursesByYearProvider(year));
    final unlockedAsync = ref.watch(unlockedSubjectsProvider);

    return coursesAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 4,
        itemBuilder: (context, index) => const _SkeletonSubjectCard(),
      ),
      error: (e, _) => Center(child: Text('Error loading subjects: $e')),
      data: (courses) {
        final filteredCourses = courses.where((c) =>
          !c.title.toLowerCase().contains('combo') &&
          !c.title.toLowerCase().contains('package')).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(coursesByYearProvider(year));
            ref.invalidate(unlockedSubjectsProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            physics: const BouncingScrollPhysics(),
            itemCount: filteredCourses.length,
            itemBuilder: (context, index) {
              final course = filteredCourses[index];
              final subjectNameForMatching = course.subject ?? course.title;
              final isUnlocked = unlockedAsync.maybeWhen(
                data: (set) => set.contains(subjectNameForMatching) || set.contains('ALL_$year'),
                orElse: () => false,
              );

              final subjectIdToMatch = course.subjectId;
              final subjectName = (course.subject ?? course.title);
              
              final staticSubject = AppData.curriculum[year]?.firstWhere(
                (s) => s.id == subjectIdToMatch,
                orElse: () => AppData.curriculum[year]!.firstWhere(
                  (s) => s.name.toLowerCase() == subjectName.toLowerCase(),
                  orElse: () => AppData.curriculum[year]!.first,
                ),
              );

              return _PremiumSubjectCard(
                course: course,
                isUnlocked: isUnlocked,
                imageUrl: staticSubject?.imageUrl ?? '',
              );
            },
          ),
        );
      },
    );
  }
}

class _PremiumSubjectCard extends StatefulWidget {
  final Course course;
  final bool isUnlocked;
  final String imageUrl;

  const _PremiumSubjectCard({
    required this.course,
    required this.isUnlocked,
    required this.imageUrl,
  });

  @override
  State<_PremiumSubjectCard> createState() => _PremiumSubjectCardState();
}

class _PremiumSubjectCardState extends State<_PremiumSubjectCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap(WidgetRef ref) async {
    if (_isUpdating) return;
    
    final subjectName = widget.course.subject ?? widget.course.title;
    
    if (widget.isUnlocked) {
      if (mounted) {
        context.push(
          '/subject_materials',
          extra: {
            'year': widget.course.year, 
            'subject': subjectName,
            'subject_id': widget.course.subjectId, // Pass subject_id
          },
        );
      }
      return;
    }
    
    final user = Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      if (mounted) context.push('/login');
      return;
    }

    setState(() => _isUpdating = true);

    try {
      // 1. Check purchases table for active subscription
      final data = await Supabase.instance.client
          .from('purchases')
          .select()
          .eq('user_id', user.id)
          .eq('course_name', subjectName)
          .order('purchased_at', ascending: false)
          .limit(1);

      if (data.isNotEmpty) {
        final purchase = data.first;
        final validUntilStr = purchase['valid_until'] as String?;
        final status = purchase['status'] as String? ?? 'active';
        
        final validUntil = validUntilStr != null ? DateTime.tryParse(validUntilStr) : null;
        final isActive = validUntil != null && DateTime.now().isBefore(validUntil) && status == 'active';

        if (isActive) {
          // Valid active purchase exists
          setState(() => _isUpdating = false);
          if (mounted) {
            context.push(
              '/subject_materials',
              extra: {
                'year': widget.course.year, 
                'subject': subjectName,
                'subject_id': widget.course.subjectId, // Pass subject_id
              },
            );
          }
          return;
        } else {
          // Purchase exists but is expired
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Subscription Expired. Please repurchase to access.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error validating subscription: $e');
    }

    // No valid purchase found or expired, proceed to payment
    _initiatePayment(ref, subjectName);
  }

  void _initiatePayment(WidgetRef ref, String subjectName) async {
    final profile = ref.read(userProfileProvider).value;
    final paymentService = ref.read(paymentServiceProvider);

    paymentService.init(
      onSuccess: (paymentId, orderId) async {
        setState(() => _isUpdating = true);
        try {
          await ref.read(courseRepositoryProvider).purchaseCourse(
            subjectName: subjectName,
            courseId: widget.course.id,
            paymentId: paymentId,
            amount: widget.course.price.toInt(),
          );

          await ref.read(paymentStatusServiceProvider).savePurchase(
            paymentId: paymentId,
            orderId: orderId,
            bundleName: subjectName,
          );

          ref.invalidate(unlockedSubjectsProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment successful! $subjectName unlocked for 30 days.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error syncing purchase: $e')));
          }
        } finally {
          if (mounted) setState(() => _isUpdating = false);
        }
      },
      onFailure: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $message')));
        }
      }
    );

    try {
      await paymentService.purchaseSubject(
        subjectId: widget.course.id,
        subjectName: subjectName,
        amount: widget.course.price.toDouble(),
        userEmail: profile?['email'] ?? '',
        userName: profile?['phone'] ?? profile?['contact'] ?? '',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) => GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          _onTap(ref);
        },
        onTapCancel: () => _controller.reverse(),
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: PremiumImage(
                    imageUrl: widget.imageUrl,
                    width: 72,
                    height: 72,
                    borderRadius: 14,
                    fallbackIcon: Icons.menu_book_rounded,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.course.subject ?? widget.course.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.isUnlocked ? 'Unlocked ✓' : 'Tap to unlock',
                        style: TextStyle(
                            color: widget.isUnlocked ? Colors.green : Colors.grey,
                            fontSize: 12,
                            fontWeight: widget.isUnlocked ? FontWeight.bold : FontWeight.normal),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: _buildActionState(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionState() {
    if (_isUpdating) {
      return const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
    }

    return widget.isUnlocked ? _buildArrow() : _buildPriceButton();
  }

  Widget _buildArrow() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: const Icon(Icons.arrow_forward_rounded, size: 22, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPriceButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(30), // Pill shape
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Text(
        '₹${widget.course.price.toInt()}',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _SkeletonSubjectCard extends StatefulWidget {
  const _SkeletonSubjectCard();

  @override
  State<_SkeletonSubjectCard> createState() => _SkeletonSubjectCardState();
}

class _SkeletonSubjectCardState extends State<_SkeletonSubjectCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(opacity: 0.4 + (_controller.value * 0.4), child: child),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 104,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16))),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 16, width: 140, color: Colors.grey.shade200),
                  const SizedBox(height: 8),
                  Container(height: 12, width: 100, color: Colors.grey.shade200),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
