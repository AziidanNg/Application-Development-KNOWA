// lib/screens/donation_page.dart
import 'package:flutter/material.dart';
import 'package:knowa_frontend/screens/donation_payment_screen.dart'; // We'll create this next

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPage();
}

class _DonationPage extends State<DonationPage> {
  String? _selectedAmount;
  final _customAmountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _presetAmounts = ['10', '15', '30', '50', '100'];

  void _onDonateNow() {
    if (_selectedAmount == null && _customAmountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an amount.')),
      );
      return;
    }

    // Use custom amount if "Other" is selected, otherwise use the preset
    String amount = (_selectedAmount == 'Other') 
        ? _customAmountController.text 
        : _selectedAmount!;

    // Navigate to the payment screen and pass the amount
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DonationPaymentScreen(amount: amount),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Placeholder for Header Image & Goal ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  'assets/images/donationheaderimg.png', // <-- Make sure this matches your image's filename
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // We'll add the goal tracker here later

              const Text(
                'Your contribution helps us provide educational resources and opportunities to individuals of all ages and backgrounds.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              const Text(
                'Choose an amount',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Preset Amount Chips
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _presetAmounts.map((amount) {
                  return ChoiceChip(
                    label: Text('RM $amount'),
                    selected: _selectedAmount == amount,
                    onSelected: (selected) {
                      setState(() {
                        _selectedAmount = selected ? amount : null;
                        if (_selectedAmount != 'Other') {
                          _customAmountController.clear();
                        }
                      });
                    },
                  );
                }).toList()
                ..add(
                  ChoiceChip(
                    label: const Text('Other'),
                    selected: _selectedAmount == 'Other',
                    onSelected: (selected) {
                      setState(() {
                        _selectedAmount = selected ? 'Other' : null;
                      });
                    },
                  )
                ),
              ),
              const SizedBox(height: 16),

              // Custom Amount Field
              if (_selectedAmount == 'Other')
                TextFormField(
                  controller: _customAmountController,
                  decoration: const InputDecoration(
                    labelText: 'Enter custom amount (RM)',
                    border: OutlineInputBorder(),
                    prefixText: 'RM ',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_selectedAmount == 'Other' && (value == null || value.isEmpty)) {
                      return 'Please enter an amount';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 32),

              // Donate Now Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onDonateNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Donate Now', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}