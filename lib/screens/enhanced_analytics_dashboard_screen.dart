import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/customer_analytics.dart';
import '../services/customer_analytics_service.dart';
import '../services/financial_reports_service.dart';

class EnhancedAnalyticsDashboardScreen extends StatefulWidget {
  const EnhancedAnalyticsDashboardScreen({super.key});

  @override
  State<EnhancedAnalyticsDashboardScreen> createState() => _EnhancedAnalyticsDashboardScreenState();
}

class _EnhancedAnalyticsDashboardScreenState extends State<EnhancedAnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CustomerAnalyticsService _analyticsService = CustomerAnalyticsService();

  BusinessIntelligence? _businessIntelligence;
  Map<String, dynamic>? _satisfactionStats;
  Map<String, dynamic>? _retentionMetrics;
  List<CustomerAnalytics> _topCustomers = [];
  List<CustomerAnalytics> _repeatCustomers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _analyticsService.generateBusinessIntelligenceReport(),
        _analyticsService.getSatisfactionStatistics(),
        _analyticsService.getCustomerRetentionMetrics(),
        _analyticsService.getTopCustomers(limit: 10),
        _analyticsService.getRepeatCustomers(),
      ]);

      setState(() {
        _businessIntelligence = results[0] as BusinessIntelligence;
        _satisfactionStats = results[1] as Map<String, dynamic>;
        _retentionMetrics = results[2] as Map<String, dynamic>;
        _topCustomers = results[3] as List<CustomerAnalytics>;
        _repeatCustomers = results[4] as List<CustomerAnalytics>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Analytics Dashboard'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Customers', icon: Icon(Icons.people)),
            Tab(text: 'Satisfaction', icon: Icon(Icons.star)),
            Tab(text: 'Financial', icon: Icon(Icons.attach_money)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCustomersTab(),
                _buildSatisfactionTab(),
                _buildFinancialTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    if (_businessIntelligence == null) {
      return const Center(child: Text('No data available'));
    }

    final bi = _businessIntelligence!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Daily Revenue',
                  'TZS ${bi.dailyRevenue.toStringAsFixed(0)}',
                  Icons.today,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Monthly Revenue',
                  'TZS ${bi.monthlyRevenue.toStringAsFixed(0)}',
                  Icons.calendar_month,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Parcels Today',
                  bi.totalParcelsToday.toString(),
                  Icons.local_shipping,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Avg. Parcel Value',
                  'TZS ${bi.averageParcelValue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Parcels by Status Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parcels by Status (Today)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: bi.parcelsByStatus.isNotEmpty
                        ? PieChart(
                            PieChartData(
                              sections: bi.parcelsByStatus.entries.map((entry) {
                                return PieChartSectionData(
                                  value: entry.value.toDouble(),
                                  title: '${entry.key}\n${entry.value}',
                                  color: _getStatusColor(entry.key),
                                  radius: 80,
                                );
                              }).toList(),
                            ),
                          )
                        : const Center(child: Text('No data available')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Top Routes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Routes (Today)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...bi.revenueByRoute.entries.take(5).map((entry) {
                    return ListTile(
                      leading: const Icon(Icons.route),
                      title: Text(entry.key),
                      trailing: Text(
                        'TZS ${entry.value.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Customer Metrics
          if (_retentionMetrics != null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Total Customers',
                    _retentionMetrics!['totalCustomers'].toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'Repeat Customers',
                    _retentionMetrics!['repeatCustomers'].toString(),
                    Icons.repeat,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    'Retention Rate',
                    '${_retentionMetrics!['retentionRate'].toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    'New This Month',
                    _retentionMetrics!['newCustomersThisMonth'].toString(),
                    Icons.person_add,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Top Customers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Customers by Spending',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._topCustomers.take(10).map((customer) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getTierColor(customer.customerTier),
                        child: Text(
                          customer.customerTier.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(customer.customerName),
                      subtitle: Text(
                        '${customer.totalParcels} parcels • ${customer.customerTier.toUpperCase()}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TZS ${customer.totalSpent.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (customer.satisfactionScore > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                Text(customer.satisfactionScore.toStringAsFixed(1)),
                              ],
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Repeat Customers
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Repeat Customers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._repeatCustomers.take(5).map((customer) {
                    return ListTile(
                      leading: const Icon(Icons.repeat, color: Colors.green),
                      title: Text(customer.customerName),
                      subtitle: Text('${customer.totalParcels} parcels over ${customer.monthsActive} months'),
                      trailing: Text(
                        'TZS ${customer.totalSpent.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSatisfactionTab() {
    if (_satisfactionStats == null) {
      return const Center(child: Text('No satisfaction data available'));
    }

    final stats = _satisfactionStats!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Satisfaction Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Average Rating',
                  '${stats['averageRating'].toStringAsFixed(1)}/5',
                  Icons.star,
                  Colors.amber,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Ratings',
                  stats['totalRatings'].toString(),
                  Icons.rate_review,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Rating Distribution
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating Distribution',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = (stats['ratingDistribution'] as Map<int, int>)[rating] ?? 0;
                    final total = stats['totalRatings'] as int;
                    final percentage = total > 0 ? (count / total) * 100 : 0.0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text('$rating'),
                          const SizedBox(width: 8),
                          ...List.generate(rating, (i) => const Icon(Icons.star, size: 16, color: Colors.amber)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rating >= 4 ? Colors.green : rating >= 3 ? Colors.orange : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text('$count (${percentage.toStringAsFixed(1)}%)'),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    if (_businessIntelligence == null) {
      return const Center(child: Text('No financial data available'));
    }

    final bi = _businessIntelligence!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Revenue Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Insurance Revenue',
                  'TZS ${bi.insuranceRevenue.toStringAsFixed(0)}',
                  Icons.security,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Special Handling',
                  bi.specialHandlingStats.values.fold(0, (sum, count) => sum + count).toString(),
                  Icons.priority_high,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Special Handling Stats
          if (bi.specialHandlingStats.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Special Handling Requests (Today)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ...bi.specialHandlingStats.entries.map((entry) {
                      return ListTile(
                        leading: Icon(_getSpecialHandlingIcon(entry.key)),
                        title: Text(entry.key.toUpperCase()),
                        trailing: Text(
                          entry.value.toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in transit':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'platinum':
        return Colors.purple;
      case 'gold':
        return Colors.amber;
      case 'silver':
        return Colors.grey;
      case 'bronze':
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  IconData _getSpecialHandlingIcon(String handling) {
    switch (handling.toLowerCase()) {
      case 'fragile':
        return Icons.warning;
      case 'urgent':
        return Icons.flash_on;
      case 'cold_chain':
        return Icons.ac_unit;
      default:
        return Icons.local_shipping;
    }
  }
}
