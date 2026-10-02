# Verdelia Home

Verdelia Home is the central Flutter application that integrates multiple modules and packages to deliver a cohesive experience for users. This application is designed for managing products, recipes, medical data, localization, and other features related to the Verdelia ecosystem.

---

## Features

1. **Product Management**:
   - Add, update, and delete products.
   - View and search products through a catalog.
   
2. **Recipe Management**:
   - Add and manage recipes, including ingredients and steps.

3. **Medical Integration**:
   - Handle medical data relevant to the user base.

4. **Localization Support**:
   - Multilingual support including English, French, and Arabic.

5. **Authentication**:
   - Login and registration system with validation.

6. **Catalog and Supplier Management**:
   - Comprehensive catalog management and supplier details integration.

---

## Packages and Dependencies

The application uses the following custom packages and modules:

### Core Packages
- **locator**: Handles dependency injection and service location.
- **verdelia_core**: Core business logic and shared utilities.
- **app_constants**: Centralized constants and localization files.

### Feature-Specific Packages
- **impl_app**: Application-level implementation details.
- **business**: Business logic specific to Verdelia.
- **impl_mediation**: Handles communication between different modules.
- **recipe_catalog**: Module for managing recipe_catalogs and related data.
- **health**: Manages medical-related functionality and data.
- **provider_geo**: Localization handling and location-based services.
- **product_catalog**: Catalog management, including product browsing and supplier details.
- **verdelia_play**: Entertainment and gamification features.
- **login**: User authentication and login system.

---

## Installation

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.10 or higher)
- Dart SDK

### Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/OmarZos/verdelia-app.git
   ```

2. Navigate to the project directory:
   ```bash
   cd tabbed_home
   ```

3. Fetch dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app:
   ```bash
   flutter run
   ```

---

## Project Structure

```plaintext
├── lib
│   ├── main.dart        # Application entry point
│   ├── screens          # UI screens and widgets
│   ├── models           # Data models
│   ├── services         # Backend and API services
│   └── utils            # Utility functions and helpers
├── assets
│   ├── images           # Static image assets
│   ├── translations     # ARB files for localization
├── pubspec.yaml         # Flutter dependencies
└── README.md            # Project documentation
```

---

## Localization

The application supports multiple languages using ARB files stored in the `assets/translations` directory. Current languages:
- English (`en.arb`)
- French (`fr.arb`)
- Arabic (`ar.arb`)

### Adding a New Language
1. Create a new ARB file in `assets/translations` (e.g., `es.arb` for Spanish).
2. Add translations for all keys present in `en.arb`.
3. Update the supported locales in the app configuration.

---

## Contribution

1. Fork the repository.
2. Create a feature branch:
   ```bash
   git checkout -b feature-name
   ```
3. Commit your changes and push to the branch:
   ```bash
   git commit -m "Add new feature"
   git push origin feature-name
   ```
4. Create a pull request for review.

---

## License
This project is licensed under the [MIT License](LICENSE).

---

## Contact
For any inquiries, reach out at [support@verdelia.com](mailto:support@verdelia.com).

