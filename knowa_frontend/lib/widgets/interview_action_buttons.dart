import 'package:flutter/material.dart';
import '../services/interview_service.dart'; 

class InterviewActionButtons extends StatefulWidget {
  final int applicantId; 
  final VoidCallback onSuccess; 

  const InterviewActionButtons({
    Key? key, 
    required this.applicantId, 
    required this.onSuccess
  }) : super(key: key);

  @override
  _InterviewActionButtonsState createState() => _InterviewActionButtonsState();
}

class _InterviewActionButtonsState extends State<InterviewActionButtons> {
  bool _isLoading = false;
  final TextEditingController _reportController = TextEditingController(); 

  @override
  void dispose() {
    _reportController.dispose();
    super.dispose();
  }

  Future<void> _submitResult(String action) async {
    _reportController.clear(); // Clear previous text

    // 1. Show Dialog WITH Text Input
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action == 'pass' ? 'Pass Candidate' : 'Reject Candidate'),
        
        // --- THE FIX: ADD SIZEDBOX HERE ---
        content: SizedBox(
          width: double.maxFinite, // Forces the dialog to be full width
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(action == 'pass' 
                ? 'Please write a short report/reason for approval:' 
                : 'Please write the reason for rejection:'),
              SizedBox(height: 10),
              TextField(
                controller: _reportController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Enter interview notes...",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(height: 10),
              Text(
                action == 'pass' 
                  ? 'Action: Moves user to Payment stage.' 
                  : 'Action: Rejects application permanently.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // ----------------------------------
        
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'pass' ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Submit Decision", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);

    final service = InterviewService();
    
    // 2. Call the service with the REPORT text
    bool success = await service.setInterviewResult(
      widget.applicantId, 
      action,
      _reportController.text 
    );

    setState(() => _isLoading = false);

    // 3. Handle success
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Report saved & Status updated."))
      );
      widget.onSuccess(); 
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: You might not be authorized."))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Row(
      children: [
        // --- 1. PASS BUTTON (Now on the LEFT) ---
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, 
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _submitResult('pass'),
            icon: Icon(Icons.check),
            label: Text("Pass"),
          ),
        ),

        SizedBox(width: 16), // Space between buttons

        // --- 2. REJECT BUTTON (Now on the RIGHT) ---
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[50],
              foregroundColor: Colors.red,
              side: BorderSide(color: Colors.red),
              padding: EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _submitResult('fail'),
            icon: Icon(Icons.close),
            label: Text("Reject"),
          ),
        ),
      ],
    );
  }
}