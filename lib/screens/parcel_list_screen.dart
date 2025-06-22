import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../models/parcel.dart';
import '../services/database_service.dart';
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
                                  child: ListTile(
                                    title: Text('Tracking: ${parcel.trackingNumber}'),
                                    subtitle: allowedStatuses.isEmpty
                                        ? Text('Status: ${_selectedStatuses[parcel.id] ?? parcel.status}')
                                        : DropdownButton<String>(
                                            value: _selectedStatuses[parcel.id] ?? parcel.status,
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
                                    trailing: const Icon(Icons.arrow_forward),
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/tracking',
                                        arguments: parcel.trackingNumber,
                                      );
                                    },
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