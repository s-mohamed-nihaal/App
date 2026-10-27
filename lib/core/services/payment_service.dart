```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'razorpay_service.dart';

class PaymentService {
  final RazorpayService _razorpay = getRazorpayService();

  // Callbacks
  Function(String paymentId, String orderId)? _onExternalSuccess;
  Function(String message)? _onExternalError;

  // Current purchase details
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

  Future<void> purchaseSubject({
    required String subjectId,
    required String subjectName,
    required double amount,
    required String userEmail,
    required String userName,
  }) async {
    _selectedCourseName = subjectName;
    _selectedCourseAmount = amount.round();

    await _createOrderAndPay(
      amount: amount,
      type: 'subject',
      itemId: subjectId,
      description: 'Unlock Subject: $subjectName',
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
    _selectedCourseAmount = amount.round();

    await _createOrderAndPay(
      amount: amount,
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
      if (!amount.isFinite || amount <= 0) {
        throw ArgumentError('Invalid payment amount');
      }

      // Convert rupees to paise exactly once.
      final int amountInPaise = (amount * 100).round();

      debugPrint(
        'Creating Razorpay order: type=$type, itemId=$itemId',
      );

      final response =
          await Supabase.instance.client.functions.invoke(
        'create-razorpay-order',
        body: {
          'amount': amountInPaise,
          'currency': 'INR',
          'type': type,
          'itemId': itemId,
          'receipt':
              'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final data = response.data;

      if (data == null ||
          data is! Map ||
          data['id'] == null ||
          data['id'] is! String) {
        final errorMessage =
            data is Map && data['error'] != null
                ? data['error'].toString()
                : 'Order creation failed';

        throw Exception(errorMessage);
      }

      final String orderId = data['id'] as String;

      // Confirm the amount returned by the backend matches
      // the amount requested before opening checkout.
      final returnedAmount = data['amount'];

      if (returnedAmount != null &&
          returnedAmount is num &&
          returnedAmount != amountInPaise) {
        throw Exception(
          'Order amount mismatch. Checkout was not opened.',
        );
      }

      debugPrint('Razorpay order created: $orderId');

      await _razorpay.openCheckout(
        amountInPaise: amountInPaise,
        name: 'Unani Academy',
        description: description.length > 255
            ? description.substring(0, 255)
            : description,
        email: userEmail,
        contact: '',
        orderId: orderId,
      );
    } catch (e, stackTrace) {
      debugPrint('Payment Service Error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _onExternalError?.call(e.toString());
      rethrow;
    }
  }

  Future<void> _handlePaymentSuccess(
    String paymentId,
    String orderId,
  ) async {
    try {
      final user =
          Supabase.instance.client.auth.currentUser;

      if (user == null) {
        throw Exception(
          'Please sign in again before recording your purchase.',
        );
      }

      if (paymentId.isEmpty || orderId.isEmpty) {
        throw Exception(
          'Missing payment details. Purchase was not recorded.',
        );
      }

      debugPrint('Payment callback received: $paymentId');
      debugPrint('Order ID: $orderId');

      // IMPORTANT:
      // This callback alone does NOT verify that a payment is genuine.
      // Server-side Razorpay signature/payment verification must be
      // implemented before this purchase is treated as paid.

      final now = DateTime.now();

      final insertData = {
        'user_id': user.id,
        'course_name': _selectedCourseName ?? 'Unknown',
        'amount': _selectedCourseAmount ?? 0,
        'payment_id': paymentId,
        'purchased_at': now.toIso8601String(),
        'valid_until':
            now.add(const Duration(days: 30)).toIso8601String(),
        'status': 'active',
      };

      await Supabase.instance.client
          .from('purchases')
          .insert(insertData);

      _onExternalSuccess?.call(paymentId, orderId);
    } catch (e, stackTrace) {
      debugPrint('PURCHASE SAVE ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      _onExternalError?.call(
        'Payment callback received, but the purchase '
        'could not be recorded. Contact support before retrying.',
      );
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
```
