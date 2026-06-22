import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kreativ_flow/providers/product_provider.dart';
import 'package:kreativ_flow/providers/cart_provider.dart';
import 'package:kreativ_flow/data/models/models.dart';
import 'package:kreativ_flow/presentation/screens/cart/cart_screen.dart';
import 'package:kreativ_flow/presentation/screens/inventario/producto_detalle_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      provider.cargarCategorias();
      provider.cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Muebles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar muebles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                Provider.of<ProductProvider>(context, listen: false).buscar(value);
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: provider.categoriaSeleccionada == null,
                onSelected: (selected) => provider.filtrarPorCategoria(null),
              ),
              const SizedBox(width: 8),
              ...provider.categorias.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat.nombre),
                    selected: provider.categoriaSeleccionada == cat.id,
                    onSelected: (selected) => provider.filtrarPorCategoria(cat.id),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.productos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                Text('No se encontraron muebles'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: provider.productos.length,
          itemBuilder: (context, index) {
            final producto = provider.productos[index];
            return _ProductCard(producto: producto);
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Producto producto;
  const _ProductCard({required this.producto});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductoDetalleScreen(productoId: producto.id)),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: producto.imagenUrl != null
                    ? Image.network(
                        producto.imagenUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.image_not_supported)),
                      )
                    : const Center(child: Icon(Icons.chair, size: 50, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    producto.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    producto.categoriaNombre ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BOB ${producto.precioMinimo.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, color: Colors.blue, size: 24),
                        onPressed: () {
                          if (producto.variantePrincipalId != 0) {
                            print('DEBUG CATALOG - Añadiendo producto: ${producto.nombre} con variante: ${producto.variantePrincipalId}');
                            Provider.of<CartProvider>(context, listen: false)
                                .addToCart(producto.variantePrincipalId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('¡${producto.nombre} añadido al carrito!'),
                                duration: const Duration(seconds: 2),
                                action: SnackBarAction(
                                  label: 'VER',
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                                  },
                                ),
                              ),
                            );
                          } else {
                            print('DEBUG CATALOG - ERROR: El producto ${producto.nombre} no tiene variante_principal_id');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Este producto no se puede añadir (sin variante)')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
