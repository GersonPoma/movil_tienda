import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ApiService {
  // ---- Helpers de headers ----
  Future<Map<String, String>> _getHeaders({bool isJson = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      if (isJson) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Uri _buildUri(String endpoint, {Map<String, String>? queryParams}) {
    var uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    return uri;
  }

  // ---- Métodos HTTP ----
  Future<http.Response> get(String endpoint, {Map<String, String>? queryParams}) async {
    final headers = await _getHeaders();
    return http.get(_buildUri(endpoint, queryParams: queryParams), headers: headers);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.post(_buildUri(endpoint), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.put(_buildUri(endpoint), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return http.patch(_buildUri(endpoint), headers: headers, body: jsonEncode(body));
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return http.delete(_buildUri(endpoint), headers: headers);
  }

  /// Subida de archivo multipart (para logo, imágenes de productos)
  Future<http.Response> uploadFile(
    String endpoint,
    File file,
    String fieldName, {
    Map<String, String>? extraFields,
    bool usePatch = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final uri = _buildUri(endpoint);

    final request = http.MultipartRequest(usePatch ? 'PATCH' : 'POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    // Determinar tipo MIME por extensión
    final ext = file.path.split('.').last.toLowerCase();
    final mimeType = ext == 'png' ? 'image/png' : ext == 'gif' ? 'image/gif' : 'image/jpeg';

    request.files.add(await http.MultipartFile.fromPath(
      fieldName,
      file.path,
      contentType: MediaType.parse(mimeType),
    ));

    if (extraFields != null) request.fields.addAll(extraFields);

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  /// Parsear respuesta paginada genérica
  static Map<String, dynamic>? parseBody(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static List<dynamic> parseList(http.Response response) {
    if (response.body.isEmpty) return [];
    try {
      final data = jsonDecode(response.body);
      if (data is List) return data;
      if (data is Map && data.containsKey('results')) return data['results'] as List;
      return [];
    } catch (_) {
      return [];
    }
  }
}
