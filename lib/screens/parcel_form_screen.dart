import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../models/agent.dart';
import '../models/parcel.dart';
import '../services/database_service.dart';

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
  String _trackingNumber = '';
  bool _isLoading = false;
  String? _errorMessage;

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
        );

        await DatabaseService().insertParcel(parcel);
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

  @override
  void dispose() {
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _fromLocationController.dispose();
    _toLocationController.dispose();
    _amountController.dispose();
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
                const SizedBox(height: 16),
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