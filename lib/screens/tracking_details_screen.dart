import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../models/agent.dart'; // Added missing import
import '../models/parcel.dart';
import '../services/database_service.dart';
import '../services/sms_service.dart';

class TrackingDetailsScreen extends StatefulWidget {
  final String trackingNumber;

  const TrackingDetailsScreen({super.key, required this.trackingNumber});

  @override
  State<TrackingDetailsScreen> createState() => _TrackingDetailsScreenState();
}

class _TrackingDetailsScreenState extends State<TrackingDetailsScreen> {
  Parcel? _parcel;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchParcel();
  }

  Future<void> _fetchParcel() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dbService = DatabaseService();
      final parcel = await dbService.getParcelByTrackingNumber(widget.trackingNumber);
      if (parcel == null) {
        setState(() {
          _errorMessage = 'Parcel not found';
        });
        return;
      }

      // Fetch current logged-in agent's email from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final currentAgentEmail = prefs.getString('current_agent_email');
      final currentAgent = currentAgentEmail != null
          ? await dbService.getAgentByEmail(currentAgentEmail)
          : null;

      if (currentAgent == null) {
        // Clear session and redirect to login
        await prefs.remove('current_agent_email');
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false, // Remove all previous routes
        );
        return;
      }

      // Update receivedBy or deliveredBy based on status
      if (parcel.status == 'In Transit' && parcel.receivedBy == null) {
        final updatedParcel = Parcel(
          id: parcel.id,
          senderName: parcel.senderName,
          senderPhone: parcel.senderPhone,
          receiverName: parcel.receiverName,
          receiverPhone: parcel.receiverPhone,
          fromLocation: parcel.fromLocation,
          toLocation: parcel.toLocation,
          amount: parcel.amount,
          status: parcel.status,
          trackingNumber: parcel.trackingNumber,
          createdBy: parcel.createdBy,
          createdAt: parcel.createdAt,
          receivedBy: currentAgent.id,
          deliveredBy: parcel.deliveredBy,
        );
        await dbService.updateParcel(updatedParcel);
        setState(() {
          _parcel = updatedParcel;
        });
      } else if (parcel.status == 'Delivered' && parcel.deliveredBy == null) {
        final updatedParcel = Parcel(
          id: parcel.id,
          senderName: parcel.senderName,
          senderPhone: parcel.senderPhone,
          receiverName: parcel.receiverName,
          receiverPhone: parcel.receiverPhone,
          fromLocation: parcel.fromLocation,
          toLocation: parcel.toLocation,
          amount: parcel.amount,
          status: parcel.status,
          trackingNumber: parcel.trackingNumber,
          createdBy: parcel.createdBy,
          createdAt: parcel.createdAt,
          receivedBy: parcel.receivedBy,
          deliveredBy: currentAgent.id, // Set deliveredBy to current agent
        );
        await dbService.updateParcel(updatedParcel);
        setState(() {
          _parcel = updatedParcel;
        });
      } else {
        setState(() {
          _parcel = parcel;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load parcel: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Parcel'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                          onPressed: _fetchParcel,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _parcel == null
                    ? const Center(child: Text('Parcel not found.'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking Number: ${_parcel!.trackingNumber}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('Status: ${_parcel!.status}'),
                          const SizedBox(height: 8),
                          Text('Sender: ${_parcel!.senderName} (${_parcel!.senderPhone})'),
                          const SizedBox(height: 8),
                          Text('Receiver: ${_parcel!.receiverName} (${_parcel!.receiverPhone})'),
                          const SizedBox(height: 8),
                          Text('From: ${_parcel!.fromLocation}'),
                          const SizedBox(height: 8),
                          Text('To: ${_parcel!.toLocation}'),
                          const SizedBox(height: 8),
                          Text('Amount: ${_parcel!.amount} TZS'),
                          const SizedBox(height: 8),
                          FutureBuilder<Agent?>(
                            future: DatabaseService().getAgentById(_parcel!.createdBy),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Created by: Loading...');
                              } else if (snapshot.hasError || snapshot.data == null) {
                                return const Text('Created by: Unknown');
                              } else {
                                final creator = snapshot.data!;
                                return Text('Created by: ${creator.name} (${creator.mobile})');
                              }
                            },
                          ),
                          if (_parcel!.receivedBy != null) ...[
                            const SizedBox(height: 8),
                            Text('Received By: ${_parcel!.receivedBy}'),
                          ],
                          if (_parcel!.deliveredBy != null) ...[
                            const SizedBox(height: 8),
                            FutureBuilder<Agent?>(
                              future: DatabaseService().getAgentById(_parcel!.deliveredBy!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Text('Delivered By: Loading...');
                                } else if (snapshot.hasError || snapshot.data == null) {
                                  return const Text('Delivered By: Unknown');
                                } else {
                                  final deliverer = snapshot.data!;
                                  return Text('Delivered By: ${deliverer.name} (${deliverer.mobile})');
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text('Created At: ${_parcel!.createdAt}'),
                        ],
                      ),
      ),
    );
  }
}
