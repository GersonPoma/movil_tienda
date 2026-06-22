import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';

class BitacoraScreen extends StatefulWidget {
  const BitacoraScreen({Key? key}) : super(key: key);
  @override
  State<BitacoraScreen> createState() => _BitacoraScreenState();
}

class _BitacoraScreenState extends State<BitacoraScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SeguridadProvider>().cargarBitacora());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  String _formatFecha(String fechaStr) {
    try {
      final dt = DateTime.parse(fechaStr).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) { return fechaStr; }
  }

  Color _accionColor(String accion) {
    final a = accion.toLowerCase();
    if (a.contains('cre') || a.contains('add')) return AppTheme.successColor;
    if (a.contains('edit') || a.contains('update') || a.contains('modi')) return AppTheme.warningColor;
    if (a.contains('del') || a.contains('elim')) return AppTheme.errorColor;
    return AppTheme.primaryColor;
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
              decoration: InputDecoration(hintText: 'Buscar en bitácora...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (val) => context.read<SeguridadProvider>().cargarBitacora(search: val),
            ),
          ),
          Expanded(
            child: Consumer<SeguridadProvider>(
              builder: (_, p, __) {
                if (p.isLoading) return const Center(child: CircularProgressIndicator());
                if (p.bitacora.isEmpty) return const Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.history, size: 64, color: AppTheme.textSecondary), SizedBox(height: 12), Text('Sin registros en bitácora', style: AppTheme.bodyMedium)],
                ));
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: p.bitacora.length,
                  itemBuilder: (_, i) {
                    final b = p.bitacora[i];
                    final accionColor = _accionColor(b.accion);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: accionColor.withOpacity(0.1),
                          child: Icon(Icons.history, color: accionColor, size: 20),
                        ),
                        title: Row(children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: accionColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                            child: Text(b.accion.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accionColor))),
                          if (b.modulo != null) ...[const SizedBox(width: 6), Text(b.modulo!, style: AppTheme.bodyMedium)],
                        ]),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if (b.usuarioNombre != null) Text('Usuario: ${b.usuarioNombre}', style: AppTheme.bodyMedium),
                          if (b.descripcion != null && b.descripcion!.isNotEmpty) Text(b.descripcion!, style: AppTheme.caption, maxLines: 2, overflow: TextOverflow.ellipsis),
                          Text(_formatFecha(b.fechaHora), style: AppTheme.caption),
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
    );
  }
}
