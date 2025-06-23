import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_analytics.dart';
import '../models/parcel.dart';
import 'database_service.dart';

class CustomerAnalyticsService {
  static final CustomerAnalyticsService _instance = CustomerAnalyticsService._internal();
  factory CustomerAnalyticsService() => _instance;
  CustomerAnalyticsService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Update customer analytics for a customer
  Future<void> updateCustomerAnalytics(String customerPhone) async {
    try {
      final db = await _databaseService.database;

      // Get all parcels for this customer (as sender)
      final parcelsResult = await db.query(
        'parcels',
        where: 'senderPhone = ?',
        whereArgs: [customerPhone],
        orderBy: 'createdAt ASC',
      );

      if (parcelsResult.isEmpty) {
        debugPrint('No parcels found for customer: $customerPhone');
        return;
      }

      final parcels = parcelsResult.map((map) => Parcel.fromMap(map)).toList();

      // Calculate analytics
      final totalParcels = parcels.length;
      final totalSpent = parcels.fold<double>(0.0, (sum, parcel) => sum + parcel.amount);
      final firstParcelDate = DateTime.parse(parcels.first.createdAt);
      final lastParcelDate = DateTime.parse(parcels.last.createdAt);
      final averageParcelValue = totalSpent / totalParcels;

      // Get frequent routes
      final routeFrequency = <String, int>{};
      for (final parcel in parcels) {
        final route = '${parcel.fromLocation} → ${parcel.toLocation}';
        routeFrequency[route] = (routeFrequency[route] ?? 0) + 1;
      }
      
      final frequentRoutes = routeFrequency.entries
          .where((entry) => entry.value > 1)
          .map((entry) => entry.key)
          .toList();

      // Get satisfaction score
      final satisfactionResult = await db.rawQuery('''
        SELECT AVG(rating) as avgRating, COUNT(*) as ratingCount
        FROM satisfaction_ratings sr
        JOIN parcels p ON sr.parcelId = p.id
        WHERE p.senderPhone = ?
      ''', [customerPhone]);

      final satisfactionScore = satisfactionResult.isNotEmpty && satisfactionResult.first['avgRating'] != null
          ? (satisfactionResult.first['avgRating'] as num).toDouble()
          : 0.0;
      final satisfactionRatingsCount = satisfactionResult.isNotEmpty
          ? satisfactionResult.first['ratingCount'] as int
          : 0;

      // Calculate customer tier
      final customerTier = CustomerAnalytics.calculateCustomerTier(totalSpent);

      // Check if repeat customer
      final isRepeatCustomer = CustomerAnalytics.isRepeatCustomerCheck(totalParcels);

      // Calculate months active
      final monthsActive = _calculateMonthsActive(firstParcelDate, lastParcelDate);

      // Get customer name from most recent parcel
      final customerName = parcels.last.senderName;

      // Create or update customer analytics
      final analytics = CustomerAnalytics(
        id: const Uuid().v4(),
        customerPhone: customerPhone,
        customerName: customerName,
        totalParcels: totalParcels,
        totalSpent: totalSpent,
        firstParcelDate: firstParcelDate,
        lastParcelDate: lastParcelDate,
        averageParcelValue: averageParcelValue,
        frequentRoutes: frequentRoutes,
        satisfactionScore: satisfactionScore,
        satisfactionRatingsCount: satisfactionRatingsCount,
        customerTier: customerTier,
        isRepeatCustomer: isRepeatCustomer,
        monthsActive: monthsActive,
      );

      // Save to database
      await db.insert(
        'customer_analytics',
        analytics.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('📊 Customer analytics updated: $customerPhone');
      debugPrint('   Total Parcels: $totalParcels');
      debugPrint('   Total Spent: TZS ${totalSpent.toStringAsFixed(2)}');
      debugPrint('   Customer Tier: $customerTier');
      debugPrint('   Satisfaction Score: ${satisfactionScore.toStringAsFixed(1)}/5');

    } catch (e) {
      debugPrint('❌ Error updating customer analytics: $e');
    }
  }

  /// Calculate months active
  int _calculateMonthsActive(DateTime firstDate, DateTime lastDate) {
    final difference = lastDate.difference(firstDate);
    return (difference.inDays / 30).ceil();
  }

  /// Get customer analytics by phone
  Future<CustomerAnalytics?> getCustomerAnalytics(String customerPhone) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'customer_analytics',
      where: 'customerPhone = ?',
      whereArgs: [customerPhone],
    );

    if (result.isEmpty) return null;
    return CustomerAnalytics.fromMap(result.first);
  }

  /// Get all customer analytics
  Future<List<CustomerAnalytics>> getAllCustomerAnalytics() async {
    final db = await _databaseService.database;
    final result = await db.query('customer_analytics', orderBy: 'totalSpent DESC');
    return result.map((map) => CustomerAnalytics.fromMap(map)).toList();
  }

  /// Get repeat customers
  Future<List<CustomerAnalytics>> getRepeatCustomers() async {
    final db = await _databaseService.database;
    final result = await db.query(
      'customer_analytics',
      where: 'isRepeatCustomer = ?',
      whereArgs: [1],
      orderBy: 'totalSpent DESC',
    );
    return result.map((map) => CustomerAnalytics.fromMap(map)).toList();
  }

  /// Get customers by tier
  Future<List<CustomerAnalytics>> getCustomersByTier(String tier) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'customer_analytics',
      where: 'customerTier = ?',
      whereArgs: [tier],
      orderBy: 'totalSpent DESC',
    );
    return result.map((map) => CustomerAnalytics.fromMap(map)).toList();
  }

  /// Get top customers by spending
  Future<List<CustomerAnalytics>> getTopCustomers({int limit = 10}) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'customer_analytics',
      orderBy: 'totalSpent DESC',
      limit: limit,
    );
    return result.map((map) => CustomerAnalytics.fromMap(map)).toList();
  }

  /// Add satisfaction rating
  Future<void> addSatisfactionRating({
    required String parcelId,
    required String trackingNumber,
    required String customerPhone,
    required int rating,
    String? feedback,
    String ratingType = 'overall',
  }) async {
    try {
      final satisfactionRating = SatisfactionRating(
        id: const Uuid().v4(),
        parcelId: parcelId,
        trackingNumber: trackingNumber,
        customerPhone: customerPhone,
        rating: rating,
        feedback: feedback,
        createdAt: DateTime.now(),
        ratingType: ratingType,
      );

      final db = await _databaseService.database;
      await db.insert('satisfaction_ratings', satisfactionRating.toMap());

      // Update customer analytics
      await updateCustomerAnalytics(customerPhone);

      debugPrint('⭐ Satisfaction rating added: $rating/5 for $trackingNumber');
    } catch (e) {
      debugPrint('❌ Error adding satisfaction rating: $e');
    }
  }

  /// Get satisfaction ratings for a customer
  Future<List<SatisfactionRating>> getCustomerSatisfactionRatings(String customerPhone) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'satisfaction_ratings',
      where: 'customerPhone = ?',
      whereArgs: [customerPhone],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => SatisfactionRating.fromMap(map)).toList();
  }

  /// Get satisfaction ratings for a parcel
  Future<List<SatisfactionRating>> getParcelSatisfactionRatings(String parcelId) async {
    final db = await _databaseService.database;
    final result = await db.query(
      'satisfaction_ratings',
      where: 'parcelId = ?',
      whereArgs: [parcelId],
      orderBy: 'createdAt DESC',
    );
    return result.map((map) => SatisfactionRating.fromMap(map)).toList();
  }

  /// Get overall satisfaction statistics
  Future<Map<String, dynamic>> getSatisfactionStatistics() async {
    final db = await _databaseService.database;

    // Overall average rating
    final avgResult = await db.rawQuery('SELECT AVG(rating) as avgRating, COUNT(*) as totalRatings FROM satisfaction_ratings');
    final averageRating = avgResult.isNotEmpty && avgResult.first['avgRating'] != null
        ? (avgResult.first['avgRating'] as num).toDouble()
        : 0.0;
    final totalRatings = avgResult.isNotEmpty ? avgResult.first['totalRatings'] as int : 0;

    // Rating distribution
    final distributionResult = await db.rawQuery('''
      SELECT rating, COUNT(*) as count
      FROM satisfaction_ratings
      GROUP BY rating
      ORDER BY rating
    ''');

    final ratingDistribution = <int, int>{};
    for (final row in distributionResult) {
      ratingDistribution[row['rating'] as int] = row['count'] as int;
    }

    // Recent ratings trend (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final trendResult = await db.rawQuery('''
      SELECT 
        strftime('%Y-%m-%d', createdAt) as date,
        AVG(rating) as avgRating,
        COUNT(*) as count
      FROM satisfaction_ratings
      WHERE createdAt >= ?
      GROUP BY strftime('%Y-%m-%d', createdAt)
      ORDER BY date
    ''', [thirtyDaysAgo]);

    final recentTrend = trendResult.map((row) => {
      'date': row['date'] as String,
      'averageRating': (row['avgRating'] as num).toDouble(),
      'count': row['count'] as int,
    }).toList();

    return {
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'ratingDistribution': ratingDistribution,
      'recentTrend': recentTrend,
    };
  }

  /// Get customer retention metrics
  Future<Map<String, dynamic>> getCustomerRetentionMetrics() async {
    final db = await _databaseService.database;

    // Total customers
    final totalCustomersResult = await db.rawQuery('SELECT COUNT(DISTINCT senderPhone) as count FROM parcels');
    final totalCustomers = totalCustomersResult.first['count'] as int;

    // Repeat customers
    final repeatCustomersResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM (
        SELECT senderPhone, COUNT(*) as parcelCount
        FROM parcels
        GROUP BY senderPhone
        HAVING parcelCount > 1
      )
    ''');
    final repeatCustomers = repeatCustomersResult.first['count'] as int;

    // Customer retention rate
    final retentionRate = totalCustomers > 0 ? (repeatCustomers / totalCustomers) * 100 : 0.0;

    // New customers this month
    final thisMonth = DateTime.now();
    final startOfMonth = DateTime(thisMonth.year, thisMonth.month, 1).toIso8601String();
    final newCustomersResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT senderPhone) as count
      FROM parcels
      WHERE senderPhone NOT IN (
        SELECT DISTINCT senderPhone
        FROM parcels
        WHERE createdAt < ?
      ) AND createdAt >= ?
    ''', [startOfMonth, startOfMonth]);
    final newCustomersThisMonth = newCustomersResult.first['count'] as int;

    // Customer lifetime value
    final clvResult = await db.rawQuery('SELECT AVG(totalSpent) as avgClv FROM customer_analytics');
    final averageCustomerLifetimeValue = clvResult.isNotEmpty && clvResult.first['avgClv'] != null
        ? (clvResult.first['avgClv'] as num).toDouble()
        : 0.0;

    return {
      'totalCustomers': totalCustomers,
      'repeatCustomers': repeatCustomers,
      'retentionRate': retentionRate,
      'newCustomersThisMonth': newCustomersThisMonth,
      'averageCustomerLifetimeValue': averageCustomerLifetimeValue,
    };
  }

  /// Generate business intelligence report
  Future<BusinessIntelligence> generateBusinessIntelligenceReport({DateTime? date}) async {
    final reportDate = date ?? DateTime.now();
    final today = DateTime(reportDate.year, reportDate.month, reportDate.day);
    final tomorrow = today.add(const Duration(days: 1));
    final startOfMonth = DateTime(reportDate.year, reportDate.month, 1);

    final db = await _databaseService.database;

    // Daily revenue
    final dailyRevenueResult = await db.rawQuery('''
      SELECT SUM(amount) as revenue
      FROM parcels
      WHERE createdAt >= ? AND createdAt < ?
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    final dailyRevenue = dailyRevenueResult.isNotEmpty && dailyRevenueResult.first['revenue'] != null
        ? (dailyRevenueResult.first['revenue'] as num).toDouble()
        : 0.0;

    // Monthly revenue
    final monthlyRevenueResult = await db.rawQuery('''
      SELECT SUM(amount) as revenue
      FROM parcels
      WHERE createdAt >= ?
    ''', [startOfMonth.toIso8601String()]);
    final monthlyRevenue = monthlyRevenueResult.isNotEmpty && monthlyRevenueResult.first['revenue'] != null
        ? (monthlyRevenueResult.first['revenue'] as num).toDouble()
        : 0.0;

    // Parcel counts
    final dailyParcelsResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM parcels
      WHERE createdAt >= ? AND createdAt < ?
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    final totalParcelsToday = dailyParcelsResult.first['count'] as int;

    final monthlyParcelsResult = await db.rawQuery('''
      SELECT COUNT(*) as count
      FROM parcels
      WHERE createdAt >= ?
    ''', [startOfMonth.toIso8601String()]);
    final totalParcelsMonth = monthlyParcelsResult.first['count'] as int;

    // Average parcel value
    final averageParcelValue = totalParcelsToday > 0 ? dailyRevenue / totalParcelsToday : 0.0;

    // Parcels by status
    final statusResult = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM parcels
      WHERE createdAt >= ? AND createdAt < ?
      GROUP BY status
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    
    final parcelsByStatus = <String, int>{};
    for (final row in statusResult) {
      parcelsByStatus[row['status'] as String] = row['count'] as int;
    }

    // Revenue by route
    final routeResult = await db.rawQuery('''
      SELECT 
        (fromLocation || ' → ' || toLocation) as route,
        SUM(amount) as revenue
      FROM parcels
      WHERE createdAt >= ? AND createdAt < ?
      GROUP BY fromLocation, toLocation
      ORDER BY revenue DESC
      LIMIT 5
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    
    final revenueByRoute = <String, double>{};
    for (final row in routeResult) {
      revenueByRoute[row['route'] as String] = (row['revenue'] as num).toDouble();
    }

    // Parcels by agent
    final agentResult = await db.rawQuery('''
      SELECT createdBy, COUNT(*) as count
      FROM parcels
      WHERE createdAt >= ? AND createdAt < ?
      GROUP BY createdBy
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    
    final parcelsByAgent = <String, int>{};
    for (final row in agentResult) {
      parcelsByAgent[row['createdBy'] as String] = row['count'] as int;
    }

    // Customer satisfaction average
    final satisfactionResult = await db.rawQuery('''
      SELECT AVG(rating) as avgRating
      FROM satisfaction_ratings
      WHERE createdAt >= ? AND createdAt < ?
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    final customerSatisfactionAverage = satisfactionResult.isNotEmpty && satisfactionResult.first['avgRating'] != null
        ? (satisfactionResult.first['avgRating'] as num).toDouble()
        : 0.0;

    // New and repeat customers today
    final newCustomersResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT senderPhone) as count
      FROM parcels
      WHERE senderPhone NOT IN (
        SELECT DISTINCT senderPhone
        FROM parcels
        WHERE createdAt < ?
      ) AND createdAt >= ? AND createdAt < ?
    ''', [today.toIso8601String(), today.toIso8601String(), tomorrow.toIso8601String()]);
    final newCustomersToday = newCustomersResult.first['count'] as int;

    final repeatCustomersResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT senderPhone) as count
      FROM parcels
      WHERE senderPhone IN (
        SELECT DISTINCT senderPhone
        FROM parcels
        WHERE createdAt < ?
      ) AND createdAt >= ? AND createdAt < ?
    ''', [today.toIso8601String(), today.toIso8601String(), tomorrow.toIso8601String()]);
    final repeatCustomersToday = repeatCustomersResult.first['count'] as int;

    // Special handling stats
    final specialHandlingResult = await db.rawQuery('''
      SELECT specialHandling, COUNT(*) as count
      FROM parcels
      WHERE specialHandling IS NOT NULL AND createdAt >= ? AND createdAt < ?
      GROUP BY specialHandling
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    
    final specialHandlingStats = <String, int>{};
    for (final row in specialHandlingResult) {
      specialHandlingStats[row['specialHandling'] as String] = row['count'] as int;
    }

    // Insurance revenue
    final insuranceResult = await db.rawQuery('''
      SELECT SUM(insurancePremium) as revenue
      FROM parcels
      WHERE hasInsurance = 1 AND createdAt >= ? AND createdAt < ?
    ''', [today.toIso8601String(), tomorrow.toIso8601String()]);
    final insuranceRevenue = insuranceResult.isNotEmpty && insuranceResult.first['revenue'] != null
        ? (insuranceResult.first['revenue'] as num).toDouble()
        : 0.0;

    final businessIntelligence = BusinessIntelligence(
      id: const Uuid().v4(),
      reportDate: reportDate,
      dailyRevenue: dailyRevenue,
      monthlyRevenue: monthlyRevenue,
      totalParcelsToday: totalParcelsToday,
      totalParcelsMonth: totalParcelsMonth,
      averageParcelValue: averageParcelValue,
      parcelsByStatus: parcelsByStatus,
      revenueByRoute: revenueByRoute,
      parcelsByAgent: parcelsByAgent,
      customerSatisfactionAverage: customerSatisfactionAverage,
      newCustomersToday: newCustomersToday,
      repeatCustomersToday: repeatCustomersToday,
      specialHandlingStats: specialHandlingStats,
      insuranceRevenue: insuranceRevenue,
    );

    debugPrint('🧠 Business intelligence report generated');
    debugPrint('   Daily Revenue: TZS ${dailyRevenue.toStringAsFixed(2)}');
    debugPrint('   Monthly Revenue: TZS ${monthlyRevenue.toStringAsFixed(2)}');
    debugPrint('   Parcels Today: $totalParcelsToday');
    debugPrint('   Customer Satisfaction: ${customerSatisfactionAverage.toStringAsFixed(1)}/5');

    return businessIntelligence;
  }
}
