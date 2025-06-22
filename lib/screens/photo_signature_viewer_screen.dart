import 'dart:io';
import 'package:flutter/material.dart';
import '../models/parcel.dart';
import '../services/photo_service.dart';
import '../services/signature_service.dart';

class PhotoSignatureViewerScreen extends StatefulWidget {
  final Parcel parcel;

  const PhotoSignatureViewerScreen({
    super.key,
    required this.parcel,
  });

  @override
  State<PhotoSignatureViewerScreen> createState() => _PhotoSignatureViewerScreenState();
}

class _PhotoSignatureViewerScreenState extends State<PhotoSignatureViewerScreen> {
  final PhotoService _photoService = PhotoService();
  final SignatureService _signatureService = SignatureService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Proof of Delivery #${widget.parcel.trackingNumber}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Parcel information
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
                    Text('Recipient: ${widget.parcel.receiverName}'),
                    Text('Status: ${widget.parcel.status}'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Pickup Photo Section
            if (widget.parcel.pickupPhotoPath != null) ...[
              Text(
                'Pickup Photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildPhotoCard(widget.parcel.pickupPhotoPath!, 'Pickup Photo'),
              const SizedBox(height: 16),
            ],
            
            // Delivery Photo Section
            if (widget.parcel.deliveryPhotoPath != null) ...[
              Text(
                'Delivery Photo',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildPhotoCard(widget.parcel.deliveryPhotoPath!, 'Delivery Photo'),
              const SizedBox(height: 16),
            ],
            
            // Digital Signature Section
            if (widget.parcel.signaturePath != null) ...[
              Text(
                'Digital Signature',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              _buildSignatureCard(widget.parcel.signaturePath!),
              const SizedBox(height: 16),
            ],
            
            // No proof message
            if (widget.parcel.pickupPhotoPath == null &&
                widget.parcel.deliveryPhotoPath == null &&
                widget.parcel.signaturePath == null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No delivery proof available',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Photos and signatures will appear here when available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(String photoPath, String title) {
    final File? photoFile = _photoService.getPhotoFile(photoPath);
    
    if (photoFile == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Text(
                'Photo not found',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Image.file(
              photoFile,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.camera_alt, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewFullScreenImage(photoFile, title),
                  child: const Text('View Full Size'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard(String signaturePath) {
    final File? signatureFile = _signatureService.getSignatureFile(signaturePath);
    
    if (signatureFile == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400),
              const SizedBox(width: 8),
              Text(
                'Signature not found',
                style: TextStyle(color: Colors.red.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 150,
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.file(
                signatureFile,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load signature',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.draw, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                const Text(
                  'Digital Signature',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _viewFullScreenImage(signatureFile, 'Digital Signature'),
                  child: const Text('View Full Size'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _viewFullScreenImage(File imageFile, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.file(imageFile),
            ),
          ),
        ),
      ),
    );
  }
}
