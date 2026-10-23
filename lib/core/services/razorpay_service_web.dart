// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use, uri_does_not_exist, undefined_function
import 'dart:js' as js;
import 'dart:js_util' as js_util;
import 'package:flutter/foundation.dart';
import 'razorpay_service_interface.dart';

class RazorpayServiceImpl implements RazorpayService {
  @override
  final String apiKey = 'rzp_test_ScvaUZtfQzPnC0';

  Function(String paymentId, String orderId)? _onSuccess;
  Function(String message)? _onError;

  @override
  set onSuccess(Function(String paymentId, String orderId)? callback) => _onSuccess = callback;
  @override
  set onError(Function(String message)? callback) => _onError = callback;

  @override
  void init() {
    // No initialization needed for web JS SDK
  }

  @override
  void dispose() {
    // No disposal needed for web JS SDK
  }

  @override
  Future<void> openCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    required String email,
    required String contact,
    String? orderId,
  }) async {
    debugPrint('Initializing Razorpay Checkout with Order: $orderId');
    debugPrint('Amount: $amountInPaise, User: $email');

    final optionsData = {
      'key': apiKey,
      'amount': amountInPaise,
      'currency': 'INR',
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        'name': name,
        'email': email,
        'contact': contact,
      },
      'theme': {'color': '#6B21A8'},
      'handler': js.allowInterop((response) {
        try {
          final paymentId = js_util.getProperty(response, 'razorpay_payment_id') ?? '';
          final respOrderId = js_util.getProperty(response, 'razorpay_order_id') ?? orderId ?? '';
          _onSuccess?.call(paymentId.toString(), respOrderId.toString());
        } catch (e) {
          debugPrint('Error in Razorpay success handler: $e');
          _onError?.call('Error processing payment response: $e');
        }
      }),
      'modal': {
        'ondismiss': js.allowInterop(() {
          _onError?.call('Payment Cancelled');
        }),
      },
    };

    try {
      final options = js_util.jsify(optionsData);
      
      final razorpayConstructor = js_util.getProperty(js.context, 'Razorpay');
      if (razorpayConstructor == null) {
        debugPrint('CRITICAL: Razorpay SDK (checkout.js) not found in window context.');
        throw Exception('Razorpay SDK not found. Please ensure checkout.js is loaded.');
      }

      final razorpay = js_util.callConstructor(razorpayConstructor, [options]);
      js_util.callMethod(razorpay, 'open', []);
    } catch (e) {
      debugPrint('Razorpay Init Error: $e');
      _onError?.call('Payment service error: $e');
      rethrow;
    }
  }
}

RazorpayService getRazorpayService() => RazorpayServiceImpl();
