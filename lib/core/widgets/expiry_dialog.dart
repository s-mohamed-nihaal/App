import 'package:flutter/material.dart';
import '../../features/main/nav_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showExpiryDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Column(
        children: [
          Icon(Icons.timer_off_outlined, color: Colors.orange, size: 60),
          SizedBox(height: 16),
          Text('Plan Expired', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Text(
        'Your plan has expired. Renew to continue accessing premium content and materials.',
        textAlign: TextAlign.center,
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A8C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Switch to subscription tab
              ref.read(mainNavigationProvider.notifier).state = 3; // Assuming 3 is Subscription tab
            },
            child: const Text('Renew Now', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}
