import 'package:flutter/foundation.dart';
import '../models/parcel.dart';
import '../models/agent.dart';
import 'database_service.dart';

class AnalyticsData {
  final int totalParcels;
  final int pendingParcels;
  final int inTransitParcels;
  final int deliveredParcels;
  final int cancelledParcels;
  final double totalRevenue;
  final double averageParcelValue;
  final Map<String, int> parcelsByStatus;
  final Map<String, double> revenueByPaymentMethod;
  final Map<String, int> parcelsByAgent;
  final List<DailyStats> dailyStats;
  final Map<String, int> topRoutes;

  AnalyticsData({
    required this.totalParcels,
    required this.pendingParcels,
    required this.inTransitParcels,
    required this.deliveredParcels,
    required this.cancelledParcels,
    required this.totalRevenue,
    required this.averageParcelValue,
    required this.parcelsByStatus,
    required this.revenueByPaymentMethod,
    required this.parcelsByAgent,
    required this.dailyStats,
    required this.topRoutes,
  });
}

class DailyStats {
  final DateTime date;
  final int parcelsCreated;
  final int parcelsDelivered;
  final double revenue;

  DailyStats({
    required this.date,
    required this.parcelsCreated,
    required this.parcelsDelivered,
    required this.revenue,
  });
}

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Get comprehensive analytics data
  Future<AnalyticsData> getAnalyticsData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allParcels = await _databaseService.getAllParcels();
      final allAgents = await _databaseService.getAllAgents();
      
      // Filter parcels by date range if provided
      List<Parcel> filteredParcels = allParcels;
      if (startDate != null || endDate != null) {
        filteredParcels = allParcels.where((parcel) {
          final createdAt = DateTime.tryParse(parcel.createdAt);
          if (createdAt == null) return false;
          
          if (startDate != null && createdAt.isBefore(startDate)) return false;
          if (endDate != null && createdAt.isAfter(endDate)) return false;
          
          return true;
        }).toList();
      }

      // Basic counts
      final totalParcels = filteredParcels.length;
      final pendingParcels = filteredParcels.where((p) => p.status == 'Pending').length;
      final inTransitParcels = filteredParcels.where((p) => p.status == 'In Transit').length;
      final deliveredParcels = filteredParcels.where((p) => p.status == 'Delivered').length;
      final cancelledParcels = filteredParcels.where((p) => p.status == 'Cancelled').length;

      // Revenue calculations
      final totalRevenue = filteredParcels.fold<double>(0, (sum, parcel) => sum + parcel.amount);
      final averageParcelValue = totalParcels > 0 ? totalRevenue / totalParcels : 0.0;

      // Parcels by status
      final parcelsByStatus = <String, int>{
        'Pending': pendingParcels,
        'In Transit': inTransitParcels,
        'Delivered': deliveredParcels,
        'Cancelled': cancelledParcels,
      };

      // Revenue by payment method
      final revenueByPaymentMethod = <String, double>{};
      for (final parcel in filteredParcels) {
        final method = parcel.paymentMethod;
        revenueByPaymentMethod[method] = (revenueByPaymentMethod[method] ?? 0) + parcel.amount;
      }

      // Parcels by agent
      final parcelsByAgent = <String, int>{};
      for (final parcel in filteredParcels) {
        final agent = allAgents.firstWhere(
          (a) => a.id == parcel.createdBy,
          orElse: () => Agent(
            id: parcel.createdBy,
            name: 'Unknown Agent',
            email: '',
            password: '',
            mobile: '',
            isAdmin: false,
            isFrozen: false,
          ),
        );
        parcelsByAgent[agent.name] = (parcelsByAgent[agent.name] ?? 0) + 1;
      }

      // Daily statistics for the last 30 days
      final dailyStats = _calculateDailyStats(filteredParcels);

      // Top routes
      final topRoutes = _calculateTopRoutes(filteredParcels);

      return AnalyticsData(
        totalParcels: totalParcels,
        pendingParcels: pendingParcels,
        inTransitParcels: inTransitParcels,
        deliveredParcels: deliveredParcels,
        cancelledParcels: cancelledParcels,
        totalRevenue: totalRevenue,
        averageParcelValue: averageParcelValue,
        parcelsByStatus: parcelsByStatus,
        revenueByPaymentMethod: revenueByPaymentMethod,
        parcelsByAgent: parcelsByAgent,
        dailyStats: dailyStats,
        topRoutes: topRoutes,
      );
    } catch (e) {
      debugPrint('❌ Error getting analytics data: $e');
      rethrow;
    }
  }

  /// Calculate daily statistics for the last 30 days
  List<DailyStats> _calculateDailyStats(List<Parcel> parcels) {
    final now = DateTime.now();
    final dailyStats = <DailyStats>[];

    for (int i = 29; i >= 0; i--) {
      final date = DateTime(now.year, now.month, now.day - i);
      final dateStr = date.toIso8601String().split('T')[0];

      final dayParcels = parcels.where((parcel) {
        final createdAt = DateTime.tryParse(parcel.createdAt);
        if (createdAt == null) return false;
        final createdDateStr = createdAt.toIso8601String().split('T')[0];
        return createdDateStr == dateStr;
      }).toList();

      final deliveredParcels = dayParcels.where((p) => p.status == 'Delivered').length;
      final revenue = dayParcels.fold<double>(0, (sum, parcel) => sum + parcel.amount);

      dailyStats.add(DailyStats(
        date: date,
        parcelsCreated: dayParcels.length,
        parcelsDelivered: deliveredParcels,
        revenue: revenue,
      ));
    }

    return dailyStats;
  }

  /// Calculate top routes by parcel count
  Map<String, int> _calculateTopRoutes(List<Parcel> parcels) {
    final routeCounts = <String, int>{};

    for (final parcel in parcels) {
      final route = '${parcel.fromLocation} → ${parcel.toLocation}';
      routeCounts[route] = (routeCounts[route] ?? 0) + 1;
    }

    // Sort by count and return top 10
    final sortedRoutes = routeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topRoutes = <String, int>{};
    for (int i = 0; i < sortedRoutes.length && i < 10; i++) {
      topRoutes[sortedRoutes[i].key] = sortedRoutes[i].value;
    }

    return topRoutes;
  }

  /// Get delivery performance metrics
  Future<Map<String, dynamic>> getDeliveryPerformance() async {
    try {
      final allParcels = await _databaseService.getAllParcels();
      final deliveredParcels = allParcels.where((p) => p.status == 'Delivered').toList();

      if (deliveredParcels.isEmpty) {
        return {
          'deliveryRate': 0.0,
          'averageDeliveryTime': 0.0,
          'onTimeDeliveries': 0,
          'totalDeliveries': 0,
        };
      }

      final deliveryRate = (deliveredParcels.length / allParcels.length) * 100;
      
      // Calculate average delivery time (simplified - from creation to delivery)
      double totalDeliveryTime = 0;
      int validDeliveryTimes = 0;

      for (final parcel in deliveredParcels) {
        final createdAt = DateTime.tryParse(parcel.createdAt);
        if (createdAt != null) {
          // Assume delivery time is roughly now for delivered parcels
          // In a real system, you'd track actual delivery timestamps
          final deliveryTime = DateTime.now().difference(createdAt).inHours.toDouble();
          totalDeliveryTime += deliveryTime;
          validDeliveryTimes++;
        }
      }

      final averageDeliveryTime = validDeliveryTimes > 0 
          ? totalDeliveryTime / validDeliveryTimes 
          : 0.0;

      // Calculate on-time deliveries (simplified)
      int onTimeDeliveries = 0;
      for (final parcel in deliveredParcels) {
        if (parcel.preferredDeliveryDate != null) {
          final preferredDate = DateTime.tryParse(parcel.preferredDeliveryDate!);
          final createdAt = DateTime.tryParse(parcel.createdAt);
          if (preferredDate != null && createdAt != null) {
            // Simplified: assume delivered on time if within preferred date
            final daysDifference = preferredDate.difference(createdAt).inDays;
            if (daysDifference >= 0) {
              onTimeDeliveries++;
            }
          }
        }
      }

      return {
        'deliveryRate': deliveryRate,
        'averageDeliveryTime': averageDeliveryTime,
        'onTimeDeliveries': onTimeDeliveries,
        'totalDeliveries': deliveredParcels.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting delivery performance: $e');
      return {
        'deliveryRate': 0.0,
        'averageDeliveryTime': 0.0,
        'onTimeDeliveries': 0,
        'totalDeliveries': 0,
      };
    }
  }

  /// Get payment analytics
  Future<Map<String, dynamic>> getPaymentAnalytics() async {
    try {
      final allParcels = await _databaseService.getAllParcels();
      
      final paidParcels = allParcels.where((p) => p.paymentStatus == 'paid').length;
      final pendingPayments = allParcels.where((p) => p.paymentStatus == 'pending').length;
      final failedPayments = allParcels.where((p) => p.paymentStatus == 'failed').length;
      
      final mobileMoneyRevenue = allParcels
          .where((p) => p.paymentMethod == 'mobile_money')
          .fold<double>(0, (sum, parcel) => sum + parcel.amount);
      
      final cashRevenue = allParcels
          .where((p) => p.paymentMethod == 'cash')
          .fold<double>(0, (sum, parcel) => sum + parcel.amount);

      return {
        'paidParcels': paidParcels,
        'pendingPayments': pendingPayments,
        'failedPayments': failedPayments,
        'mobileMoneyRevenue': mobileMoneyRevenue,
        'cashRevenue': cashRevenue,
        'totalParcels': allParcels.length,
      };
    } catch (e) {
      debugPrint('❌ Error getting payment analytics: $e');
      return {
        'paidParcels': 0,
        'pendingPayments': 0,
        'failedPayments': 0,
        'mobileMoneyRevenue': 0.0,
        'cashRevenue': 0.0,
        'totalParcels': 0,
      };
    }
  }
}
