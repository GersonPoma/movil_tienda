import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/providers.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../data/models/models.dart';
import 'visor_3d_screen.dart';

class ProductoDetalleScreen extends StatefulWidget {
  final int productoId;
  const ProductoDetalleScreen({Key? key, required this.productoId}) : super(key: key);

  @override
  State<ProductoDetalleScreen> createState() => _ProductoDetalleScreenState();
}

class _ProductoDetalleScreenState extends State<ProductoDetalleScreen> {
  Producto? _producto;
  bool _isLoading = true;
  bool _isUploading = false;
  
  // Multimedia Upload Form
  String _tipoMultimedia = 'imagen'; // imagen, realidad_aumentada
  File? _archivoSeleccionado;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    setState(() => _isLoading = true);
    final p = await context.read<InventarioProvider>().cargarProductoDetalle(widget.productoId);
    if (mounted) {
      if (p != null) {
        context.read<InventarioProvider>().cargarRecomendaciones(widget.productoId);
      }
      setState(() {
        _producto = p;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // IMAGE PICKER METHOD
  Future<void> _seleccionarArchivo() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _archivoSeleccionado = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar archivo: $e')),
      );
    }
  }

  // UPLOAD METHOD
  Future<void> _subirMultimedia() async {
    if (_archivoSeleccionado == null || _producto == null) return;
    setState(() => _isUploading = true);
    
    final inventarioProvider = context.read<InventarioProvider>();
    final orden = _producto!.multimedios.length;
    final esPrincipal = orden == 0;
    
    final exito = await inventarioProvider.subirImagenProducto(
      _producto!.id,
      _archivoSeleccionado!,
      _tipoMultimedia,
      esPrincipal,
      orden,
    );
    
    if (mounted) {
      setState(() {
        _isUploading = false;
        if (exito) {
          _archivoSeleccionado = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Archivo subido exitosamente')),
          );
          _cargarProducto();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al subir el archivo')),
          );
        }
      });
    }
  }

  // DELETE MULTIMEDIA METHOD
  Future<void> _eliminarMultimedia(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar imagen?'),
        content: const Text('¿Estás seguro de que deseas eliminar este archivo multimedia?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      final exito = await context.read<InventarioProvider>().eliminarImagenProducto(id);
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen eliminada correctamente')),
        );
        _cargarProducto();
      }
    }
  }

  // CREATE VARIANT DIALOG
  void _mostrarCrearVarianteDialog() {
    final skuController = TextEditingController();
    final precioController = TextEditingController();
    final stockController = TextEditingController();
    final costoController = TextEditingController();
    final limiteController = TextEditingController(text: '10');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar Nueva Variante'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: skuController,
                  decoration: const InputDecoration(labelText: 'SKU', hintText: 'Ej: SKU-PROD-01'),
                  validator: (value) => value == null || value.isEmpty ? 'SKU requerido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: precioController,
                  decoration: const InputDecoration(labelText: 'Precio (BOB)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Precio inválido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: stockController,
                  decoration: const InputDecoration(labelText: 'Cantidad (Stock)'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || int.tryParse(value) == null ? 'Cantidad inválida' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: costoController,
                  decoration: const InputDecoration(labelText: 'Costo Promedio (BOB)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Costo inválido' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: limiteController,
                  decoration: const InputDecoration(labelText: 'Límite por Venta'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || int.tryParse(value) == null ? 'Límite inválido' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final exito = await context.read<InventarioProvider>().crearVariante({
                  'sku': skuController.text.trim(),
                  'precio': double.parse(precioController.text),
                  'cantidad': int.parse(stockController.text),
                  'costo_ponderado': double.parse(costoController.text),
                  'limite_cantidad': int.parse(limiteController.text),
                  'producto_id': widget.productoId,
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  if (exito) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Variante creada exitosamente')),
                    );
                    _cargarProducto();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error al crear variante (SKU duplicado)')),
                    );
                  }
                }
              }
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  // DELETE VARIANT METHOD
  Future<void> _eliminarVariante(int id) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar Variante?'),
        content: const Text('¿Estás seguro de que deseas eliminar esta variante de producto?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ELIMINAR', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      final exito = await context.read<InventarioProvider>().eliminarVariante(id);
      if (exito && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Variante eliminada correctamente')),
        );
        _cargarProducto();
      }
    }
  }

  // ADD TO CART METHOD
  void _agregarAlCarrito(int varianteId, String sku) async {
    final cartProvider = context.read<CartProvider>();
    await cartProvider.addToCart(varianteId, cantidad: 1);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Variante ($sku) agregada al carrito!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final inventarioProvider = context.watch<InventarioProvider>();
    final isAdmin = auth.usuario?.isSuperuser ?? false;
    final tieneModelo3d = _producto?.modelo3dUrl != null;

    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: Text(_producto?.nombre ?? 'Detalles del Producto'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _producto == null
              ? const Center(child: Text('Producto no encontrado'))
              : RefreshIndicator(
                  onRefresh: _cargarProducto,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // INFO BÁSICA DEL PRODUCTO
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(_producto!.nombre, style: AppTheme.titleLarge)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'ID: ${_producto!.id}',
                                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 6),
                              if (_producto!.categoriaNombre != null)
                                Text('Categoría: ${_producto!.categoriaNombre!}', style: AppTheme.bodyMedium),
                              if (_producto!.marcaNombre != null)
                                Text('Marca: ${_producto!.marcaNombre!}', style: AppTheme.bodyMedium),
                              if (_producto!.descripcion != null && _producto!.descripcion!.isNotEmpty) ...[
                                const Divider(height: 24),
                                Text('Descripción', style: AppTheme.titleSmall),
                                const SizedBox(height: 4),
                                Text(_producto!.descripcion!, style: AppTheme.bodyMedium),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // SECCIÓN DE IMÁGENES DEL PRODUCTO + BOTÓN VER 3D
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Imágenes del producto:', style: AppTheme.titleMedium),
                              if (tieneModelo3d)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => Visor3DScreen(
                                          modelo3dUrl: _producto!.modelo3dUrl!,
                                          productoNombre: _producto!.nombre,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.view_in_ar_outlined),
                                  label: const Text('Ver 3D'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.primaryColor,
                                    side: const BorderSide(color: AppTheme.primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // LISTADO DE IMÁGENES
                        _buildImagenesList(isAdmin),

                        // UPLOADER FORM (Solo para Admin)
                        if (isAdmin) ...[
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildUploaderForm(),
                          ),
                        ],
                        
                        const SizedBox(height: 16),

                        // SECCIÓN DE VARIANTES (TABLA SIMILAR AL FRONTEND)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Variantes del Producto', style: AppTheme.titleMedium),
                                  if (isAdmin)
                                    OutlinedButton.icon(
                                      onPressed: _mostrarCrearVarianteDialog,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Agregar'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildVariantesTable(isAdmin),
                            ],
                          ),
                        ),

                        // SECCIÓN DE RECOMENDACIONES (TE PODRÍA INTERESAR)
                        _buildRecomendacionesSection(inventarioProvider),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  // SECCIÓN DE RECOMENDACIONES HORIZONTAL
  Widget _buildRecomendacionesSection(InventarioProvider provider) {
    final recomendados = provider.recomendaciones;

    if (recomendados.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Te podría interesar',
            style: AppTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recomendados.length,
              itemBuilder: (context, index) {
                final prod = recomendados[index];
                final String precioLabel = 'BOB ${prod.precioMinimo.toStringAsFixed(2)}';

                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 12),
                  child: Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        // Navegar reemplazando para evitar pila infinita
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductoDetalleScreen(productoId: prod.id),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: AppTheme.bgColor,
                              child: prod.imagenUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: prod.imagenUrl!,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppTheme.textSecondary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppTheme.textSecondary,
                                    ),
                            ),
                          ),
                          // Info
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppTheme.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  precioLabel,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // LISTADO DE IMÁGENES HORIZONTAL
  Widget _buildImagenesList(bool isAdmin) {
    final imagenes = _producto!.multimedios.where((m) => m.tipo == 'imagen').toList();
    
    return Container(
      height: 180,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: imagenes.isEmpty
          ? const Center(child: Text('No hay imágenes subidas', style: AppTheme.bodyMedium))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagenes.length,
              itemBuilder: (context, i) {
                final img = imagenes[i];
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: img.url,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                        ),
                        if (isAdmin)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: Colors.red.withOpacity(0.9),
                              radius: 18,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                                onPressed: () => _eliminarMultimedia(img.id),
                              ),
                            ),
                          ),
                        if (img.esPrincipal)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.successColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('Principal', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // UPLOADER FORM (Solo para Admin)
  Widget _buildUploaderForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _tipoMultimedia,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo de multimedio', contentPadding: EdgeInsets.symmetric(horizontal: 10)),
                  items: const [
                    DropdownMenuItem(value: 'imagen', child: Text('Imagen')),
                    DropdownMenuItem(value: 'realidad_aumentada', child: Text('Realidad Aumentada (3D)', overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _tipoMultimedia = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _seleccionarArchivo,
                child: Text(_archivoSeleccionado != null ? 'Cambiar' : 'Seleccionar'),
              ),
            ],
          ),
          if (_archivoSeleccionado != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Seleccionado: ${_archivoSeleccionado!.path.split(Platform.pathSeparator).last}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.caption,
                  ),
                ),
                _isUploading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : TextButton(
                        onPressed: _subirMultimedia,
                        child: const Text('SUBIR ARCHIVO'),
                      ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // TABLA DE VARIANTES DINÁMICA
  Widget _buildVariantesTable(bool isAdmin) {
    if (_producto!.variantes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No hay variantes registradas en este producto', style: AppTheme.bodyMedium)),
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(AppTheme.primaryColor.withOpacity(0.05)),
          columns: [
            const DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Precio', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
            if (isAdmin) ...[
              const DataColumn(label: Text('Costo Prom.', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Límite', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            const DataColumn(label: Text('Acciones', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _producto!.variantes.map((v) {
            return DataRow(
              cells: [
                DataCell(Text(v.sku ?? 'S/SKU', style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text('S/ ${v.precio.toStringAsFixed(2)}')),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: v.cantidad > 0 ? AppTheme.successColor.withOpacity(0.1) : AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      v.cantidad.toString(),
                      style: TextStyle(
                        color: v.cantidad > 0 ? AppTheme.successColor : AppTheme.errorColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  DataCell(Text('S/ ${v.costoPonderado.toStringAsFixed(2)}')),
                  DataCell(Text(v.limiteCantidad.toString())),
                ],
                DataCell(
                  Row(
                    children: [
                      // Carrito
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: AppTheme.primaryColor, size: 20),
                        tooltip: 'Agregar al carrito',
                        onPressed: v.cantidad > 0 ? () => _agregarAlCarrito(v.id, v.sku ?? '') : null,
                      ),
                      // Eliminar
                      if (isAdmin)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: 'Eliminar variante',
                          onPressed: () => _eliminarVariante(v.id),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
