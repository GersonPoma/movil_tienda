import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:kreativ_flow/core/theme/app_theme.dart';
import 'package:kreativ_flow/providers/auth_provider.dart';
import 'package:kreativ_flow/providers/product_provider.dart';
import 'package:kreativ_flow/providers/cart_provider.dart';
import 'package:kreativ_flow/providers/supplier_provider.dart';
import 'package:kreativ_flow/presentation/screens/auth/login_screen.dart';
import 'package:kreativ_flow/presentation/screens/dashboard/home_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kreativ-Flow App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isAuthenticated) {
            return const HomeScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}
