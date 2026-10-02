import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:impl_mediation/impl_mediation.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate a mock class for Dio
@GenerateNiceMocks([MockSpec<Dio>()])
import './impl_mediation_test.mocks.dart';

void main() {
  late StorageServiceImpl storageService;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    storageService = StorageServiceImpl(dio: mockDio); // Inject mockDio
  });

  // Authentication API
  group('Authentication API', () {
    test('POST /authentication/token - success', () async {
      final requestBody = {
        "app_user_name": "testuser",
        "app_user_password": "securepassword"
      };
      final expectedResponse = {"token": "mock_token_123"};

      when(mockDio.post(
        '/authentication/token',
        data: requestBody,
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
        onSendProgress: anyNamed('onSendProgress'),
        onReceiveProgress: anyNamed('onReceiveProgress'),
      )).thenAnswer((_) async => Response(
            data: expectedResponse,
            statusCode: 200,
            requestOptions: RequestOptions(path: '/authentication/token'),
          ));

      final result = await storageService.signInUsingUsernameAndPassword(
          '/authentication/token', requestBody);
      expect(result, expectedResponse);
    });
  });

  // Supplier API
  group('Supplier API', () {
    test('PUT /supplier/add - success', () async {
      final supplierData = {
        "id_product_provider": 456,
        "provider_name": "New Supplier"
      };

      final expectedResponse = Response(
        statusCode: 201,
        requestOptions: RequestOptions(path: '/supplier/add'),
      );

      when(mockDio.post(
        '/supplier/add',
        data: supplierData, // Fixed: Removed JSON encoding
        options: anyNamed('options'),
      )).thenAnswer((_) async => Response(
            statusCode: 201,
            requestOptions: RequestOptions(path: '/supplier/add'),
          ));

      final result = await storageService.insert('/supplier/add', supplierData);
      expect(result, expectedResponse.statusCode);
    });
  });

  // User API
  group('User API', () {
    test('DELETE /appUser/delete - success', () async {
      when(mockDio.delete(
        '/appUser/delete', // Fixed: Ensured exact path
        data: anyNamed('data'),
        queryParameters: anyNamed('queryParameters'),
        options: anyNamed('options'),
        cancelToken: anyNamed('cancelToken'),
      )).thenAnswer((_) async => Response(
            statusCode: 204,
            requestOptions: RequestOptions(path: '/appUser/delete'),
          ));

      final result = await storageService.delete('/appUser/delete', '');
      expect(result, 204);
    });
  });
}
