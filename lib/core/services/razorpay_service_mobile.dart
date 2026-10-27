import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'razorpay_service_interface.dart';

class RazorpayServiceImpl implements RazorpayService {
  late final Razorpay _razorpay;

  @override
  final String apiKey = 'rzp_live_TsZwzdte4V7LHz';

  // Callback now accepts all three payment details.
  Function(String, String, String)? _onSuccess;

  Function(String)? _onError;

  RazorpayServiceImpl() {
    _razorpay = Razorpay();
  }

  @override
  set onSuccess(Function(String, String, String)? callback) {
    _onSuccess = callback;
  }

  @override
  set onError(Function(String)? callback) {
    _onError = callback;
  }

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
    final paymentId = response.paymentId;
    final orderId = response.orderId;
    final signature = response.signature;

    debugPrint('Razorpay Mobile Success: $paymentId');

    if (paymentId == null ||
        orderId == null ||
        signature == null ||
        paymentId.isEmpty ||
        orderId.isEmpty ||
        signature.isEmpty) {
      _onError?.call('Payment details are incomplete. Please contact support.');
      return;
    }

    _onSuccess?.call(paymentId, orderId, signature);
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint(
      'Razorpay Mobile Payment Error: '
      '${response.code} - ${response.message}',
    );

    _onError?.call(response.message ?? 'Payment failed');
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
    init();

    if (amountInPaise <= 0) {
      _onError?.call('Invalid payment amount.');
      return;
    }

    if (orderId == null || orderId.isEmpty) {
      _onError?.call('A valid Razorpay order ID is required.');
      return;
    }

    final options = {
      'key': apiKey,
      'amount': amountInPaise,
      'name': name,
      'order_id': orderId,
      'description': description,
      'prefill': {'contact': contact, 'email': email},
      'theme': {'color': '#2E3A8C'},
      'method': {'upi': true, 'card': true, 'netbanking': true, 'wallet': true},
      'config': {
        'display': {
          'blocks': {
            'upi': {
              'name': 'Pay via UPI',
              'instruments': [
                {'method': 'upi'},
              ],
            },
          },
          'sequence': ['block.upi'],
          'preferences': {'show_default_blocks': true},
        },
      },
    };

    debugPrint('Opening Razorpay Mobile Checkout');

    try {
      _razorpay.open(options);
    } catch (e, stackTrace) {
      debugPrint('Razorpay Mobile Exception: $e');
      debugPrintStack(stackTrace: stackTrace);

      _onError?.call('Failed to open Razorpay checkout.');
    }
  }
}

RazorpayService getRazorpayService() => RazorpayServiceImpl();
