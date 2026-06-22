import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

class ReportesProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<dynamic> _vistas = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _resultados;
  Map<String, dynamic>? _queryInterpretada;

  List<dynamic> get vistas => _vistas;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get resultados => _resultados;
  Map<String, dynamic>? get queryInterpretada => _queryInterpretada;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void limpiarResultados() {
    _resultados = null;
    _queryInterpretada = null;
    _error = null;
    notifyListeners();
  }

  Future<void> cargarVistas() async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _api.get(ApiConstants.reporteVistasEndpoint);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        if (data is Map && data.containsKey('vistas')) {
          _vistas = data['vistas'];
        } else if (data is List) {
          _vistas = data;
        } else {
          _vistas = [];
        }
      } else {
        _setError('Error ${res.statusCode} al cargar vistas');
      }
    } catch (e) {
      _setError('Error de conexión al cargar vistas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> ejecutarQBE(Map<String, dynamic> payload) async {
    _setLoading(true);
    _setError(null);
    _resultados = null;
    _queryInterpretada = null;
    try {
      final res = await _api.post(ApiConstants.reporteQbeEndpoint, payload);
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        _resultados = data;
        _setLoading(false);
        return true;
      } else {
        final data = ApiService.parseBody(res);
        final msg = data?['error'] ?? data?['message'] ?? 'Error al ejecutar QBE';
        _setError('Error ${res.statusCode}: $msg');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error de conexión al ejecutar QBE: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> ejecutarNLP(String texto) async {
    _setLoading(true);
    _setError(null);
    _resultados = null;
    _queryInterpretada = null;
    try {
      final res = await _api.post(ApiConstants.reporteNlpEndpoint, {
        'texto': texto,
        'idioma': 'es-ES'
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        _queryInterpretada = data['query_interpretada'];
        _resultados = data['resultados'];
        _setLoading(false);
        return true;
      } else {
        final data = ApiService.parseBody(res);
        final msg = data?['error'] ?? data?['detail'] ?? data?['message'] ?? 'Error al procesar consulta NLP';
        _setError('Error ${res.statusCode}: $msg');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Error de conexión al ejecutar NLP: $e');
      _setLoading(false);
      return false;
    }
  }
}
