import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../data/models/models.dart';

class EmpresaScreen extends StatefulWidget {
  const EmpresaScreen({Key? key}) : super(key: key);
  @override
  State<EmpresaScreen> createState() => _EmpresaScreenState();
}

class _EmpresaScreenState extends State<EmpresaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();

  File? _logoFile;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<EmpresaProvider>().cargarConfiguracion();
      _llenarFormulario();
    });
  }

  void _llenarFormulario() {
    final config = context.read<EmpresaProvider>().config;
    if (config != null) {
      _nombreCtrl.text = config.nombre;
      _emailCtrl.text = config.email ?? '';
      _telefonoCtrl.text = config.telefono ?? '';
      _direccionCtrl.text = config.direccion ?? '';
      _facebookCtrl.text = config.facebook ?? '';
      _instagramCtrl.text = config.instagram ?? '';
      _tiktokCtrl.text = config.tiktok ?? '';
      _rucCtrl.text = config.ruc ?? '';
    }
    setState(() => _init = true);
  }

  Future<void> _seleccionarLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);
    if (picked != null) setState(() => _logoFile = File(picked.path));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<EmpresaProvider>();

    // Si hay logo nuevo, primero subirlo
    if (_logoFile != null) {
      await provider.subirLogo(_logoFile!);
      setState(() => _logoFile = null);
    }

    // Luego guardar datos del formulario
    final ok = await provider.guardarConfiguracion({
      'nombre': _nombreCtrl.text.trim(),
      if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_telefonoCtrl.text.isNotEmpty) 'telefono': _telefonoCtrl.text.trim(),
      if (_direccionCtrl.text.isNotEmpty) 'direccion': _direccionCtrl.text.trim(),
      if (_facebookCtrl.text.isNotEmpty) 'facebook': _facebookCtrl.text.trim(),
      if (_instagramCtrl.text.isNotEmpty) 'instagram': _instagramCtrl.text.trim(),
      if (_tiktokCtrl.text.isNotEmpty) 'tiktok': _tiktokCtrl.text.trim(),
      if (_rucCtrl.text.isNotEmpty) 'ruc': _rucCtrl.text.trim(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '✅ Configuración guardada exitosamente' : '❌ ${provider.error ?? "Error al guardar"}'),
        backgroundColor: ok ? AppTheme.successColor : AppTheme.errorColor,
      ));
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _emailCtrl.dispose(); _telefonoCtrl.dispose();
    _direccionCtrl.dispose(); _facebookCtrl.dispose(); _instagramCtrl.dispose();
    _tiktokCtrl.dispose(); _rucCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      body: Consumer<EmpresaProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading && !_init) return const Center(child: CircularProgressIndicator());
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Sección Logo ----
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        const Text('Logo de la Empresa', style: AppTheme.titleMedium),
                        const SizedBox(height: 16),
                        // Preview del logo
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120, height: 120,
                                decoration: BoxDecoration(color: AppTheme.bgColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.borderColor, width: 2)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: _logoFile != null
                                      ? Image.file(_logoFile!, fit: BoxFit.cover)
                                      : provider.config?.logoUrl != null
                                          ? CachedNetworkImage(imageUrl: provider.config!.logoUrl!, fit: BoxFit.cover,
                                              errorWidget: (_, __, ___) => const Icon(Icons.storefront, size: 48, color: AppTheme.textSecondary))
                                          : const Icon(Icons.storefront, size: 48, color: AppTheme.textSecondary),
                                ),
                              ),
                              if (_logoFile != null || provider.config?.logoUrl != null)
                                Positioned(top: 0, right: 0, child: GestureDetector(
                                  onTap: () => setState(() { _logoFile = null; }), // solo limpiar preview
                                  child: Container(decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle), padding: const EdgeInsets.all(4), child: const Icon(Icons.close, color: Colors.white, size: 16)),
                                )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _seleccionarLogo,
                          icon: const Icon(Icons.photo_camera),
                          label: const Text('Subir Nuevo Logo'),
                        ),
                        const SizedBox(height: 4),
                        const Text('Formatos recomendados: PNG, JPG (Max: 1MB)', style: AppTheme.caption),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Datos Generales ----
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Datos Generales', style: AppTheme.titleMedium),
                        const SizedBox(height: 16),
                        _FormField(controller: _nombreCtrl, label: 'Nombre de la Empresa *', hint: 'Ej: Tienda Amiga S.A.C.', icon: Icons.business, required: true),
                        const SizedBox(height: 12),
                        _FormField(controller: _rucCtrl, label: 'RUC / NIT', hint: 'Ej: 20123456789', icon: Icons.badge_outlined, keyboardType: TextInputType.number),
                        const SizedBox(height: 12),
                        _FormField(controller: _emailCtrl, label: 'Correo Electrónico Corporativo', hint: 'contacto@empresa.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                        const SizedBox(height: 12),
                        _FormField(controller: _telefonoCtrl, label: 'Teléfono de Contacto', hint: '+51 987654321', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                        const SizedBox(height: 12),
                        _FormField(controller: _direccionCtrl, label: 'Ubicación / Dirección Física', hint: 'Av. Principal 123, Ciudad', icon: Icons.location_on_outlined, maxLines: 2),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ---- Redes Sociales ----
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Redes Sociales', style: AppTheme.titleMedium),
                        const SizedBox(height: 16),
                        _SocialField(controller: _facebookCtrl, label: 'Facebook URL', hint: 'https://facebook.com/empresa', color: const Color(0xFF1877F2), icon: Icons.facebook),
                        const SizedBox(height: 12),
                        _SocialField(controller: _instagramCtrl, label: 'Instagram URL', hint: 'https://instagram.com/empresa', color: const Color(0xFFE4405F), icon: Icons.photo_camera_outlined),
                        const SizedBox(height: 12),
                        _SocialField(controller: _tiktokCtrl, label: 'TikTok URL', hint: 'https://tiktok.com/@empresa', color: Colors.black87, icon: Icons.play_circle_outline),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ---- Botón Guardar ----
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isLoading ? null : _guardar,
                      icon: provider.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(provider.isLoading ? 'Guardando...' : 'Guardar Configuración'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final int maxLines;
  final bool required;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'Este campo es requerido' : null : null,
    );
  }
}

class _SocialField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Color color;
  final IconData icon;

  const _SocialField({required this.controller, required this.label, required this.hint, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.url,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: color),
      border: const OutlineInputBorder(),
    ),
  );
}
