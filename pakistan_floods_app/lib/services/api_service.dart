import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Returns the actual endpoint based on user setup
  static String getBaseUrl(String serverIp) {
    if (serverIp.trim().isEmpty) {
      // Default to Android Emulator local loopback, otherwise localhost
      return 'http://10.0.2.2:5000/api';
    }
    // Ensure protocol is present
    if (!serverIp.startsWith('http://') && !serverIp.startsWith('https://')) {
      serverIp = 'http://$serverIp';
    }
    // Strip trailing slash if present
    if (serverIp.endsWith('/')) {
      serverIp = serverIp.substring(0, serverIp.length - 1);
    }
    return '$serverIp/api';
  }

  // Unified headers helper to bypass Ngrok browser security intercept warning pages
  static Map<String, String> _jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  static Map<String, String> _getHeaders() {
    return {
      'ngrok-skip-browser-warning': 'true',
    };
  }

  // Get general ML stats and dataset summary
  static Future<Map<String, dynamic>> getStats(String ip) async {
    final url = Uri.parse('${getBaseUrl(ip)}/stats');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to connect: $e'};
    }
  }

  // Get active unique regions list
  static Future<Map<String, dynamic>> getRegions(String ip) async {
    final url = Uri.parse('${getBaseUrl(ip)}/regions');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to load regions: $e'};
    }
  }

  // Perform ML prediction for affected population
  static Future<Map<String, dynamic>> predict(String ip, Map<String, dynamic> inputs) async {
    final url = Uri.parse('${getBaseUrl(ip)}/predict');
    try {
      final response = await http.post(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode(inputs),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['message'] ?? 'Inference failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Prediction request failed: $e'};
    }
  }

  // Submit new disaster data & auto-trigger training
  static Future<Map<String, dynamic>> reportDisaster(String ip, Map<String, dynamic> data) async {
    final url = Uri.parse('${getBaseUrl(ip)}/report');
    try {
      final response = await http.post(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['message'] ?? 'Submission failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Failed to report disaster: $e'};
    }
  }

  // Get Sindh 2023-2030 worst-case future predictions / projections
  static Future<Map<String, dynamic>> getProjections(String ip, String region) async {
    final url = Uri.parse('${getBaseUrl(ip)}/projections?region=$region');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        return {'success': false, 'message': body['message'] ?? 'Failed to render projections'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Projections query failed: $e'};
    }
  }

  // Fetch active disaster warning alerts (from NDMA/Weather departments)
  static Future<Map<String, dynamic>> getAlerts(String ip) async {
    final url = Uri.parse('${getBaseUrl(ip)}/alerts');
    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to compile alerts'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Alerts request failed: $e'};
    }
  }

  // Trigger manual model training/calibration
  static Future<Map<String, dynamic>> forceRetrain(String ip) async {
    final url = Uri.parse('${getBaseUrl(ip)}/retrain');
    try {
      final response = await http.post(url, headers: _getHeaders()).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Retraining failed.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Fail to connect during training: $e'};
    }
  }

  // Download dataset CSV
  static Future<http.Response> downloadDataset(String ip) async {
    final url = Uri.parse('${getBaseUrl(ip)}/exports/dataset');
    return await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
  }

  // Download simulation report CSV for a region
  static Future<http.Response> downloadReport(String ip, String region) async {
    final url = Uri.parse('${getBaseUrl(ip)}/exports/report?region=$region');
    return await http.get(url, headers: _getHeaders()).timeout(const Duration(seconds: 15));
  }

  // Upload/Import custom dataset CSV files
  static Future<Map<String, dynamic>> uploadDataset(String ip, List<int> bytes, String filename) async {
    final url = Uri.parse('${getBaseUrl(ip)}/imports/dataset');
    try {
      final request = http.MultipartRequest('POST', url);
      request.headers['ngrok-skip-browser-warning'] = 'true';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );
      final response = await request.send().timeout(const Duration(seconds: 30));
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        final Map<String, dynamic> body = jsonDecode(responseBody);
        return {'success': false, 'message': body['message'] ?? 'Upload failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  // Request server to email an export (dataset or regional report)
  static Future<Map<String, dynamic>> emailExport({
    required String ip,
    required String email,
    required String type, // 'dataset' or 'report'
    String region = 'Sindh',
    String officerName = 'EOC Officer',
    String batchId = 'EOC-UNKNOWN',
  }) async {
    final url = Uri.parse('${getBaseUrl(ip)}/exports/email');
    try {
      final response = await http.post(
        url,
        headers: _jsonHeaders(),
        body: jsonEncode({
          'email': email,
          'type': type,
          'region': region,
          'officer_name': officerName,
          'batch_id': batchId,
        }),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final Map<String, dynamic> body = jsonDecode(response.body);
        return {'success': false, 'message': body['message'] ?? 'Email request failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Email dispatch error: $e'};
    }
  }
}
