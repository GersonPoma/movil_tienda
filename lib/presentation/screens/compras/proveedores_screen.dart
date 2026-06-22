import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({Key? key}) : super(key: key);
  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<ComprasProvider>().cargarProveedores());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _mostrarFormulario({Proveedor? proveedor}) {
    final nombreCtrl = TextEditingController(text: proveedor?.nombre ?? '');
    final rucCtrl = TextEditingController(text: proveedor?.ruc ?? '');
    final telefonoCtrl = TextEditingController(text: proveedor?.telefono ?? '');
    final emailCtrl = TextEditingController(text: proveedor?.email ?? '');
    final dirCtrl = TextEditingController(text: proveedor?.direccion ?? '');
    final contactoCtrl = TextEditingController(text: proveedor?.contacto ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
              const SizedBox(height: 10),
              TextFormField(controller: rucCtrl, decoration: const InputDecoration(labelText: 'RUC / NIT', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              TextFormField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 10),
              TextFormField(controller: dirCtrl, decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 10),
              TextFormField(controller: contactoCtrl, decoration: const InputDecoration(labelText: 'Persona de Contacto', border: OutlineInputBorder())),
            ]),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final data = {
                'nombre': nombreCtrl.text.trim(),
                if (rucCtrl.text.isNotEmpty) 'ruc': rucCtrl.text.trim(),
                if (telefonoCtrl.text.isNotEmpty) 'telefono': telefonoCtrl.text.trim(),
                if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
                if (dirCtrl.text.isNotEmpty) 'direccion': dirCtrl.text.trim(),
                if (contactoCtrl.text.isNotEmpty) 'contacto': contactoCtrl.text.trim(),
              };
              final provider = context.read<ComprasProvider>();
              bool ok;
              if (proveedor == null) { ok = await provider.crearProveedor(data); }
              else { ok = await provider.actualizarProveedor(proveedor.id, data); }
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? '¡Proveedor guardado!' : 'Error al guardar'), backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor));
              }
            },
            child: const Text('Guardar'),
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
            child: TextField(controller: _searchCtrl, decoration: InputDecoration(hintText: 'Buscar proveedores...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (val) => context.read<ComprasProvider>().cargarProveedores(search: val)),
          ),
          Expanded(
            child: Consumer<ComprasProvider>(
              builder: (_, p, __) {
                if (p.isLoading) return const Center(child: CircularProgressIndicator());
                if (p.proveedores.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: AppTheme.textSecondary), SizedBox(height: 12), Text('No hay proveedores', style: AppTheme.bodyMedium),
                ]));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: p.proveedores.length,
                  itemBuilder: (_, i) {
                    final prov = p.proveedores[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: AppTheme.accentColor.withOpacity(0.1), child: const Icon(Icons.local_shipping_outlined, color: AppTheme.accentColor)),
                        title: Text(prov.nombre, style: AppTheme.titleSmall),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (prov.ruc != null) Text('RUC: ${prov.ruc}', style: AppTheme.caption),
                          if (prov.telefono != null) Text('Tel: ${prov.telefono}', style: AppTheme.caption),
                          if (prov.email != null) Text(prov.email!, style: AppTheme.caption),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20), onPressed: () => _mostrarFormulario(proveedor: prov)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20), onPressed: () async {
                            final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                              title: const Text('¿Eliminar proveedor?'),
                              content: Text('¿Eliminar "${prov.nombre}"?'),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor), onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar'))],
                            ));
                            if (ok == true && context.mounted) context.read<ComprasProvider>().eliminarProveedor(prov.id);
                          }),
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
