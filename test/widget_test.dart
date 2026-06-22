// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kreativ_flow/providers/auth_provider.dart';
import 'package:kreativ_flow/providers/providers.dart';
import 'package:kreativ_flow/providers/product_provider.dart';
import 'package:kreativ_flow/providers/cart_provider.dart';
import 'package:kreativ_flow/providers/supplier_provider.dart';
import 'package:kreativ_flow/providers/reportes_provider.dart';
import 'package:kreativ_flow/main.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => InventarioProvider()),
          ChangeNotifierProvider(create: (_) => SeguridadProvider()),
          ChangeNotifierProvider(create: (_) => ComprasProvider()),
          ChangeNotifierProvider(create: (_) => VentasProvider()),
          ChangeNotifierProvider(create: (_) => EmpresaProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => SupplierProvider()),
          ChangeNotifierProvider(create: (_) => ReportesProvider()),
        ],
        child: const TiendaApp(),
      ),
    );
    // Basic verification that the app widget tree starts up
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
