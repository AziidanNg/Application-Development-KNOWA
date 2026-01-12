// lib/screens/admin_interview_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/interview_service.dart';

class AdminInterviewHistoryScreen extends StatefulWidget {
  const AdminInterviewHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AdminInterviewHistoryScreen> createState() => _AdminInterviewHistoryScreenState();
}

class _AdminInterviewHistoryScreenState extends State<AdminInterviewHistoryScreen> {
  final InterviewService _service = InterviewService();
  List<dynamic> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final data = await _service.getInterviewHistory();
    if (mounted) {
      setState(() {
        _history = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. GET SYSTEM PADDING (Navigation Bar Height)
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Interview Reports", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? const Center(child: Text("No past interviews found."))
              : ListView.builder(
                  // 2. APPLY DYNAMIC PADDING
                  // Replaced const EdgeInsets.all(16)
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + bottomPadding, // <--- The Fix: Adds nav bar height
                  ),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    return _buildHistoryCard(item);
                  },
                ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final String status = item['status'] ?? 'UNKNOWN';
    final bool isPass = status == 'COMPLETED';
    final String dateStr = item['date_time'] ?? '';
    final String report = item['report'] ?? 'No report provided.';
    final String applicant = item['applicant_name'] ?? 'Unknown Applicant';

    // Format Date
    String formattedDate = dateStr;
    try {
      DateTime dt = DateTime.parse(dateStr);
      formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(dt);
    } catch (e) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isPass ? Colors.green[100] : Colors.red[100],
          child: Icon(
            isPass ? Icons.check : Icons.close,
            color: isPass ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          applicant,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(formattedDate),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "INTERVIEWER REPORT:",
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.grey
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    report.isNotEmpty ? report : "No notes recorded.",
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      isPass ? "Outcome: PASSED" : "Outcome: REJECTED",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPass ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}