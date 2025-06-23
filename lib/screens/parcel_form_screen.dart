import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import '../models/agent.dart';
import '../models/parcel.dart';
import '../services/database_service.dart';
import '../services/payment_service.dart';
import '../services/customer_analytics_service.dart';

class ParcelFormScreen extends StatefulWidget {
  final Agent agent;

  const ParcelFormScreen({super.key, required this.agent});

  @override
  State<ParcelFormScreen> createState() => _ParcelFormScreenState();
}

class _ParcelFormScreenState extends State<ParcelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderNameController = TextEditingController();
  final _senderPhoneController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _fromLocationController = TextEditingController();
  final _toLocationController = TextEditingController();
  final _amountController = TextEditingController();
  final _deliveryInstructionsController = TextEditingController();

  String _trackingNumber = '';
  bool _isLoading = false;
  String? _errorMessage;

  // Payment fields
  String _paymentMethod = 'cash';
  String _paymentStatus = 'pending';
  String? _paymentReference;

  // Delivery scheduling fields
  DateTime? _preferredDeliveryDate;
  TimeOfDay? _preferredDeliveryTime;

  // Smart parcel features
  bool _hasInsurance = false;
  double? _insuranceValue;
  double? _insurancePremium;
  String? _specialHandling;
  double? _declaredValue;

  final PaymentService _paymentService = PaymentService();
  final CustomerAnalyticsService _analyticsService = CustomerAnalyticsService();

  // Special handling options
  final List<String> _specialHandlingOptions = [
    'standard',
    'fragile',
    'urgent',
    'cold_chain',
  ];

  final Map<String, String> _specialHandlingLabels = {
    'standard': 'Standard Handling',
    'fragile': 'Fragile (+ TZS 5,000)',
    'urgent': 'Urgent Delivery (+ TZS 10,000)',
    'cold_chain': 'Cold Chain (+ TZS 15,000)',
  };

  final Map<String, double> _specialHandlingFees = {
    'standard': 0.0,
    'fragile': 5000.0,
    'urgent': 10000.0,
    'cold_chain': 15000.0,
  };

  @override
  void initState() {
    super.initState();
    _generateTrackingNumber();
  }

  Future<void> _generateTrackingNumber() async {
    final dbService = DatabaseService();
    String newTrackingNumber;
    bool isUnique = false;

    while (!isUnique) {
      final randomNum = 100000 + Random().nextInt(900000);
      newTrackingNumber = randomNum.toString().padLeft(6, '0'); // Ensure 6 digits
      final existingParcel = await dbService.getParcelByTrackingNumber(newTrackingNumber);
      if (existingParcel == null) {
        isUnique = true;
        setState(() {
          _trackingNumber = newTrackingNumber;
        });
      }
    }
  }

  Future<void> _submitParcel() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final amount = double.tryParse(_amountController.text);
        if (amount == null || amount <= 0) {
          throw Exception('Invalid amount. Please enter a positive number.');
        }

        // Process mobile money payment if selected
        if (_paymentMethod == 'mobile_money') {
          final paymentRef = await _paymentService.processMobileMoneyPayment(
            customerPhone: _senderPhoneController.text.trim(),
            amount: amount,
            trackingNumber: _trackingNumber,
          );

          if (paymentRef != null) {
            _paymentReference = paymentRef;
            _paymentStatus = 'pending';
          } else {
            throw Exception('Failed to initiate mobile money payment. Please try again.');
          }
        }

        final parcel = Parcel(
          id: const Uuid().v4(),
          senderName: _senderNameController.text.trim(),
          senderPhone: _senderPhoneController.text.trim(),
          receiverName: _receiverNameController.text.trim(),
          receiverPhone: _receiverPhoneController.text.trim(),
          fromLocation: _fromLocationController.text.trim(),
          toLocation: _toLocationController.text.trim(),
          amount: amount,
          status: 'Pending',
          trackingNumber: _trackingNumber,
          createdBy: widget.agent.id,
          createdAt: DateTime.now().toIso8601String(),
          receivedBy: null,
          deliveredBy: null,
          // Payment fields
          paymentMethod: _paymentMethod,
          paymentStatus: _paymentStatus,
          paymentReference: _paymentReference,
          // Delivery scheduling fields
          preferredDeliveryDate: _preferredDeliveryDate?.toIso8601String(),
          preferredDeliveryTime: _preferredDeliveryTime != null
              ? '${_preferredDeliveryTime!.hour.toString().padLeft(2, '0')}:${_preferredDeliveryTime!.minute.toString().padLeft(2, '0')}'
              : null,
          deliveryInstructions: _deliveryInstructionsController.text.trim().isEmpty
              ? null
              : _deliveryInstructionsController.text.trim(),
          // Smart parcel features
          hasInsurance: _hasInsurance,
          insuranceValue: _insuranceValue,
          insurancePremium: _insurancePremium,
          specialHandling: _specialHandling,
          declaredValue: _declaredValue,
        );

        await DatabaseService().insertParcel(parcel);

        // Update customer analytics
        await _analyticsService.updateCustomerAnalytics(parcel.senderPhone);

        // Debug: Check delivery schedules in database
        await DatabaseService().debugDeliverySchedules();

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to create parcel: $e';
          if (_errorMessage!.contains('UNIQUE constraint failed')) {
            _errorMessage = 'Tracking number conflict. Regenerating...';
            _generateTrackingNumber();
          }
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _selectDeliveryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _preferredDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _preferredDeliveryDate) {
      setState(() {
        _preferredDeliveryDate = picked;
      });
    }
  }

  Future<void> _selectDeliveryTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _preferredDeliveryTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _preferredDeliveryTime) {
      setState(() {
        _preferredDeliveryTime = picked;
      });
    }
  }

  void _calculateInsurancePremium() {
    if (_hasInsurance && _insuranceValue != null && _insuranceValue! > 0) {
      // Insurance premium is 2% of declared value, minimum TZS 2,000
      _insurancePremium = (_insuranceValue! * 0.02).clamp(2000.0, double.infinity);
    } else {
      _insurancePremium = null;
    }
  }

  double _calculateTotalAmount() {
    double baseAmount = double.tryParse(_amountController.text) ?? 0.0;
    double specialHandlingFee = _specialHandlingFees[_specialHandling] ?? 0.0;
    double insuranceFee = _insurancePremium ?? 0.0;
    return baseAmount + specialHandlingFee + insuranceFee;
  }

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _amountController.dispose();
    _deliveryInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Parcel'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (_errorMessage != null) ...[
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                ],
                TextFormField(
                  controller: _senderNameController,
                  decoration: const InputDecoration(labelText: 'Sender Name'),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Enter sender name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senderPhoneController,
                  decoration: const InputDecoration(labelText: 'Sender Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Enter sender phone' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _receiverNameController,
                  decoration: const InputDecoration(labelText: 'Receiver Name'),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Enter receiver name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _receiverPhoneController,
                  decoration: const InputDecoration(labelText: 'Receiver Phone'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Enter receiver phone' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fromLocationController,
                  decoration: const InputDecoration(labelText: 'From Location'),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Enter from location' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _toLocationController,
                  decoration: const InputDecoration(labelText: 'To Location'),
                  validator: (value) => value?.trim().isEmpty ?? true ? 'Enter to location' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount (TZS)'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.trim().isEmpty ?? true) return 'Enter amount';
                    final amount = double.tryParse(value!);
                    if (amount == null || amount <= 0) return 'Enter a valid positive amount';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Payment Method Section
                const Text(
                  'Payment Method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Cash on Delivery'),
                        value: 'cash',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                            _paymentStatus = 'pending';
                            _paymentReference = null;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Mobile Money'),
                        value: 'mobile_money',
                        groupValue: _paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _paymentMethod = value!;
                            _paymentStatus = 'pending';
                            _paymentReference = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                if (_paymentMethod == 'mobile_money') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📱 Mobile Money Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text('Send payment to: 0629661245'),
                        Text('Name: BENARD PAUL'),
                        Text('💡 Payment instructions will be sent via SMS'),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Delivery Scheduling Section
                const Text(
                  'Delivery Preferences (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(_preferredDeliveryDate == null
                            ? 'Select Delivery Date'
                            : DateFormat('MMM dd, yyyy').format(_preferredDeliveryDate!)),
                        leading: const Icon(Icons.calendar_today),
                        onTap: _selectDeliveryDate,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_preferredDeliveryDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _preferredDeliveryDate = null;
                          });
                        },
                      ),
                  ],
                ),

                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: Text(_preferredDeliveryTime == null
                            ? 'Select Delivery Time'
                            : _preferredDeliveryTime!.format(context)),
                        leading: const Icon(Icons.access_time),
                        onTap: _selectDeliveryTime,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_preferredDeliveryTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _preferredDeliveryTime = null;
                          });
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 8),
                TextFormField(
                  controller: _deliveryInstructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Instructions (Optional)',
                    hintText: 'e.g., Call before delivery, Leave at gate, etc.',
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Smart Parcel Features Section
                const Text(
                  'Smart Parcel Features',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                // Special Handling
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Special Handling',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 8),
                        ..._specialHandlingOptions.map((option) {
                          return RadioListTile<String>(
                            title: Text(_specialHandlingLabels[option]!),
                            value: option,
                            groupValue: _specialHandling ?? 'standard',
                            onChanged: (value) {
                              setState(() {
                                _specialHandling = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Insurance Options
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: const Text('Add Parcel Insurance'),
                          subtitle: const Text('Protect your parcel value'),
                          value: _hasInsurance,
                          onChanged: (value) {
                            setState(() {
                              _hasInsurance = value ?? false;
                              if (!_hasInsurance) {
                                _insuranceValue = null;
                                _insurancePremium = null;
                                _declaredValue = null;
                              }
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_hasInsurance) ...[
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Declared Value (TZS)',
                              hintText: 'Enter the value of your parcel',
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              final declaredValue = double.tryParse(value);
                              setState(() {
                                _declaredValue = declaredValue;
                                _insuranceValue = declaredValue;
                                _calculateInsurancePremium();
                              });
                            },
                            validator: _hasInsurance
                                ? (value) {
                                    if (value?.trim().isEmpty ?? true) return 'Enter declared value';
                                    final amount = double.tryParse(value!);
                                    if (amount == null || amount <= 0) return 'Enter a valid positive amount';
                                    return null;
                                  }
                                : null,
                          ),
                          if (_insurancePremium != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'Insurance Premium: TZS ${_insurancePremium!.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                // Total Amount Display
                if (_specialHandling != null || _hasInsurance) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cost Breakdown',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Base Amount:'),
                              Text('TZS ${(double.tryParse(_amountController.text) ?? 0.0).toStringAsFixed(2)}'),
                            ],
                          ),
                          if (_specialHandling != null && _specialHandling != 'standard') ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${_specialHandlingLabels[_specialHandling]?.split('(')[0].trim()}:'),
                                Text('TZS ${(_specialHandlingFees[_specialHandling] ?? 0.0).toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                          if (_hasInsurance && _insurancePremium != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Insurance Premium:'),
                                Text('TZS ${_insurancePremium!.toStringAsFixed(2)}'),
                              ],
                            ),
                          ],
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'TZS ${_calculateTotalAmount().toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                Text('Tracking Number: $_trackingNumber'),
                const SizedBox(height: 16),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitParcel,
                        child: const Text('Submit'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}