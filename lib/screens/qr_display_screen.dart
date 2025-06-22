import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/parcel.dart';
import '../services/qr_service.dart';

class QRDisplayScreen extends StatefulWidget {
  final Parcel parcel;

  const QRDisplayScreen({
    super.key,
    required this.parcel,
  });

  @override
  State<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends State<QRDisplayScreen> {
  final QRService _qrService = QRService();
  final GlobalKey _qrKey = GlobalKey();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parcel QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareQRCode,
            tooltip: 'Share QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveQRCode,
            tooltip: 'Save QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Parcel information header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parcel Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Tracking: #${widget.parcel.trackingNumber}'),
                    Text('From: ${widget.parcel.fromLocation}'),
                    Text('To: ${widget.parcel.toLocation}'),
                    Text('Receiver: ${widget.parcel.receiverName}'),
                    Text('Phone: ${widget.parcel.receiverPhone}'),
                    Text('Amount: TZS ${widget.parcel.amount.toStringAsFixed(2)}'),
                    Text('Status: ${widget.parcel.status}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // QR Code display
            const Text(
              'QR Code',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: _qrService.generateParcelQRWidget(
                  widget.parcel,
                  size: 250,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Instructions
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to use this QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Scan with ZipBus app to view parcel details'),
                    const Text('• Share with customers for easy tracking'),
                    const Text('• Print and attach to physical parcel'),
                    const Text('• Use for quick parcel identification'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyTrackingNumber,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Tracking #'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveQRCode,
                    icon: _isSaving 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isSaving ? 'Saving...' : 'Save QR Code'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Printable version button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showPrintableVersion,
                icon: const Icon(Icons.print),
                label: const Text('View Printable Label'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTrackingNumber() {
    Clipboard.setData(ClipboardData(text: widget.parcel.trackingNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tracking number copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveQRCode() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final savedPath = await _qrService.saveParcelQRCode(widget.parcel, _qrKey);
      
      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('QR code saved successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save QR code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving QR code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _shareQRCode() {
    final qrData = _qrService.generateShareableQRData(widget.parcel);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('QR Code Data:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                qrData,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('You can share this data or save the QR code image to share with others.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: qrData));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR data copied to clipboard')),
              );
            },
            child: const Text('Copy Data'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrintableVersion() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Printable QR Label',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _qrService.createPrintableQRLabel(widget.parcel),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // In a real app, you would implement printing functionality here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Print functionality would be implemented here'),
                        ),
                      );
                    },
                    child: const Text('Print'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
