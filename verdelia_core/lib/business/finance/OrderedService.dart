import 'package:verdelia_core/business/finance/ProvidedService.dart';

class OrderedService {
  final int id;
  final int cartId;
  final int serviceId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderedService({
    required this.id,
    required this.cartId,
    required this.serviceId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderedService.fromJson(Map<String, dynamic> json) {
    return OrderedService(
      id: json['ordered_service_id'] as int,
      cartId: json['ordered_service_cart_id'] as int,
      serviceId: json['ordered_service_service_id'] as int,
      quantity: json['ordered_service_quantity'] as int,
      unitPrice: (json['ordered_service_unit_price'] as num).toDouble(),
      totalPrice: (json['ordered_service_total_price'] as num).toDouble(),
      notes: json['ordered_service_notes'] as String?,
      createdAt: DateTime.parse(json['ordered_service_created_at']),
      updatedAt: DateTime.parse(json['ordered_service_updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ordered_service_id': id,
      'ordered_service_cart_id': cartId,
      'ordered_service_service_id': serviceId,
      'ordered_service_quantity': quantity,
      'ordered_service_unit_price': unitPrice,
      'ordered_service_total_price': totalPrice,
      'ordered_service_notes': notes,
      'ordered_service_created_at': createdAt.toIso8601String(),
      'ordered_service_updated_at': updatedAt.toIso8601String(),
    };
  }

  OrderedService copyWith({
    int? id,
    int? cartId,
    int? serviceId,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderedService(
      id: id ?? this.id,
      cartId: cartId ?? this.cartId,
      serviceId: serviceId ?? this.serviceId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get hasNotes => notes != null && notes!.isNotEmpty;

  @override
  String toString() {
    return 'OrderedService(id: $id, serviceId: $serviceId, qty: $quantity, total: DZD$totalPrice)';
  }
}

// Helper class for working with collections
class ServiceUtils {
  // Parse a list of provided services
  static List<ProvidedService> parseProvidedServices(List<dynamic> jsonList) {
    return jsonList
        .map((json) => ProvidedService.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Parse a list of ordered services
  static List<OrderedService> parseOrderedServices(List<dynamic> jsonList) {
    return jsonList
        .map((json) => OrderedService.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Group provided services by category
  static Map<int, List<ProvidedService>> groupByCategory(
      List<ProvidedService> services) {
    final Map<int, List<ProvidedService>> grouped = {};

    for (final service in services) {
      grouped.putIfAbsent(service.categoryId, () => []).add(service);
    }

    return grouped;
  }

  // Calculate cart total from ordered services
  static double calculateCartTotal(List<OrderedService> orderedServices) {
    return orderedServices.fold(
      0.0,
      (total, service) => total + service.totalPrice,
    );
  }
}
