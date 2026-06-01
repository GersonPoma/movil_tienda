// ---- MODELOS COMPLETOS PARA TIENDA MOVIL ----

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

  Map<String, dynamic> toJson() => {'nombre': nombre, 'descripcion': descripcion};
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
  final String? color;
  final String? talla;
  final double precio;
  final int stock;

  Variante({required this.id, this.color, this.talla, required this.precio, required this.stock});

  factory Variante.fromJson(Map<String, dynamic> json) => Variante(
        id: json['id'],
        color: json['color'],
        talla: json['talla'],
        precio: double.tryParse(json['precio'].toString()) ?? 0.0,
        stock: json['stock'] ?? 0,
      );

  String get descripcion {
    final parts = [if (color != null) color!, if (talla != null) talla!];
    return parts.isEmpty ? 'Estándar' : parts.join(' / ');
  }
}

class Multimedia {
  final int id;
  final String tipo;
  final String url;

  Multimedia({required this.id, required this.tipo, required this.url});

  factory Multimedia.fromJson(Map<String, dynamic> json) => Multimedia(
        id: json['id'],
        tipo: json['tipo'] ?? 'imagen',
        url: json['url'] ?? json['archivo'] ?? '',
      );
}

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final int stock;
  final String? imagenUrl;
  final Categoria? categoria;
  final Marca? marca;
  final List<Variante> variantes;
  final List<Multimedia> multimedios;

  Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    required this.stock,
    this.imagenUrl,
    this.categoria,
    this.marca,
    this.variantes = const [],
    this.multimedios = const [],
  });

  factory Producto.fromJson(Map<String, dynamic> json) => Producto(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        descripcion: json['descripcion'],
        precio: double.tryParse(json['precio'].toString()) ?? 0.0,
        stock: json['stock'] ?? 0,
        imagenUrl: json['imagen_url'] ?? json['imagen_principal'] ?? json['imagen'],
        categoria: json['categoria'] != null
            ? (json['categoria'] is Map ? Categoria.fromJson(json['categoria']) : null)
            : null,
        marca: json['marca'] != null
            ? (json['marca'] is Map ? Marca.fromJson(json['marca']) : null)
            : null,
        variantes: (json['variantes'] as List<dynamic>? ?? [])
            .map((v) => Variante.fromJson(v))
            .toList(),
        multimedios: (json['multimedios'] as List<dynamic>? ?? [])
            .map((m) => Multimedia.fromJson(m))
            .toList(),
      );

  String? get modelo3dUrl {
    try {
      return multimedios.firstWhere((m) => m.tipo == 'modelo_3d').url;
    } catch (_) {
      return null;
    }
  }
}

// ---- SEGURIDAD ----

class Usuario {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? email;
  final bool isActive;
  final bool isSuperuser;

  Usuario({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.email,
    this.isActive = true,
    this.isSuperuser = false,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: json['id'],
        username: json['username'] ?? '',
        firstName: json['first_name'],
        lastName: json['last_name'],
        email: json['email'],
        isActive: json['is_active'] ?? true,
        isSuperuser: json['is_superuser'] ?? false,
      );

  String get nombreCompleto {
    final parts = [firstName ?? '', lastName ?? ''].where((s) => s.isNotEmpty);
    return parts.join(' ').trim().isEmpty ? username : parts.join(' ').trim();
  }
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
  final String? usuario;
  final String fechaHora;
  final String? descripcion;

  Bitacora({
    required this.id,
    required this.accion,
    this.modulo,
    this.usuario,
    required this.fechaHora,
    this.descripcion,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) => Bitacora(
        id: json['id'],
        accion: json['accion'] ?? json['action'] ?? '',
        modulo: json['modulo'] ?? json['module'],
        usuario: json['usuario'] ?? json['user'],
        fechaHora: json['fecha_hora'] ?? json['created_at'] ?? '',
        descripcion: json['descripcion'] ?? json['description'],
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

  Proveedor({
    required this.id,
    required this.nombre,
    this.ruc,
    this.telefono,
    this.email,
    this.direccion,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) => Proveedor(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        ruc: json['ruc'],
        telefono: json['telefono'],
        email: json['email'],
        direccion: json['direccion'],
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (ruc != null) 'ruc': ruc,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (direccion != null) 'direccion': direccion,
      };
}

class DetalleCompra {
  final int id;
  final Producto? producto;
  final Variante? variante;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleCompra({
    required this.id,
    this.producto,
    this.variante,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleCompra.fromJson(Map<String, dynamic> json) => DetalleCompra(
        id: json['id'],
        producto: json['producto'] is Map ? Producto.fromJson(json['producto']) : null,
        variante: json['variante'] is Map ? Variante.fromJson(json['variante']) : null,
        cantidad: json['cantidad'] ?? 1,
        precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0.0,
        subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      );
}

class Compra {
  final int id;
  final String? numeroCompra;
  final Proveedor? proveedor;
  final String fecha;
  final double total;
  final String estado;
  final List<DetalleCompra> detalles;

  Compra({
    required this.id,
    this.numeroCompra,
    this.proveedor,
    required this.fecha,
    required this.total,
    required this.estado,
    this.detalles = const [],
  });

  factory Compra.fromJson(Map<String, dynamic> json) => Compra(
        id: json['id'],
        numeroCompra: json['numero_compra']?.toString(),
        proveedor: json['proveedor'] is Map ? Proveedor.fromJson(json['proveedor']) : null,
        fecha: json['fecha'] ?? json['created_at'] ?? '',
        total: double.tryParse(json['total'].toString()) ?? 0.0,
        estado: json['estado'] ?? 'pendiente',
        detalles: (json['detalles'] as List<dynamic>? ?? [])
            .map((d) => DetalleCompra.fromJson(d))
            .toList(),
      );
}

// ---- VENTAS ----

class DetalleVenta {
  final int id;
  final Producto? producto;
  final Variante? variante;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  DetalleVenta({
    required this.id,
    this.producto,
    this.variante,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory DetalleVenta.fromJson(Map<String, dynamic> json) => DetalleVenta(
        id: json['id'],
        producto: json['producto'] is Map ? Producto.fromJson(json['producto']) : null,
        variante: json['variante'] is Map ? Variante.fromJson(json['variante']) : null,
        cantidad: json['cantidad'] ?? 1,
        precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0.0,
        subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      );
}

class Venta {
  final int id;
  final String? numeroVenta;
  final String fecha;
  final double total;
  final String estado;
  final String? metodoPago;
  final String? tipoComprobante;
  final List<DetalleVenta> detalles;

  Venta({
    required this.id,
    this.numeroVenta,
    required this.fecha,
    required this.total,
    required this.estado,
    this.metodoPago,
    this.tipoComprobante,
    this.detalles = const [],
  });

  factory Venta.fromJson(Map<String, dynamic> json) => Venta(
        id: json['id'],
        numeroVenta: json['numero_venta']?.toString(),
        fecha: json['fecha'] ?? json['created_at'] ?? '',
        total: double.tryParse(json['total'].toString()) ?? 0.0,
        estado: json['estado'] ?? 'completada',
        metodoPago: json['metodo_pago'],
        tipoComprobante: json['tipo_comprobante'],
        detalles: (json['detalles'] as List<dynamic>? ?? [])
            .map((d) => DetalleVenta.fromJson(d))
            .toList(),
      );
}

// ---- EMPRESA ----

class ConfiguracionEmpresa {
  final int? id;
  final String nombre;
  final String? ruc;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String moneda;
  final double igvPorcentaje;
  final String? logoUrl;

  ConfiguracionEmpresa({
    this.id,
    required this.nombre,
    this.ruc,
    this.telefono,
    this.email,
    this.direccion,
    this.moneda = 'PEN',
    this.igvPorcentaje = 18.0,
    this.logoUrl,
  });

  factory ConfiguracionEmpresa.fromJson(Map<String, dynamic> json) => ConfiguracionEmpresa(
        id: json['id'],
        nombre: json['nombre'] ?? '',
        ruc: json['ruc'],
        telefono: json['telefono'],
        email: json['email'],
        direccion: json['direccion'],
        moneda: json['moneda'] ?? 'PEN',
        igvPorcentaje: double.tryParse(json['igv_porcentaje'].toString()) ?? 18.0,
        logoUrl: json['logo_url'] ?? json['logo'],
      );

  Map<String, dynamic> toJson() => {
        'nombre': nombre,
        if (ruc != null) 'ruc': ruc,
        if (telefono != null) 'telefono': telefono,
        if (email != null) 'email': email,
        if (direccion != null) 'direccion': direccion,
        'moneda': moneda,
        'igv_porcentaje': igvPorcentaje,
      };
}

// ---- PAGINACION ----
class PaginatedResponse<T> {
  final int count;
  final String? next;
  final String? previous;
  final List<T> results;

  PaginatedResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });
}
