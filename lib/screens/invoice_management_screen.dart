import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/invoice.dart';
import '../models/parcel.dart';
import '../services/invoice_service.dart';
import '../services/database_service.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() => _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final InvoiceService _invoiceService = InvoiceService();
  final DatabaseService _databaseService = DatabaseService();

  List<Invoice> _invoices = [];
  bool _isLoading = true;
  String _selectedStatus = 'all';

  final List<String> _statusOptions = ['all', 'draft', 'sent', 'paid', 'overdue', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      final invoices = await _invoiceService.getAllInvoices();
      setState(() {
        _invoices = invoices;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoices: $e')),
        );
      }
    }
  }

  List<Invoice> get _filteredInvoices {
    if (_selectedStatus == 'all') {
      return _invoices;
    }
    return _invoices.where((invoice) => invoice.status == _selectedStatus).toList();
  }

  Future<void> _generateInvoiceForParcel() async {
    // Show dialog to select parcel and generate invoice
    final parcels = await _databaseService.getAllParcels();
    final deliveredParcels = parcels.where((p) => p.status == 'Delivered').toList();

    if (deliveredParcels.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No delivered parcels available for invoicing')),
        );
      }
      return;
    }

    if (!mounted) return;

    final selectedParcel = await showDialog<Parcel>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Parcel for Invoice'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: deliveredParcels.length,
            itemBuilder: (context, index) {
              final parcel = deliveredParcels[index];
              return ListTile(
                title: Text('${parcel.trackingNumber} - ${parcel.senderName}'),
                subtitle: Text('${parcel.fromLocation} → ${parcel.toLocation}'),
                trailing: Text('TZS ${parcel.amount.toStringAsFixed(2)}'),
                onTap: () => Navigator.of(context).pop(parcel),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedParcel == null) return;

    // Show email input dialog
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customer Email'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'customer@example.com',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(emailController.text.trim()),
            child: const Text('Generate Invoice'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    // Generate invoice
    setState(() => _isLoading = true);

    try {
      final pdfPath = await _invoiceService.generateInvoicePDF(
        parcel: selectedParcel,
        customerEmail: email,
        agentId: selectedParcel.createdBy,
      );

      if (pdfPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invoice generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadInvoices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _viewInvoicePDF(Invoice invoice) async {
    if (invoice.pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF not available for this invoice')),
      );
      return;
    }

    try {
      final file = File(invoice.pdfPath!);
      if (await file.exists()) {
        final uri = Uri.file(invoice.pdfPath!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } else {
          throw 'Could not launch PDF viewer';
        }
      } else {
        throw 'PDF file not found';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening PDF: $e')),
        );
      }
    }
  }

  Future<void> _updateInvoiceStatus(Invoice invoice, String newStatus) async {
    try {
      await _invoiceService.updateInvoiceStatus(invoice.id, newStatus);
      await _loadInvoices();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invoice status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Management'),
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _generateInvoiceForParcel,
        backgroundColor: Colors.purple[800],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Status Filter
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter by status: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Invoices List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredInvoices.isEmpty
                    ? const Center(
                        child: Text(
                          'No invoices found',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _filteredInvoices[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(invoice.status),
                                child: Text(
                                  invoice.status.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(
                                'Invoice ${invoice.invoiceNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Customer: ${invoice.customerName}'),
                                  Text('Tracking: ${invoice.trackingNumber}'),
                                  Text('Date: ${DateFormat('MMM dd, yyyy').format(invoice.invoiceDate)}'),
                                  Text('Due: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate)}'),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'TZS ${invoice.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    invoice.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _getStatusColor(invoice.status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _showInvoiceDetails(invoice),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showInvoiceDetails(Invoice invoice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Invoice ${invoice.invoiceNumber}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),

              // Invoice Details
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildDetailRow('Customer', invoice.customerName),
                    _buildDetailRow('Email', invoice.customerEmail),
                    _buildDetailRow('Phone', invoice.customerPhone),
                    _buildDetailRow('Tracking Number', invoice.trackingNumber),
                    _buildDetailRow('Invoice Date', DateFormat('MMM dd, yyyy').format(invoice.invoiceDate)),
                    _buildDetailRow('Due Date', DateFormat('MMM dd, yyyy').format(invoice.dueDate)),
                    _buildDetailRow('Status', invoice.status.toUpperCase()),
                    const SizedBox(height: 16),
                    
                    // Amount Breakdown
                    const Text(
                      'Amount Breakdown',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow('Subtotal', 'TZS ${invoice.subtotal.toStringAsFixed(2)}'),
                    if (invoice.insuranceFee > 0)
                      _buildDetailRow('Insurance Fee', 'TZS ${invoice.insuranceFee.toStringAsFixed(2)}'),
                    if (invoice.specialHandlingFee > 0)
                      _buildDetailRow('Special Handling', 'TZS ${invoice.specialHandlingFee.toStringAsFixed(2)}'),
                    _buildDetailRow('Tax (18%)', 'TZS ${invoice.taxAmount.toStringAsFixed(2)}'),
                    const Divider(),
                    _buildDetailRow(
                      'Total Amount',
                      'TZS ${invoice.totalAmount.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                    
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Notes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(invoice.notes!),
                    ],
                  ],
                ),
              ),

              // Action Buttons
              const SizedBox(height: 16),
              Row(
                children: [
                  if (invoice.pdfPath != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _viewInvoicePDF(invoice),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('View PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButton<String>(
                      value: invoice.status,
                      isExpanded: true,
                      items: ['draft', 'sent', 'paid', 'overdue', 'cancelled'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text('Mark as ${status.toUpperCase()}'),
                        );
                      }).toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null && newStatus != invoice.status) {
                          _updateInvoiceStatus(invoice, newStatus);
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
