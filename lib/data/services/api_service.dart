import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      // Usamos el encabezado sugerido por tu amigo para mayor estabilidad
      'X-Tenant': ApiConstants.tenantHeaderValue, 
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    print('DEBUG - POST URL: $url');
    print('DEBUG - HEADERS: $headers');
    print('DEBUG - BODY: $body');
    return http.post(url, headers: headers, body: jsonEncode(body));
  }


  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getHeaders();
    var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);

    }
    return http.get(uri, headers: headers);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.put(url, headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.delete(url, headers: headers);
  }
}
