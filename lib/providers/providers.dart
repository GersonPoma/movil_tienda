import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/models.dart';
import '../data/services/api_service.dart';
import '../core/constants/api_constants.dart';

// ============================================================
// INVENTARIO PROVIDER
// ============================================================
class InventarioProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  // Categorías
  List<Categoria> _categorias = [];
  // Marcas
  List<Marca> _marcas = [];
  // Productos
  List<Producto> _productos = [];
  int _totalProductos = 0;
  bool _hasNextPage = false;
  
  // Recomendaciones
  List<Producto> _recomendaciones = [];

  bool _isLoading = false;
  String? _error;

  List<Categoria> get categorias => _categorias;
  List<Marca> get marcas => _marcas;
  List<Producto> get productos => _productos;
  List<Producto> get recomendaciones => _recomendaciones;
  int get totalProductos => _totalProductos;
  bool get hasNextPage => _hasNextPage;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String? e) { _error = e; notifyListeners(); }
  void clearError() { _error = null; notifyListeners(); }

  // ---- CATEGORÍAS ----
  Future<void> cargarCategorias({String? search}) async {
    _setLoading(true); _error = null;
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.categoriasEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        _categorias = ApiService.parseList(res).map((c) => Categoria.fromJson(c)).toList();
      } else { _error = 'Error ${res.statusCode} al cargar categorías'; }
    } catch (e) { _error = 'Error de conexión'; }
    _setLoading(false);
  }

  Future<bool> crearCategoria(String nombre, {String? descripcion}) async {
    try {
      final res = await _api.post(ApiConstants.categoriasEndpoint, {'nombre': nombre, if (descripcion != null) 'descripcion': descripcion});
      if (res.statusCode == 201 || res.statusCode == 200) { await cargarCategorias(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> actualizarCategoria(int id, String nombre, {String? descripcion}) async {
    try {
      final res = await _api.put('${ApiConstants.categoriasEndpoint}$id/', {'nombre': nombre, if (descripcion != null) 'descripcion': descripcion});
      if (res.statusCode == 200) { await cargarCategorias(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> eliminarCategoria(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.categoriasEndpoint}$id/');
      if (res.statusCode == 204 || res.statusCode == 200) { await cargarCategorias(); return true; }
      return false;
    } catch (e) { return false; }
  }

  // ---- MARCAS ----
  Future<void> cargarMarcas({String? search}) async {
    _setLoading(true); _error = null;
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.marcasEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        _marcas = ApiService.parseList(res).map((m) => Marca.fromJson(m)).toList();
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión'; }
    _setLoading(false);
  }

  Future<bool> crearMarca(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.marcasEndpoint, data);
      if (res.statusCode == 201 || res.statusCode == 200) { await cargarMarcas(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> actualizarMarca(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.marcasEndpoint}$id/', data);
      if (res.statusCode == 200) { await cargarMarcas(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> eliminarMarca(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.marcasEndpoint}$id/');
      if (res.statusCode == 204 || res.statusCode == 200) { await cargarMarcas(); return true; }
      return false;
    } catch (e) { return false; }
  }

  // ---- PRODUCTOS ----
  Future<void> cargarProductos({String? search, int? categoriaId, int page = 1}) async {
    if (page == 1) { _productos = []; _isLoading = true; _error = null; notifyListeners(); }
    try {
      final params = <String, String>{
        'page': page.toString(),
        'page_size': '100',
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (categoriaId != null) params['categoria'] = categoriaId.toString();
      final res = await _api.get(ApiConstants.productosEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        List rawList;
        if (data is Map && data.containsKey('results')) {
          _totalProductos = data['count'] ?? 0;
          _hasNextPage = data['next'] != null;
          rawList = data['results'];
        } else { rawList = data is List ? data : []; _totalProductos = rawList.length; _hasNextPage = false; }
        final nuevos = rawList.map((p) => Producto.fromJson(p)).toList();

        // Si los productos cargados no traen sus variantes integradas (comportamiento del servidor de producción),
        // las solicitamos de forma agrupada desde el endpoint de variantes.
        if (nuevos.isNotEmpty && nuevos.any((p) => p.variantes.isEmpty)) {
          try {
            final varRes = await _api.get(
              ApiConstants.variantesEndpoint,
              queryParams: {'page_size': '250'},
            );
            if (varRes.statusCode == 200) {
              final varData = jsonDecode(varRes.body);
              final List<dynamic> results = varData is Map && varData.containsKey('results')
                  ? varData['results'] as List
                  : varData is List ? varData : [];
              
              final Map<int, List<Variante>> productVariants = {};
              for (var vJson in results) {
                final Map<String, dynamic> map = Map<String, dynamic>.from(vJson);
                final prodId = map['producto'] as int?;
                if (prodId != null) {
                  final v = Variante.fromJson(map);
                  productVariants.putIfAbsent(prodId, () => []).add(v);
                }
              }
              
              for (var i = 0; i < nuevos.length; i++) {
                final p = nuevos[i];
                if (p.variantes.isEmpty) {
                  final vars = productVariants[p.id] ?? [];
                  nuevos[i] = Producto(
                    id: p.id,
                    nombre: p.nombre,
                    descripcion: p.descripcion,
                    categoriaNombre: p.categoriaNombre,
                    categoriaId: p.categoriaId,
                    marcaNombre: p.marcaNombre,
                    marcaId: p.marcaId,
                    imagenUrl: p.imagenUrl,
                    variantes: vars,
                    multimedios: p.multimedios,
                    precioMinimoJson: p.precioMinimoJson,
                    variantePrincipalIdJson: p.variantePrincipalIdJson,
                  );
                }
              }
            }
          } catch (varError) {
            debugPrint('Error cargando variantes agrupadas: $varError');
          }
        }

        if (page == 1) _productos = nuevos; else _productos.addAll(nuevos);
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión: $e'; }
    _setLoading(false);
  }

  Future<Producto?> cargarProductoDetalle(int id) async {
    try {
      final res = await _api.get('${ApiConstants.productosEndpoint}$id/');
      if (res.statusCode == 200) {
        final Map<String, dynamic> productJson = Map<String, dynamic>.from(jsonDecode(res.body));
        
        // Fetch variants for this product
        final varRes = await _api.get(
          ApiConstants.variantesEndpoint,
          queryParams: {'producto_id': id.toString(), 'page_size': '100'},
        );
        
        if (varRes.statusCode == 200) {
          final varData = jsonDecode(varRes.body);
          final List<dynamic> results = varData is Map && varData.containsKey('results')
              ? varData['results'] as List
              : varData is List ? varData : [];
          productJson['variantes'] = results;
        }
        
        return Producto.fromJson(productJson);
      }
    } catch (e) {
      debugPrint('Error en cargarProductoDetalle: $e');
    }
    return null;
  }

  Future<bool> crearProducto(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.productosEndpoint, data);
      if (res.statusCode == 201 || res.statusCode == 200) { await cargarProductos(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> actualizarProducto(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.productosEndpoint}$id/', data);
      if (res.statusCode == 200) { await cargarProductos(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> eliminarProducto(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.productosEndpoint}$id/');
      if (res.statusCode == 204 || res.statusCode == 200) { await cargarProductos(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> crearVariante(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.variantesEndpoint, data);
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> eliminarVariante(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.variantesEndpoint}$id/');
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> subirImagenProducto(int productoId, File archivo, String tipo, bool esPrincipal, int orden) async {
    try {
      final res = await _api.uploadFile(
        ApiConstants.multimediosEndpoint,
        archivo,
        'archivo',
        extraFields: {
          'producto_id': productoId.toString(),
          'tipo': tipo,
          'es_principal': esPrincipal.toString(),
          'orden': orden.toString(),
        },
      );
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) { return false; }
  }

  Future<bool> eliminarImagenProducto(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.multimediosEndpoint}$id/');
      return res.statusCode == 204 || res.statusCode == 200;
    } catch (e) { return false; }
  }

  // ---- RECOMENDACIONES (EMBEDDINGS / PGVECTOR) ----
  Future<void> cargarRecomendaciones(int productoId) async {
    _recomendaciones = [];
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await _api.get('${ApiConstants.productosEndpoint}$productoId/recomendados/');
      if (res.statusCode == 200) {
        final List<dynamic> rawList = jsonDecode(res.body);
        _recomendaciones = rawList.map((p) => Producto.fromJson(p)).toList();
      } else {
        _error = 'Error ${res.statusCode} al cargar recomendaciones';
      }
    } catch (e) {
      _error = 'Error de conexión: $e';
    }
    _isLoading = false;
    notifyListeners();
  }
}

// ============================================================
// SEGURIDAD PROVIDER
// ============================================================
class SeguridadProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Usuario> _usuarios = [];
  List<Rol> _roles = [];
  List<Bitacora> _bitacora = [];
  bool _isLoading = false;
  String? _error;

  List<Usuario> get usuarios => _usuarios;
  List<Rol> get roles => _roles;
  List<Bitacora> get bitacora => _bitacora;
  bool get isLoading => _isLoading;
  String? get error => _error;
  void clearError() { _error = null; notifyListeners(); }

  // Usuarios
  Future<void> cargarUsuarios({String? search}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.usuariosEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        _usuarios = ApiService.parseList(res).map((u) => Usuario.fromJson(u)).toList();
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión'; }
    _isLoading = false; notifyListeners();
  }

  Future<bool> crearUsuario(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.usuariosEndpoint, data);
      if (res.statusCode == 201 || res.statusCode == 200) { await cargarUsuarios(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> actualizarUsuario(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.usuariosEndpoint}$id/', data);
      if (res.statusCode == 200) { await cargarUsuarios(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> eliminarUsuario(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.usuariosEndpoint}$id/');
      if (res.statusCode == 204 || res.statusCode == 200) { await cargarUsuarios(); return true; }
      return false;
    } catch (e) { return false; }
  }

  // Roles
  Future<void> cargarRoles() async {
    _isLoading = true; notifyListeners();
    try {
      final res = await _api.get(ApiConstants.rolesEndpoint);
      if (res.statusCode == 200) {
        _roles = ApiService.parseList(res).map((r) => Rol.fromJson(r)).toList();
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión'; }
    _isLoading = false; notifyListeners();
  }

  Future<bool> crearRol(String name) async {
    try {
      final res = await _api.post(ApiConstants.rolesEndpoint, {'name': name});
      if (res.statusCode == 201 || res.statusCode == 200) { await cargarRoles(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> eliminarRol(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.rolesEndpoint}$id/');
      if (res.statusCode == 204 || res.statusCode == 200) { await cargarRoles(); return true; }
      return false;
    } catch (e) { return false; }
  }

  // Bitácora (solo lectura)
  Future<void> cargarBitacora({String? search}) async {
    _isLoading = true; notifyListeners();
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.bitacoraEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        _bitacora = ApiService.parseList(res).map((b) => Bitacora.fromJson(b)).toList();
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión'; }
    _isLoading = false; notifyListeners();
  }
}

// ============================================================
// COMPRAS PROVIDER
// ============================================================
class ComprasProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Proveedor> _proveedores = [];
  List<Compra> _compras = [];
  Compra? _compraDetalle;
  bool _isLoading = false;
  String? _error;

  List<Proveedor> get proveedores => _proveedores;
  List<Compra> get compras => _compras;
  Compra? get compraDetalle => _compraDetalle;
  bool get isLoading => _isLoading;
  String? get error => _error;
  void clearError() { _error = null; notifyListeners(); }

  // Proveedores
  Future<void> cargarProveedores({String? search}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.proveedoresEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        _proveedores = ApiService.parseList(res).map((p) => Proveedor.fromJson(p)).toList();
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión'; }
    _isLoading = false; notifyListeners();
  }

  Future<bool> crearProveedor(Map<String, dynamic> data) async {
    try {
      final res = await _api.post(ApiConstants.proveedoresEndpoint, data);
      if (res.statusCode == 201 || res.statusCode == 200) { await cargarProveedores(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> actualizarProveedor(int id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('${ApiConstants.proveedoresEndpoint}$id/', data);
      if (res.statusCode == 200) { await cargarProveedores(); return true; }
      return false;
    } catch (e) { return false; }
  }

  Future<bool> eliminarProveedor(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.proveedoresEndpoint}$id/');
      if (res.statusCode == 204 || res.statusCode == 200) { await cargarProveedores(); return true; }
      return false;
    } catch (e) { return false; }
  }

  // Compras
  Future<void> cargarCompras({String? search}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.comprasEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        _compras = ApiService.parseList(res).map((c) => Compra.fromJson(c)).toList();
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión'; }
    _isLoading = false; notifyListeners();
  }

  Future<void> cargarDetalleCompra(int id) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await _api.get('${ApiConstants.comprasEndpoint}$id/');
      if (res.statusCode == 200) _compraDetalle = Compra.fromJson(jsonDecode(res.body));
    } catch (e) {}
    _isLoading = false; notifyListeners();
  }
}

// ============================================================
// VENTAS PROVIDER
// ============================================================
class VentasProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<Venta> _ventas = [];
  Venta? _ventaDetalle;
  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  // Carrito para nueva venta
  final List<ItemCarrito> _carrito = [];
  Usuario? _clienteSeleccionado;
  List<Usuario> _usuariosBuscados = [];
  bool _isLoadingUsuarios = false;

  List<Venta> get ventas => _ventas;
  Venta? get ventaDetalle => _ventaDetalle;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;
  List<ItemCarrito> get carrito => _carrito;
  Usuario? get clienteSeleccionado => _clienteSeleccionado;
  List<Usuario> get usuariosBuscados => _usuariosBuscados;
  bool get isLoadingUsuarios => _isLoadingUsuarios;
  double get totalCarrito => _carrito.fold(0.0, (sum, item) => sum + item.subtotal);
  bool get carritoValido => _carrito.isNotEmpty;

  void clearError() { _error = null; notifyListeners(); }
  void clearSuccess() { _successMessage = null; notifyListeners(); }

  // ---- Lista de ventas ----
  Future<void> cargarVentas({String? search}) async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final params = <String, String>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.ventasEndpoint, queryParams: params);
      if (res.statusCode == 200) {
        _ventas = ApiService.parseList(res).map((v) => Venta.fromJson(v)).toList();
      } else { _error = 'Error ${res.statusCode}'; }
    } catch (e) { _error = 'Error de conexión'; }
    _isLoading = false; notifyListeners();
  }

  Future<void> cargarDetalleVenta(int id) async {
    _isLoading = true; notifyListeners();
    try {
      final res = await _api.get('${ApiConstants.ventasEndpoint}$id/');
      if (res.statusCode == 200) _ventaDetalle = Venta.fromJson(jsonDecode(res.body));
    } catch (e) {}
    _isLoading = false; notifyListeners();
  }

  Future<bool> eliminarVenta(int id) async {
    try {
      final res = await _api.delete('${ApiConstants.ventasEndpoint}$id/');
      if (res.statusCode == 204 || res.statusCode == 200) { await cargarVentas(); return true; }
      return false;
    } catch (e) { return false; }
  }

  // ---- Búsqueda de clientes (para crear venta) ----
  Future<void> buscarUsuarios(String term) async {
    if (term.length < 2) { _usuariosBuscados = []; notifyListeners(); return; }
    _isLoadingUsuarios = true; notifyListeners();
    try {
      final res = await _api.get(ApiConstants.usuariosEndpoint, queryParams: {'search': term});
      if (res.statusCode == 200) {
        _usuariosBuscados = ApiService.parseList(res).map((u) => Usuario.fromJson(u)).toList();
      }
    } catch (e) {}
    _isLoadingUsuarios = false; notifyListeners();
  }

  void seleccionarCliente(Usuario? u) { _clienteSeleccionado = u; notifyListeners(); }
  void limpiarCliente() { _clienteSeleccionado = null; _usuariosBuscados = []; notifyListeners(); }

  // ---- Carrito para nueva venta ----
  void agregarAlCarrito(Variante variante, Producto producto, int cantidad) {
    final existente = _carrito.where((i) => i.varianteId == variante.id).firstOrNull;
    if (existente != null) {
      existente.cantidad += cantidad;
    } else {
      _carrito.add(ItemCarrito(
        varianteId: variante.id,
        productoNombre: producto.nombre,
        sku: variante.sku ?? variante.descripcionCorta,
        precioUnitario: variante.precio,
        cantidad: cantidad,
      ));
    }
    notifyListeners();
  }

  void quitarDelCarrito(int index) {
    if (index >= 0 && index < _carrito.length) { _carrito.removeAt(index); notifyListeners(); }
  }

  void limpiarCarrito() { _carrito.clear(); notifyListeners(); }

  // ---- Crear venta: guardar pendiente ----
  Future<bool> guardarPendiente() async {
    if (_carrito.isEmpty) return false;
    _isLoading = true; _error = null; notifyListeners();
    try {
      final body = await _buildVentaBody('pendiente');
      final res = await _api.post(ApiConstants.ventasEndpoint, body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        _successMessage = 'Venta guardada como pendiente';
        limpiarCarrito(); limpiarCliente();
        await cargarVentas();
        _isLoading = false; notifyListeners();
        return true;
      }
      _error = 'Error al guardar venta (${res.statusCode}): ${res.body}';
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  // ---- Crear venta: pagar y completar ----
  Future<bool> pagarYCompletar() async {
    if (_carrito.isEmpty) return false;
    _isLoading = true; _error = null; notifyListeners();
    try {
      final body = await _buildVentaBody('completado');
      final res = await _api.post(ApiConstants.ventasEndpoint, body);
      if (res.statusCode == 201 || res.statusCode == 200) {
        _successMessage = 'Venta completada exitosamente';
        limpiarCarrito(); limpiarCliente();
        await cargarVentas();
        _isLoading = false; notifyListeners();
        return true;
      }
      _error = 'Error al completar venta (${res.statusCode}): ${res.body}';
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> _buildVentaBody(String estado) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('usuario_json');
    int? currentUserId;
    if (userJson != null) {
      try {
        final decoded = jsonDecode(userJson);
        currentUserId = decoded['usuario_id'] ?? decoded['id'];
      } catch (_) {}
    }

    final userId = _clienteSeleccionado?.id ?? currentUserId ?? 1;

    return {
      'tipo': 'digital',
      'estado': estado,
      'usuario_id': userId,
      'detalles': _carrito.map((item) => {
        'variante_producto_id': item.varianteId,
        'cantidad': item.cantidad,
        'precio_unitario': item.precioUnitario,
      }).toList(),
    };
  }
}

// ============================================================
// EMPRESA PROVIDER
// ============================================================
class EmpresaProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  ConfiguracionEmpresa? _config;
  bool _isLoading = false;
  String? _error;
  bool _guardadoExitoso = false;

  ConfiguracionEmpresa? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get guardadoExitoso => _guardadoExitoso;
  void clearStatus() { _error = null; _guardadoExitoso = false; notifyListeners(); }

  Future<void> cargarConfiguracion() async {
    _isLoading = true; _error = null; notifyListeners();
    try {
      final res = await _api.get(ApiConstants.empresaEndpoint);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          _config = ConfiguracionEmpresa.fromJson(Map<String, dynamic>.from(data.first));
        } else if (data is Map && data.containsKey('results')) {
          final results = data['results'] as List;
          if (results.isNotEmpty) {
            _config = ConfiguracionEmpresa.fromJson(Map<String, dynamic>.from(results.first));
          }
        } else if (data is Map) {
          _config = ConfiguracionEmpresa.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e) { 
      _error = 'Error de conexión'; 
    }
    _isLoading = false; notifyListeners();
  }

  Future<bool> guardarConfiguracion(Map<String, dynamic> data) async {
    _isLoading = true; _error = null; _guardadoExitoso = false; notifyListeners();
    try {
      final id = _config?.id;
      final res = id != null
          ? await _api.put('${ApiConstants.empresaEndpoint}$id/', data)
          : await _api.post(ApiConstants.empresaEndpoint, data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        _config = ConfiguracionEmpresa.fromJson(Map<String, dynamic>.from(decoded));
        _guardadoExitoso = true; _isLoading = false; notifyListeners();
        return true;
      }
      _error = 'Error ${res.statusCode}: ${res.body}';
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _error = 'Error de conexión: $e';
      _isLoading = false; notifyListeners();
      return false;
    }
  }

  Future<bool> subirLogo(File logoFile) async {
    _isLoading = true; notifyListeners();
    try {
      final id = _config?.id;
      final endpoint = id != null
          ? '${ApiConstants.empresaEndpoint}$id/'
          : ApiConstants.empresaEndpoint;
      final res = await _api.uploadFile(endpoint, logoFile, 'logo', usePatch: id != null);
      if (res.statusCode == 200 || res.statusCode == 201) {
        final decoded = jsonDecode(res.body);
        _config = ConfiguracionEmpresa.fromJson(Map<String, dynamic>.from(decoded));
        _isLoading = false; notifyListeners();
        return true;
      }
      _isLoading = false; notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false; notifyListeners();
      return false;
    }
  }
}
