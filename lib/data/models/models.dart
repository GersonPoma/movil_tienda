import 'package:flutter/material.dart';

// ============================================================
// MODELOS COMPLETOS - TiendaMovil Flutter App
// Basados en los modelos del backend Django y frontend Angular
// ============================================================

// ---- PAGINACIÓN ----
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;
  PaginatedResponse({required this.count, this.next, this.previous, required this.results});
}

// ---- AUTENTICACIÓN ----
class UsuarioLogueado {
  final int id;
  final String username;
  final String? nombre;
  final String? apellido;
  final String? email;
  final bool isSuperuser;
  final List<String> permisos;
  final List<String> roles;

  UsuarioLogueado({
    required this.id,
    required this.username,
    this.nombre,
    this.apellido,
    this.email,
    this.isSuperuser = false,
    this.permisos = const [],
    this.roles = const [],
  });

  String get nombreCompleto {
    final n = '${nombre ?? ''} ${apellido ?? ''}'.trim();
    return n.isEmpty ? username : n;
  }

  factory UsuarioLogueado.fromJson(Map<String, dynamic> json) => UsuarioLogueado(
        id: json['usuario_id'] ?? json['id'] ?? 0,
        username: json['username'] ?? '',
        nombre: json['nombre'] ?? json['nombre_completo'],
        apellido: json['apellido'],
        email: json['email'],
        isSuperuser: json['is_superuser'] ?? false,
        permisos: List<String>.from(json['permisos'] ?? []),
        roles: List<String>.from(json['roles'] ?? []),
      );
}

// ---- INVENTARIO ----

class Categoria {
  final int id;
  final String nombre;
  final String? descripcion;

  Categoria({required this.id, required this.nombre, this.descripcion});

  factory Categoria.fromJson(Map<String, dynamic> json) => Categoria(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        descripcion: json['descripcion'],
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (descripcion != null && descripcion!.isNotEmpty) 'descripcion': descripcion,
      };
}

class Marca {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? logoUrl;

  Marca({required this.id, required this.nombre, this.descripcion, this.logoUrl});

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        descripcion: json['descripcion'],
        logoUrl: json['logo_url'] ?? json['logo'],
      );
}

class Variante {
  final int id;
  final String? sku;
  final String? color;
  final String? talla;
  final double precio;
  final int cantidad; // stock
  final double costoPonderado;
  final int limiteCantidad;
  final String? imagenUrl;

  Variante({
    required this.id,
    this.sku,
    this.color,
    this.talla,
    required this.precio,
    required this.cantidad,
    this.costoPonderado = 0.0,
    this.limiteCantidad = 10,
    this.imagenUrl,
  });

  factory Variante.fromJson(Map<String, dynamic> json) => Variante(
        id: json['id'],
        sku: json['sku'],
        color: json['color'],
        talla: json['talla'],
        precio: double.tryParse(json['precio'].toString()) ?? 0.0,
        cantidad: json['cantidad'] ?? json['stock'] ?? 0,
        costoPonderado: double.tryParse(json['costo_ponderado']?.toString() ?? '0') ?? 0.0,
        limiteCantidad: int.tryParse(json['limite_cantidad']?.toString() ?? '10') ?? 10,
        imagenUrl: json['imagen_url'] ?? json['archivo_url'],
      );

  String get descripcionCorta {
    final parts = <String>[];
    if (sku != null && sku!.isNotEmpty) parts.add(sku!);
    if (color != null && color!.isNotEmpty) parts.add(color!);
    if (talla != null && talla!.isNotEmpty) parts.add(talla!);
    return parts.isEmpty ? 'Variante #$id' : parts.join(' / ');
  }
}

class Multimedia {
  final int id;
  final String tipo; // imagen, realidad_aumentada, video
  final String url;
  final bool esPrincipal;

  Multimedia({required this.id, required this.tipo, required this.url, this.esPrincipal = false});

  factory Multimedia.fromJson(Map<String, dynamic> json) => Multimedia(
        id: json['id'],
        tipo: json['tipo'] ?? 'imagen',
        url: json['archivo_url'] ?? json['url'] ?? json['archivo'] ?? '',
        esPrincipal: json['es_principal'] ?? false,
      );
}

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final String? categoriaNombre;
  final int? categoriaId;
  final String? marcaNombre;
  final int? marcaId;
  final String? imagenUrl;
  final List<Variante> variantes;
  final List<Multimedia> multimedios;
  final double? precioMinimoJson;
  final int? variantePrincipalIdJson;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.categoriaNombre,
    this.categoriaId,
    this.marcaNombre,
    this.marcaId,
    this.imagenUrl,
    this.variantes = const [],
    this.multimedios = const [],
    this.precioMinimoJson,
    this.variantePrincipalIdJson,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    // Django backend splits multimedia into 'imagenes' and 'modelos_3d' lists
    final imagenesJson = json['imagenes'] as List<dynamic>? ?? [];
    final modelos3dJson = json['modelos_3d'] as List<dynamic>? ?? [];
    
    final List<Multimedia> multimedios = [];
    multimedios.addAll(imagenesJson.map((m) => Multimedia.fromJson(Map<String, dynamic>.from(m))));
    multimedios.addAll(modelos3dJson.map((m) => Multimedia.fromJson(Map<String, dynamic>.from(m))));

    // Obtener imagen principal
    final principal = multimedios.where((m) => m.tipo == 'imagen' && m.esPrincipal).firstOrNull;
    final primeraImagen = multimedios.where((m) => m.tipo == 'imagen').firstOrNull;
    final imagenUrl = principal?.url ?? primeraImagen?.url ?? json['imagen_principal'] ?? json['imagen_url'];

    return Producto(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'],
      categoriaNombre: json['categoria_nombre'] ?? (json['categoria'] is Map ? json['categoria']['nombre'] : null),
      categoriaId: json['categoria_id'] ?? (json['categoria'] is Map ? json['categoria']['id'] : json['categoria']),
      marcaNombre: json['marca_nombre'] ?? (json['marca'] is Map ? json['marca']['nombre'] : null),
      marcaId: json['marca_id'] ?? (json['marca'] is Map ? json['marca']['id'] : json['marca']),
      imagenUrl: imagenUrl,
      variantes: (json['variantes'] as List<dynamic>? ?? []).map((v) => Variante.fromJson(Map<String, dynamic>.from(v))).toList(),
      multimedios: multimedios,
      precioMinimoJson: double.tryParse(json['precio_minimo']?.toString() ?? '') ?? (json['precio_minimo'] != null ? (json['precio_minimo'] as num).toDouble() : null),
      variantePrincipalIdJson: json['variante_principal_id'] != null ? int.tryParse(json['variante_principal_id'].toString()) ?? (json['variante_principal_id'] as int?) : null,
    );
  }

  String? get modelo3dUrl {
    final ar = multimedios.firstWhere((m) => m.tipo == 'realidad_aumentada', orElse: () => Multimedia(id: 0, url: '', tipo: 'imagen'));
    return ar.url.isNotEmpty ? ar.url : null;
  }

  double get precioMinimo {
    if (precioMinimoJson != null && precioMinimoJson! > 0.0) {
      return precioMinimoJson!;
    }
    return variantes.isEmpty ? 0.0 : variantes.map((v) => v.precio).reduce((a, b) => a < b ? a : b);
  }

  int get variantePrincipalId {
    if (variantePrincipalIdJson != null && variantePrincipalIdJson! > 0) {
      return variantePrincipalIdJson!;
    }
    return variantes.isNotEmpty ? variantes.first.id : 0;
  }
}

// Agrupación de variantes para la pantalla crear-venta (igual al frontend)
class ProductoGrupo {
  final int productoId;
  final String productoNombre;
  final String? imagenUrl;
  final String? categoriaNombre;
  final String? marcaNombre;
  final List<Variante> variantes;

  ProductoGrupo({
    required this.productoId,
    required this.productoNombre,
    this.imagenUrl,
    this.categoriaNombre,
    this.marcaNombre,
    required this.variantes,
  });

  factory ProductoGrupo.fromProducto(Producto p) => ProductoGrupo(
        productoId: p.id,
        productoNombre: p.nombre,
        imagenUrl: p.imagenUrl,
        categoriaNombre: p.categoriaNombre,
        marcaNombre: p.marcaNombre,
        variantes: p.variantes.where((v) => v.cantidad > 0).toList(),
      );
}

// ---- SEGURIDAD ----

class Usuario {
  final int id;
  final String username;
  final String? nombre;
  final String? apellido;
  final String? email;
  final bool isActive;
  final bool isSuperuser;
  final List<String> grupos;

  Usuario({
    required this.id,
    required this.username,
    this.nombre,
    this.apellido,
    this.email,
    this.isActive = true,
    this.isSuperuser = false,
    this.grupos = const [],
  });

  String get nombreCompleto {
    final n = '${nombre ?? ''} ${apellido ?? ''}'.trim();
    return n.isEmpty ? username : n;
  }

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'],
        username: json['username'] ?? '',
        nombre: json['nombre'] ?? json['first_name'],
        apellido: json['apellido'] ?? json['last_name'],
        email: json['email'],
        isActive: json['is_active'] ?? true,
        isSuperuser: json['is_superuser'] ?? false,
        grupos: List<String>.from((json['grupos'] ?? json['groups'] ?? [])
            .map((g) => g is Map ? g['name'] : g.toString())),
      );
}

class Rol {
  final int id;
  final String name;
  final List<dynamic> permissions;

  Rol({required this.id, required this.name, this.permissions = const []});

  factory Rol.fromJson(Map<String, dynamic> json) => Rol(
        id: json['id'],
        name: json['name'] ?? '',
        permissions: json['permissions'] ?? [],
      );
}

class Bitacora {
  final int id;
  final String accion;
  final String? modulo;
  final String? usuarioNombre;
  final String fechaHora;
  final String? descripcion;
  final String? ipAddress;

  Bitacora({
    required this.id,
    required this.accion,
    this.modulo,
    this.usuarioNombre,
    required this.fechaHora,
    this.descripcion,
    this.ipAddress,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) => Bitacora(
        id: json['id'],
        accion: json['accion'] ?? json['action'] ?? '',
        modulo: json['modulo'] ?? json['module'],
        usuarioNombre: json['usuario'] is Map
            ? (json['usuario']['username'] ?? json['usuario']['nombre'])
            : json['usuario']?.toString() ?? json['user']?.toString(),
        fechaHora: json['fecha_hora'] ?? json['created_at'] ?? json['timestamp'] ?? '',
        descripcion: json['descripcion'] ?? json['description'],
        ipAddress: json['ip_address'],
      );
}

// ---- COMPRAS ----

class Proveedor {
  final int id;
  final String nombre;
  final String? ruc;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? contacto;

  Proveedor({
    required this.id,
    required this.nombre,
    this.ruc,
    this.telefono,
    this.email,
    this.direccion,
    this.contacto,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        ruc: json['ruc'],
        telefono: json['telefono'],
        email: json['email'],
        direccion: json['direccion'],
        contacto: json['contacto'],
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (ruc != null) 'ruc': ruc,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (direccion != null) 'direccion': direccion,
        if (contacto != null) 'contacto': contacto,
      };
}

class DetalleCompra {
  final int id;
  final String? productoNombre;
  final String? sku;
  final int cantidad;
  final double costoUnitario;
  final double subtotal;

  DetalleCompra({
    required this.id,
    this.productoNombre,
    this.sku,
    required this.cantidad,
    required this.costoUnitario,
    required this.subtotal,
  });

  factory DetalleCompra.fromJson(Map<String, dynamic> json) => DetalleCompra(
        id: json['id'],
        productoNombre: json['producto_nombre'] ?? (json['variante'] is Map ? json['variante']['sku'] : null),
        sku: json['sku'],
        cantidad: json['cantidad'] ?? 1,
        costoUnitario: double.tryParse(json['costo_unitario']?.toString() ?? '0') ?? 0.0,
        subtotal: double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
      );
}

class Compra {
  final int id;
  final String? numeroCompra;
  final String? proveedorNombre;
  final int? proveedorId;
  final String fecha;
  final double total;
  final String estado;
  final List<DetalleCompra> detalles;

  Compra({
    required this.id,
    this.numeroCompra,
    this.proveedorNombre,
    this.proveedorId,
    required this.fecha,
    required this.total,
    required this.estado,
    this.detalles = const [],
  });

  factory Compra.fromJson(Map<String, dynamic> json) => Compra(
        id: json['id'],
        numeroCompra: json['numero_compra']?.toString(),
        proveedorNombre: json['proveedor_nombre'] ??
            (json['proveedor'] is Map ? json['proveedor']['nombre'] : null),
        proveedorId: json['proveedor_id'] ??
            (json['proveedor'] is Map ? json['proveedor']['id'] : json['proveedor']),
        fecha: json['fecha'] ?? json['created_at'] ?? '',
        total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
        estado: json['estado'] ?? 'pendiente',
        detalles: (json['detalles'] as List<dynamic>? ?? [])
            .map((d) => DetalleCompra.fromJson(d))
            .toList(),
      );
}

// ---- VENTAS ----

class ItemCarrito {
  final int varianteId;
  final String productoNombre;
  final String sku;
  final double precioUnitario;
  int cantidad;

  ItemCarrito({
    required this.varianteId,
    required this.productoNombre,
    required this.sku,
    required this.precioUnitario,
    required this.cantidad,
  });

  double get subtotal => precioUnitario * cantidad;
}

class DetalleVenta {
  final int id;
  final String? productoNombre;
  final String? sku;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVenta({
    required this.id,
    this.productoNombre,
    this.sku,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) => DetalleVenta(
        id: json['id'],
        productoNombre: json['variante_producto_nombre'] ?? json['producto_nombre'],
        sku: json['variante_producto_sku'] ?? json['sku'],
        cantidad: json['cantidad'] ?? 1,
        precioUnitario: double.tryParse(json['precio_unitario']?.toString() ?? '0') ?? 0.0,
        subtotal: double.tryParse(json['precio_subtotal']?.toString() ?? json['subtotal']?.toString() ?? '0') ?? 0.0,
      );
}

class Venta {
  final int id;
  final String? numeroVenta;
  final String? clienteNombre;
  final int? clienteId;
  final String fecha;
  final double total;
  final String estado; // pendiente, completada, anulada
  final List<DetalleVenta> detalles;

  Venta({
    required this.id,
    this.numeroVenta,
    this.clienteNombre,
    this.clienteId,
    required this.fecha,
    required this.total,
    required this.estado,
    this.detalles = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
        id: json['id'],
        numeroVenta: json['numero_venta']?.toString(),
        clienteNombre: json['usuario_username'] ?? json['cliente_nombre'] ?? json['usuario_nombre'] ??
            (json['cliente'] is Map ? json['cliente']['username'] : null),
        clienteId: json['usuario'] ?? json['cliente_id'] ?? json['usuario_id'] ??
            (json['cliente'] is Map ? json['cliente']['id'] : json['cliente']),
        fecha: json['fecha'] ?? json['created_at'] ?? '',
        total: double.tryParse(json['precio_total']?.toString() ?? json['total']?.toString() ?? '0') ?? 0.0,
        estado: json['estado'] ?? 'pendiente',
        detalles: (json['detalles'] as List<dynamic>? ?? [])
            .map((d) => DetalleVenta.fromJson(d))
            .toList(),
      );

}

// ---- EMPRESA ----

class ConfiguracionEmpresa {
  final int? id;
  final String nombre;
  final String? email;
  final String? telefono;
  final String? direccion;
  final String? logoUrl;
  final String? facebook;
  final String? instagram;
  final String? tiktok;
  final String? ruc;
  final String moneda;
  final double igvPorcentaje;

  ConfiguracionEmpresa({
    this.id,
    required this.nombre,
    this.email,
    this.telefono,
    this.direccion,
    this.logoUrl,
    this.facebook,
    this.instagram,
    this.tiktok,
    this.ruc,
    this.moneda = 'PEN',
    this.igvPorcentaje = 18.0,
  });

  factory ConfiguracionEmpresa.fromJson(Map<String, dynamic> json) => ConfiguracionEmpresa(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        email: json['email'],
        telefono: json['telefono'],
        direccion: json['direccion'],
        logoUrl: json['logo_url'] ?? json['logo'],
        facebook: json['facebook'],
        instagram: json['instagram'],
        tiktok: json['tiktok'],
        ruc: json['ruc'],
        moneda: json['moneda'] ?? 'PEN',
        igvPorcentaje: double.tryParse(json['igv_porcentaje']?.toString() ?? '18') ?? 18.0,
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (email != null) 'email': email,
        if (telefono != null) 'telefono': telefono,
        if (direccion != null) 'direccion': direccion,
        if (facebook != null) 'facebook': facebook,
        if (instagram != null) 'instagram': instagram,
        if (tiktok != null) 'tiktok': tiktok,
        if (ruc != null) 'ruc': ruc,
        'moneda': moneda,
        'igv_porcentaje': igvPorcentaje,
      };
}


