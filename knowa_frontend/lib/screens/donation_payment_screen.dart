// lib/screens/donation_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:knowa_frontend/services/donation_service.dart';

class DonationPaymentScreen extends StatefulWidget {
  final String amount;
  const DonationPaymentScreen({super.key, required this.amount});

  @override
  State<DonationPaymentScreen> createState() => _DonationPaymentScreenState();
}

class _DonationPaymentScreenState extends State<DonationPaymentScreen> {
  final DonationService _donationService = DonationService();
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
  void _submitDonation() async {
    if (_receiptFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your receipt file first.')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    final result = await _donationService.submitDonation(
      amount: widget.amount,
      receiptFile: _receiptFile!,
    );

    setState(() { _isLoading = false; });
    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donation submitted! Thank you for your support.'),
          backgroundColor: Colors.green,
        ),
      );
      // Pop both payment screen and amount screen to go back to dashboard
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Donation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Your Donation: RM${widget.amount}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please make your payment to the account below. After payment, upload your receipt for verification.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // --- THIS IS THE PLACEHOLDER FOR BANK INFO ---
            Card(
              elevation: 0,
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NGO BANK ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Bank Name: Maybank'),
                    const Text('Account Name: PERTUBUHAN ILMIAH PULAU PINANG'),
                    const Text('Account Number: 557036648153'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 10),
                    const Text(
                      'Or scan the QR code below:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    // --- THIS IS YOUR IMAGE ---
                    Image.asset(
                      'assets/images/qr_knowa_new.jpg', // <-- Make sure this filename matches yours
                      width: double.infinity,
                      fit: BoxFit.contain,
                    ),
                    // --------------------------
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
                onPressed: _isLoading ? null : _submitDonation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit Donation', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}