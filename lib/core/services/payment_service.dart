import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'razorpay_service.dart';

class PaymentService {
  final RazorpayService _razorpay = getRazorpayService();
  final String razorpayKey = 'rzp_live_TsZwzdte4V7LHz';

  // State to track current purchase for success handler
  Function(String paymentId, String orderId)? _onExternalSuccess;
  Function(String message)? _onExternalError;

  String? _selectedCourseName;
  int? _selectedCourseAmount;

  void init({
    Function(String paymentId, String orderId)? onSuccess,
    Function(String message)? onFailure,
  }) {
    _onExternalSuccess = onSuccess;
    _onExternalError = onFailure;

    _razorpay.onSuccess = (paymentId, orderId) {
      _handlePaymentSuccess(paymentId, orderId);
    };
    _razorpay.onError = (message) {
      _handlePaymentError(message);
    };
    _razorpay.init();
  }

  Future<void> purchaseBundle({
  required String bundleId,
  required String bundleName,
  required double amount,
  required String userEmail,
  required String userName,
}) async {
  _selectedCourseName = bundleName;
  _selectedCourseAmount = amount.toInt();

  await _createOrderAndPay(
    amount: amount,
    type: 'bundle',
    itemId: bundleId,
    description: 'Bundle: $bundleName',
    userEmail: userEmail,
    userName: userName,
  );
}

  Future<void> purchaseBundle({
    required String bundleId,
    required String bundleName,
    required double amount,
    required String userEmail,
    required String userName,
  }) async {
    _selectedCourseName = bundleName;
    _selectedCourseAmount = amount.toInt();
    await _createOrderAndPay(
      'amount': amountInPaise,
      type: 'bundle',
      itemId: bundleId,
      description: 'Bundle: $bundleName',
      userEmail: userEmail,
      userName: userName,
    );
  }

  Future<void> _createOrderAndPay({
    required double amount,
    required String type,
    required String itemId,
    required String description,
    required String userEmail,
    required String userName,
  }) async {
    try {
      debugPrint('Creating Razorpay Order via Edge Function... Type: $type, Item: $itemId');
      
      final amountInPaise = (amount * 100).round();

      final response = await Supabase.instance.client.functions.invoke(
        'create-razorpay-order',
        body: {
          'amount': amountInPaise,
          'currency': 'INR',
          'type': type,
          'itemId': itemId,
          'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (response.data == null || response.data['id'] == null) {
        final errorMsg = response.data?['error'] ?? 'Order creation failed';
        debugPrint('Edge Function Error: $errorMsg');
        throw Exception(errorMsg);
      }

      final orderId = response.data['id'] as String;

      debugPrint('Opening Razorpay Checkout with OrderID: $orderId');
      await _razorpay.openCheckout(
        amountInPaise: amountInPaise,
        name: 'Unani Academy',
        description: description.length > 255 ? description.substring(0, 255) : description,
        email: userEmail,
        contact: '',
        orderId: orderId,
      );
    } catch (e) {
      debugPrint('Payment Service Error: $e');
      _onExternalError?.call(e.toString());
      rethrow;
    }
  }

  void _handlePaymentSuccess(String paymentId, String orderId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('ERROR: No logged in user found');
        _onExternalSuccess?.call(paymentId, orderId);
        return;
      }

      debugPrint('Payment success: $paymentId');
      debugPrint('Saving purchase for user: ${user.id}');
      debugPrint('Course: $_selectedCourseName, Amount: $_selectedCourseAmount');

      final insertData = {
        'user_id': user.id,
        'course_name': _selectedCourseName ?? 'Unknown',
        'amount': _selectedCourseAmount ?? 0,
        'payment_id': paymentId.isNotEmpty ? paymentId : 'N/A',
        'purchased_at': DateTime.now().toIso8601String(),
        'valid_until': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
        'status': 'active',
      };

      debugPrint('Inserting: $insertData');

      await Supabase.instance.client
          .from('purchases')
          .insert(insertData);

      _onExternalSuccess?.call(paymentId, orderId);
    } catch (e) {
      debugPrint('PURCHASE SAVE ERROR: $e');
      // Even if saving to remote database encounters an issue, notify caller so UI stops loading
      _onExternalSuccess?.call(paymentId, orderId);
    }
  }

  void _handlePaymentError(String message) {
    debugPrint('Razorpay Error: $message');
    _onExternalError?.call(message);
  }

  void dispose() {
    _razorpay.dispose();
  }
}
