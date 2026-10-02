

# Verdelia Localiser

The `Verdelia Localiser` is a Flutter-based application package that enables users to view and manage the locations of suppliers on an interactive map. This package integrates with Google Maps, allowing users to search for suppliers, filter results, and view detailed information about each supplier.

## Features

- **Google Maps Integration**: Displays supplier locations with interactive markers.
- **Search and Filter**: Quickly find suppliers by name or other details.
- **Dynamic Markers**: Markers on the map update automatically based on the search results.
- **Supplier Details**: View additional details about a supplier, including contact information and location.
- **Sliding Panel**: Provides a smooth and intuitive way to display a list of suppliers alongside the map.

## Getting Started

### Prerequisites

To use `Verdelia Localiser`, ensure you have the following set up:

- **Flutter SDK**: Version 3.0.0 or higher.
- **Google Maps API Key**: Required for integrating Google Maps. [Get a key here](https://developers.google.com/maps/documentation/embed/get-api-key).

### Installation

Add the package dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_maps_flutter: ^2.1.2
  provider: ^6.0.5
```

### Setup

1. **Google Maps Configuration**:
   Add your Google Maps API key to the `AndroidManifest.xml` and `AppDelegate.swift` as per [Google Maps Flutter Setup](https://pub.dev/packages/google_maps_flutter).

2. **Provider Integration**:
   Wrap your app or widget tree with a `ChangeNotifierProvider` to manage state:

   ```dart
   import 'package:provider/provider.dart';
   import 'supplier_change_notifier.dart';

   void main() {
     runApp(
       MultiProvider(
         providers: [
           ChangeNotifierProvider(
             create: (_) => SupplierChangeNotifier()..loadSuppliers(),
           ),
         ],
         child: MyApp(),
       ),
     );
   }
   ```

3. **Interactive Map and Sliding Panel**:
   Use the `SlidingSuppliersWidget` in your app to display the supplier list and map:

   ```dart
   import 'package:flutter/material.dart';
   import 'sliding_suppliers_widget.dart';

   class MyApp extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return MaterialApp(
         home: SlidingSuppliersWidget(),
       );
     }
   }
   ```

## Usage

- **Search Suppliers**: Use the search bar at the top to filter the supplier list.
- **View on Map**: Click a supplier's location icon to focus on its position on the map.
- **Detailed Information**: Tap on a supplier to view its details in a popup.


## Contributions

Contributions to enhance the package are welcome! Feel free to open issues or submit pull requests.



## Acknowledgments

- Google Maps for providing robust mapping functionality.
- The Flutter and Dart community for supporting a modern development ecosystem.

