import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({Key? key}) : super(key: key);
  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioProvider>().cargarCategorias();
    });
  }

  @override
  void dispose() { _searchController.dispose(); super.dispose(); }

  void _mostrarFormulario({Categoria? categoria}) {
    final nombreCtrl = TextEditingController(text: categoria?.nombre ?? '');
    final descCtrl = TextEditingController(text: categoria?.descripcion ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(categoria == null ? 'Nueva Categoría' : 'Editar Categoría'),
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
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                maxLines: 2,
              ),
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
              if (categoria == null) {
                ok = await provider.crearCategoria(nombreCtrl.text.trim(), descripcion: descCtrl.text.trim());
              } else {
                ok = await provider.actualizarCategoria(categoria.id, nombreCtrl.text.trim(), descripcion: descCtrl.text.trim());
              }
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? '¡Categoría guardada!' : 'Error al guardar'),
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

  void _confirmarEliminar(Categoria cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de eliminar "${cat.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<InventarioProvider>().eliminarCategoria(cat.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Categoría eliminada' : 'Error al eliminar'),
                  backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
                ));
              }
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
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar categorías...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                        _searchController.clear();
                        context.read<InventarioProvider>().cargarCategorias();
                      })
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) => context.read<InventarioProvider>().cargarCategorias(search: val),
            ),
          ),
          // Lista
          Expanded(
            child: Consumer<InventarioProvider>(
              builder: (_, provider, __) {
                if (provider.isLoading) return const Center(child: CircularProgressIndicator());
                if (provider.error != null) return Center(child: Text(provider.error!, style: const TextStyle(color: AppTheme.errorColor)));
                if (provider.categorias.isEmpty) return const Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.label_off_outlined, size: 64, color: AppTheme.textSecondary),
                    SizedBox(height: 12),
                    Text('No hay categorías', style: AppTheme.bodyMedium),
                  ]),
                );
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.categorias.length,
                  itemBuilder: (_, i) {
                    final cat = provider.categorias[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.label_outline, color: AppTheme.primaryColor),
                        ),
                        title: Text(cat.nombre, style: AppTheme.titleSmall),
                        subtitle: cat.descripcion != null && cat.descripcion!.isNotEmpty
                            ? Text(cat.descripcion!, style: AppTheme.bodyMedium)
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor), onPressed: () => _mostrarFormulario(categoria: cat)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor), onPressed: () => _confirmarEliminar(cat)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
