import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2), // Blue theme
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Conditions',
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
              'By using the ZipBus app, you agree to the following terms and conditions. Please read them carefully.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '1. Acceptance of Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'By accessing or using the ZipBus app, you agree to be bound by these terms and conditions, as well as our Privacy & Security Policy.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '2. Use of the App',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You agree to use the app for lawful purposes only, including:\n'
              '- Managing and tracking parcels.\n'
              '- Updating agent profiles as permitted.\n'
              'You must not:\n'
              '- Use the app to engage in fraudulent activities.\n'
              '- Share your account credentials with others.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '3. Account Responsibilities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You are responsible for:\n'
              '- Keeping your account password secure.\n'
              '- Ensuring the accuracy of parcel and profile information.\n'
              '- Notifying us of any unauthorized use of your account.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '4. Limitation of Liability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ZipBus is not liable for:\n'
              '- Delays or losses due to incorrect parcel information.\n'
              '- Any indirect or consequential damages arising from app usage.\n'
              'Our total liability is limited to the amount you paid for using the app, if applicable.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '5. Changes to Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We may update these terms from time to time. You will be notified of significant changes via email or in-app notifications.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              '6. Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF57C00), // Orange theme
              ),
            ),
            SizedBox(height: 8),
            Text(
              'For questions about these terms, contact us at:\n'
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