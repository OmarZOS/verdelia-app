import 'package:flutter_test/flutter_test.dart';
import 'package:verdelia_core/business/Delivery.dart';

void main() {
  group('Delivery Model Tests', () {
    test('Default constructor initializes values correctly', () {
      final delivery = Delivery();

      expect(delivery.id_delivery, 0);
      expect(delivery.delivery_package_count, 0);
      expect(delivery.delivery_total_weight, 0.0);
      expect(delivery.delivery_shipping_method, 'standard');
      expect(delivery.delivery_status, 'PENDING');
    });

    test('fromJson parses correctly', () {
      final json = {
        'id_delivery': 10,
        'recipient_person': 5,
        'delivery_package_count': 2,
        'delivery_total_weight': 4.5,
        'delivery_address_id': 7,
        'delivery_shipping_method': 'express',
        'delivery_status': 'IN_TRANSIT',
      };

      final delivery = Delivery.fromJson(json);

      expect(delivery.id_delivery, 10);
      expect(delivery.recipient_person, 5);
      expect(delivery.delivery_package_count, 2);
      expect(delivery.delivery_total_weight, 4.5);
      expect(delivery.delivery_address_id, 7);
      expect(delivery.delivery_shipping_method, 'express');
      expect(delivery.delivery_status, 'IN_TRANSIT');
    });

    test('toJson produces valid map', () {
      final delivery = Delivery(
        id_delivery: 3,
        recipient_person: 1,
        delivery_package_count: 1,
        delivery_total_weight: 2.0,
        delivery_address_id: 4,
      );

      final json = delivery.toJson();

      expect(json['id_delivery'], 3);
      expect(json['recipient_person'], 1);
      expect(json['delivery_package_count'], 1);
      expect(json['delivery_total_weight'], 2.0);
      expect(json['delivery_address_id'], 4);
    });

    test('copyWith overrides only provided fields', () {
      final delivery = Delivery(
        id_delivery: 1,
        delivery_package_count: 1,
      );

      final updated = delivery.copyWith(
        delivery_package_count: 3,
      );

      expect(updated.id_delivery, 1);
      expect(updated.delivery_package_count, 3);
    });

    test('isValidForCreation true for valid delivery', () {
      final delivery = Delivery(
        recipient_person: 2,
        delivery_package_count: 1,
        delivery_total_weight: 2.0,
        delivery_address_id: 5,
      );

      expect(delivery.isValidForCreation, true);
    });

    test('isValidForCreation false for invalid delivery', () {
      final delivery = Delivery();

      expect(delivery.isValidForCreation, false);
    });

    test('validate returns errors for invalid fields', () {
      final delivery = Delivery();

      final errors = delivery.validate();

      expect(errors.isNotEmpty, true);
      expect(errors.contains('Delivery address is required'), true);
    });

    test('status helpers work correctly', () {
      final delivery = Delivery(delivery_status: 'DELIVERED');

      expect(delivery.isDelivered, true);
      expect(delivery.canBeUpdated, false);
    });

    test('shipping method label resolves correctly', () {
      final delivery = Delivery(delivery_shipping_method: 'express');

      expect(delivery.shippingMethodLabel, 'Express Delivery');
    });

    test('price estimation works', () {
      final delivery = Delivery(
        delivery_total_weight: 10,
        delivery_shipping_method: 'express',
      );

      final price = delivery.calculateEstimatedPrice();

      expect(price > 0, true);
    });

    test('formatted display helpers work', () {
      final delivery = Delivery(
        delivery_package_count: 2,
        delivery_total_weight: 3.5,
        delivery_fee: 12.3,
      );

      expect(delivery.formattedWeight, '3.50 kg');
      expect(delivery.formattedFee, '\$12.30');
      expect(delivery.formattedPackageCount, '2 packages');
    });

    test('DeliveryData conversion works', () {
      final data = DeliveryData(
        idDelivery: 5,
        deliveryPackageCount: 2,
        deliveryTotalWeight: 6.0,
      );

      final delivery = data.toDelivery();

      expect(delivery.id_delivery, 5);
      expect(delivery.delivery_package_count, 2);
      expect(delivery.delivery_total_weight, 6.0);
    });

    test('Delivery equality based on id', () {
      final a = Delivery(id_delivery: 1);
      final b = Delivery(id_delivery: 1);

      expect(a == b, true);
    });
  });
}
