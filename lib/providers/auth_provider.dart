import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isAuthenticated = false;
  String? _idSocio;
  String? _username;
  bool _isLoading = false;

  bool get isAuthenticated => _isAuthenticated;
  String? get idSocio => _idSocio;
  String? get username => _username;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      _isAuthenticated = true;
      _idSocio = prefs.getString('id_socio');
      _username = prefs.getString('username');
      notifyListeners();
    }
  }

  Future<String?> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.loginEndpoint, {
        'username': username,
        'password': password,
      });

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        
        if (data['success'] == true) {
          await prefs.setString('access_token', data['access']);
          if (data['refresh'] != null) await prefs.setString('refresh_token', data['refresh']);
          
          _idSocio = data['usuario_id']?.toString();
          _username = data['username'];
          
          await prefs.setString('id_socio', _idSocio ?? '');
          await prefs.setString('username', _username ?? '');
          
          _isAuthenticated = true;
          return null; // Éxito
        }
      }
      
      // Si llegamos aquí, hubo un error. Retornamos el mensaje del backend si existe.
      return data['error'] ?? 'Usuario o contraseña incorrectos';
    } catch (e) {
      debugPrint('Error en login: $e');
      return 'Error de conexión con el servidor';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpiar todo por seguridad

    _isAuthenticated = false;
    _idSocio = null;
    _username = null;
    notifyListeners();
  }

  // PASO 1: Solicitar código
  Future<Map<String, dynamic>> requestRecoveryCode(String username) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.recoverRequestEndpoint, {
        'username': username,
      });
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PASO 2: Verificar código
  Future<Map<String, dynamic>> verifyRecoveryCode(String username, String code) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.recoverVerifyEndpoint, {
        'username': username,
        'codigo': code,
      });
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PASO 3: Cambiar contraseña
  Future<Map<String, dynamic>> changePassword(String username, String code, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.recoverChangeEndpoint, {
        'username': username,
        'codigo': code,
        'nueva_password': newPassword,
      });
      return json.decode(response.body);
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión'};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
