// lib/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:knowa_frontend/services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final AuthService _authService = AuthService();
  File? _receiptFile;
  bool _isLoading = false;

  // Function to pick a file (receipt)
  Future<void> _pickReceipt() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
    );
    if (result != null) {
      setState(() {
        _receiptFile = File(result.files.single.path!);
      });
    }
  }

  // Function to submit the receipt
  void _submitReceipt() async {
    if (_receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your receipt file first.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final success = await _authService.uploadReceipt(_receiptFile!);

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receipt uploaded! Admin will review it soon.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Go back to the dashboard
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upload failed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Membership Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pay Your Membership Fee',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please make a one-time payment of RM50 to the account below. After payment, upload your receipt for verification.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- THIS IS THE PLACEHOLDER FOR BANK INFO ---
            Card(
              elevation: 0,
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NGO BANK ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Bank Name: Maybank'),
                    Text('Account Name: KNOWA NGO'),
                    Text('Account Number: 1234 5678 9012'),
                    SizedBox(height: 16),
                    // You could also add an Image.asset('assets/qr_code.png') here
                    const Text(
                      'Or scan the QR code below:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Image.asset(
                      'assets/images/knowa_qr_testing.png', // <-- Make sure this filename matches yours
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
            // ---------------------------------------------

            const SizedBox(height: 24),
            const Text(
              'Upload Your Receipt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // File Picker Button
            InkWell(
              onTap: _pickReceipt,
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.shade300)
                ),
                child: Row(
                  children: [
                    Icon(Icons.attach_file, color: Colors.grey[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _receiptFile == null 
                          ? 'Tap to select your receipt...' 
                          : _receiptFile!.path.split('/').last,
                        style: TextStyle(
                          color: _receiptFile == null ? Colors.grey[700] : Colors.black,
                          fontStyle: _receiptFile == null ? FontStyle.italic : FontStyle.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReceipt,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Receipt', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}