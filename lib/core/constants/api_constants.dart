class ApiConstants {
  // URL configurable - cambia según tu entorno
  static String baseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator -> localhost
  // Para dispositivo físico usar: 'http://192.168.X.X:8000/api'

  // Auth
  static const String loginEndpoint = '/login/';
  static const String recoverRequestEndpoint = '/recuperar-password/solicitar/';
  static const String recoverVerifyEndpoint = '/recuperar-password/verificar/';
  static const String recoverChangeEndpoint = '/recuperar-password/cambiar/';

  // Inventario
  static const String productosEndpoint = '/productos/';
  static const String categoriasEndpoint = '/categorias/';
  static const String marcasEndpoint = '/marcas/';

  // Seguridad
  static const String usuariosEndpoint = '/usuarios/';
  static const String rolesEndpoint = '/roles/';
  static const String bitacoraEndpoint = '/bitacora/';

  // Compras
  static const String proveedoresEndpoint = '/proveedores/';
  static const String comprasEndpoint = '/compras/';

  // Ventas
  static const String ventasEndpoint = '/ventas/';
  static const String carritoEndpoint = '/carrito/';
  static const String cotizacionEndpoint = '/carrito/descargar_pdf/';

  // Empresa
  static const String empresaEndpoint = '/empresa/';

  // Reportes
  static const String reportesEndpoint = '/reportes/';
}
