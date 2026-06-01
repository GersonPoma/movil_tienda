import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kreativ_flow/data/models/producto_model.dart';
import 'package:kreativ_flow/providers/cart_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Producto producto;

  const ProductDetailScreen({Key? key, required this.producto}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Descripción'),
                  const SizedBox(height: 8),
                  Text(
                    producto.descripcion.isNotEmpty 
                        ? producto.descripcion 
                        : 'Este mueble de alta calidad es perfecto para renovar tu hogar con estilo y confort.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  _buildFeatures(),
                  const SizedBox(height: 100), // Espacio para el botón flotante
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(context),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: Colors.blue[700],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'prod_${producto.id}',
          child: producto.imagenPrincipal != null
              ? Image.network(producto.imagenPrincipal!, fit: BoxFit.cover)
              : const Center(child: Icon(Icons.chair, size: 100, color: Colors.white54)),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            producto.categoriaNombre,
            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          producto.nombre,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'BOB ${producto.precioMinimo.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildFeatures() {
    return Row(
      children: [
        _FeatureIcon(icon: Icons.verified_user, label: 'Garantía'),
        _FeatureIcon(icon: Icons.local_shipping, label: 'Envío'),
        _FeatureIcon(icon: Icons.workspace_premium, label: 'Premium'),
      ],
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: () {
            if (producto.variantePrincipalId != null) {
              Provider.of<CartProvider>(context, listen: false)
                  .addToCart(producto.variantePrincipalId!);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${producto.nombre} añadido al carrito')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text(
            'AÑADIR AL CARRITO',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _FeatureIcon extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureIcon({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}
