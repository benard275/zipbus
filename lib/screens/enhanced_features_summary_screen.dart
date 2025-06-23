import 'package:flutter/material.dart';
import 'enhanced_analytics_dashboard_screen.dart';
import 'financial_reports_screen.dart';
import 'invoice_management_screen.dart';
import 'customer_satisfaction_screen.dart';

class EnhancedFeaturesSummaryScreen extends StatelessWidget {
  const EnhancedFeaturesSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced ZipBus Features'),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              color: Colors.indigo[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.rocket_launch, color: Colors.indigo[800], size: 32),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Welcome to Enhanced ZipBus!',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your courier service now includes advanced analytics, automated invoicing, smart parcel features, and customer satisfaction tracking.',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Enhanced Analytics Section
            const Text(
              '📊 Enhanced Analytics & Business Intelligence',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.analytics, color: Colors.blue),
                    title: const Text('Enhanced Analytics Dashboard'),
                    subtitle: const Text('Customer analytics, repeat customers, satisfaction scores'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EnhancedAnalyticsDashboardScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✨ New Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Customer tier classification (Bronze, Silver, Gold, Platinum)'),
                        Text('• Repeat customer identification and tracking'),
                        Text('• Customer satisfaction scores and ratings'),
                        Text('• Business intelligence metrics'),
                        Text('• Revenue trends and performance analytics'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Financial Reports Section
            const Text(
              '💰 Advanced Payment & Financial System',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.attach_money, color: Colors.green),
                    title: const Text('Financial Reports'),
                    subtitle: const Text('Daily/monthly revenue summaries, profit analysis'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FinancialReportsScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.purple),
                    title: const Text('Invoice Management'),
                    subtitle: const Text('Automated PDF invoice generation'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const InvoiceManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('✨ New Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('• Automated PDF invoice generation with business branding'),
                        Text('• Daily, monthly, and yearly financial reports'),
                        Text('• Profit margin analysis and revenue trends'),
                        Text('• Tax calculation (18% VAT) and collection tracking'),
                        Text('• Payment method breakdown and agent performance'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Smart Parcel Features Section
            const Text(
              '🌟 Smart Parcel Features',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Insurance Options', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Parcel value protection with 2% premium (minimum TZS 2,000)'),
                    const Text('• Declared value tracking and insurance claims'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        const Icon(Icons.priority_high, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Special Handling', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Fragile handling (+TZS 5,000)'),
                    const Text('• Urgent delivery (+TZS 10,000)'),
                    const Text('• Cold chain transport (+TZS 15,000)'),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        const Icon(Icons.calculate, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text('Smart Pricing', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('• Automatic cost calculation with breakdown'),
                    const Text('• Real-time total amount display'),
                    const Text('• Transparent fee structure'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Customer Satisfaction Section
            const Text(
              '⭐ Customer Satisfaction System',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Collect and track customer feedback to improve service quality:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text('• 5-star rating system for deliveries'),
                    const Text('• Multiple rating categories (delivery, service, overall)'),
                    const Text('• Optional feedback comments'),
                    const Text('• Satisfaction score tracking per customer'),
                    const Text('• Rating distribution analytics'),
                    const SizedBox(height: 16),
                    
                    ElevatedButton.icon(
                      onPressed: () {
                        // Show demo satisfaction screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerSatisfactionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.star),
                      label: const Text('View Rating Interface'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Implementation Notes
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[800]),
                        const SizedBox(width: 8),
                        const Text(
                          'Implementation Complete',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('✅ Database schema updated with new tables and fields'),
                    const Text('✅ Smart parcel features integrated in parcel creation'),
                    const Text('✅ Customer analytics automatically updated'),
                    const Text('✅ PDF invoice generation with business branding'),
                    const Text('✅ Financial reporting with profit analysis'),
                    const Text('✅ Customer satisfaction tracking system'),
                    const Text('✅ Enhanced admin dashboard with new features'),
                    const SizedBox(height: 12),
                    const Text(
                      'All features are now available in the admin panel and throughout the application.',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Getting Started
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[800]),
                        const SizedBox(width: 8),
                        const Text(
                          'Getting Started',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('1. Create parcels with insurance and special handling options'),
                    const Text('2. Track customer satisfaction through delivery ratings'),
                    const Text('3. Generate professional PDF invoices for customers'),
                    const Text('4. Monitor business performance through enhanced analytics'),
                    const Text('5. Use financial reports for business decision making'),
                    const SizedBox(height: 12),
                    const Text(
                      'Access all features through the Admin Panel → Enhanced Features section.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
