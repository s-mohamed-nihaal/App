import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/payment_service.dart';

final paymentServiceProvider = Provider<PaymentService>((ref) {
  final service = PaymentService();
  ref.onDispose(() => service.dispose());
  return service;
});
