import 'package:flutter/material.dart';
import '../domain/models/supplier_model.dart';
import '../data/services/supplier_service.dart';

class SupplierProvider with ChangeNotifier {
  final SupplierService _supplierService = SupplierService();
  
  List<Supplier> _suppliers = [];
  bool _isLoading = false;

  List<Supplier> get suppliers => _suppliers;
  bool get isLoading => _isLoading;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    notifyListeners();
    try {
      _suppliers = await _supplierService.getSuppliers();
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(Supplier supplier) async {
    try {
      await _supplierService.createSupplier(supplier);
      await loadSuppliers();
      return true;
    } catch (e) {
      debugPrint('Error adding supplier: $e');
      return false;
    }
  }

  Future<bool> updateSupplier(int id, Supplier supplier) async {
    try {
      await _supplierService.updateSupplier(id, supplier);
      await loadSuppliers();
      return true;
    } catch (e) {
      debugPrint('Error updating supplier: $e');
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      await _supplierService.deleteSupplier(id);
      await loadSuppliers();
      return true;
    } catch (e) {
      debugPrint('Error deleting supplier: $e');
      return false;
    }
  }
}
