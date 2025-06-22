import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../services/signature_service.dart';

class SignatureCaptureScreen extends StatefulWidget {
  final String trackingNumber;
  final String recipientName;

  const SignatureCaptureScreen({
    super.key,
    required this.trackingNumber,
    required this.recipientName,
  });

  @override
  State<SignatureCaptureScreen> createState() => _SignatureCaptureScreenState();
}

class _SignatureCaptureScreenState extends State<SignatureCaptureScreen> {
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  
  final SignatureService _signatureService = SignatureService();
  bool _isLoading = false;

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a signature before saving'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get signature as bytes
      final Uint8List? signatureBytes = await _signatureController.toPngBytes();
      
      if (signatureBytes == null) {
        throw Exception('Failed to capture signature');
      }

      // Validate signature
      if (!SignatureService.isSignatureValid(signatureBytes)) {
        throw Exception('Signature appears to be empty or invalid');
      }

      // Save signature
      final String? signaturePath = await _signatureService.saveSignature(
        signatureBytes,
        widget.trackingNumber,
      );

      if (signaturePath == null) {
        throw Exception('Failed to save signature');
      }

      if (!mounted) return;
      
      // Return the signature path to the previous screen
      Navigator.pop(context, signaturePath);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Signature captured successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error saving signature: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _clearSignature() {
    _signatureController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Signature'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSignature,
            tooltip: 'Clear Signature',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parcel: #${widget.trackingNumber}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recipient: ${widget.recipientName}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '✍️ Please sign below to confirm delivery:',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Signature pad
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Signature(
                  controller: _signatureController,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),
          
          // Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              '💡 Tip: Use your finger to sign in the box above',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _clearSignature,
                    child: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveSignature,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Signature'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
