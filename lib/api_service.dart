import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String apiUrl = 'https://bpk-webapp-prd1.bdms.co.th/ApiPhamacySmartLabel';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('$apiUrl/PatientVerify');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'emplid': username,
      'pass': password,
    });

    final response = await http.post(url, headers: headers, body: body);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load data with status code ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchPatientDetails(String visitId) async {
    final url = Uri.parse('$apiUrl/PatientDetails');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'emplid': visitId, 'pass': ""});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load patient details');
    }
  }

    Future<Map<String, dynamic>> fetchPatientMonth(String hn) async {
    final url = Uri.parse('$apiUrl/PatientDetailsByHn');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'emplid': hn, 'pass': ""});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load patient details');
    }
  }
}
