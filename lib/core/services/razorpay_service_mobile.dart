import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_service_interface.dart';

class RazorpayServiceImpl implements RazorpayService {
  late final Razorpay _razorpay;
  @override
  final String apiKey = 'rzp_test_ScvaUZtfQzPnC0';

  Function(String paymentId, String orderId)? _onSuccess;
  Function(String message)? _onError;

  RazorpayServiceImpl() {
    _razorpay = Razorpay();
  }

  @override
  set onSuccess(Function(String paymentId, String orderId)? callback) => _onSuccess = callback;
  @override
  set onError(Function(String message)? callback) => _onError = callback;

  @override
  void init() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay Mobile Success: ${response.paymentId}');
    _onSuccess?.call(response.paymentId ?? '', response.orderId ?? '');
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint('Razorpay Mobile Payment Error: ${response.code} - ${response.message}');
    _onError?.call(response.message ?? 'Payment Failed');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay Mobile External Wallet: ${response.walletName}');
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
    // Ensure handlers are registered before opening
    init();

    var options = {
      'key': apiKey,
      'amount': amountInPaise,
      'name': name,
      'order_id': orderId,
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'theme': {'color': '#2E3A8C'},
      'method': {
        'upi': true,
        'card': true,
        'netbanking': true,
        'wallet': true,
      },
      'config': {
        'display': {
          'blocks': {
            'upi': {
              'name': 'Pay via UPI',
              'instruments': [
                {'method': 'upi'}
              ]
            }
          },
          'sequence': ['block.upi'],
          'preferences': {'show_default_blocks': true}
        }
      }
    };

    debugPrint('Opening Razorpay Mobile Checkout: $options');

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay Mobile Exception: $e');
      _onError?.call('Failed to open Razorpay: $e');
    }
  }
}

RazorpayService getRazorpayService() => RazorpayServiceImpl();
