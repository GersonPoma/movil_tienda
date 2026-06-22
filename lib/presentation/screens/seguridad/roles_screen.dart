import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({Key? key}) : super(key: key);
  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SeguridadProvider>().cargarRoles());
  }

  void _crearRol() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo Rol'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Rol *', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final ok = await context.read<SeguridadProvider>().crearRol(nameCtrl.text.trim());
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? '¡Rol creado!' : 'Error al crear rol'),
                backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
              ));
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Consumer<SeguridadProvider>(
        builder: (_, p, __) {
          if (p.isLoading) return const Center(child: CircularProgressIndicator());
          if (p.roles.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock_outline, size: 64, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            const Text('No hay roles', style: AppTheme.bodyMedium),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _crearRol, icon: const Icon(Icons.add), label: const Text('Crear Rol')),
          ]));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: p.roles.length,
            itemBuilder: (_, i) {
              final rol = p.roles[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: AppTheme.accentColor.withOpacity(0.1), child: const Icon(Icons.lock_open_outlined, color: AppTheme.accentColor)),
                  title: Text(rol.name, style: AppTheme.titleSmall),
                  subtitle: Text('${(rol.permissions as List).length} permisos', style: AppTheme.bodyMedium),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                    onPressed: () async {
                      final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                        title: const Text('¿Eliminar Rol?'),
                        content: Text('¿Eliminar el rol "${rol.name}"?'),
                        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor), onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar'))],
                      ));
                      if (ok == true && context.mounted) context.read<SeguridadProvider>().eliminarRol(rol.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _crearRol, child: const Icon(Icons.add)),
    );
  }
}
