import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/agent.dart';
import '../services/analytics_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final Agent agent;

  const AnalyticsDashboardScreen({
    super.key,
    required this.agent,
  });

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  AnalyticsData? _analyticsData;
  Map<String, dynamic>? _deliveryPerformance;
  Map<String, dynamic>? _paymentAnalytics;
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analyticsData = await _analyticsService.getAnalyticsData(
        startDate: _startDate,
        endDate: _endDate,
      );
      final deliveryPerformance = await _analyticsService.getDeliveryPerformance();
      final paymentAnalytics = await _analyticsService.getPaymentAnalytics();

      if (mounted) {
        setState(() {
          _analyticsData = analyticsData;
          _deliveryPerformance = deliveryPerformance;
          _paymentAnalytics = paymentAnalytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load analytics: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalyticsData();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    _loadAnalyticsData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          if (_startDate != null || _endDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearDateFilter,
              tooltip: 'Clear Date Filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalyticsData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalyticsData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_analyticsData == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date filter indicator
          if (_startDate != null || _endDate != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtered: ${_startDate != null ? DateFormat('MMM dd, yyyy').format(_startDate!) : 'Start'} - ${_endDate != null ? DateFormat('MMM dd, yyyy').format(_endDate!) : 'End'}',
                      style: TextStyle(color: Colors.blue.shade700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Key metrics cards
          _buildKeyMetricsSection(),
          const SizedBox(height: 24),

          // Charts section
          _buildChartsSection(),
          const SizedBox(height: 24),

          // Performance metrics
          _buildPerformanceSection(),
          const SizedBox(height: 24),

          // Top routes
          _buildTopRoutesSection(),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              'Total Parcels',
              _analyticsData!.totalParcels.toString(),
              Icons.inventory,
              Colors.blue,
            ),
            _buildMetricCard(
              'Total Revenue',
              'TZS ${_analyticsData!.totalRevenue.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
            ),
            _buildMetricCard(
              'Delivered',
              _analyticsData!.deliveredParcels.toString(),
              Icons.check_circle,
              Colors.green,
            ),
            _buildMetricCard(
              'In Transit',
              _analyticsData!.inTransitParcels.toString(),
              Icons.local_shipping,
              Colors.orange,
            ),
            _buildMetricCard(
              'Cancelled',
              _analyticsData!.cancelledParcels.toString(),
              Icons.cancel,
              Colors.red,
            ),
            _buildMetricCard(
              'Pending',
              _analyticsData!.pendingParcels.toString(),
              Icons.pending,
              Colors.grey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Charts & Trends',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Status distribution pie chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Parcel Status Distribution',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: PieChart(
                    PieChartData(
                      sections: _buildPieChartSections(),
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Daily revenue chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Revenue (Last 30 Days)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < _analyticsData!.dailyStats.length) {
                                final date = _analyticsData!.dailyStats[index].date;
                                return Text(
                                  DateFormat('MM/dd').format(date),
                                  style: const TextStyle(fontSize: 10),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _buildLineChartSpots(),
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          dotData: const FlDotData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final data = _analyticsData!.parcelsByStatus;
    final total = data.values.fold<int>(0, (sum, value) => sum + value);

    if (total == 0) return [];

    final colors = [Colors.grey, Colors.orange, Colors.blue, Colors.green, Colors.red];
    final statuses = ['Pending', 'In Transit', 'Delivered', 'Cancelled'];

    return statuses.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      final count = data[status] ?? 0;
      final percentage = (count / total) * 100;

      return PieChartSectionData(
        color: colors[index],
        value: count.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  List<FlSpot> _buildLineChartSpots() {
    return _analyticsData!.dailyStats.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.revenue);
    }).toList();
  }

  Widget _buildPerformanceSection() {
    if (_deliveryPerformance == null || _paymentAnalytics == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Metrics',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Delivery Performance',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Delivery Rate: ${_deliveryPerformance!['deliveryRate'].toStringAsFixed(1)}%',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Avg. Delivery Time: ${_deliveryPerformance!['averageDeliveryTime'].toStringAsFixed(1)} hours',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'On-time Deliveries: ${_deliveryPerformance!['onTimeDeliveries']}/${_deliveryPerformance!['totalDeliveries']}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Payment Analytics',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Paid: ${_paymentAnalytics!['paidParcels']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pending: ${_paymentAnalytics!['pendingPayments']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mobile Money: TZS ${_paymentAnalytics!['mobileMoneyRevenue'].toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cash: TZS ${_paymentAnalytics!['cashRevenue'].toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopRoutesSection() {
    if (_analyticsData!.topRoutes.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Routes',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: _analyticsData!.topRoutes.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}