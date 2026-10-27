// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'razorpay_service_interface.dart';

/// Binding for the global `Razorpay` constructor from
/// https://checkout.razorpay.com/v1/checkout.js
@JS('Razorpay')
extension type _RazorpayCheckout._(JSObject _) implements JSObject {
  external _RazorpayCheckout(JSObject options);
  external void open();
}

/// Thrown when checkout.js could not be loaded (blocked, offline, timed out).
/// [toString] returns the user-facing message so it can be shown as-is.
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
      'Could not load the Razorpay payment service. Please check your internet '
      'connection, disable any ad/content blocker for this site, and try again.';

  Function(String paymentId, String orderId)? _onSuccess;
  Function(String message)? _onError;

  @override
  set onSuccess(Function(String paymentId, String orderId)? callback) =>
      _onSuccess = callback;
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

  bool get _sdkAvailable => globalContext.has('Razorpay');

  /// Waits until `window.Razorpay` exists. Uses the loader in web/index.html
  /// (`window.ensureRazorpaySdk`) and falls back to polling if it is missing,
  /// e.g. when a stale cached index.html is being served.
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
      debugPrint('Razorpay SDK (checkout.js) failed to load: $e');
    }

    if (!_sdkAvailable) {
      debugPrint(
        'CRITICAL: Razorpay SDK (checkout.js) not found on window after waiting.',
      );
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
    debugPrint('Initializing Razorpay Checkout with Order: $orderId');
    debugPrint('Amount: $amountInPaise, User: $email');

    // Make sure checkout.js has finished loading before touching window.Razorpay.
    // Failures are thrown to the caller (PaymentService reports them to the UI).
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
            var respOrderId = _readString(response, 'razorpay_order_id');
            if (respOrderId.isEmpty) respOrderId = orderId ?? '';
            _onSuccess?.call(paymentId, respOrderId);
          } catch (e) {
            debugPrint('Error in Razorpay success handler: $e');
            _onError?.call('Error processing payment response: $e');
          }
        }).toJS,
      );

      final modal = JSObject();
      modal.setProperty(
        'ondismiss'.toJS,
        (() {
          _onError?.call('Payment Cancelled');
        }).toJS,
      );
      options.setProperty('modal'.toJS, modal);

      _RazorpayCheckout(options).open();
    } catch (e) {
      debugPrint('Razorpay Init Error: $e');
      throw Exception('Could not open Razorpay Checkout: $e');
    }
  }
}

RazorpayService getRazorpayService() => RazorpayServiceImpl();
