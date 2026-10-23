abstract class RazorpayService {
  factory RazorpayService() => throw UnsupportedError('Cannot create a RazorpayService');

  String get apiKey;
  
  set onSuccess(Function(String paymentId, String orderId)? callback);
  set onError(Function(String message)? callback);

  void init();
  void dispose();

  Future<void> openCheckout({
    required int amountInPaise,
    required String name,
    required String description,
    required String email,
    required String contact,
    String? orderId,
  });
}
