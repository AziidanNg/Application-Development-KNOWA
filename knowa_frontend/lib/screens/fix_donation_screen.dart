import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:knowa_frontend/services/donation_service.dart';

class FixDonationScreen extends StatefulWidget {
  final int donationId;
  final String reason;

  const FixDonationScreen({super.key, required this.donationId, required this.reason});

  @override
  State<FixDonationScreen> createState() => _FixDonationScreenState();
}

class _FixDonationScreenState extends State<FixDonationScreen> {
  final DonationService _donationService = DonationService();
  File? _newReceiptFile;
  bool _isLoading = false;

  Future<void> _pickReceipt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'jpeg'],
    );
    if (result != null) {
      setState(() {
        _newReceiptFile = File(result.files.single.path!);
      });
    }
  }

  void _submitFix() async {
    if (_newReceiptFile == null) return;

    setState(() { _isLoading = true; });

    bool success = await _donationService.fixDonation(widget.donationId, _newReceiptFile!);

    setState(() { _isLoading = false; });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt updated! Issue resolved.'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return 'true' to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update receipt.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resolve Issue')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Box showing the reason
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Issue Reported by Admin:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  const SizedBox(height: 8),
                  Text(widget.reason, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Please upload a new, clear receipt to resolve this issue.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            // File Picker
            InkWell(
              onTap: _pickReceipt,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_upload_outlined, size: 32, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tap to upload new receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            _newReceiptFile != null ? _newReceiptFile!.path.split('/').last : 'No file selected',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_newReceiptFile != null && !_isLoading) ? _submitFix : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Fix'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}