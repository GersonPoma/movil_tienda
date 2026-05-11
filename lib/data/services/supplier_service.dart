import 'dart:convert';
import '../../domain/models/supplier_model.dart';
import 'api_service.dart';
import '../../core/constants/api_constants.dart';

class SupplierService {
  final ApiService _apiService = ApiService();

  Future<List<Supplier>> getSuppliers() async {
    final response = await _apiService.get(ApiConstants.suppliersEndpoint);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Supplier.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load suppliers');
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    final response = await _apiService.post(ApiConstants.suppliersEndpoint, supplier.toJson());
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Supplier.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create supplier');
    }
  }

  Future<Supplier> updateSupplier(int id, Supplier supplier) async {
    final response = await _apiService.put('${ApiConstants.suppliersEndpoint}$id/', supplier.toJson());
    if (response.statusCode == 200) {
      return Supplier.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update supplier');
    }
  }

  Future<void> deleteSupplier(int id) async {
    final response = await _apiService.delete('${ApiConstants.suppliersEndpoint}$id/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete supplier');
    }
  }
}
