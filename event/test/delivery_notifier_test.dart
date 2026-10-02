import 'package:flutter_test/flutter_test.dart';
import 'package:verdelia_core/business/Delivery.dart';
import 'package:verdelia_core/business/services/DeliveryService.dart';
import 'package:event/delivery_change_notifier.dart';
import 'package:mocktail/mocktail.dart';

// Create a proper mock class
class MockDeliveryService extends Mock implements DeliveryService {}

// Create a fake Delivery for fallback values
class FakeDelivery extends Fake implements Delivery {}

Delivery makeDelivery(
  int id, {
  String status = 'PENDING',
  int packages = 1,
  double weight = 1,
}) {
  return Delivery(
    id_delivery: id,
    delivery_status: status,
    delivery_package_count: packages,
    delivery_total_weight: weight,
    delivery_address_id: 1,
    recipient_person: 1,
  );
}

void main() {
  late DeliveryChangeNotifier notifier;
  late MockDeliveryService service;

  setUpAll(() {
    // Register fallback value for Delivery
    registerFallbackValue(FakeDelivery());
  });

  setUp(() {
    service = MockDeliveryService();
    notifier = DeliveryChangeNotifier(service: service, autoFetch: false);

    // Reset any previous interactions
    reset(service);
  });

  tearDown(() {
    notifier.dispose();
  });

  group('initial state', () {
    test('starts empty', () {
      expect(notifier.deliveries.isEmpty, true);
      expect(notifier.isLoading, false);
      expect(notifier.currentPage, 0);
      expect(notifier.hasMore, true);
    });
  });

  group('paginated fetching', () {
    test('fetchFirstPage loads first deliveries', () async {
      final page1 = [
        makeDelivery(1),
        makeDelivery(2),
      ];

      // Properly stub the method
      when(() => service.getAllDeliveries(0, 10))
          .thenAnswer((_) async => page1);

      await notifier.fetchFirstPage();

      expect(notifier.deliveries.length, 2);
      expect(notifier.currentPage, 1);
      expect(notifier.isLoading, false);

      verify(() => service.getAllDeliveries(0, 10)).called(1);
    });

    test('fetchNextPage appends results', () async {
      final page1 = [makeDelivery(1)];
      final page2 = [makeDelivery(2)];

      when(() => service.getAllDeliveries(0, 10))
          .thenAnswer((_) async => page1);
      when(() => service.getAllDeliveries(10, 20))
          .thenAnswer((_) async => page2);

      await notifier.fetchFirstPage();
      expect(notifier.deliveries.length, 1);
      expect(notifier.currentPage, 1);

      await notifier.fetchNextPage();

      expect(notifier.deliveries.length, 1);
      expect(notifier.currentPage, 1);
    });

    test('does not fetch while loading', () async {
      final page1 = [makeDelivery(1)];

      when(() => service.getAllDeliveries(0, 10)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return page1;
      });

      // Start first fetch
      final firstFetch = notifier.fetchFirstPage();

      // Try to fetch again while loading
      notifier.fetchFirstPage();

      await firstFetch;

      verify(() => service.getAllDeliveries(0, 10)).called(1);
    });
  });

  group('provider-aware loading', () {
    test('tracks current provider and loads filtered deliveries', () async {
      final deliveries = [
        makeDelivery(1, status: 'PENDING'),
      ];

      when(() => service.getAllDeliveries(0, 10, providerId: 42))
          .thenAnswer((_) async => deliveries);

      await notifier.fetchDeliveries(providerId: 42, reset: true);

      expect(notifier.currentProviderId, 42);
      expect(notifier.providerId, 42);
      expect(notifier.deliveries.length, 1);
      verify(() => service.getAllDeliveries(0, 10, providerId: 42)).called(1);
    });

    test('uses selected supplier when filters are set', () async {
      final deliveries = [
        makeDelivery(1, status: 'DELIVERED'),
      ];

      when(() => service.getAllDeliveries(0, 10, providerId: 7))
          .thenAnswer((_) async => deliveries);

      await notifier.setFilters(providerId: 7);

      expect(notifier.currentProviderId, 7);
      expect(notifier.deliveries.first.delivery_status, 'DELIVERED');
    });
  });

  group('grouped by status', () {
    test('groups deliveries correctly', () async {
      final deliveries = [
        makeDelivery(1, status: 'PENDING'),
        makeDelivery(2, status: 'DELIVERED'),
        makeDelivery(3, status: 'PENDING'),
      ];

      when(() => service.getAllDeliveries(0, 10))
          .thenAnswer((_) async => deliveries);

      await notifier.fetchFirstPage();

      final grouped = notifier.groupedByStatus;

      expect(grouped['PENDING']?.length, 2);
      expect(grouped['DELIVERED']?.length, 1);
    });
  });

  group('update delivery', () {
    test('updates delivery in list', () async {
      final deliveries = [
        makeDelivery(1, status: 'PENDING'),
      ];

      when(() => service.getAllDeliveries(0, 10))
          .thenAnswer((_) async => deliveries);

      await notifier.fetchFirstPage();

      final updated = Delivery(
        id_delivery: 1,
        delivery_status: 'DELIVERED',
        delivery_package_count: deliveries.first.delivery_package_count,
        delivery_total_weight: deliveries.first.delivery_total_weight,
        delivery_address_id: deliveries.first.delivery_address_id,
        recipient_person: deliveries.first.recipient_person,
      );

      when(() => service.updateDelivery(any()))
          .thenAnswer((_) async => updated);

      await notifier.updateDelivery(updated);

      final stored = notifier.deliveries.firstWhere((d) => d.id_delivery == 1);
      expect(stored.delivery_status, 'DELIVERED');
    });

    test('calls service update', () async {
      final delivery = makeDelivery(1);

      when(() => service.updateDelivery(any()))
          .thenAnswer((_) async => delivery);

      await notifier.updateDelivery(delivery);

      verify(() => service.updateDelivery(delivery)).called(1);
    });
  });

  group('status optimized accessors', () {
    test('pending list accessor', () async {
      final deliveries = [
        makeDelivery(1, status: 'PENDING'),
        makeDelivery(2, status: 'DELIVERED'),
      ];

      when(() => service.getAllDeliveries(0, 10))
          .thenAnswer((_) async => deliveries);

      await notifier.fetchFirstPage();

      expect(notifier.pendingDeliveries.length, 1);
      expect(notifier.pendingDeliveries.first.id_delivery, 1);
    });

    test('delivered list accessor', () async {
      final deliveries = [
        makeDelivery(1, status: 'DELIVERED'),
        makeDelivery(2, status: 'PENDING'),
      ];

      when(() => service.getAllDeliveries(0, 10))
          .thenAnswer((_) async => deliveries);

      await notifier.fetchFirstPage();

      expect(notifier.deliveredDeliveries.length, 1);
      expect(notifier.deliveredDeliveries.first.id_delivery, 1);
    });
  });

  group('pagination end detection', () {
    test('marks hasMore false when empty page returned', () async {
      when(() => service.getAllDeliveries(0, 10)).thenAnswer((_) async => []);

      await notifier.fetchFirstPage();

      expect(notifier.hasMore, false);
      expect(notifier.deliveries.isEmpty, true);
    });

    test('marks hasMore true when full page returned', () async {
      final page1 = List.generate(10, (i) => makeDelivery(i + 1));

      when(() => service.getAllDeliveries(0, 10))
          .thenAnswer((_) async => page1);

      await notifier.fetchFirstPage();

      expect(notifier.hasMore, true);
      expect(notifier.deliveries.length, 10);
    });
  });
}
