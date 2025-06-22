import 'package:flutter/material.dart';

class PrivacyAndSecurityScreen extends StatelessWidget {
  const PrivacyAndSecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2), // Blue theme
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Security Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2), // Blue theme
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: June 03, 2025',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'At ZipBus, we are committed to protecting your privacy and ensuring the security of your data. This Privacy & Security Policy explains how we collect, use, and safeguard your information when you use our parcel tracking app.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '1. Information We Collect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We may collect the following information:\n'
              '- Personal details (e.g., name, email, mobile number) when you register as an agent or user.\n'
              '- Parcel tracking data, including sender and receiver information.\n'
              '- Device information (e.g., IP address, device type) for security purposes.\n'
              '- Profile pictures if you choose to upload one.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '2. How We Use Your Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We use your information to:\n'
              '- Facilitate parcel tracking and delivery.\n'
              '- Manage agent accounts and authentication.\n'
              '- Improve our app’s functionality and user experience.\n'
              '- Ensure security by detecting and preventing fraud.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '3. Data Security',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We implement industry-standard security measures, including:\n'
              '- Encryption of sensitive data.\n'
              '- Secure storage of profile pictures and other user data.\n'
              '- Regular security audits to protect against unauthorized access.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '4. Your Rights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You have the right to:\n'
              '- Access and update your personal information.\n'
              '- Delete your account and associated data.\n'
              '- Opt-out of non-essential data collection.\n'
              'To exercise these rights, please contact us at support@zipbus2.com.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '5. Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'If you have any questions about this policy, please reach out to us at:\n'
              'Email: support@zipbus2.com\n'
              'Phone: +255 123 456 789',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}