import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'razorpay_service_interface.dart';

@JS('Razorpay')
extension type _RazorpayCheckout._(JSObject _) implements JSObject {
  external _RazorpayCheckout(JSObject options);
  external void open();
}

class RazorpaySdkLoadException implements Exception {
  final String message;

  const RazorpaySdkLoadException(this.message);

  @override
  String toString() => message;
}

class RazorpayServiceImpl implements RazorpayService {
  @override
  final String apiKey = 'rzp_live_TsZwzdte4V7LHz';

  static const Duration _sdkLoadTimeout = Duration(seconds: 15);

  static const String _sdkLoadErrorMessage =
      'Could not load the Razorpay payment service. '
      'Please check your internet connection and try again.';

  Function(String paymentId, String orderId, String signature)? _onSuccess;

  Function(String message)? _onError;

  @override
  set onSuccess(
    Function(String paymentId, String orderId, String signature)? callback,
  ) {
    _onSuccess = callback;
  }

  @override
  set onError(Function(String message)? callback) {
    _onError = callback;
  }

  @override
  void init() {
    // The Razorpay JavaScript SDK is initialized when checkout opens.
  }

  @override
  void dispose() {
    // No disposal is required for the JavaScript SDK.
  }

  bool get _sdkAvailable => globalContext.has('Razorpay');

  Future<void> _ensureSdkLoaded() async {
    if (_sdkAvailable) return;

    try {
      if (globalContext.has('ensureRazorpaySdk')) {
        final promise = globalContext.callMethod<JSPromise<JSAny?>>(
          'ensureRazorpaySdk'.toJS,
          _sdkLoadTimeout.inMilliseconds.toJS,
        );

        await promise.toDart;
      } else {
        final deadline = DateTime.now().add(_sdkLoadTimeout);

        while (!_sdkAvailable && DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
    } catch (e) {
      debugPrint('Razorpay SDK loading error: $e');
    }

    if (!_sdkAvailable) {
      throw const RazorpaySdkLoadException(_sdkLoadErrorMessage);
    }
  }

  String _readString(JSObject object, String key) {
    final value = object.getProperty<JSAny?>(key.toJS).dartify();

    return value is String ? value : '';
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
    if (amountInPaise <= 0) {
      throw ArgumentError('Invalid payment amount.');
    }

    if (orderId == null || orderId.isEmpty) {
      throw ArgumentError('A valid Razorpay order ID is required.');
    }

    debugPrint('Initializing Razorpay Checkout: $orderId');

    await _ensureSdkLoaded();

    try {
      final options =
          <String, Object?>{
                'key': apiKey,
                'amount': amountInPaise,
                'currency': 'INR',
                'name': name,
                'description': description,
                'order_id': orderId,
                'prefill': {'name': name, 'email': email, 'contact': contact},
                'theme': {'color': '#6B21A8'},
              }.jsify()
              as JSObject;

      options.setProperty(
        'handler'.toJS,
        ((JSObject response) {
          try {
            final paymentId = _readString(response, 'razorpay_payment_id');

            final responseOrderId = _readString(response, 'razorpay_order_id');

            final signature = _readString(response, 'razorpay_signature');

            if (paymentId.isEmpty || signature.isEmpty) {
              _onError?.call(
                'Payment details are incomplete. '
                'Please contact support if money was deducted.',
              );
              return;
            }

            // Use the order ID returned by Razorpay.
            // Fall back to the original order only if necessary.
            final resolvedOrderId = responseOrderId.isNotEmpty
                ? responseOrderId
                : orderId;

            _onSuccess?.call(paymentId, resolvedOrderId, signature);
          } catch (e, stackTrace) {
            debugPrint('Razorpay success handler error: $e');
            debugPrintStack(stackTrace: stackTrace);

            _onError?.call('Unable to process the payment response.');
          }
        }).toJS,
      );

      final modal = JSObject();

      modal.setProperty(
        'ondismiss'.toJS,
        (() {
          _onError?.call('Payment checkout was closed.');
        }).toJS,
      );

      options.setProperty('modal'.toJS, modal);

      _RazorpayCheckout(options).open();
    } catch (e, stackTrace) {
      debugPrint('Razorpay checkout error: $e');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }
}

RazorpayService getRazorpayService() => RazorpayServiceImpl();
