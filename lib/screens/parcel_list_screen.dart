import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/agent.dart';
import '../models/parcel.dart';
import '../services/database_service.dart';
import '../services/payment_service.dart';
import 'qr_display_screen.dart';
import 'tracking_details_screen.dart';
import '../widgets/theme_selector.dart';

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
    // Show confirmation dialog for cancellation
    if (newStatus == 'Cancelled') {
      final confirmed = await _showCancellationDialog(parcel);
      if (!confirmed) return;
    }

    if ((parcel.status == 'Pending' && (newStatus == 'In Transit' || newStatus == 'Cancelled')) ||
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Parcels'),
        centerTitle: true,
        elevation: 0,
        actions: const [
          ThemeToggleButton(),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by Tracking Number or Status',
                      prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '${_filteredParcels.length} parcel${_filteredParcels.length != 1 ? 's' : ''} found',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Container(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Loading parcels...',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _errorMessage != null
                    ? Container(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _fetchParcels,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredParcels.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No parcels found',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your search criteria',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(20),
                            itemCount: _filteredParcels.length,
                            itemBuilder: (context, index) {
                              final parcel = _filteredParcels[index];
                              final allowedStatuses = getAllowedStatuses(parcel.status);

                              return _buildModernParcelCard(parcel, allowedStatuses, theme);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _markPaymentAsPaid(Parcel parcel) async {
    // Show confirmation dialog
    final confirmed = await _showPaymentConfirmationDialog(parcel);
    if (!confirmed) return;

    try {
      final success = await DatabaseService().markPaymentAsPaid(
        parcelId: parcel.id,
        agentId: widget.agent.id,
        agentName: widget.agent.name,
      );

      if (success) {
        // Refresh the parcel list
        _fetchParcels();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment marked as PAID for parcel #${parcel.trackingNumber}',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to mark payment as paid. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showPaymentConfirmationDialog(Parcel parcel) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.payment, color: Colors.green),
              SizedBox(width: 8),
              Text('Confirm Payment'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mark this payment as PAID?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tracking: #${parcel.trackingNumber}'),
                    Text('Amount: TZS ${parcel.amount.toStringAsFixed(2)}'),
                    Text('Method: ${PaymentService().getPaymentMethodDisplayName(parcel.paymentMethod)}'),
                    Text('From: ${parcel.fromLocation}'),
                    Text('To: ${parcel.toLocation}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  '⚠️ This action is IRREVERSIBLE. Once marked as paid, it cannot be changed back to pending.',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mark as Paid'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showCancellationDialog(Parcel parcel) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Cancel Parcel'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to cancel this parcel?',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tracking: #${parcel.trackingNumber}'),
                    Text('From: ${parcel.fromLocation}'),
                    Text('To: ${parcel.toLocation}'),
                    Text('Sender: ${parcel.senderName}'),
                    Text('Amount: TZS ${parcel.amount.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ This action cannot be undone. The sender and receiver will be notified.',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Parcel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel Parcel'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  List<String> getAllowedStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return ['In Transit', 'Cancelled'];
      case 'In Transit':
        return ['Delivered'];
      case 'Delivered':
      case 'Cancelled':
      default:
        return [];
    }
  }

  Widget _buildModernParcelCard(Parcel parcel, List<String> allowedStatuses, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with tracking number and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tracking #${parcel.trackingNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Created ${_formatDate(parcel.createdAt)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(parcel.status, theme),
              ],
            ),

            const SizedBox(height: 16),

            // Route Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.my_location, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parcel.fromLocation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 2,
                        height: 20,
                        color: Colors.grey.shade400,
                        margin: const EdgeInsets.only(left: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parcel.toLocation,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Details Grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Receiver',
                    parcel.receiverName,
                    Icons.person_outline,
                    theme,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Amount',
                    'TZS ${parcel.amount.toStringAsFixed(2)}',
                    Icons.attach_money,
                    theme,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Payment Status
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Payment: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(PaymentService().getPaymentStatusColor(parcel.paymentStatus)).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      PaymentService().getPaymentStatusDisplayName(parcel.paymentStatus),
                      style: TextStyle(
                        color: Color(PaymentService().getPaymentStatusColor(parcel.paymentStatus)),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Column(
              children: [
                if (allowedStatuses.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedStatuses[parcel.id] ?? parcel.status,
                      isExpanded: true,
                      underline: const SizedBox(),
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
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/tracking',
                            arguments: parcel.trackingNumber,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.qr_code, size: 16),
                        label: const Text('QR Code'),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Payment action button (only for pending payments)
            if (parcel.paymentStatus == 'pending') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _markPaymentAsPaid(parcel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Mark as Paid'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color;
    switch (status) {
      case 'Delivered':
        color = Colors.green;
        break;
      case 'In Transit':
        color = Colors.blue;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM dd, yyyy').format(date);
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}