import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paymentStatusServiceProvider = Provider<PaymentStatusService>((ref) {
  return PaymentStatusService();
});

class PaymentStatusService {
  static const String keyIsPurchased = 'is_purchased';
  static const String keyPurchaseDate = 'purchase_date';
  static const String keyExpiryDate = 'expiry_date';
  static const String keyPaymentId = 'payment_id';
  static const String keyOrderId = 'order_id';
  static const String keyBundleName = 'bundle_name';

  Future<bool> isPlanActive() async {
    final prefs = await SharedPreferences.getInstance();
    final isPurchased = prefs.getBool(keyIsPurchased) ?? false;
    if (!isPurchased) return false;

    final expiryStr = prefs.getString(keyExpiryDate);
    if (expiryStr == null) return false;

    final expiryDate = DateTime.parse(expiryStr);
    return DateTime.now().isBefore(expiryDate);
  }

  Future<DateTime?> getExpiryDate() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryStr = prefs.getString(keyExpiryDate);
    if (expiryStr == null) return null;
    return DateTime.parse(expiryStr);
  }

  Future<void> savePurchase({
    required String paymentId,
    required String orderId,
    required String bundleName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final expiry = now.add(const Duration(days: 30));

    await prefs.setBool(keyIsPurchased, true);
    await prefs.setString(keyPurchaseDate, now.toIso8601String());
    await prefs.setString(keyExpiryDate, expiry.toIso8601String());
    await prefs.setString(keyPaymentId, paymentId);
    await prefs.setString(keyOrderId, orderId);
    await prefs.setString(keyBundleName, bundleName);
  }

  Future<void> clearPurchase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyIsPurchased);
    await prefs.remove(keyPurchaseDate);
    await prefs.remove(keyExpiryDate);
    await prefs.remove(keyPaymentId);
    await prefs.remove(keyOrderId);
    await prefs.remove(keyBundleName);
  }

  Future<Map<String, dynamic>> getPurchaseDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'is_purchased': prefs.getBool(keyIsPurchased),
      'purchase_date': prefs.getString(keyPurchaseDate),
      'expiry_date': prefs.getString(keyExpiryDate),
      'payment_id': prefs.getString(keyPaymentId),
      'order_id': prefs.getString(keyOrderId),
      'bundle_name': prefs.getString(keyBundleName),
    };
  }
}
