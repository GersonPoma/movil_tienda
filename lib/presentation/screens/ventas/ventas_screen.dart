import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';
import 'crear_venta_screen.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({Key? key}) : super(key: key);
  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<VentasProvider>().cargarVentas(),
    );
  }

  String _formatFecha(String fechaStr) {
    try {
      return DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format(DateTime.parse(fechaStr).toLocal());
    } catch (_) {
      return fechaStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar ventas...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) =>
                  context.read<VentasProvider>().cargarVentas(search: val),
            ),
          ),
          Expanded(
            child: Consumer<VentasProvider>(
              builder: (_, p, __) {
                if (p.isLoading)
                  return const Center(child: CircularProgressIndicator());
                if (p.ventas.isEmpty)
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.point_of_sale_outlined,
                          size: 64,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No hay ventas registradas',
                          style: AppTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CrearVentaScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Nueva Venta'),
                        ),
                      ],
                    ),
                  );
                return RefreshIndicator(
                  onRefresh: () => p.cargarVentas(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: p.ventas.length,
                    itemBuilder: (_, i) {
                      final v = p.ventas[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.estadoBgColor(v.estado),
                            child: Icon(
                              Icons.receipt_outlined,
                              color: AppTheme.estadoColor(v.estado),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                v.numeroVenta != null
                                    ? 'Venta #${v.numeroVenta}'
                                    : 'Venta #${v.id}',
                                style: AppTheme.titleSmall,
                              ),
                              const SizedBox(width: 8),
                              _EstadoBadge(estado: v.estado),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (v.clienteNombre != null)
                                Text(
                                  'Cliente: ${v.clienteNombre}',
                                  style: AppTheme.bodyMedium,
                                ),
                              Text(
                                _formatFecha(v.fecha),
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'S/ ${v.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${v.detalles.length} items',
                                style: AppTheme.caption,
                              ),
                            ],
                          ),
                          onTap: () => _verDetalle(v),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrearVentaScreen()),
        ).then((_) => context.read<VentasProvider>().cargarVentas()),
        icon: const Icon(Icons.add),
        label: const Text('+'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _verDetalle(Venta venta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Venta #${venta.numeroVenta ?? venta.id}',
                  style: AppTheme.titleLarge,
                ),
                _EstadoBadge(estado: venta.estado),
              ],
            ),
            if (venta.clienteNombre != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Cliente: ${venta.clienteNombre}',
                  style: AppTheme.bodyMedium,
                ),
              ),
            Text(_formatFecha(venta.fecha), style: AppTheme.caption),
            const Divider(height: 20),
            if (venta.detalles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Cargando detalles...',
                    style: AppTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...venta.detalles.map(
                (det) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              det.productoNombre ?? 'Producto',
                              style: AppTheme.bodyLarge,
                            ),
                            if (det.sku != null)
                              Text(det.sku!, style: AppTheme.caption),
                          ],
                        ),
                      ),
                      Text(
                        'x${det.cantidad}  S/${det.precioUnitario.toStringAsFixed(2)}',
                        style: AppTheme.bodyMedium,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'S/${det.subtotal.toStringAsFixed(2)}',
                        style: AppTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOTAL', style: AppTheme.titleMedium),
                Text(
                  'S/ ${venta.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: AppTheme.estadoBgColor(estado),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      estado.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppTheme.estadoColor(estado),
      ),
    ),
  );
}
