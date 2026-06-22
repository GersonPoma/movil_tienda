import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_service.dart';
import '../data/models/models.dart';
import '../core/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _token;
  UsuarioLogueado? _usuario;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  UsuarioLogueado? get usuario => _usuario;
  String? get token => _token;

  AuthProvider() { _loadFromStorage(); }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    final userJson = prefs.getString('usuario_json');
    if (userJson != null) {
      try { _usuario = UsuarioLogueado.fromJson(jsonDecode(userJson)); } catch (_) {}
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.loginEndpoint, {
        'username': username, 'password': password,
      });
      _isLoading = false;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        _token = data['access'];
        await prefs.setString('access_token', _token!);
        if (data['refresh'] != null) await prefs.setString('refresh_token', data['refresh']);
        // Guardar perfil de usuario
        _usuario = UsuarioLogueado.fromJson(data);
        await prefs.setString('usuario_json', jsonEncode(data));
        notifyListeners();
        return {'success': true};
      } else {
        String msg = 'Credenciales inválidas';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('detail')) msg = errorData['detail'];
          else if (errorData is Map && errorData.containsKey('non_field_errors')) msg = errorData['non_field_errors'][0].toString();
        } catch (_) {}
        notifyListeners();
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Verifica si el usuario tiene un permiso específico
  bool tienePermiso(String permiso) {
    if (_usuario == null) return false;
    if (_usuario!.isSuperuser) return true;
    return _usuario!.permisos.contains(permiso);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('usuario_json');
    _token = null;
    _usuario = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> requestRecoveryCode(String email) async {
    _isLoading = true; notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.recoverRequestEndpoint, {'email': email});
      _isLoading = false; notifyListeners();
      if (response.statusCode == 200) return {'success': true, 'message': 'Código enviado a tu correo'};
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Error al solicitar código'};
    } catch (e) { _isLoading = false; notifyListeners(); return {'success': false, 'message': 'Error de conexión'}; }
  }

  Future<Map<String, dynamic>> changePassword(String email, String code, String password) async {
    _isLoading = true; notifyListeners();
    try {
      final response = await _apiService.post(ApiConstants.recoverChangeEndpoint, {
        'email': email, 'codigo': code, 'nuevo_password': password,
      });
      _isLoading = false; notifyListeners();
      if (response.statusCode == 200) return {'success': true, 'message': 'Contraseña actualizada con éxito'};
      final data = jsonDecode(response.body);
      return {'success': false, 'message': data['message'] ?? 'Error al cambiar contraseña'};
    } catch (e) { _isLoading = false; notifyListeners(); return {'success': false, 'message': 'Error de conexión'}; }
  }
}
