import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';

// ============================================================
// USUARIOS SCREEN
// ============================================================
class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({Key? key}) : super(key: key);
  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SeguridadProvider>().cargarUsuarios());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  void _mostrarFormulario({Usuario? usuario}) {
    final usernameCtrl = TextEditingController(text: usuario?.username ?? '');
    final nombreCtrl = TextEditingController(text: usuario?.nombre ?? '');
    final apellidoCtrl = TextEditingController(text: usuario?.apellido ?? '');
    final emailCtrl = TextEditingController(text: usuario?.email ?? '');
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isActive = usuario?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(usuario == null ? 'Nuevo Usuario' : 'Editar Usuario'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Requerido' : null),
                const SizedBox(height: 10),
                TextFormField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(controller: apellidoCtrl, decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextFormField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 10),
                TextFormField(controller: passCtrl, decoration: InputDecoration(labelText: usuario == null ? 'Contraseña *' : 'Nueva contraseña (opcional)', border: const OutlineInputBorder()), obscureText: true,
                  validator: usuario == null ? (v) => v == null || v.isEmpty ? 'Requerido' : null : null),
                const SizedBox(height: 10),
                SwitchListTile(title: const Text('Activo'), value: isActive, onChanged: (v) => setDialogState(() => isActive = v), dense: true),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final provider = context.read<SeguridadProvider>();
                final data = {
                  'username': usernameCtrl.text.trim(),
                  if (nombreCtrl.text.isNotEmpty) 'nombre': nombreCtrl.text.trim(),
                  if (apellidoCtrl.text.isNotEmpty) 'apellido': apellidoCtrl.text.trim(),
                  if (emailCtrl.text.isNotEmpty) 'email': emailCtrl.text.trim(),
                  if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                  'is_active': isActive,
                };
                bool ok;
                if (usuario == null) { ok = await provider.crearUsuario(data); }
                else { ok = await provider.actualizarUsuario(usuario.id, data); }
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? 'Usuario guardado' : 'Error al guardar'), backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor));
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
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
              decoration: InputDecoration(hintText: 'Buscar usuarios...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (val) => context.read<SeguridadProvider>().cargarUsuarios(search: val),
            ),
          ),
          Expanded(
            child: Consumer<SeguridadProvider>(
              builder: (_, p, __) {
                if (p.isLoading) return const Center(child: CircularProgressIndicator());
                if (p.usuarios.isEmpty) return const Center(child: Text('No hay usuarios', style: AppTheme.bodyMedium));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: p.usuarios.length,
                  itemBuilder: (_, i) {
                    final u = p.usuarios[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: u.isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          child: Text(u.nombreCompleto.isNotEmpty ? u.nombreCompleto[0].toUpperCase() : '?',
                              style: TextStyle(color: u.isActive ? AppTheme.primaryColor : Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(u.nombreCompleto, style: AppTheme.titleSmall),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('@${u.username}', style: AppTheme.caption),
                          if (u.email != null) Text(u.email!, style: AppTheme.caption),
                          Row(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: u.isActive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(u.isActive ? 'Activo' : 'Inactivo', style: TextStyle(fontSize: 10, color: u.isActive ? AppTheme.successColor : AppTheme.errorColor, fontWeight: FontWeight.w600))),
                            if (u.isSuperuser) ...[const SizedBox(width: 4), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Text('Super Admin', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.w600)))],
                          ]),
                        ]),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          IconButton(icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor, size: 20), onPressed: () => _mostrarFormulario(usuario: u)),
                          IconButton(icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor, size: 20), onPressed: () async {
                            final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                              title: const Text('¿Eliminar usuario?'),
                              content: Text('¿Eliminar a "${u.nombreCompleto}"?'),
                              actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor), onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar'))],
                            ));
                            if (ok == true && context.mounted) context.read<SeguridadProvider>().eliminarUsuario(u.id);
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
      floatingActionButton: FloatingActionButton(onPressed: () => _mostrarFormulario(), child: const Icon(Icons.person_add)),
    );
  }
}
