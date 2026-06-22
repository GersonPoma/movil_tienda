import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';
import '../checkout/payment_screen.dart';

class CrearVentaScreen extends StatefulWidget {
  const CrearVentaScreen({Key? key}) : super(key: key);
  @override
  State<CrearVentaScreen> createState() => _CrearVentaScreenState();
}

class _CrearVentaScreenState extends State<CrearVentaScreen> {
  final _clienteCtrl = TextEditingController();
  final _productoCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  bool _isLoadingProductos = false;

  // Cantidades por varianteId
  final Map<int, int> _cantidades = {};

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    // Resetear carrito al abrir pantalla nueva
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<VentasProvider>();
      p.limpiarCarrito();
      p.limpiarCliente();
    });
  }

  Future<void> _cargarProductos() async {
    setState(() => _isLoadingProductos = true);
    await context.read<InventarioProvider>().cargarProductos();
    if (mounted) {
      setState(() {
        _productos = context.read<InventarioProvider>().productos;
        _productosFiltrados = _productos;
        _isLoadingProductos = false;
      });
    }
  }

  void _filtrarProductos(String term) {
    setState(() {
      _productosFiltrados = term.isEmpty
          ? _productos
          : _productos.where((p) => p.nombre.toLowerCase().contains(term.toLowerCase())).toList();
    });
  }

  void _agregarAlCarrito(Variante variante, Producto producto) {
    final cantidad = _cantidades[variante.id] ?? 1;
    if (cantidad <= 0) return;
    context.read<VentasProvider>().agregarAlCarrito(variante, producto, cantidad);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${producto.nombre} (${variante.descripcionCorta}) agregado al carrito'),
      duration: const Duration(seconds: 1),
      backgroundColor: AppTheme.successColor,
    ));
  }

  Future<void> _guardarPendiente() async {
    final p = context.read<VentasProvider>();
    if (!p.carritoValido) { _mostrarError('El carrito está vacío'); return; }
    final ok = await p.guardarPendiente();
    if (mounted) {
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Venta guardada como pendiente'), backgroundColor: AppTheme.successColor));
        Navigator.pop(context);
      } else {
        _mostrarError(p.error ?? 'Error al guardar venta');
      }
    }
  }

  Future<void> _pagarYCompletar() async {
    final p = context.read<VentasProvider>();
    if (!p.carritoValido) { _mostrarError('El carrito está vacío'); return; }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          total: p.totalCarrito,
          isNuevaVenta: true,
        ),
      ),
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppTheme.errorColor));
  }

  @override
  void dispose() { _clienteCtrl.dispose(); _productoCtrl.dispose(); _scrollCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Venta')),
      body: Consumer<VentasProvider>(
        builder: (_, ventasProvider, __) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ---- Selector de cliente ----
                      const Text('Cliente', style: AppTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (ventasProvider.clienteSeleccionado == null) ...[
                        TextField(
                          controller: _clienteCtrl,
                          decoration: InputDecoration(
                            hintText: 'Buscar cliente por nombre o usuario...',
                            prefixIcon: const Icon(Icons.person_search),
                            filled: true, fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (val) => ventasProvider.buscarUsuarios(val),
                        ),
                        // Resultados de búsqueda de cliente
                        if (ventasProvider.isLoadingUsuarios)
                          const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator(strokeWidth: 2)))
                        else if (ventasProvider.usuariosBuscados.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppTheme.borderColor), borderRadius: BorderRadius.circular(10)),
                            child: Column(
                              children: ventasProvider.usuariosBuscados.take(5).map((u) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                                title: Text(u.nombreCompleto, style: AppTheme.bodyLarge),
                                subtitle: Text('@${u.username}', style: AppTheme.caption),
                                onTap: () {
                                  ventasProvider.seleccionarCliente(u);
                                  _clienteCtrl.clear();
                                },
                              )).toList(),
                            ),
                          ),
                      ] else
                        // Cliente seleccionado
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.06), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2))),
                          child: Row(children: [
                            const Icon(Icons.person, color: AppTheme.primaryColor),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ventasProvider.clienteSeleccionado!.nombreCompleto, style: AppTheme.titleSmall),
                              Text('@${ventasProvider.clienteSeleccionado!.username}', style: AppTheme.caption),
                            ])),
                            IconButton(icon: const Icon(Icons.close, color: AppTheme.errorColor, size: 20), onPressed: () { ventasProvider.limpiarCliente(); _clienteCtrl.clear(); }),
                          ]),
                        ),

                      const SizedBox(height: 20),

                      // ---- Búsqueda de productos ----
                      const Text('Productos', style: AppTheme.titleSmall),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _productoCtrl,
                        decoration: InputDecoration(
                          hintText: 'Buscar producto por nombre...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true, fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: _filtrarProductos,
                      ),
                      const SizedBox(height: 12),

                      // ---- Lista de productos con variantes ----
                      if (_isLoadingProductos)
                        const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                      else if (_productosFiltrados.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text('No se encontraron productos con stock', style: AppTheme.bodyMedium)),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _productosFiltrados.length,
                          itemBuilder: (_, i) {
                            final prod = _productosFiltrados[i];
                            final variantesConStock = prod.variantes.where((v) => v.cantidad > 0).toList();
                            if (variantesConStock.isEmpty) return const SizedBox.shrink();
                            return _ProductoCard(
                              producto: prod,
                              variantes: variantesConStock,
                              cantidades: _cantidades,
                              onIncrement: (varId) => setState(() => _cantidades[varId] = (_cantidades[varId] ?? 1) + 1),
                              onDecrement: (varId) {
                                if ((_cantidades[varId] ?? 1) > 1) setState(() => _cantidades[varId] = (_cantidades[varId]!) - 1);
                              },
                              onAgregar: (variante) => _agregarAlCarrito(variante, prod),
                            );
                          },
                        ),

                      const SizedBox(height: 20),

                      // ---- Carrito ----
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.borderColor)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(children: [
                                const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text('Carrito de Venta', style: AppTheme.titleMedium),
                                const Spacer(),
                                if (ventasProvider.carrito.isNotEmpty)
                                  TextButton(onPressed: () { ventasProvider.limpiarCarrito(); setState(() {}); }, child: const Text('Limpiar', style: TextStyle(color: AppTheme.errorColor))),
                              ]),
                            ),
                            if (ventasProvider.carrito.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(child: Column(children: [
                                  Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textSecondary),
                                  SizedBox(height: 8), Text('Agrega productos al carrito', style: AppTheme.bodyMedium),
                                ])),
                              )
                            else ...[
                              const Divider(height: 1),
                              ...ventasProvider.carrito.asMap().entries.map((entry) {
                                final i = entry.key;
                                final item = entry.value;
                                return Column(children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(children: [
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Text(item.productoNombre, style: AppTheme.bodyLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(item.sku, style: AppTheme.caption),
                                      ])),
                                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                        Text('x${item.cantidad}  S/${item.precioUnitario.toStringAsFixed(2)}', style: AppTheme.bodyMedium),
                                        Text('S/ ${item.subtotal.toStringAsFixed(2)}', style: AppTheme.titleSmall),
                                      ]),
                                      IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20), onPressed: () => ventasProvider.quitarDelCarrito(i)),
                                    ]),
                                  ),
                                  if (i < ventasProvider.carrito.length - 1) const Divider(height: 1),
                                ]);
                              }),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                  const Text('TOTAL:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                  Text('S/ ${ventasProvider.totalCarrito.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                ]),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Espacio para los botones de abajo
                    ],
                  ),
                ),
              ),

              // ---- Botones de acción fijos abajo ----
              if (ventasProvider.carrito.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2))],
                  ),
                  child: ventasProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(children: [
                          // Botón "Guardar Pendiente"
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _guardarPendiente,
                              icon: const Icon(Icons.save_outlined),
                              label: const Text('Guardar Pendiente'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.warningColor,
                                side: const BorderSide(color: AppTheme.warningColor),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón "Pagar y Completar"
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pagarYCompletar,
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Pagar y Completar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ]),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---- Widget Producto Card con variantes ----
class _ProductoCard extends StatelessWidget {
  final Producto producto;
  final List<Variante> variantes;
  final Map<int, int> cantidades;
  final Function(int varId) onIncrement;
  final Function(int varId) onDecrement;
  final Function(Variante v) onAgregar;

  const _ProductoCard({
    required this.producto,
    required this.variantes,
    required this.cantidades,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Encabezado del producto
          Row(children: [
            if (producto.imagenUrl != null)
              ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: producto.imagenUrl!, width: 48, height: 48, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(width: 48, height: 48, color: AppTheme.bgColor, child: const Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary))))
            else
              Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(producto.nombre, style: AppTheme.titleSmall),
              if (producto.categoriaNombre != null || producto.marcaNombre != null)
                Text([if (producto.categoriaNombre != null) producto.categoriaNombre!, if (producto.marcaNombre != null) producto.marcaNombre!].join(' · '), style: AppTheme.caption),
            ])),
          ]),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 8),
          // Variantes
          ...variantes.map((v) => _VarianteRow(
            variante: v,
            cantidad: cantidades[v.id] ?? 1,
            onIncrement: () => onIncrement(v.id),
            onDecrement: () => onDecrement(v.id),
            onAgregar: () => onAgregar(v),
          )),
        ]),
      ),
    );
  }
}

class _VarianteRow extends StatelessWidget {
  final Variante variante;
  final int cantidad;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAgregar;

  const _VarianteRow({required this.variante, required this.cantidad, required this.onIncrement, required this.onDecrement, required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    final stockOk = variante.cantidad > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Detalle de la variante
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variante.descripcionCorta,
                  style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: variante.cantidad == 0
                            ? AppTheme.errorColor.withOpacity(0.1)
                            : variante.cantidad <= 5
                                ? AppTheme.warningColor.withOpacity(0.1)
                                : AppTheme.successColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        variante.cantidad == 0 ? 'Agotado' : 'Stock: ${variante.cantidad}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: variante.cantidad == 0
                              ? AppTheme.errorColor
                              : variante.cantidad <= 5
                                  ? AppTheme.warningColor
                                  : AppTheme.successColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'S/${variante.precio.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Botones de acción y Stepper
          if (stockOk)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StepperBtn(icon: Icons.remove, onTap: onDecrement, enabled: cantidad > 1),
                Container(
                  width: 28,
                  alignment: Alignment.center,
                  child: Text('$cantidad', style: AppTheme.bodyLarge),
                ),
                _StepperBtn(icon: Icons.add, onTap: onIncrement, enabled: cantidad < variante.cantidad),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryColor, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onAgregar,
                ),
              ],
            )
          else
            const Text(
              'Sin stock',
              style: TextStyle(color: AppTheme.errorColor, fontSize: 12, fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }
}

class _StepperBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool enabled;
  const _StepperBtn({required this.icon, required this.onTap, required this.enabled});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 26, height: 26,
      decoration: BoxDecoration(
        color: enabled ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: enabled ? AppTheme.primaryColor : Colors.grey),
    ),
  );
}
