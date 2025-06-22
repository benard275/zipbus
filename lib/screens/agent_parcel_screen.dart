import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../services/database_service.dart';

class AgentParcelScreen extends StatefulWidget {
  const AgentParcelScreen({super.key});

  @override
  State<AgentParcelScreen> createState() => _AgentParcelScreenState();
}

class _AgentParcelScreenState extends State<AgentParcelScreen> {
  List<Parcel> _parcels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchParcels();
  }

  Future<void> _fetchParcels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final parcels = await DatabaseService().getParcelsByAgent(DatabaseService().getCurrentUser().id);
      if (mounted) {
        setState(() {
          _parcels = parcels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load parcels: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markParcelAsDelivered(String parcelId) async {
    try {
      final parcel = _parcels.firstWhere((p) => p.id == parcelId);
      String pickerName = parcel.receiverName; // Default to intended receiver
      String pickerPhone = parcel.receiverPhone; // Default to intended receiver

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm Delivery'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Intended Receiver:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Name: ${parcel.receiverName}'),
                  Text('Phone: ${parcel.receiverPhone}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Person Picking Up (if different):',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Picker Name'),
                    onChanged: (value) => pickerName = value,
                    controller: TextEditingController(text: parcel.receiverName),
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Picker Phone'),
                    keyboardType: TextInputType.phone,
                    onChanged: (value) => pickerPhone = value,
                    controller: TextEditingController(text: parcel.receiverPhone),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  if (pickerName.isNotEmpty && pickerPhone.isNotEmpty) {
                    final updatedParcel = Parcel(
                      id: parcel.id,
                      senderName: parcel.senderName,
                      senderPhone: parcel.senderPhone,
                      receiverName: parcel.receiverName,
                      receiverPhone: parcel.receiverPhone,
                      fromLocation: parcel.fromLocation,
                      toLocation: parcel.toLocation,
                      amount: parcel.amount,
                      status: 'Delivered',
                      trackingNumber: parcel.trackingNumber,
                      createdBy: parcel.createdBy,
                      createdAt: parcel.createdAt,
                      receivedBy: parcel.receivedBy,
                      deliveredBy: 'Handed To: $pickerName and $pickerPhone',
                    );
                    await DatabaseService().updateParcel(updatedParcel);
                    await _fetchParcels();
                    if (mounted) {
                      navigator.pop();
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Parcel marked as delivered')),
                      );
                    }
                  } else {
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(content: Text('Please enter name and phone number')),
                      );
                    }
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark parcel as delivered: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Parcels'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1976D2), // Blue theme
      ),
      body: _isLoading
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
              : _parcels.isEmpty
                  ? const Center(child: Text('No parcels assigned.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _parcels.length,
                      itemBuilder: (context, index) {
                        final parcel = _parcels[index];
                        return Card(
                          elevation: 4,
                          child: ListTile(
                            title: Text('Tracking #${parcel.trackingNumber}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('From: ${parcel.fromLocation}'),
                                Text('To: ${parcel.toLocation}'),
                                Text('Status: ${parcel.status}'),
                                Text('Intended Receiver: ${parcel.receiverName} (${parcel.receiverPhone})'),
                                if (parcel.deliveredBy != null)
                                  Text(parcel.deliveredBy!),
                              ],
                            ),
                            trailing: parcel.status != 'Delivered'
                                ? IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.green),
                                    onPressed: () => _markParcelAsDelivered(parcel.id),
                                    tooltip: 'Mark as Delivered',
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
    );
  }
}