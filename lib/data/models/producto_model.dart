class Categoria {
  final int id;
  final String nombre;

  Categoria({required this.id, required this.nombre});

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}

class Producto {
  final int id;
  final String nombre;
  final String descripcion;
  final String categoriaNombre;
  final String? imagenPrincipal;
  final double precioMinimo;
  final int? variantePrincipalId;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoriaNombre,
    this.imagenPrincipal,
    required this.precioMinimo,
    this.variantePrincipalId,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'] ?? '',
      categoriaNombre: json['categoria_nombre'] ?? '',
      imagenPrincipal: json['imagen_principal'],
      precioMinimo: (json['precio_minimo'] ?? 0.0).toDouble(),
      variantePrincipalId: json['variante_principal_id'],
    );
  }
}
