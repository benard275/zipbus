class CustomerAnalytics {
  final String id;
  final String customerPhone;
  final String customerName;
  final int totalParcels;
  final double totalSpent;
  final DateTime firstParcelDate;
  final DateTime lastParcelDate;
  final double averageParcelValue;
  final List<String> frequentRoutes;
  final double satisfactionScore;
  final int satisfactionRatingsCount;
  final String customerTier; // 'bronze', 'silver', 'gold', 'platinum'
  final bool isRepeatCustomer;
  final int monthsActive;

  CustomerAnalytics({
    required this.id,
    required this.customerPhone,
    required this.customerName,
    required this.totalParcels,
    required this.totalSpent,
    required this.firstParcelDate,
    required this.lastParcelDate,
    required this.averageParcelValue,
    required this.frequentRoutes,
    required this.satisfactionScore,
    required this.satisfactionRatingsCount,
    required this.customerTier,
    required this.isRepeatCustomer,
    required this.monthsActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerPhone': customerPhone,
      'customerName': customerName,
      'totalParcels': totalParcels,
      'totalSpent': totalSpent,
      'firstParcelDate': firstParcelDate.toIso8601String(),
      'lastParcelDate': lastParcelDate.toIso8601String(),
      'averageParcelValue': averageParcelValue,
      'frequentRoutes': frequentRoutes.join(','),
      'satisfactionScore': satisfactionScore,
      'satisfactionRatingsCount': satisfactionRatingsCount,
      'customerTier': customerTier,
      'isRepeatCustomer': isRepeatCustomer ? 1 : 0,
      'monthsActive': monthsActive,
    };
  }

  factory CustomerAnalytics.fromMap(Map<String, dynamic> map) {
    return CustomerAnalytics(
      id: map['id'],
      customerPhone: map['customerPhone'],
      customerName: map['customerName'],
      totalParcels: map['totalParcels'],
      totalSpent: map['totalSpent'].toDouble(),
      firstParcelDate: DateTime.parse(map['firstParcelDate']),
      lastParcelDate: DateTime.parse(map['lastParcelDate']),
      averageParcelValue: map['averageParcelValue'].toDouble(),
      frequentRoutes: (map['frequentRoutes'] as String).split(',').where((route) => route.isNotEmpty).toList(),
      satisfactionScore: map['satisfactionScore'].toDouble(),
      satisfactionRatingsCount: map['satisfactionRatingsCount'],
      customerTier: map['customerTier'],
      isRepeatCustomer: (map['isRepeatCustomer'] as int) == 1,
      monthsActive: map['monthsActive'],
    );
  }

  // Helper method to determine customer tier based on total spent
  static String calculateCustomerTier(double totalSpent) {
    if (totalSpent >= 500000) return 'platinum'; // 500,000 TZS
    if (totalSpent >= 200000) return 'gold';     // 200,000 TZS
    if (totalSpent >= 50000) return 'silver';    // 50,000 TZS
    return 'bronze';
  }

  // Helper method to check if customer is repeat customer
  static bool isRepeatCustomerCheck(int totalParcels) {
    return totalParcels > 1;
  }
}

class SatisfactionRating {
  final String id;
  final String parcelId;
  final String trackingNumber;
  final String customerPhone;
  final int rating; // 1-5 stars
  final String? feedback;
  final DateTime createdAt;
  final String ratingType; // 'delivery', 'service', 'overall'

  SatisfactionRating({
    required this.id,
    required this.parcelId,
    required this.trackingNumber,
    required this.customerPhone,
    required this.rating,
    this.feedback,
    required this.createdAt,
    required this.ratingType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parcelId': parcelId,
      'trackingNumber': trackingNumber,
      'customerPhone': customerPhone,
      'rating': rating,
      'feedback': feedback,
      'createdAt': createdAt.toIso8601String(),
      'ratingType': ratingType,
    };
  }

  factory SatisfactionRating.fromMap(Map<String, dynamic> map) {
    return SatisfactionRating(
      id: map['id'],
      parcelId: map['parcelId'],
      trackingNumber: map['trackingNumber'],
      customerPhone: map['customerPhone'],
      rating: map['rating'],
      feedback: map['feedback'],
      createdAt: DateTime.parse(map['createdAt']),
      ratingType: map['ratingType'],
    );
  }
}

class BusinessIntelligence {
  final String id;
  final DateTime reportDate;
  final double dailyRevenue;
  final double monthlyRevenue;
  final int totalParcelsToday;
  final int totalParcelsMonth;
  final double averageParcelValue;
  final Map<String, int> parcelsByStatus;
  final Map<String, double> revenueByRoute;
  final Map<String, int> parcelsByAgent;
  final double customerSatisfactionAverage;
  final int newCustomersToday;
  final int repeatCustomersToday;
  final Map<String, int> specialHandlingStats;
  final double insuranceRevenue;

  BusinessIntelligence({
    required this.id,
    required this.reportDate,
    required this.dailyRevenue,
    required this.monthlyRevenue,
    required this.totalParcelsToday,
    required this.totalParcelsMonth,
    required this.averageParcelValue,
    required this.parcelsByStatus,
    required this.revenueByRoute,
    required this.parcelsByAgent,
    required this.customerSatisfactionAverage,
    required this.newCustomersToday,
    required this.repeatCustomersToday,
    required this.specialHandlingStats,
    required this.insuranceRevenue,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportDate': reportDate.toIso8601String(),
      'dailyRevenue': dailyRevenue,
      'monthlyRevenue': monthlyRevenue,
      'totalParcelsToday': totalParcelsToday,
      'totalParcelsMonth': totalParcelsMonth,
      'averageParcelValue': averageParcelValue,
      'parcelsByStatus': parcelsByStatus.entries.map((e) => '${e.key}:${e.value}').join(','),
      'revenueByRoute': revenueByRoute.entries.map((e) => '${e.key}:${e.value}').join(','),
      'parcelsByAgent': parcelsByAgent.entries.map((e) => '${e.key}:${e.value}').join(','),
      'customerSatisfactionAverage': customerSatisfactionAverage,
      'newCustomersToday': newCustomersToday,
      'repeatCustomersToday': repeatCustomersToday,
      'specialHandlingStats': specialHandlingStats.entries.map((e) => '${e.key}:${e.value}').join(','),
      'insuranceRevenue': insuranceRevenue,
    };
  }

  factory BusinessIntelligence.fromMap(Map<String, dynamic> map) {
    return BusinessIntelligence(
      id: map['id'],
      reportDate: DateTime.parse(map['reportDate']),
      dailyRevenue: map['dailyRevenue'].toDouble(),
      monthlyRevenue: map['monthlyRevenue'].toDouble(),
      totalParcelsToday: map['totalParcelsToday'],
      totalParcelsMonth: map['totalParcelsMonth'],
      averageParcelValue: map['averageParcelValue'].toDouble(),
      parcelsByStatus: _parseMapFromString(map['parcelsByStatus']),
      revenueByRoute: _parseDoubleMapFromString(map['revenueByRoute']),
      parcelsByAgent: _parseMapFromString(map['parcelsByAgent']),
      customerSatisfactionAverage: map['customerSatisfactionAverage'].toDouble(),
      newCustomersToday: map['newCustomersToday'],
      repeatCustomersToday: map['repeatCustomersToday'],
      specialHandlingStats: _parseMapFromString(map['specialHandlingStats']),
      insuranceRevenue: map['insuranceRevenue'].toDouble(),
    );
  }

  static Map<String, int> _parseMapFromString(String data) {
    if (data.isEmpty) return {};
    return Map.fromEntries(
      data.split(',').map((entry) {
        final parts = entry.split(':');
        return MapEntry(parts[0], int.parse(parts[1]));
      }),
    );
  }

  static Map<String, double> _parseDoubleMapFromString(String data) {
    if (data.isEmpty) return {};
    return Map.fromEntries(
      data.split(',').map((entry) {
        final parts = entry.split(':');
        return MapEntry(parts[0], double.parse(parts[1]));
      }),
    );
  }
}
