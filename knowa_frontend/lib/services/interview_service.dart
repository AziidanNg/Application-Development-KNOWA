import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; 

class InterviewService {
  // Ensure this matches your backend IP
  final String baseUrl = "http://10.0.2.2:8000/api"; 

  // UPDATED: Now accepts 'report' as the 3rd argument
  Future<bool> setInterviewResult(int userId, String action, String report) async {
    final url = Uri.parse('$baseUrl/users/admin/interview-result/$userId/');
    
    // 1. Get the stored Token
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Try to find the token with common names
    String? token = prefs.getString('access') ?? prefs.getString('access_token') ?? prefs.getString('token');

    if (token == null) {
      print("DEBUG: Tokens found in storage: ${prefs.getKeys()}"); // This will print ALL keys to your console
      print("Error: No token found");
      return false;
    }

    try {
      // 2. Send the POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
        body: jsonEncode({
          'action': action,
          'report': report // Now this variable exists!
        }),
      );

      // 3. Check result
      if (response.statusCode == 200) {
        print("Success: User status updated to $action with report.");
        return true;
      } else {
        print('Failed to update: ${response.body}');
        return false;
      }
    } catch (e) {
      print("Error calling API: $e");
      return false;
    }
  }

  Future<List<dynamic>> getInterviewHistory() async {
    final url = Uri.parse('$baseUrl/users/admin/interviews/history/');
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('access'); // Use correct key

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      print("Error fetching history: $e");
      return [];
    }
  }
}