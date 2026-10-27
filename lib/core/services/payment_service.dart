import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'razorpay_service.dart';

class PaymentService {
  final RazorpayService _razorpay = getRazorpayService();

  Function(String paymentId, String orderId)? _onExternalSuccess;
  Function(String message)? _onExternalError;

  String? _selectedType;
  String? _selectedItemId;

  // Prevent duplicate handling of the same checkout callback.
  bool _isVerifyingPayment = false;

  void init({
    Function(String paymentId, String orderId)? onSuccess,
    Function(String message)? onFailure,
  }) {
    _onExternalSuccess = onSuccess;
    _onExternalError = onFailure;

    _razorpay.onSuccess = (paymentId, orderId, signature) {
      _handlePaymentSuccess(paymentId, orderId, signature);
    };

    _razorpay.onError = _handlePaymentError;
    _razorpay.init();
  }

  Future<void> purchaseSubject({
    required String subjectId,
    required String subjectName,
    required double amount,
    required String userEmail,
    required String userName,
  }) async {
    _setPurchaseDetails(
      name: subjectName,
      amount: amount,
      type: 'subject',
      itemId: subjectId,
    );

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
    _setPurchaseDetails(
      name: bundleName,
      amount: amount,
      type: 'bundle',
      itemId: bundleId,
    );

    await _createOrderAndPay(
      amount: amount,
      type: 'bundle',
      itemId: bundleId,
      description: 'Bundle: $bundleName',
      userEmail: userEmail,
      userName: userName,
    );
  }

  void _setPurchaseDetails({
    required String name,
    required double amount,
    required String type,
    required String itemId,
  }) {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('Invalid payment amount.');
    }

    if (itemId.trim().isEmpty) {
      throw ArgumentError('Invalid purchase item.');
    }

    _selectedType = type;
    _selectedItemId = itemId;
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
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in before making a purchase.');
      }

      // Convert rupees to paise once.
      final amountInPaise = (amount * 100).round();

      debugPrint('Creating Razorpay order: type=$type, itemId=$itemId');

      final response = await client.functions.invoke(
        'create-razorpay-order',
        body: {
          'amount': amountInPaise,
          'currency': 'INR',
          'type': type,
          'itemId': itemId,
          'receipt': 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      final data = response.data;

      if (data is! Map ||
          data['id'] is! String ||
          (data['id'] as String).isEmpty) {
        final message = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Unable to create the payment order.';

        throw Exception(message);
      }

      final orderId = data['id'] as String;
      final returnedAmount = data['amount'];

      if (returnedAmount is! num || returnedAmount != amountInPaise) {
        throw Exception(
          'The order amount could not be confirmed. Please try again.',
        );
      }

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
      debugPrint('Payment order error: $e');
      debugPrintStack(stackTrace: stackTrace);
      _onExternalError?.call(e.toString());
      rethrow;
    }
  }

  Future<void> _handlePaymentSuccess(
    String paymentId,
    String orderId,
    String signature,
  ) async {
    if (_isVerifyingPayment) return;
    _isVerifyingPayment = true;

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('Your session has expired. Please sign in again.');
      }

      if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
        throw Exception('Payment verification details are incomplete.');
      }

      if (_selectedType == null || _selectedItemId == null) {
        throw Exception('The purchase details could not be identified.');
      }

      debugPrint('Requesting server-side payment verification.');

      // The backend must verify the signature, confirm the payment,
      // validate the order and price, and create the purchase record.
      // Flutter must not insert directly into the purchases table.
      final response = await client.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'paymentId': paymentId,
          'orderId': orderId,
          'signature': signature,
          'type': _selectedType,
          'itemId': _selectedItemId,
        },
      );

      final data = response.data;

      if (data is! Map || data['verified'] != true) {
        final message = data is Map && data['error'] != null
            ? data['error'].toString()
            : 'Payment could not be verified. Contact support if money was deducted.';

        throw Exception(message);
      }

      debugPrint('Payment verified by server: $paymentId');

      _onExternalSuccess?.call(paymentId, orderId);
    } catch (e, stackTrace) {
      debugPrint('Payment verification error: $e');
      debugPrintStack(stackTrace: stackTrace);

      _onExternalError?.call(
        'Payment verification is pending or failed. '
        'If money was deducted, do not pay again; contact support.',
      );
    } finally {
      _isVerifyingPayment = false;
    }
  }

  void _handlePaymentError(String message) {
    debugPrint('Razorpay payment error: $message');
    _onExternalError?.call(message);
  }

  void dispose() {
    _razorpay.dispose();
  }
}
