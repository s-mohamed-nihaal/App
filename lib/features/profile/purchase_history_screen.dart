import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  List<Map<String, dynamic>> _purchases = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      setState(() => _isLoading = true);

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() { _isLoading = false; _purchases = []; });
        return;
      }

      debugPrint('Fetching purchases for user: ${user.id}');

      final response = await Supabase.instance.client
          .from('purchases')
          .select('*')
          .eq('user_id', user.id)
          .order('purchased_at', ascending: false);

      debugPrint('Purchases fetched: $response');

      if (mounted) {
        setState(() {
          _purchases = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('FETCH PURCHASES ERROR: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _purchases = [];
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Purchase History', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error loading history: $_error'));
    }

    if (_purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No purchases found',
              style: TextStyle(
                color: AppTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your course transactions will appear here.',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        final purchase = _purchases[index];
        final courseName = purchase['course_name'] ?? 'Unknown Course';
        final amount = purchase['amount'] ?? 0;
        final paymentId = purchase['payment_id'] ?? 'N/A';
        
        final purchasedAtStr = purchase['purchased_at'] as String?;
        final validUntilStr = purchase['valid_until'] as String?;
        
        final purchasedAt = purchasedAtStr != null ? DateTime.tryParse(purchasedAtStr) : null;
        final validUntil = validUntilStr != null ? DateTime.tryParse(validUntilStr) : null;
        
        final isActive = validUntil != null && DateTime.now().isBefore(validUntil);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        courseName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isActive ? 'ACTIVE' : 'EXPIRED',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Course Access',
                      style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '₹$amount',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: $paymentId',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade100, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDateColumn('Purchased On', purchasedAt),
                    _buildDateColumn('Valid Until', validUntil),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateColumn(String label, DateTime? date) {
    final dateStr = date != null ? '${date.day}/${date.month}/${date.year}' : '--';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textPrimaryColor),
            const SizedBox(width: 4),
            Text(dateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        )
      ],
    );
  }
}
