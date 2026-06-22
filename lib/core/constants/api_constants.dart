class ApiConstants {
  // URL configurable - cambia según tu entorno
  static String baseUrl = 'https://pillips.campusflow.store/api'; // Servidor de producción (Tenant Pillips)

  // Auth
  static const String loginEndpoint = '/login/';
  static const String recoverRequestEndpoint = '/recuperar-password/solicitar/';
  static const String recoverVerifyEndpoint = '/recuperar-password/verificar/';
  static const String recoverChangeEndpoint = '/recuperar-password/cambiar/';

  // Inventario
  static const String productosEndpoint = '/productos/';
  static const String categoriasEndpoint = '/categorias/';
  static const String marcasEndpoint = '/marcas/';
  static const String variantesEndpoint = '/variantes/';
  static const String multimediosEndpoint = '/multimedios/';

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
  static const String reporteVistasEndpoint = '/reporte/vistas/';
  static const String reporteQbeEndpoint = '/reporte/qbe/';
  static const String reporteNlpEndpoint = '/reporte/nlp/';
}
