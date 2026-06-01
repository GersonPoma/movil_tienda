import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:kreativ_flow/providers/cart_provider.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmClear(context),
          )
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cart = provider.cart;
          if (cart == null || cart['detalles'] == null || (cart['detalles'] as List).isEmpty) {
            return _buildEmptyCart();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: (cart['detalles'] as List).length,
                  itemBuilder: (context, index) {
                    final item = cart['detalles'][index];
                    return _CartItemTile(item: item);
                  },
                ),
              ),
              _buildSummary(context, cart, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_cart_outlined, size: 100, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Tu carrito está vacío', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('IR A COMPRAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, Map<String, dynamic> cart, CartProvider provider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text('BOB ${cart['total']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final pdfBytes = await provider.downloadQuotation();
                if (pdfBytes != null) {
                  try {
                    final tempDir = await getTemporaryDirectory();
                    final file = File('${tempDir.path}/cotizacion_muebles.pdf');
                    await file.writeAsBytes(pdfBytes);
                    
                    await OpenFilex.open(file.path);
                    
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cotización descargada y abierta')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al abrir el archivo: $e')),
                      );
                    }
                  }
                }
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('DESCARGAR COTIZACIÓN'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('COMPRAR AHORA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Vaciar carrito?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              Provider.of<CartProvider>(context, listen: false).clearCart();
              Navigator.pop(context);
            },
            child: const Text('VACIAR'),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final info = item['variante_producto_info'];
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: info['producto_imagen'] != null
            ? Image.network(info['producto_imagen'], width: 50, height: 50, fit: BoxFit.cover)
            : const Icon(Icons.chair),
        title: Text(info['producto_nombre'] ?? 'Producto'),
        subtitle: Text('BOB ${info['precio']} x ${item['cantidad']}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (item['cantidad'] > 1) {
                  Provider.of<CartProvider>(context, listen: false)
                      .updateQuantity(item['variante_producto'], item['cantidad'] - 1);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                Provider.of<CartProvider>(context, listen: false)
                    .removeItem(item['variante_producto']);
              },
            ),
          ],
        ),
      ),
    );
  }
}
