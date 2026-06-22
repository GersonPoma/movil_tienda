import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/providers.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';

class PaymentScreen extends StatefulWidget {
  final double total;
  final bool isNuevaVenta;
  const PaymentScreen({Key? key, required this.total, this.isNuevaVenta = false}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isProcessing = false;

  // EFECTIVO STATE
  final TextEditingController _recibidoController = TextEditingController();
  double _vuelto = 0;
  bool _efectivoSuficiente = false;

  // QR STATE
  String? _qrComprobanteNombre;
  bool _qrCargando = false;
  bool _qrVerificado = false;

  // TARJETA STATE
  final _formKeyTarjeta = GlobalKey<FormState>();
  final _tarjetaNombreController = TextEditingController();
  final _tarjetaNumeroController = TextEditingController();
  final _tarjetaExpController = TextEditingController();
  final _tarjetaCvvController = TextEditingController();

  String _visualNombre = 'TITULAR DE LA TARJETA';
  String _visualNumero = '**** **** **** ****';
  String _visualExp = 'MM/AA';
  String _visualCvv = '***';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _recibidoController.addListener(_calcularVuelto);
    _tarjetaNombreController.addListener(() {
      setState(() {
        _visualNombre = _tarjetaNombreController.text.toUpperCase();
        if (_visualNombre.isEmpty) _visualNombre = 'TITULAR DE LA TARJETA';
      });
    });
    _tarjetaNumeroController.addListener(() {
      setState(() {
        _visualNumero = _tarjetaNumeroController.text;
        if (_visualNumero.isEmpty) _visualNumero = '**** **** **** ****';
      });
    });
    _tarjetaExpController.addListener(() {
      setState(() {
        _visualExp = _tarjetaExpController.text;
        if (_visualExp.isEmpty) _visualExp = 'MM/AA';
      });
    });
    _tarjetaCvvController.addListener(() {
      setState(() {
        _visualCvv = _tarjetaCvvController.text;
        if (_visualCvv.isEmpty) _visualCvv = '***';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recibidoController.dispose();
    _tarjetaNombreController.dispose();
    _tarjetaNumeroController.dispose();
    _tarjetaExpController.dispose();
    _tarjetaCvvController.dispose();
    super.dispose();
  }

  void _calcularVuelto() {
    final recibido = double.tryParse(_recibidoController.text) ?? 0;
    setState(() {
      if (recibido >= widget.total) {
        _vuelto = recibido - widget.total;
        _efectivoSuficiente = true;
      } else {
        _vuelto = 0;
        _efectivoSuficiente = false;
      }
    });
  }

  // SIMULACION DE QR
  void _cargarComprobanteMock() {
    setState(() {
      _qrComprobanteNombre = 'captura_transferencia_${DateTime.now().millisecondsSinceEpoch}.png';
      _qrVerificado = false;
    });
  }

  void _verificarQR() async {
    if (_qrComprobanteNombre == null || _qrCargando) return;

    setState(() {
      _qrCargando = true;
    });

    // Simular API bancaria de 2.5 segundos
    await Future.delayed(const Duration(milliseconds: 2500));

    if (mounted) {
      setState(() {
        _qrCargando = false;
        _qrVerificado = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Comprobante verificado con éxito'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  // PROCESAMIENTO Y REGISTRO DE PAGO
  void _completarPago(String metodo) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isProcessing = true);

    // Simular retraso de procesamiento para tarjeta o QR/Efectivo
    await Future.delayed(Duration(seconds: metodo == 'tarjeta' ? 2 : 1));

    try {
      if (widget.isNuevaVenta) {
        final ventasProvider = Provider.of<VentasProvider>(context, listen: false);
        final ok = await ventasProvider.pagarYCompletar();
        if (mounted) {
          setState(() => _isProcessing = false);
          if (ok) {
            _showSuccessDialog(metodo);
          } else {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text('❌ Error al registrar venta: ${ventasProvider.error ?? "Error desconocido"}'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
        return;
      }

      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final usuarioId = authProvider.usuario?.id;
      final total = cartProvider.totalAmount;
      final items = cartProvider.cartItems;

      if (usuarioId == null) {
        throw Exception('Usuario no autenticado');
      }

      final detalles = items.map((item) {
        final info = item['variante_producto_info'];
        final precio = double.tryParse(info['precio']?.toString() ?? '0') ?? 0.0;
        return {
          'variante_producto_id': item['variante_producto'],
          'cantidad': int.tryParse(item['cantidad']?.toString() ?? '1') ?? 1,
          'precio_unitario': precio,
        };
      }).toList();

      final apiService = ApiService();
      final response = await apiService.post(ApiConstants.ventasEndpoint, {
        'tipo': 'digital',
        'estado': 'completado',
        'precio_total': total,
        'usuario_id': usuarioId,
        'detalles': detalles,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          setState(() => _isProcessing = false);
          cartProvider.clearCart();
          _showSuccessDialog(metodo);
        }
      } else {
        String errMsg = 'Error en el servidor al registrar la venta';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('detail')) {
            errMsg = decoded['detail'];
          } else if (decoded is Map && decoded.values.isNotEmpty) {
            final firstVal = decoded.values.first;
            if (firstVal is List && firstVal.isNotEmpty) {
              errMsg = firstVal.first.toString();
            } else {
              errMsg = firstVal.toString();
            }
          }
        } catch (_) {}

        if (mounted) {
          setState(() => _isProcessing = false);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('❌ Error al registrar venta: $errMsg'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('❌ Error de conexión: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String metodo) {
    String msg = '';
    if (metodo == 'efectivo') {
      msg = 'Venta registrada en efectivo.\nCambio/Vuelto a entregar: BOB ${_vuelto.toStringAsFixed(2)}';
    } else if (metodo == 'qr') {
      msg = 'Pago recibido correctamente mediante transferencia QR.';
    } else {
      msg = 'Transacción de tarjeta autorizada con éxito por el banco.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppTheme.successColor, size: 80),
            const SizedBox(height: 20),
            const Text('¡Pago Exitoso!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('VOLVER AL INICIO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- WIDGETS TABS ----

  Widget _buildEfectivoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTotalBanner(),
          const SizedBox(height: 24),
          const Text('Ingrese Monto Recibido', style: AppTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _recibidoController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: InputDecoration(
              labelText: 'Monto en Efectivo',
              prefixText: 'BOB ',
              hintText: '0.00',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          if (_recibidoController.text.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: _efectivoSuficiente ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _efectivoSuficiente ? Colors.green.shade200 : Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _efectivoSuficiente ? 'Cambio / Vuelto a entregar:' : 'Monto insuficiente:',
                    style: TextStyle(
                      color: _efectivoSuficiente ? Colors.green.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'BOB ${_vuelto.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _efectivoSuficiente ? Colors.green.shade900 : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: (_efectivoSuficiente && !_isProcessing) ? () => _completarPago('efectivo') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check, color: Colors.white),
              label: const Text('CONFIRMAR REGISTRO EN EFECTIVO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildTotalBanner(),
          const SizedBox(height: 20),
          const Text('Escanee el código QR para transferir', style: AppTheme.titleSmall),
          const SizedBox(height: 12),
          // Estilizado código QR representativo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              children: [
                // QR Mock Drawing
                Container(
                  width: 160,
                  height: 160,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: Icon(Icons.qr_code_2, size: 140, color: Colors.blue.shade900),
                  ),
                ),
                const SizedBox(height: 8),
                Text('PILLIPS MULTI-TENANT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_qrComprobanteNombre == null)
            OutlinedButton.icon(
              onPressed: _cargarComprobanteMock,
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir Captura de Comprobante'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.image, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _qrComprobanteNombre!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    onPressed: () => setState(() {
                      _qrComprobanteNombre = null;
                      _qrVerificado = false;
                    }),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (!_qrVerificado)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _qrCargando ? null : _verificarQR,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _qrCargando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.lock_reset, color: Colors.white),
                  label: Text(_qrCargando ? 'Verificando con Banco (2.5s)...' : 'VERIFICAR TRANSFERENCIA', style: const TextStyle(color: Colors.white)),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.shade200)),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successColor),
                    SizedBox(width: 8),
                    Text('Transferencia Validada correctamente', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_qrVerificado && !_isProcessing) ? () => _completarPago('qr') : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('CONFIRMAR PAGO QR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKeyTarjeta,
        child: Column(
          children: [
            // Visa card visual
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.contactless, color: Colors.white, size: 28),
                      Text('VISA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
                    ],
                  ),
                  Text(
                    _visualNumero,
                    style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2, fontFamily: 'monospace'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TITULAR', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9)),
                            Text(
                              _visualNombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EXPIRA', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9)),
                          Text(_visualExp, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CVV', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9)),
                          Text(_visualCvv, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _tarjetaNombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del Titular',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Titular requerido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tarjetaNumeroController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                CardNumberFormatter(),
              ],
              decoration: InputDecoration(
                labelText: 'Número de Tarjeta',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.replaceAll(' ', '').length < 16 ? 'Número inválido' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tarjetaExpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      ExpiryDateFormatter(),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Expiración (MM/AA)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.replaceAll('/', '').length < 4 ? 'Fecha inválida' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _tarjetaCvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => v == null || v.length < 3 ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () {
                  if (_formKeyTarjeta.currentState?.validate() ?? false) {
                    _completarPago('tarjeta');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('AUTORIZAR Y PAGAR', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total a Pagar:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(
            'BOB ${widget.total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text('Pasarela de Pagos (Simulado)'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.money), text: 'Efectivo'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR / Transf.'),
            Tab(icon: Icon(Icons.credit_card), text: 'Tarjeta'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEfectivoTab(),
          _buildQRTab(),
          _buildTarjetaTab(),
        ],
      ),
    );
  }
}

// ---- CUSTOM FORMATTERS ----

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(' ', '');
    if (text.length > 16) text = text.substring(0, 16);

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('/', '');
    if (text.length > 4) text = text.substring(0, 4);

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
