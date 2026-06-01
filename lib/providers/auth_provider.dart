import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _token;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.loginEndpoint, {
        'username': username,
        'password': password,
      });


      _isLoading = false;
      notifyListeners();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        _token = data['access'];
        await prefs.setString('access_token', _token!);
        if (data['refresh'] != null) {
          await prefs.setString('refresh_token', data['refresh']);
        }
        notifyListeners();
        return {'success': true};
      } else {
        print('DEBUG SERVER RESPONSE: ${response.statusCode} - ${response.body}');
        String msg = 'Credenciales inválidas';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) {
            msg = errorData['detail'];
          } else if (errorData is Map && errorData.containsKey('non_field_errors')) {
            msg = errorData['non_field_errors'][0].toString();
          }
        } catch (_) {}
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('DEBUG ERROR: $e');
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // Restaurando con argumentos por posición para compatibilidad
  Future<Map<String, dynamic>> requestRecoveryCode(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.recoverRequestEndpoint, {
        'email': email,
      });
      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Código enviado a tu correo'};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Error al solicitar código'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<Map<String, dynamic>> changePassword(String email, String code, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.recoverChangeEndpoint, {
        'email': email,
        'codigo': code,
        'nuevo_password': password,
      });
      _isLoading = false;
      notifyListeners();
      
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Contraseña actualizada con éxito'};
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Error al cambiar contraseña'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión'};
    }
  }


  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _token = null;
    notifyListeners();
  }
}
