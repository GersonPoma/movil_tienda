import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/providers.dart';
import '../auth/login_screen.dart';
// Inventario
import '../inventario/categorias_screen.dart';
import '../inventario/marcas_screen.dart';
import '../inventario/productos_screen.dart';
import '../products/catalog_screen.dart';
// Seguridad
import '../seguridad/usuarios_screen.dart';
import '../seguridad/roles_screen.dart';
import '../seguridad/bitacora_screen.dart';
// Compras
import '../compras/proveedores_screen.dart';
import '../compras/compras_screen.dart';
// Ventas
import '../ventas/ventas_screen.dart';
import '../ventas/crear_venta_screen.dart';
// Empresa
import '../empresa/empresa_screen.dart';
// Reportes
import '../reportes/reportes_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Widget _currentScreen;
  String _currentTitle = 'Dashboard';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentScreen = _DashboardContent(onNavigate: _navigateTo);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().cargarProductos();
      context.read<InventarioProvider>().cargarCategorias();
      context.read<VentasProvider>().cargarVentas();
    });
  }

  void _navigateTo(Widget screen, String title) {
    setState(() { _currentScreen = screen; _currentTitle = title; });
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop(); // cerrar drawer safely
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(_currentTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          // Botón de nueva venta rápida
          IconButton(
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            tooltip: 'Nueva Venta',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearVentaScreen())),
          ),
          // Avatar usuario
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {}, // perfil futuro
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white24,
                child: Text(
                  (usuario?.nombreCompleto.isNotEmpty == true ? usuario!.nombreCompleto[0] : 'U').toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: _currentScreen,
      floatingActionButton: _currentTitle == 'Ventas'
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CrearVentaScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Venta'),
              backgroundColor: AppTheme.primaryColor,
            )
          : null,
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider auth) {
    final usuario = auth.usuario;
    return Drawer(
      child: Column(
        children: [
          // Header del drawer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryDark, AppTheme.primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: Text(
                    (usuario?.nombreCompleto.isNotEmpty == true ? usuario!.nombreCompleto[0] : 'U').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Text(usuario?.nombreCompleto ?? 'Usuario',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                Text(usuario?.username ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (usuario?.isSuperuser == true)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(10)),
                    child: const Text('Super Admin', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
              ],
            ),
          ),
          // Opciones del menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildNavItem(Icons.dashboard_outlined, 'Dashboard', () => _navigateTo(_DashboardContent(onNavigate: _navigateTo), 'Dashboard')),

                // ---- SEGURIDAD ----
                if (auth.tienePermiso('seguridad.view_usuario') || auth.tienePermiso('auth.view_group') || usuario?.isSuperuser == true) ...[
                  _buildSectionHeader('Seguridad'),
                  if (auth.tienePermiso('seguridad.view_usuario') || usuario?.isSuperuser == true)
                    _buildNavItem(Icons.people_outline, 'Usuarios', () => _navigateTo(const UsuariosScreen(), 'Usuarios')),
                  if (auth.tienePermiso('auth.view_group') || usuario?.isSuperuser == true)
                    _buildNavItem(Icons.lock_outline, 'Roles', () => _navigateTo(const RolesScreen(), 'Roles')),
                  if (auth.tienePermiso('seguridad.view_bitacora') || usuario?.isSuperuser == true)
                    _buildNavItem(Icons.history, 'Bitácora', () => _navigateTo(const BitacoraScreen(), 'Bitácora')),
                ],

                // ---- INVENTARIO ----
                _buildSectionHeader('Inventario'),
                _buildNavItem(Icons.storefront_outlined, 'Catálogo', () => _navigateTo(const CatalogScreen(), 'Catálogo')),
                if (auth.tienePermiso('inventario.view_categoria') || usuario?.isSuperuser == true)
                  _buildNavItem(Icons.label_outline, 'Categorías', () => _navigateTo(const CategoriasScreen(), 'Categorías')),
                if (auth.tienePermiso('inventario.view_marca') || usuario?.isSuperuser == true)
                  _buildNavItem(Icons.branding_watermark_outlined, 'Marcas', () => _navigateTo(const MarcasScreen(), 'Marcas')),
                if (auth.tienePermiso('inventario.view_producto') || usuario?.isSuperuser == true)
                  _buildNavItem(Icons.inventory_2_outlined, 'Productos', () => _navigateTo(const ProductosScreen(), 'Productos')),

                // ---- COMPRAS ----
                if (auth.tienePermiso('compra.view_proveedor') || auth.tienePermiso('compra.view_compra') || usuario?.isSuperuser == true) ...[
                  _buildSectionHeader('Compras'),
                  if (auth.tienePermiso('compra.view_proveedor') || usuario?.isSuperuser == true)
                    _buildNavItem(Icons.local_shipping_outlined, 'Proveedores', () => _navigateTo(const ProveedoresScreen(), 'Proveedores')),
                  if (auth.tienePermiso('compra.view_compra') || usuario?.isSuperuser == true)
                    _buildNavItem(Icons.receipt_long_outlined, 'Compras', () => _navigateTo(const ComprasScreen(), 'Compras')),
                ],

                // ---- VENTAS ----
                if (auth.tienePermiso('venta.view_venta') || usuario?.isSuperuser == true) ...[
                  _buildSectionHeader('Ventas'),
                  _buildNavItem(Icons.point_of_sale_outlined, 'Ventas', () => _navigateTo(const VentasScreen(), 'Ventas')),
                ],

                // ---- REPORTES ----
                _buildSectionHeader('Reportes'),
                _buildNavItem(Icons.bar_chart_outlined, 'Reportes', () => _navigateTo(const ReportesScreen(), 'Reportes')),

                // ---- CONFIGURACIÓN ----
                _buildSectionHeader('Configuración'),
                _buildNavItem(Icons.business_outlined, 'Mi Empresa', () => _navigateTo(const EmpresaScreen(), 'Mi Empresa')),

                const Divider(height: 20),
                // Cerrar sesión
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                  onTap: () async {
                    Navigator.pop(context);
                    await auth.logout();
                    if (mounted) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
                    }
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.2)),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    final isActive = _currentTitle == label;
    return ListTile(
      leading: Icon(icon, color: isActive ? AppTheme.primaryColor : AppTheme.textSecondary, size: 22),
      title: Text(label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primaryColor : AppTheme.textPrimary,
          )),
      selected: isActive,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }
}

// ============================================================
// DASHBOARD CONTENT
// ============================================================
class _DashboardContent extends StatelessWidget {
  final Function(Widget screen, String title) onNavigate;
  const _DashboardContent({Key? key, required this.onNavigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final usuario = auth.usuario;
    final inventario = Provider.of<InventarioProvider>(context);
    final ventas = Provider.of<VentasProvider>(context);

    // Determinar nombre bonito para saludar
    String displayName = 'Usuario';
    String roleName = 'Personal autorizado';
    if (usuario != null) {
      final name = usuario.nombreCompleto.trim();
      final username = usuario.username.trim();
      final lowerName = name.toLowerCase();
      final lowerUsername = username.toLowerCase();

      if (lowerName == 'admin' || lowerUsername == 'admin') {
        displayName = 'Administrador';
      } else if (name.isNotEmpty) {
        displayName = name;
      } else {
        displayName = username;
      }

      if (usuario.isSuperuser) {
        roleName = 'Super Administrador';
      } else {
        roleName = 'Personal de Tienda';
      }
    }

    // Obtener últimas 3 ventas para la sección de actividad reciente
    final ultimasVentas = ventas.ventas.take(3).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tarjeta de Bienvenida a Tienda Pillips (Estilo Premium)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.primaryDark,
                  AppTheme.primaryColor,
                  AppTheme.accentColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Stack(
              children: [
                // Círculo decorativo translúcido para dar profundidad visual (Glassmorphism / Abstract)
                Positioned(
                  right: -50,
                  top: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'TIENDA PILLIPS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Bienvenido a la Gestión',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hola, $displayName 👋',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  roleName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.storefront,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Tarjetas de Estadísticas Reales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Resumen de Negocio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                'En tiempo real',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Productos',
                  count: inventario.productos.length.toString(),
                  subtitle: 'Total catálogo',
                  icon: Icons.inventory_2_outlined,
                  gradientColors: [Colors.blue.shade400, Colors.blue.shade700],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Categorías',
                  count: inventario.categorias.length.toString(),
                  subtitle: 'Clasificadores',
                  icon: Icons.category_outlined,
                  gradientColors: [Colors.orange.shade400, Colors.orange.shade700],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: 'Ventas',
                  count: ventas.ventas.length.toString(),
                  subtitle: 'Transacciones',
                  icon: Icons.monetization_on_outlined,
                  gradientColors: [Colors.green.shade400, Colors.green.shade700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Accesos Rápidos
          const Text(
            'Accesos Rápidos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _QuickCard(
                icon: Icons.storefront_outlined,
                label: 'Catálogo de Muebles',
                description: 'Ver y agregar productos',
                gradientColors: [const Color(0xFF2196F3), const Color(0xFF1976D2)],
                onTap: () => onNavigate(const CatalogScreen(), 'Catálogo'),
              ),
              _QuickCard(
                icon: Icons.add_shopping_cart_outlined,
                label: 'Nueva Venta',
                description: 'Registrar cobro cliente',
                gradientColors: [const Color(0xFF4CAF50), const Color(0xFF388E3C)],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrearVentaScreen()),
                ),
              ),
              _QuickCard(
                icon: Icons.inventory_2_outlined,
                label: 'Gestión Inventario',
                description: 'Administrar stock',
                gradientColors: [const Color(0xFFFF9800), const Color(0xFFF57C00)],
                onTap: () => onNavigate(const ProductosScreen(), 'Productos'),
              ),
              _QuickCard(
                icon: Icons.bar_chart_outlined,
                label: 'Reportes QBE & NLP',
                description: 'Consultas por voz y texto',
                gradientColors: [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                onTap: () => onNavigate(const ReportesScreen(), 'Reportes'),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Sección de Ventas Recientes (Funcionalidad mejorada)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ventas Recientes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => onNavigate(const VentasScreen(), 'Ventas'),
                child: const Text('Ver todas'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (ventas.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (ultimasVentas.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary, size: 36),
                  SizedBox(height: 8),
                  Text(
                    'No hay ventas registradas recientemente',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ultimasVentas.length,
              itemBuilder: (context, index) {
                final venta = ultimasVentas[index];
                final String cliente = (venta.clienteNombre != null && venta.clienteNombre!.isNotEmpty) ? venta.clienteNombre! : 'Cliente General';
                final String formatTotal = 'BOB ${venta.total.toStringAsFixed(2)}';
                final bool isCompletada = (venta.estado.toLowerCase() == 'completada' || venta.estado.toLowerCase() == 'completado');
                final String estadoLabel = isCompletada ? 'Completada' : 'Pendiente';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.borderColor),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.estadoBgColor(estadoLabel),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.monetization_on_outlined,
                        color: AppTheme.estadoColor(estadoLabel),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      cliente,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            venta.fecha.length >= 10 ? venta.fecha.substring(0, 10) : venta.fecha,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 12),
                          if (venta.numeroVenta != null && venta.numeroVenta!.isNotEmpty) ...[
                            const Icon(Icons.receipt_long_outlined, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              venta.numeroVenta!,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatTotal,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.estadoBgColor(estadoLabel),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            estadoLabel,
                            style: TextStyle(
                              fontSize: 9,
                              color: AppTheme.estadoColor(estadoLabel),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;

  const _StatCard({
    required this.title,
    required this.count,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 9,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
