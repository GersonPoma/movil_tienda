import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kreativ_flow/data/models/producto_model.dart';
import 'package:kreativ_flow/data/services/api_service.dart';
import 'package:kreativ_flow/core/constants/api_constants.dart';

class ProductProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Producto> _productos = [];
  List<Categoria> _categorias = [];
  bool _isLoading = false;
  int? _categoriaSeleccionada;
  String _terminoBusqueda = '';

  List<Producto> get productos => _productos;
  List<Categoria> get categorias => _categorias;
  bool get isLoading => _isLoading;
  int? get categoriaSeleccionada => _categoriaSeleccionada;

  Future<void> cargarCategorias() async {
    try {
      final response = await _apiService.get(ApiConstants.categoriasEndpoint);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _categorias = (data['results'] as List)
            .map((cat) => Categoria.fromJson(cat))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
    }
  }

  Future<void> cargarProductos({int? categoriaId, String? search}) async {
    _isLoading = true;
    _categoriaSeleccionada = categoriaId ?? _categoriaSeleccionada;
    if (categoriaId == null && search == null && _categoriaSeleccionada == null) {
      // Carga inicial
    }
    
    _terminoBusqueda = search ?? _terminoBusqueda;
    notifyListeners();

    try {
      final queryParams = {
        'page_size': '50',
        if (_categoriaSeleccionada != null) 'categoria': _categoriaSeleccionada.toString(),
        if (_terminoBusqueda.isNotEmpty) 'search': _terminoBusqueda,
      };

      final response = await _apiService.get(
        ApiConstants.productosEndpoint,
        queryParams: queryParams,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _productos = (data['results'] as List)
            .map((prod) => Producto.fromJson(prod))
            .toList();
      }
    } catch (e) {
      debugPrint('Error cargando productos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void filtrarPorCategoria(int? id) {
    _categoriaSeleccionada = id;
    cargarProductos(categoriaId: id);
  }

  void buscar(String term) {
    _terminoBusqueda = term;
    cargarProductos(search: term);
  }
}
