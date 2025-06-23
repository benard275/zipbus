class Invoice {
  final String id;
  final String invoiceNumber;
  final String parcelId;
  final String trackingNumber;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double subtotal;
  final double insuranceFee;
  final double specialHandlingFee;
  final double taxAmount;
  final double totalAmount;
  final String status; // 'draft', 'sent', 'paid', 'overdue', 'cancelled'
  final String? pdfPath;
  final DateTime createdAt;
  final String createdBy;
  final String? notes;
  final List<InvoiceLineItem> lineItems;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.parcelId,
    required this.trackingNumber,
    required this.customerName,
    required this.customerPhone,
    required this.customerEmail,
    required this.invoiceDate,
    required this.dueDate,
    required this.subtotal,
    required this.insuranceFee,
    required this.specialHandlingFee,
    required this.taxAmount,
    required this.totalAmount,
    required this.status,
    this.pdfPath,
    required this.createdAt,
    required this.createdBy,
    this.notes,
    required this.lineItems,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'parcelId': parcelId,
      'trackingNumber': trackingNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'subtotal': subtotal,
      'insuranceFee': insuranceFee,
      'specialHandlingFee': specialHandlingFee,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'status': status,
      'pdfPath': pdfPath,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'notes': notes,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map) {
    return Invoice(
      id: map['id'],
      invoiceNumber: map['invoiceNumber'],
      parcelId: map['parcelId'],
      trackingNumber: map['trackingNumber'],
      customerName: map['customerName'],
      customerPhone: map['customerPhone'],
      customerEmail: map['customerEmail'],
      invoiceDate: DateTime.parse(map['invoiceDate']),
      dueDate: DateTime.parse(map['dueDate']),
      subtotal: map['subtotal'].toDouble(),
      insuranceFee: map['insuranceFee'].toDouble(),
      specialHandlingFee: map['specialHandlingFee'].toDouble(),
      taxAmount: map['taxAmount'].toDouble(),
      totalAmount: map['totalAmount'].toDouble(),
      status: map['status'],
      pdfPath: map['pdfPath'],
      createdAt: DateTime.parse(map['createdAt']),
      createdBy: map['createdBy'],
      notes: map['notes'],
      lineItems: [], // Will be loaded separately
    );
  }

  // Generate invoice number
  static String generateInvoiceNumber() {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final time = now.millisecondsSinceEpoch.toString().substring(8);
    return 'ZB$year$month$day$time';
  }
}

class InvoiceLineItem {
  final String id;
  final String invoiceId;
  final String description;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String itemType; // 'shipping', 'insurance', 'special_handling', 'tax'

  InvoiceLineItem({
    required this.id,
    required this.invoiceId,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.itemType,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'itemType': itemType,
    };
  }

  factory InvoiceLineItem.fromMap(Map<String, dynamic> map) {
    return InvoiceLineItem(
      id: map['id'],
      invoiceId: map['invoiceId'],
      description: map['description'],
      quantity: map['quantity'],
      unitPrice: map['unitPrice'].toDouble(),
      totalPrice: map['totalPrice'].toDouble(),
      itemType: map['itemType'],
    );
  }
}

class FinancialReport {
  final String id;
  final DateTime reportDate;
  final String reportType; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime endDate;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final double grossProfit;
  final int totalParcels;
  final double averageParcelValue;
  final Map<String, double> revenueByCategory;
  final Map<String, double> expensesByCategory;
  final Map<String, int> parcelsByStatus;
  final double taxCollected;
  final double insuranceRevenue;
  final double specialHandlingRevenue;
  final List<TopRoute> topRoutes;
  final List<AgentPerformance> agentPerformance;

  FinancialReport({
    required this.id,
    required this.reportDate,
    required this.reportType,
    required this.startDate,
    required this.endDate,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.grossProfit,
    required this.totalParcels,
    required this.averageParcelValue,
    required this.revenueByCategory,
    required this.expensesByCategory,
    required this.parcelsByStatus,
    required this.taxCollected,
    required this.insuranceRevenue,
    required this.specialHandlingRevenue,
    required this.topRoutes,
    required this.agentPerformance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reportDate': reportDate.toIso8601String(),
      'reportType': reportType,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalRevenue': totalRevenue,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'grossProfit': grossProfit,
      'totalParcels': totalParcels,
      'averageParcelValue': averageParcelValue,
      'revenueByCategory': revenueByCategory.entries.map((e) => '${e.key}:${e.value}').join(','),
      'expensesByCategory': expensesByCategory.entries.map((e) => '${e.key}:${e.value}').join(','),
      'parcelsByStatus': parcelsByStatus.entries.map((e) => '${e.key}:${e.value}').join(','),
      'taxCollected': taxCollected,
      'insuranceRevenue': insuranceRevenue,
      'specialHandlingRevenue': specialHandlingRevenue,
    };
  }
}

class TopRoute {
  final String route;
  final int parcelCount;
  final double revenue;
  final double averageValue;

  TopRoute({
    required this.route,
    required this.parcelCount,
    required this.revenue,
    required this.averageValue,
  });
}

class AgentPerformance {
  final String agentId;
  final String agentName;
  final int parcelsHandled;
  final double revenueGenerated;
  final double averageParcelValue;
  final double satisfactionScore;

  AgentPerformance({
    required this.agentId,
    required this.agentName,
    required this.parcelsHandled,
    required this.revenueGenerated,
    required this.averageParcelValue,
    required this.satisfactionScore,
  });
}
