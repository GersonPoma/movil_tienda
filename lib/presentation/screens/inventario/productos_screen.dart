import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';
import 'producto_detalle_screen.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({Key? key}) : super(key: key);
  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final _searchCtrl = TextEditingController();
  int? _categoriaFiltro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>()
        ..cargarProductos()
        ..cargarCategorias();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) => context.read<InventarioProvider>().cargarProductos(search: val, categoriaId: _categoriaFiltro),
                  ),
                ),
              ],
            ),
          ),
          // Filtro de categorías
          Consumer<InventarioProvider>(
            builder: (_, p, __) {
              if (p.categorias.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Todos'),
                        selected: _categoriaFiltro == null,
                        onSelected: (_) {
                          setState(() => _categoriaFiltro = null);
                          p.cargarProductos(search: _searchCtrl.text);
                        },
                      ),
                    ),
                    ...p.categorias.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat.nombre),
                        selected: _categoriaFiltro == cat.id,
                        onSelected: (_) {
                          setState(() => _categoriaFiltro = cat.id);
                          p.cargarProductos(search: _searchCtrl.text, categoriaId: cat.id);
                        },
                      ),
                    )),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          // Tabla de productos
          Expanded(
            child: Consumer<InventarioProvider>(
              builder: (_, p, __) {
                if (p.isLoading) return const Center(child: CircularProgressIndicator());
                if (p.productos.isEmpty) return const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary), SizedBox(height: 12), Text('No hay productos', style: AppTheme.bodyMedium)],
                ));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: p.productos.length + (p.hasNextPage ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == p.productos.length) {
                      return Center(child: TextButton(
                        onPressed: () => p.cargarProductos(search: _searchCtrl.text, categoriaId: _categoriaFiltro, page: 2),
                        child: const Text('Cargar más...'),
                      ));
                    }
                    final prod = p.productos[i];
                    return _ProductoCard(producto: prod);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormCrear(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormCrear(BuildContext context) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final provider = context.read<InventarioProvider>();
    int? catId, marcaId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 20),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Nuevo Producto', style: AppTheme.titleLarge),
                const SizedBox(height: 16),
                TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 12),
                TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()), maxLines: 2),
                const SizedBox(height: 12),
                // Categoría
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Categoría', border: OutlineInputBorder()),
                  items: provider.categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                  onChanged: (v) => catId = v,
                ),
                const SizedBox(height: 12),
                // Marca
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
                  items: provider.marcas.map((m) => DropdownMenuItem(value: m.id, child: Text(m.nombre))).toList(),
                  onChanged: (v) => marcaId = v,
                ),
                const SizedBox(height: 20),
                Row(children: [
                  Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar'))),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await provider.crearProducto({
                        'nombre': nombreCtrl.text.trim(),
                        'descripcion': descCtrl.text.trim(),
                        if (catId != null) 'categoria': catId,
                        if (marcaId != null) 'marca': marcaId,
                      });
                      if (mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(ok ? '¡Producto creado!' : 'Error al crear'),
                          backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
                        ));
                      }
                    },
                    child: const Text('Guardar'),
                  )),
                ]),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Producto producto;
  const _ProductoCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: producto.imagenUrl != null
              ? CachedNetworkImage(imageUrl: producto.imagenUrl!, width: 52, height: 52, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(width: 52, height: 52, color: AppTheme.bgColor, child: const Icon(Icons.image_not_supported, color: AppTheme.textSecondary)))
              : Container(width: 52, height: 52, color: AppTheme.bgColor,
                  child: const Icon(Icons.inventory_2_outlined, color: AppTheme.textSecondary)),
        ),
        title: Text(producto.nombre, style: AppTheme.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (producto.categoriaNombre != null) Text(producto.categoriaNombre!, style: AppTheme.bodyMedium),
          if (producto.marcaNombre != null) Text(producto.marcaNombre!, style: AppTheme.caption),
          Text('${producto.variantes.length} variante(s)', style: AppTheme.caption),
        ]),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, color: AppTheme.accentColor, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoDetalleScreen(productoId: producto.id))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20),
            onPressed: () async {
              final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                title: const Text('¿Eliminar producto?'),
                content: Text('Se eliminará "${producto.nombre}"'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                  ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor), onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
                ],
              ));
              if (ok == true && context.mounted) {
                context.read<InventarioProvider>().eliminarProducto(producto.id);
              }
            },
          ),
        ]),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductoDetalleScreen(productoId: producto.id))),
      ),
    );
  }
}
