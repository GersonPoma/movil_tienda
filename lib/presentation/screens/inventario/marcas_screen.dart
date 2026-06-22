import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';

class MarcasScreen extends StatefulWidget {
  const MarcasScreen({Key? key}) : super(key: key);
  @override
  State<MarcasScreen> createState() => _MarcasScreenState();
}

class _MarcasScreenState extends State<MarcasScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<InventarioProvider>().cargarMarcas());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _mostrarFormulario({Marca? marca}) {
    final nombreCtrl = TextEditingController(text: marca?.nombre ?? '');
    final descCtrl = TextEditingController(text: marca?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(marca == null ? 'Nueva Marca' : 'Editar Marca'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()),
                validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final provider = context.read<InventarioProvider>();
              bool ok;
              final data = {'nombre': nombreCtrl.text.trim(), 'descripcion': descCtrl.text.trim()};
              if (marca == null) { ok = await provider.crearMarca(data); }
              else { ok = await provider.actualizarMarca(marca.id, data); }
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '¡Marca guardada!' : 'Error al guardar'),
                  backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
                ));
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(Marca m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Marca'),
        content: Text('¿Eliminar "${m.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<InventarioProvider>().eliminarMarca(m.id);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? 'Marca eliminada' : 'Error al eliminar'),
                backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
              ));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
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
                hintText: 'Buscar marcas...',
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => context.read<InventarioProvider>().cargarMarcas(search: val),
            ),
          ),
          Expanded(
            child: Consumer<InventarioProvider>(
              builder: (_, p, __) {
                if (p.isLoading) return const Center(child: CircularProgressIndicator());
                if (p.marcas.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.branding_watermark_outlined, size: 64, color: AppTheme.textSecondary),
                  SizedBox(height: 12), Text('No hay marcas', style: AppTheme.bodyMedium),
                ]));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: p.marcas.length,
                  itemBuilder: (_, i) {
                    final m = p.marcas[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: m.logoUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: m.logoUrl!, width: 40, height: 40, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.branding_watermark_outlined, color: AppTheme.primaryColor)))
                            : CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.1), child: const Icon(Icons.branding_watermark_outlined, color: AppTheme.primaryColor)),
                        title: Text(m.nombre, style: AppTheme.titleSmall),
                        subtitle: m.descripcion != null ? Text(m.descripcion!, style: AppTheme.bodyMedium) : null,
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor), onPressed: () => _mostrarFormulario(marca: m)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor), onPressed: () => _confirmarEliminar(m)),
                        ]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () => _mostrarFormulario(), child: const Icon(Icons.add)),
    );
  }
}
