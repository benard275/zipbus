import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/parcel.dart';
import '../models/agent.dart';
import '../services/database_service.dart';

class DeliveryScheduleScreen extends StatefulWidget {
  final Agent agent;

  const DeliveryScheduleScreen({
    super.key,
    required this.agent,
  });

  @override
  State<DeliveryScheduleScreen> createState() => _DeliveryScheduleScreenState();
}

class _DeliveryScheduleScreenState extends State<DeliveryScheduleScreen> {
  List<Parcel> _scheduledParcels = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchScheduledParcels();
  }

  Future<void> _fetchScheduledParcels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final allParcels = await DatabaseService().getAllParcels();
      final scheduledParcels = allParcels.where((parcel) {
        // Filter parcels that have delivery scheduling and are not delivered
        return parcel.preferredDeliveryDate != null && 
               parcel.status != 'Delivered';
      }).toList();

      // Sort by preferred delivery date
      scheduledParcels.sort((a, b) {
        final dateA = DateTime.tryParse(a.preferredDeliveryDate!) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.preferredDeliveryDate!) ?? DateTime.now();
        return dateA.compareTo(dateB);
      });

      if (mounted) {
        setState(() {
          _scheduledParcels = scheduledParcels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load scheduled parcels: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Parcel> _getParcelsForDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return _scheduledParcels.where((parcel) {
      if (parcel.preferredDeliveryDate == null) return false;
      final parcelDateStr = parcel.preferredDeliveryDate!.split('T')[0];
      return parcelDateStr == dateStr;
    }).toList();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Color _getPriorityColor(DateTime deliveryDate) {
    final now = DateTime.now();
    final difference = deliveryDate.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red; // Overdue
    } else if (difference == 0) {
      return Colors.orange; // Today
    } else if (difference == 1) {
      return Colors.amber; // Tomorrow
    } else {
      return Colors.green; // Future
    }
  }

  String _getPriorityText(DateTime deliveryDate) {
    final now = DateTime.now();
    final difference = deliveryDate.difference(now).inDays;
    
    if (difference < 0) {
      return 'OVERDUE';
    } else if (difference == 0) {
      return 'TODAY';
    } else if (difference == 1) {
      return 'TOMORROW';
    } else {
      return '$difference DAYS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Schedule'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchScheduledParcels,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Deliveries for ${DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Change Date'),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
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
                              onPressed: _fetchScheduledParcels,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _buildScheduleContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleContent() {
    final parcelsForDate = _getParcelsForDate(_selectedDate);
    
    if (parcelsForDate.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No deliveries scheduled for this date',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a different date to view scheduled deliveries',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: parcelsForDate.length,
      itemBuilder: (context, index) {
        final parcel = parcelsForDate[index];
        final deliveryDate = DateTime.tryParse(parcel.preferredDeliveryDate!) ?? DateTime.now();
        final priorityColor = _getPriorityColor(deliveryDate);
        final priorityText = _getPriorityText(deliveryDate);

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with tracking and priority
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
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: priorityColor),
                      ),
                      child: Text(
                        priorityText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Delivery details
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${parcel.fromLocation} → ${parcel.toLocation}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${parcel.receiverName} (${parcel.receiverPhone})',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                
                if (parcel.preferredDeliveryTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Preferred time: ${parcel.preferredDeliveryTime}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
                
                if (parcel.deliveryInstructions != null && parcel.deliveryInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            parcel.deliveryInstructions!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
