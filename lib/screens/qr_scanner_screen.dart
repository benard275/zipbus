import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/qr_service.dart';
import '../services/database_service.dart';
import '../models/parcel.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  final QRService _qrService = QRService();
  final DatabaseService _databaseService = DatabaseService();
  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: const Row(
              children: [
                Icon(Icons.qr_code_scanner, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Point your camera at a ZipBus parcel QR code to view details',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          
          // QR Scanner
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          
          // Status and controls
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_isProcessing) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text('Processing QR code...'),
                  ] else ...[
                    const Icon(
                      Icons.qr_code_2,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Align QR code within the frame',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && !_isProcessing) {
      final barcode = barcodes.first;
      if (barcode.rawValue != null && barcode.rawValue != _lastScannedCode) {
        _lastScannedCode = barcode.rawValue;
        _processQRCode(barcode.rawValue!);
      }
    }
  }

  Future<void> _processQRCode(String qrData) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
    });

    try {
      // Validate if it's a ZipBus QR code
      if (!_qrService.isValidParcelQRCode(qrData)) {
        _showErrorDialog('Invalid QR Code', 'This is not a valid ZipBus parcel QR code.');
        return;
      }

      // Extract tracking number
      final trackingNumber = _qrService.getTrackingNumberFromQR(qrData);
      if (trackingNumber == null) {
        _showErrorDialog('Invalid QR Code', 'Could not extract tracking number from QR code.');
        return;
      }

      // Look up parcel in database
      final parcel = await _databaseService.getParcelByTrackingNumber(trackingNumber);
      if (parcel == null) {
        _showErrorDialog('Parcel Not Found', 'No parcel found with tracking number: $trackingNumber');
        return;
      }

      // Navigate to parcel details
      if (mounted) {
        Navigator.pop(context); // Close scanner
        Navigator.pushNamed(
          context,
          '/tracking',
          arguments: trackingNumber,
        );
      }
    } catch (e) {
      _showErrorDialog('Error', 'Failed to process QR code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _lastScannedCode = null;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _lastScannedCode = null; // Allow rescanning
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


}
