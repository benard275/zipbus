import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../models/customer_analytics.dart';
import '../services/customer_analytics_service.dart';
import '../services/database_service.dart';

class CustomerSatisfactionScreen extends StatefulWidget {
  final Parcel? parcel;
  final String? trackingNumber;

  const CustomerSatisfactionScreen({
    super.key,
    this.parcel,
    this.trackingNumber,
  });

  @override
  State<CustomerSatisfactionScreen> createState() => _CustomerSatisfactionScreenState();
}

class _CustomerSatisfactionScreenState extends State<CustomerSatisfactionScreen> {
  final CustomerAnalyticsService _analyticsService = CustomerAnalyticsService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _feedbackController = TextEditingController();

  Parcel? _parcel;
  int _selectedRating = 0;
  String _selectedRatingType = 'overall';
  bool _isSubmitting = false;
  bool _isLoading = true;

  final List<String> _ratingTypes = [
    'overall',
    'delivery',
    'service',
  ];

  final List<String> _ratingLabels = [
    'Very Poor',
    'Poor',
    'Average',
    'Good',
    'Excellent',
  ];

  @override
  void initState() {
    super.initState();
    _loadParcel();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadParcel() async {
    if (widget.parcel != null) {
      setState(() {
        _parcel = widget.parcel;
        _isLoading = false;
      });
    } else if (widget.trackingNumber != null) {
      try {
        final parcel = await _databaseService.getParcelByTrackingNumber(widget.trackingNumber!);
        setState(() {
          _parcel = parcel;
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading parcel: $e')),
          );
        }
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_parcel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No parcel information available')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _analyticsService.addSatisfactionRating(
        parcelId: _parcel!.id,
        trackingNumber: _parcel!.trackingNumber,
        customerPhone: _parcel!.senderPhone,
        rating: _selectedRating,
        feedback: _feedbackController.text.trim().isNotEmpty ? _feedbackController.text.trim() : null,
        ratingType: _selectedRatingType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thank you for your feedback!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting rating: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate Your Experience'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _parcel == null
              ? const Center(
                  child: Text(
                    'No parcel information available',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Parcel Information Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Parcel Details',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('Tracking Number', _parcel!.trackingNumber),
                              _buildInfoRow('From', _parcel!.fromLocation),
                              _buildInfoRow('To', _parcel!.toLocation),
                              _buildInfoRow('Receiver', _parcel!.receiverName),
                              _buildInfoRow('Status', _parcel!.status),
                              _buildInfoRow('Amount', 'TZS ${_parcel!.amount.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Rating Type Selection
                      const Text(
                        'What would you like to rate?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: _ratingTypes.map((type) {
                          return ChoiceChip(
                            label: Text(type.toUpperCase()),
                            selected: _selectedRatingType == type,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedRatingType = type);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Rating Selection
                      const Text(
                        'How would you rate your experience?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Star Rating
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  final rating = index + 1;
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedRating = rating);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Icon(
                                        Icons.star,
                                        size: 40,
                                        color: rating <= _selectedRating
                                            ? Colors.amber
                                            : Colors.grey[300],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 12),
                              if (_selectedRating > 0)
                                Text(
                                  _ratingLabels[_selectedRating - 1],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Feedback Text Field
                      const Text(
                        'Additional Feedback (Optional)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _feedbackController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Tell us more about your experience...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Submit Rating',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thank You Message
                      Card(
                        color: Colors.blue[50],
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Your feedback helps us improve our service quality. Thank you for choosing ZipBus!',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

// Widget for displaying satisfaction ratings in other screens
class SatisfactionRatingWidget extends StatelessWidget {
  final double rating;
  final int totalRatings;
  final bool showDetails;

  const SatisfactionRatingWidget({
    super.key,
    required this.rating,
    required this.totalRatings,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            Icons.star,
            size: 16,
            color: index < rating.floor()
                ? Colors.amber
                : index < rating
                    ? Colors.amber.withValues(alpha: 0.5)
                    : Colors.grey[300],
          );
        }),
        if (showDetails) ...[
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($totalRatings)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}

// Quick rating dialog for use in other screens
class QuickRatingDialog extends StatefulWidget {
  final Parcel parcel;

  const QuickRatingDialog({super.key, required this.parcel});

  @override
  State<QuickRatingDialog> createState() => _QuickRatingDialogState();
}

class _QuickRatingDialogState extends State<QuickRatingDialog> {
  int _selectedRating = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rate This Delivery'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Tracking: ${widget.parcel.trackingNumber}'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedRating = rating);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    Icons.star,
                    size: 32,
                    color: rating <= _selectedRating
                        ? Colors.amber
                        : Colors.grey[300],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedRating > 0
              ? () async {
                  try {
                    await CustomerAnalyticsService().addSatisfactionRating(
                      parcelId: widget.parcel.id,
                      trackingNumber: widget.parcel.trackingNumber,
                      customerPhone: widget.parcel.senderPhone,
                      rating: _selectedRating,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Thank you for your rating!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                }
              : null,
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
