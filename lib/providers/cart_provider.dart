import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kreativ_flow/data/services/api_service.dart';
import 'package:kreativ_flow/core/constants/api_constants.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Map<String, dynamic>? _cart;
  bool _isLoading = false;

  Map<String, dynamic>? get cart => _cart;
  bool get isLoading => _isLoading;

  double get totalAmount {
    if (_cart == null || _cart!['total'] == null) return 0.0;
    // Manejar el caso de que venga como string o número
    final total = _cart!['total'];
    if (total is String) {
      return double.tryParse(total.replaceAll('BOB ', '').trim()) ?? 0.0;
    }
    return (total as num).toDouble();
  }

  List<dynamic> get cartItems {
    if (_cart == null || _cart!['detalles'] == null) return [];
    return _cart!['detalles'] as List<dynamic>;
  }

  Future<void> loadCart() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.get('${ApiConstants.carritoEndpoint}mi_carrito/');
      print('DEBUG LOAD CART - Status: ${response.statusCode}');
      print('DEBUG LOAD CART - Body: ${response.body}');
      
      if (response.statusCode == 200) {
        _cart = json.decode(response.body);
      }
    } catch (e) {
      print('ERROR LOAD CART: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(int varianteId, {int cantidad = 1}) async {
    print('DEBUG CART - Añadiendo Variante ID: $varianteId, Cantidad: $cantidad');
    try {
      final response = await _apiService.post(
        '${ApiConstants.carritoEndpoint}agregar_producto/',
        {'variante_id': varianteId, 'cantidad': cantidad},
      );
      
      print('DEBUG CART - Status Code: ${response.statusCode}');
      print('DEBUG CART - Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        _cart = json.decode(response.body);
        notifyListeners();
      } else {
        print('ERROR CART - El servidor rechazó la petición');
      }
    } catch (e) {
      print('ERROR CART - Excepción de red: $e');
    }
  }

  Future<void> updateQuantity(int varianteId, int cantidad) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.carritoEndpoint}actualizar_cantidad/',
        {'variante_id': varianteId, 'cantidad': cantidad},
      );
      if (response.statusCode == 200) {
        _cart = json.decode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error actualizando cantidad: $e');
    }
  }

  Future<void> removeItem(int varianteId) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.carritoEndpoint}quitar_producto/',
        {'variante_id': varianteId},
      );
      if (response.statusCode == 200) {
        _cart = json.decode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error eliminando ítem: $e');
    }
  }

  Future<void> clearCart() async {
    try {
      final response = await _apiService.post('${ApiConstants.carritoEndpoint}vaciar/', {});
      if (response.statusCode == 200) {
        _cart = json.decode(response.body);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error vaciando carrito: $e');
    }
  }

  Future<List<int>?> downloadQuotation() async {
    try {
      final response = await _apiService.get(ApiConstants.cotizacionEndpoint);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error descargando cotización: $e');
    }
    return null;
  }

  int get itemCount {
    if (_cart == null || _cart!['detalles'] == null) return 0;
    return (_cart!['detalles'] as List).length;
  }
}
