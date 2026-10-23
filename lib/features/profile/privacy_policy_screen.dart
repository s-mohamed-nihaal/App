import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade100, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unani Academy Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last updated: October 2024',
                style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              _buildSection(
                title: 'Data Collection & Usage',
                content:
                    'At Unani Academy, we prioritize the protection of your personal and educational data. '
                    'We only collect essential information such as your name, email address, and academic year '
                    'to provide you with personalized study materials and premium combos.\n\n'
                    'Your usage patterns and purchase history are securely stored in our cloud databases and '
                    'never sold to third-party advertisers.',
                icon: Icons.data_usage_rounded,
                iconColor: Colors.blueAccent,
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Storage & Permissions',
                content:
                    'When you download premium BUMS notes or track your subject progress, the application may '
                    'request access to save files locally on your device. '
                    'This ensures you have offline access to our EdTech materials even when without an internet connection.',
                icon: Icons.folder_shared_rounded,
                iconColor: Colors.orangeAccent,
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Secure Payments',
                content:
                    'All combo/subject purchases are securely routed. Unani Academy does not locally store your credit card or active banking details.',
                icon: Icons.shield_rounded,
                iconColor: Colors.green,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Us',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If you have further questions or require account deletion, please email us at support@unaniacademy.com.',
                      style: TextStyle(color: Colors.grey.shade800, height: 1.5, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content, required IconData icon, required Color iconColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
