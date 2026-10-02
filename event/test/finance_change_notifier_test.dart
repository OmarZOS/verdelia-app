// import 'package:flutter_test/flutter_test.dart';
// import 'package:mocktail/mocktail.dart';
// import 'package:locator/locator.dart';

// import 'package:event/finance_change_notifier.dart';
// import 'package:verdelia_core/business/finance/services/InvoiceService.dart';
// import 'package:verdelia_core/business/finance/FinancialDocument.dart';

// class MockInvoiceService extends Mock implements InvoiceService {}

// void main() {
//   late FinanceChangeNotifier notifier;
//   late MockInvoiceService mockService;

//   setUp(() {
//     mockService = MockInvoiceService();

//     AppLocator.reset();
//     AppLocator.register<InvoiceService>(() => mockService);

//     notifier = FinanceChangeNotifier();
//   });

//   group('Initial state', () {
//     test('starts empty', () {
//       expect(notifier.documents.isEmpty, true);
//       expect(notifier.totalRevenue, 0);
//       expect(notifier.totalTransactions, 0);
//     });
//   });

//   group('Fetch documents', () {
//     test('fetchDocuments loads documents', () async {
//       final docs = [
//         FinancialDocument(
//           documentId: 1,
//           sourceId: 1,
//           documentType: "invoice",
//           documentAmount: 100,
//           totalPaid: 50,
//           outstandingBalance: 50,
//           paymentStatus: "partially_paid",
//           issueDate: DateTime.now(),
//         ),
//         FinancialDocument(
//           documentId: 2,
//           sourceId: 2,
//           documentType: "invoice",
//           documentAmount: 200,
//           totalPaid: 200,
//           outstandingBalance: 0,
//           paymentStatus: "paid",
//           issueDate: DateTime.now(),
//         ),
//       ];

//       when(() => mockService.getAllFinanceDocs(
//             any(),
//             any(),
//             supplierId: any(named: 'supplierId'),
//             personId: any(named: 'personId'),
//             clientId: any(named: 'clientId'),
//             sellerId: any(named: 'sellerId'),
//             cartId: any(named: 'cartId'),
//             orderId: any(named: 'orderId'),
//             depositId: any(named: 'depositId'),
//             invoiceId: any(named: 'invoiceId'),
//           )).thenAnswer((_) async => docs);

//       await notifier.fetchDocuments();

//       expect(notifier.documents.length, 2);
//       expect(notifier.totalRevenue, 300);
//     });
//   });

//   group('Analytics', () {
//     test('calculates revenue and collected amounts', () async {
//       final docs = [
//         FinancialDocument(
//           documentId: 1,
//           sourceId: 1,
//           documentType: "invoice",
//           documentAmount: 100,
//           totalPaid: 50,
//           outstandingBalance: 50,
//           paymentStatus: "partial",
//           issueDate: DateTime.now(),
//         ),
//         FinancialDocument(
//           documentId: 2,
//           sourceId: 2,
//           documentType: "invoice",
//           documentAmount: 200,
//           totalPaid: 200,
//           outstandingBalance: 0,
//           paymentStatus: "paid",
//           issueDate: DateTime.now(),
//         ),
//       ];

//       when(() => mockService.getAllFinanceDocs(
//             any(),
//             any(),
//             supplierId: any(named: 'supplierId'),
//             personId: any(named: 'personId'),
//             clientId: any(named: 'clientId'),
//             sellerId: any(named: 'sellerId'),
//             cartId: any(named: 'cartId'),
//             orderId: any(named: 'orderId'),
//             depositId: any(named: 'depositId'),
//             invoiceId: any(named: 'invoiceId'),
//           )).thenAnswer((_) async => docs);

//       await notifier.fetchDocuments();

//       expect(notifier.totalRevenue, 300);
//       expect(notifier.totalCollected, 250);
//       expect(notifier.totalOutstanding, 50);
//       expect(notifier.totalTransactions, 2);
//     });

//     test('collection rate calculation', () async {
//       final docs = [
//         FinancialDocument(
//           documentId: 1,
//           sourceId: 1,
//           documentType: "invoice",
//           documentAmount: 100,
//           totalPaid: 50,
//           outstandingBalance: 50,
//           paymentStatus: "partial",
//           issueDate: DateTime.now(),
//         ),
//       ];

//       when(() => mockService.getAllFinanceDocs(
//             any(),
//             any(),
//             supplierId: any(named: 'supplierId'),
//             personId: any(named: 'personId'),
//             clientId: any(named: 'clientId'),
//             sellerId: any(named: 'sellerId'),
//             cartId: any(named: 'cartId'),
//             orderId: any(named: 'orderId'),
//             depositId: any(named: 'depositId'),
//             invoiceId: any(named: 'invoiceId'),
//           )).thenAnswer((_) async => docs);

//       await notifier.fetchDocuments();

//       expect(notifier.collectionRate, 50);
//     });
//   });

//   group('Filters', () {
//     test('filter by document type', () async {
//       final docs = [
//         FinancialDocument(
//           documentId: 1,
//           sourceId: 1,
//           documentType: "invoice",
//           documentAmount: 100,
//           issueDate: DateTime.now(),
//         ),
//         FinancialDocument(
//           documentId: 2,
//           sourceId: 2,
//           documentType: "receipt",
//           documentAmount: 50,
//           issueDate: DateTime.now(),
//         ),
//       ];

//       when(() => mockService.getAllFinanceDocs(
//             any(),
//             any(),
//             supplierId: any(named: 'supplierId'),
//             personId: any(named: 'personId'),
//             clientId: any(named: 'clientId'),
//             sellerId: any(named: 'sellerId'),
//             cartId: any(named: 'cartId'),
//             orderId: any(named: 'orderId'),
//             depositId: any(named: 'depositId'),
//             invoiceId: any(named: 'invoiceId'),
//           )).thenAnswer((_) async => docs);

//       await notifier.fetchDocuments();

//       notifier.setFilter(
//         const FinanceDocumentFilter(documentType: "invoice"),
//       );

//       expect(notifier.filteredDocuments.length, 1);
//     });
//   });

//   group('Statistics', () {
//     test('totalAmount returns correct value', () async {
//       final docs = [
//         FinancialDocument(
//           documentId: 1,
//           sourceId: 1,
//           documentType: "invoice",
//           documentAmount: 100,
//           issueDate: DateTime.now(),
//         ),
//         FinancialDocument(
//           documentId: 2,
//           sourceId: 2,
//           documentType: "invoice",
//           documentAmount: 200,
//           issueDate: DateTime.now(),
//         ),
//       ];

//       when(() => mockService.getAllFinanceDocs(
//             any(),
//             any(),
//             supplierId: any(named: 'supplierId'),
//             personId: any(named: 'personId'),
//             clientId: any(named: 'clientId'),
//             sellerId: any(named: 'sellerId'),
//             cartId: any(named: 'cartId'),
//             orderId: any(named: 'orderId'),
//             depositId: any(named: 'depositId'),
//             invoiceId: any(named: 'invoiceId'),
//           )).thenAnswer((_) async => docs);

//       await notifier.fetchDocuments();

//       expect(notifier.totalAmount, 300);
//     });
//   });

//   group('Cache', () {
//     test('clearCache resets state', () async {
//       final docs = [
//         FinancialDocument(
//           documentId: 1,
//           sourceId: 1,
//           documentType: "invoice",
//           documentAmount: 100,
//           issueDate: DateTime.now(),
//         ),
//       ];

//       when(() => mockService.getAllFinanceDocs(
//             any(),
//             any(),
//             supplierId: any(named: 'supplierId'),
//             personId: any(named: 'personId'),
//             clientId: any(named: 'clientId'),
//             sellerId: any(named: 'sellerId'),
//             cartId: any(named: 'cartId'),
//             orderId: any(named: 'orderId'),
//             depositId: any(named: 'depositId'),
//             invoiceId: any(named: 'invoiceId'),
//           )).thenAnswer((_) async => docs);

//       await notifier.fetchDocuments();

//       notifier.clearCache();

//       expect(notifier.documents.isEmpty, true);
//       expect(notifier.totalRevenue, 0);
//     });
//   });
// }
