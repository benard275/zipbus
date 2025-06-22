import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agent.dart';
import '../models/parcel.dart';
import '../services/database_service.dart';
import '../services/payment_service.dart';
import 'qr_display_screen.dart';
import 'tracking_details_screen.dart';

class ParcelListScreen extends StatefulWidget {
  final Agent agent;

  const ParcelListScreen({super.key, required this.agent});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen> {
  List<Parcel> _parcels = [];
  List<Parcel> _filteredParcels = [];
  Map<String, String> _selectedStatuses = {};
  bool _isLoading = true;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchParcels();
    _searchController.addListener(_filterParcels);
  }

  Future<void> _fetchParcels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parcels = await DatabaseService().getParcelsByAgent(widget.agent.id);
      if (!mounted) return;
      setState(() {
        _parcels = parcels;
        _filteredParcels = parcels;
        _selectedStatuses = {for (var parcel in parcels) parcel.id: parcel.status};
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load parcels: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterParcels() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredParcels = _parcels.where((parcel) {
        return parcel.trackingNumber.toLowerCase().contains(query) ||
            parcel.status.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _updateParcelStatus(Parcel parcel, String newStatus) async {
    if ((parcel.status == 'Pending' && newStatus == 'In Transit') ||
        (parcel.status == 'In Transit' && newStatus == 'Delivered')) {
      try {
        final updatedParcel = Parcel(
          id: parcel.id,
          senderName: parcel.senderName,
          senderPhone: parcel.senderPhone,
          receiverName: parcel.receiverName,
          receiverPhone: parcel.receiverPhone,
          fromLocation: parcel.fromLocation,
          toLocation: parcel.toLocation,
          amount: parcel.amount,
          status: newStatus,
          trackingNumber: parcel.trackingNumber,
          createdBy: parcel.createdBy,
          createdAt: parcel.createdAt,
          receivedBy: parcel.receivedBy,
          deliveredBy: parcel.deliveredBy,
          // Payment fields
          paymentMethod: parcel.paymentMethod,
          paymentStatus: parcel.paymentStatus,
          paymentReference: parcel.paymentReference,
          // Delivery scheduling fields
          preferredDeliveryDate: parcel.preferredDeliveryDate,
          preferredDeliveryTime: parcel.preferredDeliveryTime,
          deliveryInstructions: parcel.deliveryInstructions,
          // Photo proof fields
          pickupPhotoPath: parcel.pickupPhotoPath,
          deliveryPhotoPath: parcel.deliveryPhotoPath,
          signaturePath: parcel.signaturePath,
        );
        await DatabaseService().updateParcel(updatedParcel);
        if (!mounted) return;
        setState(() {
          _selectedStatuses[parcel.id] = newStatus;
        });
        _fetchParcels(); // Refresh the list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update status: $e')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status change is not allowed')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Parcels'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Tracking Number or Status',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchParcels,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _filteredParcels.isEmpty
                          ? const Center(child: Text('No parcels found.'))
                          : ListView.builder(
                              itemCount: _filteredParcels.length,
                              itemBuilder: (context, index) {
                                final parcel = _filteredParcels[index];
                                final allowedStatuses = getAllowedStatuses(parcel.status);

                                return Card(
                                  elevation: 4,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header with tracking number and status
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Tracking #${parcel.trackingNumber}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: parcel.status == 'Delivered'
                                                    ? Colors.green.shade100
                                                    : parcel.status == 'In Transit'
                                                        ? Colors.blue.shade100
                                                        : Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                parcel.status,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: parcel.status == 'Delivered'
                                                      ? Colors.green.shade700
                                                      : parcel.status == 'In Transit'
                                                          ? Colors.blue.shade700
                                                          : Colors.orange.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // Parcel details
                                        Text('From: ${parcel.fromLocation}'),
                                        Text('To: ${parcel.toLocation}'),
                                        Text('Receiver: ${parcel.receiverName}'),
                                        Text('Amount: TZS ${parcel.amount.toStringAsFixed(2)}'),

                                        // Payment status
                                        Row(
                                          children: [
                                            const Text('Payment: '),
                                            Text(
                                              PaymentService().getPaymentStatusDisplayName(parcel.paymentStatus),
                                              style: TextStyle(
                                                color: Color(PaymentService().getPaymentStatusColor(parcel.paymentStatus)),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(' (${PaymentService().getPaymentMethodDisplayName(parcel.paymentMethod)})'),
                                          ],
                                        ),

                                        // Delivery scheduling info
                                        if (parcel.preferredDeliveryDate != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Scheduled: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(parcel.preferredDeliveryDate!))}',
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              if (parcel.preferredDeliveryTime != null) ...[
                                                Text(
                                                  ' at ${parcel.preferredDeliveryTime}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],

                                        const SizedBox(height: 12),

                                        // Status update and actions
                                        Row(
                                          children: [
                                            if (allowedStatuses.isNotEmpty) ...[
                                              Expanded(
                                                child: DropdownButton<String>(
                                                  value: _selectedStatuses[parcel.id] ?? parcel.status,
                                                  isExpanded: true,
                                                  items: [
                                                    DropdownMenuItem(
                                                      value: parcel.status,
                                                      child: Text(parcel.status),
                                                    ),
                                                    ...allowedStatuses.map((status) => DropdownMenuItem(
                                                          value: status,
                                                          child: Text(status),
                                                        )),
                                                  ].toList(),
                                                  onChanged: (newValue) {
                                                    if (newValue != null && newValue != parcel.status) {
                                                      _updateParcelStatus(parcel, newValue);
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    '/tracking',
                                                    arguments: parcel.trackingNumber,
                                                  );
                                                },
                                                icon: const Icon(Icons.visibility, size: 16),
                                                label: const Text('Details'),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) => QRDisplayScreen(parcel: parcel),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(Icons.qr_code, size: 16),
                                                label: const Text('QR Code'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> getAllowedStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return ['In Transit'];
      case 'In Transit':
        return ['Delivered'];
      case 'Delivered':
      default:
        return [];
    }
  }
}