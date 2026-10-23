import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import 'data/course_repository.dart';
import 'data/material_model.dart';
import '../../core/services/payment_status_service.dart';
import '../../core/widgets/expiry_dialog.dart';
import '../auth/data/auth_repository.dart';
import '../../core/providers/payment_provider.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailScreen({super.key, required this.course});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  bool _isPurchased = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPurchaseStatus();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkPurchaseStatus() async {
    final subjectName = widget.course['subject'] ?? widget.course['title'] ?? '';
    final year = widget.course['year'] as String? ?? '';
    
    final unlocked = await ref.read(courseRepositoryProvider).fetchUnlockedSubjectNames();
    final isUnlocked = unlocked.contains(subjectName) || unlocked.contains('ALL_$year');
    
    if (mounted) {
      setState(() {
        _isPurchased = isUnlocked;
        _isLoading = false;
      });
    }
  }

  void _handleAction() async {
    // Re-check plan active status
    final isPlanActive = await ref.read(paymentStatusServiceProvider).isPlanActive();
    final prefs = await ref.read(paymentStatusServiceProvider).getPurchaseDetails();
    final wasPurchased = prefs['is_purchased'] ?? false;

    if (wasPurchased && !isPlanActive) {
      if (mounted) {
        showExpiryDialog(context, ref);
      }
      return;
    }

    if (_isPurchased) {
      if (mounted) {
        context.push(
          '/file_viewer',
          extra: MaterialModel(
            id: widget.course['id'] as String? ?? '',
            year: widget.course['year'] as String? ?? '',
            subject: widget.course['subject'] as String? ?? '',
            fileName: widget.course['title'] as String? ?? 'document',
            fileUrl: widget.course['file_url'] as String? ?? '',
            storagePath: '',
            mediaType: 'pdf',
            title: widget.course['title'] as String?,
            imagePath: null,
            videoPath: null,
            createdAt: DateTime.now(),
          ),
        );
      }
    } else {
      if (_isLoading) return;

      final priceRaw = widget.course['price'];
      final price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;
      final subjectName = widget.course['subject'] ?? widget.course['title'] ?? 'Course';
      final profile = ref.read(userProfileProvider).value;

      final paymentService = ref.read(paymentServiceProvider);
      
      paymentService.init(
        onSuccess: (paymentId, orderId) async {
          setState(() => _isLoading = true);
          try {
            await ref.read(courseRepositoryProvider).purchaseCourse(
              subjectName: subjectName,
              courseId: widget.course['id'] as String,
              paymentId: paymentId,
              amount: price.toInt(),
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
                ),
              );
              _checkPurchaseStatus();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error syncing: $e')));
            }
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        },
        onFailure: (message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: $message')));
          }
        },
      );

      try {
        await paymentService.purchaseSubject(
          subjectId: widget.course['id'] as String,
          subjectName: subjectName,
          amount: price,
          userEmail: profile?['email'] ?? '',
          userName: profile?['name'] ?? '',
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.course['title'] as String? ?? 'Course';
    final priceRaw = widget.course['price'];
    final price = priceRaw is num ? priceRaw.toDouble() : double.tryParse(priceRaw.toString()) ?? 0.0;
    final year = widget.course['year'] as String? ?? '';
    final subject = widget.course['subject'] as String? ?? 'Unani Subject';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 240,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFF4A5FD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 80, color: Colors.white),
                  const SizedBox(height: 16),
                  if (year.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'B.U.M.S $year',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subject,
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      if (!_isPurchased)
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentColor,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 4),
                      Text('4.9 (250+ Students)', style: Theme.of(context).textTheme.bodyLarge),
                      const Spacer(),
                      if (_isPurchased)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Owned',
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('What\'s Included', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _featureTile(Icons.description_outlined, 'Full HD Concept Notes'),
                  _featureTile(Icons.lightbulb_outline, 'Key Exam Points & Mnemonics'),
                  _featureTile(Icons.help_outline, 'Previous Year Important Qs'),
                  _featureTile(Icons.image_outlined, 'Clear Hand-drawn Diagrams'),
                  _featureTile(Icons.update, 'Lifetime Updates'),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('About Material', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    'This is a premium, expert-curated B.U.M.S study material for $title. '
                    'Designed by Unani Academy to help you master complex subjects with ease. '
                    'Perfect for exam preparation and quick revision.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPurchased ? Colors.green : AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isPurchased ? Icons.menu_book : Icons.shopping_cart),
                        const SizedBox(width: 12),
                        Text(
                          _isPurchased ? 'VIEW MATERIAL' : 'BUY NOW — ₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
