import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/parcel.dart';
import '../models/payment_record.dart';
import '../models/customer_analytics.dart';
import 'database_service.dart';

class FinancialReportsService {
  static final FinancialReportsService _instance = FinancialReportsService._internal();
  factory FinancialReportsService() => _instance;
  FinancialReportsService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Generate daily financial report
  Future<FinancialReport> generateDailyReport({DateTime? date}) async {
    final reportDate = date ?? DateTime.now();
    final startDate = DateTime(reportDate.year, reportDate.month, reportDate.day);
    final endDate = startDate.add(const Duration(days: 1));

    return await _generateReport(
      reportType: 'daily',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate monthly financial report
  Future<FinancialReport> generateMonthlyReport({DateTime? date}) async {
    final reportDate = date ?? DateTime.now();
    final startDate = DateTime(reportDate.year, reportDate.month, 1);
    final endDate = DateTime(reportDate.year, reportDate.month + 1, 1);

    return await _generateReport(
      reportType: 'monthly',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate yearly financial report
  Future<FinancialReport> generateYearlyReport({DateTime? date}) async {
    final reportDate = date ?? DateTime.now();
    final startDate = DateTime(reportDate.year, 1, 1);
    final endDate = DateTime(reportDate.year + 1, 1, 1);

    return await _generateReport(
      reportType: 'yearly',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Generate custom date range report
  Future<FinancialReport> generateCustomReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await _generateReport(
      reportType: 'custom',
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Core report generation logic
  Future<FinancialReport> _generateReport({
    required String reportType,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final db = await _databaseService.database;

      // Get parcels in date range
      final parcelsResult = await db.query(
        'parcels',
        where: 'createdAt >= ? AND createdAt < ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final parcels = parcelsResult.map((map) => Parcel.fromMap(map)).toList();

      // Get payment records in date range
      final paymentsResult = await db.query(
        'payment_records',
        where: 'paymentDate >= ? AND paymentDate < ?',
        whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      );
      final payments = paymentsResult.map((map) => PaymentRecord.fromMap(map)).toList();

      // Calculate basic metrics
      final totalRevenue = payments.fold<double>(0.0, (sum, payment) => sum + payment.amount);
      final totalExpenses = _calculateExpenses(parcels);
      final netProfit = totalRevenue - totalExpenses;
      final grossProfit = totalRevenue * 0.7; // Assuming 30% cost of goods sold
      final totalParcels = parcels.length;
      final averageParcelValue = totalParcels > 0 ? totalRevenue / totalParcels : 0.0;

      // Calculate revenue by category
      final revenueByCategory = <String, double>{
        'shipping': 0.0,
        'insurance': 0.0,
        'special_handling': 0.0,
        'tax': 0.0,
      };

      for (final parcel in parcels) {
        revenueByCategory['shipping'] = (revenueByCategory['shipping'] ?? 0.0) + parcel.amount;
        if (parcel.hasInsurance) {
          revenueByCategory['insurance'] = (revenueByCategory['insurance'] ?? 0.0) + (parcel.insurancePremium ?? 0.0);
        }
        if (parcel.specialHandling != null) {
          revenueByCategory['special_handling'] = (revenueByCategory['special_handling'] ?? 0.0) + _getSpecialHandlingFee(parcel.specialHandling!);
        }
      }

      // Calculate expenses by category
      final expensesByCategory = <String, double>{
        'fuel': totalRevenue * 0.15, // 15% of revenue
        'maintenance': totalRevenue * 0.05, // 5% of revenue
        'salaries': totalRevenue * 0.25, // 25% of revenue
        'other': totalRevenue * 0.05, // 5% of revenue
      };

      // Calculate parcels by status
      final parcelsByStatus = <String, int>{};
      for (final parcel in parcels) {
        parcelsByStatus[parcel.status] = (parcelsByStatus[parcel.status] ?? 0) + 1;
      }

      // Calculate tax collected (18% VAT)
      final taxCollected = totalRevenue * 0.18;

      // Calculate insurance and special handling revenue
      final insuranceRevenue = revenueByCategory['insurance'] ?? 0.0;
      final specialHandlingRevenue = revenueByCategory['special_handling'] ?? 0.0;

      // Get top routes
      final topRoutes = await _getTopRoutes(startDate, endDate);

      // Get agent performance
      final agentPerformance = await _getAgentPerformance(startDate, endDate);

      final report = FinancialReport(
        id: const Uuid().v4(),
        reportDate: DateTime.now(),
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        totalRevenue: totalRevenue,
        totalExpenses: totalExpenses,
        netProfit: netProfit,
        grossProfit: grossProfit,
        totalParcels: totalParcels,
        averageParcelValue: averageParcelValue,
        revenueByCategory: revenueByCategory,
        expensesByCategory: expensesByCategory,
        parcelsByStatus: parcelsByStatus,
        taxCollected: taxCollected,
        insuranceRevenue: insuranceRevenue,
        specialHandlingRevenue: specialHandlingRevenue,
        topRoutes: topRoutes,
        agentPerformance: agentPerformance,
      );

      // Save report to database
      await _saveReportToDatabase(report);

      debugPrint('📊 Financial report generated: ${report.reportType} (${report.startDate} - ${report.endDate})');
      debugPrint('   Total Revenue: TZS ${report.totalRevenue.toStringAsFixed(2)}');
      debugPrint('   Net Profit: TZS ${report.netProfit.toStringAsFixed(2)}');
      debugPrint('   Total Parcels: ${report.totalParcels}');

      return report;
    } catch (e) {
      debugPrint('❌ Error generating financial report: $e');
      rethrow;
    }
  }

  /// Calculate estimated expenses
  double _calculateExpenses(List<Parcel> parcels) {
    double totalExpenses = 0.0;
    
    for (final parcel in parcels) {
      // Base operational cost per parcel
      totalExpenses += parcel.amount * 0.5; // 50% of revenue as expenses
      
      // Additional costs for special handling
      if (parcel.specialHandling != null) {
        totalExpenses += _getSpecialHandlingCost(parcel.specialHandling!);
      }
    }
    
    return totalExpenses;
  }

  /// Get special handling fee
  double _getSpecialHandlingFee(String specialHandling) {
    switch (specialHandling.toLowerCase()) {
      case 'fragile':
        return 5000.0;
      case 'urgent':
        return 10000.0;
      case 'cold_chain':
        return 15000.0;
      default:
        return 0.0;
    }
  }

  /// Get special handling cost
  double _getSpecialHandlingCost(String specialHandling) {
    switch (specialHandling.toLowerCase()) {
      case 'fragile':
        return 2000.0; // Additional packaging cost
      case 'urgent':
        return 5000.0; // Express delivery cost
      case 'cold_chain':
        return 8000.0; // Refrigeration cost
      default:
        return 0.0;
    }
  }

  /// Get top routes by revenue
  Future<List<TopRoute>> _getTopRoutes(DateTime startDate, DateTime endDate) async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery('''
      SELECT 
        (fromLocation || ' → ' || toLocation) as route,
        COUNT(*) as parcelCount,
        SUM(amount) as revenue,
        AVG(amount) as averageValue
      FROM parcels 
      WHERE createdAt >= ? AND createdAt < ?
      GROUP BY fromLocation, toLocation
      ORDER BY revenue DESC
      LIMIT 10
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return result.map((row) => TopRoute(
      route: row['route'] as String,
      parcelCount: row['parcelCount'] as int,
      revenue: (row['revenue'] as num).toDouble(),
      averageValue: (row['averageValue'] as num).toDouble(),
    )).toList();
  }

  /// Get agent performance metrics
  Future<List<AgentPerformance>> _getAgentPerformance(DateTime startDate, DateTime endDate) async {
    final db = await _databaseService.database;
    
    final result = await db.rawQuery('''
      SELECT 
        p.createdBy as agentId,
        a.name as agentName,
        COUNT(*) as parcelsHandled,
        SUM(p.amount) as revenueGenerated,
        AVG(p.amount) as averageParcelValue
      FROM parcels p
      LEFT JOIN agents a ON p.createdBy = a.id
      WHERE p.createdAt >= ? AND p.createdAt < ?
      GROUP BY p.createdBy, a.name
      ORDER BY revenueGenerated DESC
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    final agentPerformance = <AgentPerformance>[];
    
    for (final row in result) {
      // Get satisfaction score for agent
      final satisfactionResult = await db.rawQuery('''
        SELECT AVG(rating) as avgRating
        FROM satisfaction_ratings sr
        JOIN parcels p ON sr.parcelId = p.id
        WHERE p.createdBy = ? AND sr.createdAt >= ? AND sr.createdAt < ?
      ''', [row['agentId'], startDate.toIso8601String(), endDate.toIso8601String()]);
      
      final satisfactionScore = satisfactionResult.isNotEmpty && satisfactionResult.first['avgRating'] != null
          ? (satisfactionResult.first['avgRating'] as num).toDouble()
          : 0.0;

      agentPerformance.add(AgentPerformance(
        agentId: row['agentId'] as String,
        agentName: row['agentName'] as String? ?? 'Unknown',
        parcelsHandled: row['parcelsHandled'] as int,
        revenueGenerated: (row['revenueGenerated'] as num).toDouble(),
        averageParcelValue: (row['averageParcelValue'] as num).toDouble(),
        satisfactionScore: satisfactionScore,
      ));
    }

    return agentPerformance;
  }

  /// Save report to database
  Future<void> _saveReportToDatabase(FinancialReport report) async {
    final db = await _databaseService.database;
    await db.insert('financial_reports', report.toMap());
  }

  /// Get saved reports
  Future<List<FinancialReport>> getSavedReports({String? reportType}) async {
    final db = await _databaseService.database;
    
    final result = await db.query(
      'financial_reports',
      where: reportType != null ? 'reportType = ?' : null,
      whereArgs: reportType != null ? [reportType] : null,
      orderBy: 'reportDate DESC',
    );

    return result.map((map) => FinancialReport(
      id: map['id'] as String,
      reportDate: DateTime.parse(map['reportDate'] as String),
      reportType: map['reportType'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      totalRevenue: (map['totalRevenue'] as num).toDouble(),
      totalExpenses: (map['totalExpenses'] as num).toDouble(),
      netProfit: (map['netProfit'] as num).toDouble(),
      grossProfit: (map['grossProfit'] as num).toDouble(),
      totalParcels: map['totalParcels'] as int,
      averageParcelValue: (map['averageParcelValue'] as num).toDouble(),
      revenueByCategory: _parseDoubleMapFromString(map['revenueByCategory'] as String),
      expensesByCategory: _parseDoubleMapFromString(map['expensesByCategory'] as String),
      parcelsByStatus: _parseIntMapFromString(map['parcelsByStatus'] as String),
      taxCollected: (map['taxCollected'] as num).toDouble(),
      insuranceRevenue: (map['insuranceRevenue'] as num).toDouble(),
      specialHandlingRevenue: (map['specialHandlingRevenue'] as num).toDouble(),
      topRoutes: [], // Will be loaded separately if needed
      agentPerformance: [], // Will be loaded separately if needed
    )).toList();
  }

  /// Parse double map from string
  Map<String, double> _parseDoubleMapFromString(String data) {
    if (data.isEmpty) return {};
    return Map.fromEntries(
      data.split(',').map((entry) {
        final parts = entry.split(':');
        return MapEntry(parts[0], double.parse(parts[1]));
      }),
    );
  }

  /// Parse int map from string
  Map<String, int> _parseIntMapFromString(String data) {
    if (data.isEmpty) return {};
    return Map.fromEntries(
      data.split(',').map((entry) {
        final parts = entry.split(':');
        return MapEntry(parts[0], int.parse(parts[1]));
      }),
    );
  }

  /// Get revenue trend data
  Future<List<Map<String, dynamic>>> getRevenueTrend({
    required DateTime startDate,
    required DateTime endDate,
    String period = 'daily', // 'daily', 'weekly', 'monthly'
  }) async {
    final db = await _databaseService.database;
    
    String dateFormat;
    switch (period) {
      case 'weekly':
        dateFormat = "strftime('%Y-W%W', createdAt)";
        break;
      case 'monthly':
        dateFormat = "strftime('%Y-%m', createdAt)";
        break;
      default:
        dateFormat = "strftime('%Y-%m-%d', createdAt)";
    }

    final result = await db.rawQuery('''
      SELECT 
        $dateFormat as period,
        COUNT(*) as parcelCount,
        SUM(amount) as revenue
      FROM parcels 
      WHERE createdAt >= ? AND createdAt < ?
      GROUP BY $dateFormat
      ORDER BY period
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return result.map((row) => {
      'period': row['period'] as String,
      'parcelCount': row['parcelCount'] as int,
      'revenue': (row['revenue'] as num).toDouble(),
    }).toList();
  }

  /// Get profit margin analysis
  Future<Map<String, dynamic>> getProfitMarginAnalysis({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final report = await _generateReport(
      reportType: 'analysis',
      startDate: startDate,
      endDate: endDate,
    );

    final grossMargin = report.totalRevenue > 0 ? (report.grossProfit / report.totalRevenue) * 100 : 0.0;
    final netMargin = report.totalRevenue > 0 ? (report.netProfit / report.totalRevenue) * 100 : 0.0;
    final operatingMargin = report.totalRevenue > 0 ? ((report.totalRevenue - report.totalExpenses) / report.totalRevenue) * 100 : 0.0;

    return {
      'grossMargin': grossMargin,
      'netMargin': netMargin,
      'operatingMargin': operatingMargin,
      'totalRevenue': report.totalRevenue,
      'totalExpenses': report.totalExpenses,
      'grossProfit': report.grossProfit,
      'netProfit': report.netProfit,
    };
  }
}
