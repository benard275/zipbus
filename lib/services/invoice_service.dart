import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/invoice.dart';
import '../models/parcel.dart';
import 'database_service.dart';

class InvoiceService {
  static final InvoiceService _instance = InvoiceService._internal();
  factory InvoiceService() => _instance;
  InvoiceService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Generate PDF invoice for a parcel
  Future<String?> generateInvoicePDF({
    required Parcel parcel,
    required String customerEmail,
    required String agentId,
    String? notes,
  }) async {
    try {
      // Create invoice record
      final invoice = await _createInvoiceRecord(
        parcel: parcel,
        customerEmail: customerEmail,
        agentId: agentId,
        notes: notes,
      );

      // Generate PDF
      final pdfPath = await _generatePDF(invoice, parcel);
      
      // Update invoice with PDF path
      await _updateInvoicePDFPath(invoice.id, pdfPath);

      debugPrint('✅ Invoice PDF generated: $pdfPath');
      return pdfPath;
    } catch (e) {
      debugPrint('❌ Error generating invoice PDF: $e');
      return null;
    }
  }

  /// Create invoice record in database
  Future<Invoice> _createInvoiceRecord({
    required Parcel parcel,
    required String customerEmail,
    required String agentId,
    String? notes,
  }) async {
    final now = DateTime.now();
    final dueDate = now.add(const Duration(days: 30)); // 30 days payment term

    // Calculate fees
    final subtotal = parcel.amount;
    final insuranceFee = parcel.hasInsurance ? (parcel.insurancePremium ?? 0.0) : 0.0;
    final specialHandlingFee = _calculateSpecialHandlingFee(parcel.specialHandling);
    final taxAmount = (subtotal + insuranceFee + specialHandlingFee) * 0.18; // 18% VAT
    final totalAmount = subtotal + insuranceFee + specialHandlingFee + taxAmount;

    final invoiceId = const Uuid().v4();

    // Create line items with the invoice ID
    final lineItems = <InvoiceLineItem>[
      InvoiceLineItem(
        id: const Uuid().v4(),
        invoiceId: invoiceId,
        description: 'Parcel Delivery Service (${parcel.fromLocation} → ${parcel.toLocation})',
        quantity: 1,
        unitPrice: subtotal,
        totalPrice: subtotal,
        itemType: 'shipping',
      ),
    ];

    if (insuranceFee > 0) {
      lineItems.add(InvoiceLineItem(
        id: const Uuid().v4(),
        invoiceId: invoiceId,
        description: 'Parcel Insurance (Value: TZS ${parcel.insuranceValue?.toStringAsFixed(2)})',
        quantity: 1,
        unitPrice: insuranceFee,
        totalPrice: insuranceFee,
        itemType: 'insurance',
      ));
    }

    if (specialHandlingFee > 0) {
      lineItems.add(InvoiceLineItem(
        id: const Uuid().v4(),
        invoiceId: invoiceId,
        description: 'Special Handling (${parcel.specialHandling?.toUpperCase()})',
        quantity: 1,
        unitPrice: specialHandlingFee,
        totalPrice: specialHandlingFee,
        itemType: 'special_handling',
      ));
    }

    lineItems.add(InvoiceLineItem(
      id: const Uuid().v4(),
      invoiceId: invoiceId,
      description: 'VAT (18%)',
      quantity: 1,
      unitPrice: taxAmount,
      totalPrice: taxAmount,
      itemType: 'tax',
    ));

    final invoice = Invoice(
      id: invoiceId,
      invoiceNumber: Invoice.generateInvoiceNumber(),
      parcelId: parcel.id,
      trackingNumber: parcel.trackingNumber,
      customerName: parcel.senderName,
      customerPhone: parcel.senderPhone,
      customerEmail: customerEmail,
      invoiceDate: now,
      dueDate: dueDate,
      subtotal: subtotal,
      insuranceFee: insuranceFee,
      specialHandlingFee: specialHandlingFee,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      status: 'draft',
      createdAt: now,
      createdBy: agentId,
      notes: notes,
      lineItems: lineItems,
    );

    // Save to database
    await _saveInvoiceToDatabase(invoice);

    return invoice;
  }

  /// Calculate special handling fee
  double _calculateSpecialHandlingFee(String? specialHandling) {
    switch (specialHandling?.toLowerCase()) {
      case 'fragile':
        return 5000.0; // TZS 5,000
      case 'urgent':
        return 10000.0; // TZS 10,000
      case 'cold_chain':
        return 15000.0; // TZS 15,000
      default:
        return 0.0;
    }
  }

  /// Generate PDF document
  Future<String> _generatePDF(Invoice invoice, Parcel parcel) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildInvoiceInfo(invoice),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(invoice),
            pw.SizedBox(height: 20),
            _buildParcelInfo(parcel),
            pw.SizedBox(height: 20),
            _buildLineItems(invoice.lineItems),
            pw.SizedBox(height: 20),
            _buildTotals(invoice),
            pw.SizedBox(height: 30),
            _buildPaymentInfo(),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    // Save PDF to file
    final directory = await getApplicationDocumentsDirectory();
    final invoicesDir = Directory('${directory.path}/invoices');
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    final filePath = '${invoicesDir.path}/invoice_${invoice.invoiceNumber}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }

  /// Build PDF header
  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'ZIPBUS COURIER SERVICES',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text('Fast & Reliable Parcel Delivery'),
            pw.Text('Phone: +255 629 661 245'),
            pw.Text('Email: info@zipbus.co.tz'),
          ],
        ),
        pw.Text(
          'INVOICE',
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
      ],
    );
  }

  /// Build invoice information section
  pw.Widget _buildInvoiceInfo(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice Number: ${invoice.invoiceNumber}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Invoice Date: ${_formatDate(invoice.invoiceDate)}'),
            pw.Text('Due Date: ${_formatDate(invoice.dueDate)}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Tracking Number: ${invoice.trackingNumber}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.Text('Status: ${invoice.status.toUpperCase()}'),
          ],
        ),
      ],
    );
  }

  /// Build customer information section
  pw.Widget _buildCustomerInfo(Invoice invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('BILL TO:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text(invoice.customerName, style: const pw.TextStyle(fontSize: 16)),
          pw.Text('Phone: ${invoice.customerPhone}'),
          pw.Text('Email: ${invoice.customerEmail}'),
        ],
      ),
    );
  }

  /// Build parcel information section
  pw.Widget _buildParcelInfo(Parcel parcel) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PARCEL DETAILS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('From: ${parcel.fromLocation}'),
              pw.Text('To: ${parcel.toLocation}'),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Receiver: ${parcel.receiverName}'),
              pw.Text('Phone: ${parcel.receiverPhone}'),
            ],
          ),
          if (parcel.hasInsurance) ...[
            pw.Text('Insurance: Yes (Value: TZS ${parcel.insuranceValue?.toStringAsFixed(2)})'),
          ],
          if (parcel.specialHandling != null) ...[
            pw.Text('Special Handling: ${parcel.specialHandling?.toUpperCase()}'),
          ],
        ],
      ),
    );
  }

  /// Build line items table
  pw.Widget _buildLineItems(List<InvoiceLineItem> lineItems) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Unit Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        // Line items
        ...lineItems.map((item) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(item.description),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(item.quantity.toString()),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('TZS ${item.unitPrice.toStringAsFixed(2)}'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('TZS ${item.totalPrice.toStringAsFixed(2)}'),
            ),
          ],
        )),
      ],
    );
  }

  /// Build totals section
  pw.Widget _buildTotals(Invoice invoice) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        child: pw.Column(
          children: [
            _buildTotalRow('Subtotal:', 'TZS ${invoice.subtotal.toStringAsFixed(2)}'),
            if (invoice.insuranceFee > 0)
              _buildTotalRow('Insurance Fee:', 'TZS ${invoice.insuranceFee.toStringAsFixed(2)}'),
            if (invoice.specialHandlingFee > 0)
              _buildTotalRow('Special Handling:', 'TZS ${invoice.specialHandlingFee.toStringAsFixed(2)}'),
            _buildTotalRow('VAT (18%):', 'TZS ${invoice.taxAmount.toStringAsFixed(2)}'),
            pw.Divider(thickness: 2),
            _buildTotalRow(
              'TOTAL AMOUNT:',
              'TZS ${invoice.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Build total row
  pw.Widget _buildTotalRow(String label, String amount, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 12,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build payment information
  pw.Widget _buildPaymentInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('PAYMENT INFORMATION:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          pw.Text('Mobile Money: 0629661245 (BENARD PAUL)'),
          pw.Text('Payment Terms: Net 30 days'),
          pw.Text('Please include invoice number in payment reference.'),
        ],
      ),
    );
  }

  /// Build footer
  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Thank you for choosing ZipBus Courier Services!',
        style: pw.TextStyle(
          fontSize: 14,
          fontStyle: pw.FontStyle.italic,
          color: PdfColors.grey600,
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Save invoice to database
  Future<void> _saveInvoiceToDatabase(Invoice invoice) async {
    final db = await _databaseService.database;
    
    // Insert invoice
    await db.insert('invoices', invoice.toMap());
    
    // Insert line items
    for (final item in invoice.lineItems) {
      await db.insert('invoice_line_items', item.toMap());
    }
    
    debugPrint('💾 Invoice saved to database: ${invoice.invoiceNumber}');
  }

  /// Update invoice PDF path
  Future<void> _updateInvoicePDFPath(String invoiceId, String pdfPath) async {
    final db = await _databaseService.database;
    await db.update(
      'invoices',
      {'pdfPath': pdfPath},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
  }

  /// Get all invoices
  Future<List<Invoice>> getAllInvoices() async {
    final db = await _databaseService.database;
    final result = await db.query('invoices', orderBy: 'createdAt DESC');
    return result.map((map) => Invoice.fromMap(map)).toList();
  }

  /// Get invoice by ID
  Future<Invoice?> getInvoiceById(String invoiceId) async {
    final db = await _databaseService.database;
    final result = await db.query('invoices', where: 'id = ?', whereArgs: [invoiceId]);
    if (result.isEmpty) return null;
    
    final invoice = Invoice.fromMap(result.first);
    
    // Load line items
    final lineItemsResult = await db.query('invoice_line_items', where: 'invoiceId = ?', whereArgs: [invoiceId]);
    final lineItems = lineItemsResult.map((map) => InvoiceLineItem.fromMap(map)).toList();
    
    return Invoice(
      id: invoice.id,
      invoiceNumber: invoice.invoiceNumber,
      parcelId: invoice.parcelId,
      trackingNumber: invoice.trackingNumber,
      customerName: invoice.customerName,
      customerPhone: invoice.customerPhone,
      customerEmail: invoice.customerEmail,
      invoiceDate: invoice.invoiceDate,
      dueDate: invoice.dueDate,
      subtotal: invoice.subtotal,
      insuranceFee: invoice.insuranceFee,
      specialHandlingFee: invoice.specialHandlingFee,
      taxAmount: invoice.taxAmount,
      totalAmount: invoice.totalAmount,
      status: invoice.status,
      pdfPath: invoice.pdfPath,
      createdAt: invoice.createdAt,
      createdBy: invoice.createdBy,
      notes: invoice.notes,
      lineItems: lineItems,
    );
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String status) async {
    final db = await _databaseService.database;
    await db.update(
      'invoices',
      {'status': status},
      where: 'id = ?',
      whereArgs: [invoiceId],
    );
    debugPrint('📄 Invoice status updated: $invoiceId -> $status');
  }
}
