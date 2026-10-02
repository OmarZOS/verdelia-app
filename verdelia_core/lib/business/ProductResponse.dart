import 'iProduct.dart';

class IProductResponse {
  final String source;
  final List<IProduct> products;

  IProductResponse({
    required this.source,
    required this.products,
  });

  factory IProductResponse.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as String? ?? 'unknown';
    final data = json['data'];

    if (data == null) return IProductResponse(source: source, products: []);

    if (data is List) {
      return IProductResponse(
        source: source,
        products: data
            .whereType<Map<String, dynamic>>()
            .map(IProduct.fromJson)
            .toList(),
      );
    }

    if (data is Map<String, dynamic>) {
      return IProductResponse(
        source: source,
        products: [IProduct.fromJson(data)],
      );
    }

    return IProductResponse(source: source, products: []);
  }
}
