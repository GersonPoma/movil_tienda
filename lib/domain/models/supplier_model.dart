class Supplier {
  final int? id;
  final String nombre;
  final String? email;
  final String? telefono;
  final String? direccion;
  final bool activo;
  
  Supplier({
    this.id,
    required this.nombre,
    this.email,
    this.telefono,
    this.direccion,
    this.activo = true,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      email: json['email'],
      telefono: json['telefono'],
      direccion: json['direccion'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'direccion': direccion,
      'activo': activo,
    };
  }
}
