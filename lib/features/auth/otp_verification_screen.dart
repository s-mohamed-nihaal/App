import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

import 'create_new_password_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() async {
    final otpText = _otpController.text.trim();
    if (otpText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.recovery,
        token: otpText,
        email: widget.email,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (response.session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email verified successfully!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const CreateNewPasswordScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid OTP. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(Icons.message_outlined, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                'Enter OTP',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'An OTP has been sent to ${widget.email}.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              TextField(
                controller: _otpController,
                decoration: const InputDecoration(
                  hintText: 'OTP Code',
                  prefixIcon: Icon(Icons.password_outlined, color: AppTheme.primaryColor),
                ),
                keyboardType: TextInputType.number,
                maxLength: 8,
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                child: _isLoading 
                  ? const SizedBox(
                      width: 24, height: 24, 
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : const Text('Verify'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
