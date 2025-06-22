import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../services/database_service.dart';
import '../services/photo_service.dart';
import '../services/signature_service.dart';
import 'signature_capture_screen.dart';
import 'photo_signature_viewer_screen.dart';

class AgentParcelScreen extends StatefulWidget {
  const AgentParcelScreen({super.key});

  @override
  State<AgentParcelScreen> createState() => _AgentParcelScreenState();
}

class _AgentParcelScreenState extends State<AgentParcelScreen> {
  List<Parcel> _parcels = [];
  bool _isLoading = true;
  String? _errorMessage;

  final PhotoService _photoService = PhotoService();

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
      await _showEnhancedDeliveryDialog(parcel);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark parcel as delivered: $e')),
        );
      }
    }
  }

  Future<void> _showEnhancedDeliveryDialog(Parcel parcel) async {
    String pickerName = parcel.receiverName;
    String pickerPhone = parcel.receiverPhone;
    String? deliveryPhotoPath;
    String? signaturePath;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirm Delivery'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Parcel information
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parcel #${parcel.trackingNumber}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('From: ${parcel.fromLocation}'),
                          Text('To: ${parcel.toLocation}'),
                          Text('Amount: TZS ${parcel.amount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Intended receiver
                    const Text(
                      'Intended Receiver:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${parcel.receiverName}'),
                    Text('Phone: ${parcel.receiverPhone}'),

                    const SizedBox(height: 16),

                    // Person picking up
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

                    const SizedBox(height: 20),

                    // Delivery proof section
                    const Text(
                      'Delivery Proof:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Photo proof
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final photoPath = await _photoService.takeDeliveryPhoto(parcel.trackingNumber);
                              if (photoPath != null) {
                                setState(() {
                                  deliveryPhotoPath = photoPath;
                                });
                              }
                            },
                            icon: Icon(
                              deliveryPhotoPath != null ? Icons.check_circle : Icons.camera_alt,
                              color: deliveryPhotoPath != null ? Colors.green : null,
                            ),
                            label: Text(deliveryPhotoPath != null ? 'Photo Taken' : 'Take Photo'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Digital signature
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push<String>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignatureCaptureScreen(
                                    trackingNumber: parcel.trackingNumber,
                                    recipientName: pickerName,
                                  ),
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  signaturePath = result;
                                });
                              }
                            },
                            icon: Icon(
                              signaturePath != null ? Icons.check_circle : Icons.draw,
                              color: signaturePath != null ? Colors.green : null,
                            ),
                            label: Text(signaturePath != null ? 'Signature Captured' : 'Get Signature'),
                          ),
                        ),
                      ],
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
                    await _confirmDelivery(
                      parcel,
                      pickerName,
                      pickerPhone,
                      deliveryPhotoPath,
                      signaturePath,
                    );
                    if (mounted) navigator.pop();
                  },
                  child: const Text('Confirm Delivery'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelivery(
    Parcel parcel,
    String pickerName,
    String pickerPhone,
    String? deliveryPhotoPath,
    String? signaturePath,
  ) async {
    try {
      if (pickerName.isEmpty || pickerPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter name and phone number')),
        );
        return;
      }

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
        // Payment fields
        paymentMethod: parcel.paymentMethod,
        paymentStatus: parcel.paymentStatus,
        paymentReference: parcel.paymentReference,
        // Delivery scheduling fields
        preferredDeliveryDate: parcel.preferredDeliveryDate,
        preferredDeliveryTime: parcel.preferredDeliveryTime,
        deliveryInstructions: parcel.deliveryInstructions,
        // Photo proof fields - update with new photos/signature
        pickupPhotoPath: parcel.pickupPhotoPath,
        deliveryPhotoPath: deliveryPhotoPath ?? parcel.deliveryPhotoPath,
        signaturePath: signaturePath ?? parcel.signaturePath,
      );

      await DatabaseService().updateParcel(updatedParcel);
      await _fetchParcels();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Parcel #${parcel.trackingNumber} delivered successfully!',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm delivery: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _viewDeliveryProof(Parcel parcel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoSignatureViewerScreen(parcel: parcel),
      ),
    );
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
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                Text('Amount: TZS ${parcel.amount.toStringAsFixed(2)}'),
                                Text('Receiver: ${parcel.receiverName} (${parcel.receiverPhone})'),

                                if (parcel.deliveredBy != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    parcel.deliveredBy!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // Action buttons
                                Row(
                                  children: [
                                    if (parcel.status != 'Delivered') ...[
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _markParcelAsDelivered(parcel.id),
                                          icon: const Icon(Icons.check_circle, size: 18),
                                          label: const Text('Mark Delivered'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      // Show delivery proof button for delivered parcels
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _viewDeliveryProof(parcel),
                                          icon: const Icon(Icons.visibility, size: 18),
                                          label: const Text('View Proof'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}