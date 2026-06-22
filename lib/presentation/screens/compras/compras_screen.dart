import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({Key? key}) : super(key: key);
  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ComprasProvider>().cargarCompras());
  }

  String _formatFecha(String fechaStr) {
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaStr).toLocal()); } catch (_) { return fechaStr; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Buscar compras...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (val) => context.read<ComprasProvider>().cargarCompras(search: val)),
          ),
          Expanded(
            child: Consumer<ComprasProvider>(
              builder: (_, p, __) {
                if (p.isLoading) return const Center(child: CircularProgressIndicator());
                if (p.compras.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary), SizedBox(height: 12), Text('No hay compras registradas', style: AppTheme.bodyMedium),
                ]));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: p.compras.length,
                  itemBuilder: (_, i) {
                    final c = p.compras[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: const Icon(Icons.receipt_long_outlined, color: AppTheme.primaryColor)),
                        title: Text(c.numeroCompra != null ? 'Compra #${c.numeroCompra}' : 'Compra #${c.id}', style: AppTheme.titleSmall),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (c.proveedorNombre != null) Text('Proveedor: ${c.proveedorNombre}', style: AppTheme.bodyMedium),
                          Text('Fecha: ${_formatFecha(c.fecha)}', style: AppTheme.caption),
                          Text('Total: S/ ${c.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryColor, fontSize: 13)),
                        ]),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.estadoBgColor(c.estado),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(c.estado.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.estadoColor(c.estado))),
                        ),
                        onTap: () => _verDetalle(c),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _verDetalle(Compra compra) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (_, scroll) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Compra #${compra.numeroCompra ?? compra.id}', style: AppTheme.titleLarge),
              if (compra.proveedorNombre != null) Text('Proveedor: ${compra.proveedorNombre}', style: AppTheme.bodyMedium),
              Text('Fecha: ${_formatFecha(compra.fecha)}', style: AppTheme.bodyMedium),
              const Divider(height: 20),
              if (compra.detalles.isEmpty) const Text('Sin detalles cargados', style: AppTheme.bodyMedium)
              else Expanded(
                child: ListView.builder(
                  controller: scroll,
                  itemCount: compra.detalles.length,
                  itemBuilder: (_, i) {
                    final det = compra.detalles[i];
                    return ListTile(
                      dense: true,
                      title: Text(det.productoNombre ?? det.sku ?? 'Producto', style: AppTheme.bodyLarge),
                      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('x${det.cantidad}', style: AppTheme.caption),
                        Text('S/ ${det.subtotal.toStringAsFixed(2)}', style: AppTheme.titleSmall),
                      ]),
                    );
                  },
                ),
              ),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('TOTAL', style: AppTheme.titleMedium),
                Text('S/ ${compra.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
