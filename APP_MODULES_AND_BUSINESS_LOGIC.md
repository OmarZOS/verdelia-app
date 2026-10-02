# Verdelia App: Modules, Widgets, and Business Logic

This document summarizes the architecture of the Flutter monorepo, the main UI widgets, and the business logic that drives the app.

## 1. Application overview

The app is organized as a multi-package Flutter workspace with a shared core and several feature packages. The entry point is the launcher package:

- launcher/lib/main.dart
  - Configures dependency injection through AppLocator
  - Restores locale/theme state
  - Initializes authentication state
  - Registers all providers at the root
  - Starts the MaterialApp with generated routes and theming

The root app runs as a Provider-based state tree. The central setup is:

- `VerdeliaApp` creates a `MultiProvider` with state notifiers for products, cart, user, recipes, suppliers, delivery, notifications, orders, personnel, services, finance, pricing, and locale.
- `AppRouter.generateRoute` handles navigation and guards screens based on auth state.
- `HomePage` acts as the main shell for catalog, suppliers, recipes, games, and profile areas.

---

## 2. Module map

### 2.1 Core runtime and platform

#### launcher
- Purpose: app bootstrap, dependency registration, route setup, app-level theming.
- Entry file: `launcher/lib/main.dart`
- Responsibilities:
  - Creates all singleton services via `setupLocator()`
  - Restores saved locale/theme preferences
  - Initializes `AppUserNotifier`
  - Creates the root `MaterialApp` and route system

#### locator
- Purpose: lightweight service container abstraction.
- File: `locator/lib/locator.dart`
- Responsibilities:
  - central `GetIt` wrapper
  - registers singleton or factory dependencies
  - allows app-wide access to service implementations

#### app_constants
- Purpose: route constants and shared app config.
- Files:
  - `app_constants/lib/app_routes.dart`
  - `app_constants/lib/app_constants.dart`
- Responsibilities:
  - centralized route names
  - API endpoint constants
  - common app-level settings

#### verdelia_localizations
- Purpose: internationalization.
- Responsibilities:
  - Arabic, French, and English localization support
  - used by `LocaleProvider` and screens through `AppLocalizations`

#### verdelia_core
- Purpose: domain model and shared abstractions.
- Responsibilities:
  - business models like `Product`, `Order`, `Cart`, `Supplier`, `AppUser`, `Delivery`, `ProvidedService`
  - service contracts such as `ProductService`, `OrderService`, `CartService`, `SupplierService`, `DeliveryService`, `RecipeService`, `BusinessOperationService`
  - storage and persistence abstractions

### 2.2 State and UI orchestration

#### event
- Purpose: all stateful notifiers and UI view-model classes for the app.
- Main files:
  - `event/lib/user_change_notifier.dart` — authentication and user state
  - `event/lib/product_change_notifier.dart` — product catalog state and local cart operations
  - `event/lib/cart_change_notifier.dart` — cart orchestration and filtering
  - `event/lib/order_change_notifier.dart` — order flow state
  - `event/lib/recipe_change_notifier.dart` — recipe management state
  - `event/lib/supplier_change_notifier.dart` — supplier/provider state
  - `event/lib/delivery_change_notifier.dart` — delivery list and provider-based loading
  - `event/lib/service_change_notifier.dart` — service management
  - `event/lib/personnel_notifier.dart` — supplier personnel / management state
  - `event/lib/notification_notifier.dart` — notifications
  - `event/lib/finance_change_notifier.dart` — finance operations and calculations
  - `event/lib/views/checkout_view_model.dart` — checkout state
  - `event/lib/views/finance_view_model.dart` — finance dashboard state
  - `event/lib/preferenceChangeNotifier.dart` — locale/theme persistence
- Responsibilities:
  - central state management layer for the app
  - wraps service interactions and exposes UI-friendly state
  - tracks async loading, errors, pagination, and cache handling

#### business
- Purpose: concrete business services that interact with storage and the API layer.
- Main files:
  - `business/lib/verdelia_impl_product.dart`
  - `business/lib/verdelia_impl_order.dart`
  - `business/lib/verdelia_impl_cart.dart`
  - `business/lib/verdelia_impl_recipe.dart`
  - `business/lib/verdelia_impl_supplier.dart`
  - `business/lib/verdelia_impl_delivery.dart`
  - `business/lib/verdelia_impl_service.dart`
  - `business/lib/finance/business_operation.dart`
  - `business/lib/finance/verdelia_impl_invoice.dart`
- Responsibilities:
  - implement service contracts from `verdelia_core`
  - call external or mediated storage APIs
  - translate backend payloads into domain objects
  - persist traceable response metadata for debugging and auditability

#### impl_app and impl_mediation
- Purpose: concrete app-layer implementations and persistence adapters.
- `impl_app/lib/impl_auth.dart` and `impl_app/lib/impl_app.dart`
  - implement `AuthService` and `AppUserService`
- `impl_mediation/lib/impl_mediation.dart`
  - provides `StorageServiceImpl`, the transport layer for API requests
- Responsibilities:
  - handle auth tokens, REST calls, persistence, and response handling

#### io
- Purpose: infrastructure implementations for file/image handling.
- `io/VerdeliaImageImpl.dart`
- Responsibilities:
  - image upload / file handling abstraction

### 2.3 Feature modules

#### login
- Purpose: login, guest sign-in, Google sign-in, registration, web auth views.
- Main screens:
  - `login/lib/screens/login_screen.dart`
  - `login/lib/screens/registration_screen.dart`
  - `login/lib/screens/web_view.dart`
- Business logic:
  - `AppUserNotifier.signInWithUsernameAndPassword()`
  - `signInAsGuest()`
  - token and session restoration through auth persistence

#### product_catalog
- Purpose: product browsing, search, category filtering, product create/edit, product details, orders and cart entry.
- Main screens:
  - `product_catalog/lib/screens/product_catalog_screen.dart`
  - `product_catalog/lib/screens/product_form_screen.dart`
  - `product_catalog/lib/screens/product_screen.dart`
  - `product_catalog/lib/screens/cart_screen.dart`
  - `product_catalog/lib/screens/orders_screen.dart`
  - `product_catalog/lib/screens/iproduct_details_screen.dart`
- Business logic:
  - `ProductNotifier` fetches products with caching, pagination, and searches
  - `CartChangeNotifier` handles add/remove/update quantity for product and services

#### provider_store
- Purpose: business selling / checkout / dashboard flow for supplier-side commerce.
- Main screens:
  - `provider_store/lib/screens/dashboard_screen.dart`
  - `provider_store/lib/screens/checkout_screen.dart`
  - `provider_store/lib/screens/service_details_screen.dart`
  - `provider_store/lib/screens/services_screen.dart`
- UI orchestration:
  - selling point components, cart summary, item grids, checkout flow
  - service form screen for provided service creation

#### recipe_catalog
- Purpose: recipe creation, ingredient management, recipe catalog.
- Main screens:
  - `recipe_catalog/lib/screens/recipe_catalog_screen.dart`
  - `recipe_catalog/lib/screens/recipe_form_screen.dart`
  - `recipe_catalog/lib/screens/ingredient_management_screen.dart`
- Business logic:
  - `RecipeNotifier` manages recipe-related operations and UI state

#### provider_geo
- Purpose: supplier map and location-based provider management.
- Main screens:
  - `provider_geo/screens/suppliers_map_screen.dart`
  - `provider_geo/screens/supplier_form_page.dart`
- Business logic:
  - supplier search and map-related provider state

#### provider_personnel
- Purpose: supplier management dashboard, personnel assignments, privileges.
- Main screens:
  - `provider_personnel/lib/personnel_management_screen.dart`
  - `provider_personnel/lib/supplier_entities_screen.dart`
- Business logic:
  - `PersonnelNotifier`, supplier dashboards, user invite/management flow

#### scanner
- Purpose: barcode and QR scanning.
- Main screens:
  - `scanner/lib/screens/barcode_scanner.dart`
  - `scanner/lib/screens/qr_scanner.dart`
  - `scanner/lib/screens/product_scanner.dart`
- Responsibilities:
  - scan product or QR data and route into product-detail workflows

#### tabbed_home
- Purpose: app shell and global navigation.
- Main file:
  - `tabbed_home/lib/verdelia_router.dart`
  - `tabbed_home/lib/screens/home_screen.dart`
- Responsibilities:
  - navigation guard logic
  - home shell with tab navigation
  - notification panel and profile entry points

#### ui
- Purpose: shared UI components, forms, and presentation helpers reused by multiple modules.
- Examples:
  - `ui/components/organisation_picker.dart`
  - `ui/components/document/DocumentTypeManager.dart`
  - `ui/SupplierProductCard.dart`

#### health and verdelia_play
- Purpose: extra feature packages.
- `health` contains medical or wellbeing screens.
- `verdelia_play` contains game catalog / playful UI examples.

---

## 3. Main widgets and how they fit together

### 3.1 Root application

#### `VerdeliaApp`
Located in `launcher/lib/main.dart`.

Responsibilities:
- Creates the global `MultiProvider` list.
- Supplies state notifiers to the whole app.
- Sets locales and localizations.
- Builds the root `MaterialApp`.
- Uses `AppRouter.generateRoute` to route the app.

#### `AppRouter`
Located in `tabbed_home/lib/verdelia_router.dart`.

Flow:
- Reads `AppUserNotifier` from the provider tree.
- Checks `isAuthenticated`.
- For protected routes, shows the authorized screen or redirects to a fallback unauthorized screen.
- Routes include:
  - home
  - login
  - registration
  - product create
  - recipe create
  - cart
  - orders
  - supplier management
  - product scan / QR scan
  - image upload
  - service form

### 3.2 Home shell

#### `HomePage`
Located in `tabbed_home/lib/screens/home_screen.dart`.

Responsibilities:
- Hosts the primary tabbed app shell.
- Builds the list of main pages:
  - `ProductCatalogScreen`
  - `SuppliersMapScreen`
  - `RecipeCatalogScreen`
  - `GameSelectionScreen`
  - `ProfileScreen`
- Handles tab tap logic through `_handlePageSpecificLogic()`.
- Refreshes product lists when the catalog tab is selected.
- Triggers supplier fetch when the supplier tab is selected.
- Shows notification modal bottom sheet.

### 3.3 Catalog flow

#### `ProductCatalogScreen`
Located in `product_catalog/lib/screens/product_catalog_screen.dart`.

Responsibilities:
- Displays product list with search and category filtering.
- Uses `ProductNotifier` as the controller.
- Debounces search input.
- Loads products on init and on pagination threshold.
- Provides actions for:
  - scanning a barcode
  - adding a product
  - navigating to orders
  - navigating to cart

Flow:
1. `initState()` attaches listeners and triggers initial fetch.
2. `_onSearchChanged()` debounces the search text.
3. `_filterProducts()` calls `ProductNotifier.searchProducts()`.
4. `_selectCategory()` clears the search if needed and refetches by category.
5. `_scrollListener()` loads more results when near the end.
6. `_refreshProducts()` invalidates cache and reloads the list.

### 3.4 Auth flow

#### `LoginScreen`
Located in `login/lib/screens/login_screen.dart`.

Responsibilities:
- Handles username/password sign-in.
- Supports guest login.
- Supports Google login flow.
- Shows loading states and validation messages.
- Uses `AppUserNotifier` to authenticate.

Flow:
1. Form validates.
2. `_submit()` calls `signInWithUsernameAndPassword()` on `AppUserNotifier`.
3. Response is evaluated via `ResponseHandler`.
4. On success, the app schedules navigation to the home route.
5. `AppUserNotifier` restores tokens and user state at startup.

### 3.5 Dashboard and provider management

#### `DashboardScreen`
Located in `provider_store/lib/screens/dashboard_screen.dart`.

Responsibilities:
- Loads the current app user.
- Fetches suppliers and personnel data during init.
- Uses `DashboardContent` to render the dashboard shell.

#### `PersonnelManagementScreen`
Located in `provider_personnel/lib/personnel_management_screen.dart`.

Responsibilities:
- Displays supplier personnel and access management pages.
- Handles tabulated management content for invites, users, suppliers, and pending actions.

---

## 4. Business logic architecture

### 4.1 Dependency injection and service layer

The app uses `AppLocator` to register services at startup in `launcher/lib/main.dart`:

- `StorageServiceImpl`
- `AppUserServiceImpl`
- `DeliveryServiceImpl`
- `RecipeServiceImpl`
- `SupplierServiceImpl`
- `NotificationImpl`
- `ProductServiceImpl`
- `OrderServiceImpl`
- `CartServiceImpl`
- `AuthServiceImpl`
- `ProvidedServiceManagementImpl`
- `BusinessOperationServiceImpl`
- `InvoiceServiceImpl`

This acts as the root of the business service graph. All state notifiers pull from these services through the locator.

### 4.2 Authentication logic

#### `AppUserNotifier`
Located in `event/lib/user_change_notifier.dart`.

This is the central auth state manager. It encapsulates several subcomponents:

- `AuthState`: stores token, refresh token, user, expiry, auth flags.
- `AuthPersistence`: loads and saves auth info.
- `AuthResponseManager`: tracks success/failure responses and operation keys.
- `AuthTokenManager`: handles refresh and token validation.
- `AuthUserManager`: fetches and stores user information.
- `AuthCrudManager`: handles create/update/delete user operations.

Main flow:
1. `initializeAuthState()` loads saved data from persistence.
2. It restores user and token information.
3. It checks if token is expired or close to expiry.
4. If needed, it refreshes the token.
5. If the state is valid, `isAuthenticated` becomes true.
6. If refresh fails, the app clears the session.

This is the app’s real authentication backbone.

### 4.3 Product logic

#### `ProductService`
Contract in `verdelia_core/lib/business/services/ProductService.dart`.

Concrete implementation:
- `ProductServiceImpl` in `business/lib/verdelia_impl_product.dart`

Functionality:
- add product
- update product
- delete product
- get product by id
- list products with filters and pagination
- search products by keyword
- cache-aware retrieval patterns

#### `ProductNotifier`
Located in `event/lib/product_change_notifier.dart`.

This aggregator wraps several product-oriented components:

- `ProductState` — central product state
- `ProductCache` — caching for product lists and product details
- `ProductCrud` — create/update/delete product operations
- `ProductFetch` — fetch list and detail operations
- `ProductCart` — cart-like local quantities for product selection
- `ProductSupplier` — supplier-scoped fetch logic
- `ProductPolling` — polling updates to product entities

Main behavior:
- fetches products initially and on category/search changes
- supports supplier filtering and product cache invalidation
- provides local cart quantity tracking
- can trigger refresh after successful order creation

### 4.4 Cart and ordering logic

#### `CartService`
Located in `verdelia_core/lib/business/services/CartService.dart`.

Concrete implementation:
- `CartServiceImpl` in `business/lib/verdelia_impl_cart.dart`

Responsibilities:
- fetch carts by filters
- fetch cart by id
- add/update/delete cart
- get cart details and ordered items

#### `CartChangeNotifier`
Located in `event/lib/cart_change_notifier.dart`.

This is the app’s cart orchestrator.

Key responsibilities:
- local cart state for products and services
- track product/service items and quantities
- calculate subtotal and total amount
- support filters (`CartFilter`)
- support add/remove/update operations
- sync with API carts if needed

Business rules in the cart model include:
- add product or service item by type
- quantity validation and removal when quantity drops to zero
- scheduled service dates and times
- product/service distinction for filtering and summary

### 4.5 Order flow

#### `OrderService`
Contract in `verdelia_core/lib/business/services/OrderService.dart`.

Implementation:
- `OrderServiceImpl` in `business/lib/verdelia_impl_order.dart`

Responsibilities:
- add order
- get order details
- list orders by user
- update order state
- delete order

The notifier layer (`OrderChangeNotifier`) is the UI-facing state container for order operations and list refreshes.

Typical app flow:
1. user adds products/services to cart
2. checkout screen collects financial and delivery information
3. order is created using `OrderService`
4. product inventory and cart state are refreshed
5. confirmation is shown and product catalog may be invalidated

### 4.6 Supplier and provider logic

#### `SupplierService`
Contract in `verdelia_core/lib/business/services/SupplierService.dart`.

Implementation:
- `SupplierServiceImpl` in `business/lib/verdelia_impl_supplier.dart`

Responsibilities:
- fetch supplier profiles and organization details
- manage supplier records and provider relationships
- support supplier search and dashboard state

#### `SupplierChangeNotifier`
Located in `event/lib/supplier_change_notifier.dart`.

Responsibilities:
- loads suppliers and organizations
- matches product providers to known companies
- supports provider filtering and dashboard views

This state feeds screens such as `SuppliersMapScreen`, `SupplierFormScreen`, and the provider dashboard.

### 4.7 Delivery and logistics logic

#### `DeliveryService`
Contract in `verdelia_core/lib/business/services/DeliveryService.dart`.

Implementation:
- `DeliveryServiceImpl` in `business/lib/verdelia_impl_delivery.dart`

Responsibilities:
- fetch deliveries by provider/order/broker/query
- support pagination and filtering
- map backend responses into `Delivery` models

#### `DeliveryChangeNotifier`
Located in `event/lib/delivery_change_notifier.dart`.

Responsibilities:
- provider-aware loading
- query-based filtering
- caching based on page and search parameters
- item pagination and state tracking

### 4.8 Finance and billing logic

The app includes finance-related services and notifiers:

- `BusinessOperationService`
- `InvoiceService`
- `FinanceChangeNotifier`
- `FinanceViewModel`
- `CheckoutViewModel`

Responsibilities:
- invoice generation and wallet / finance metadata
- business operation calculations
- checkout totals and payment metadata
- connected finance dashboard reporting

Core process:
1. cart items are summarized
2. checkout view model computes values and document info
3. finance service generates or validates business operation records
4. order and invoice data are stored and shown in UI

### 4.9 Notifications and local state

`NotificationNotifier` and `NotificationService` manage low-level app notifications and user-facing actions.

The home page also uses a `NotificationsPanel` widget, which is a UI surface on top of this notifier layer.

### 4.10 Locale and theme logic

#### `LocaleProvider`
Located in `event/lib/preferenceChangeNotifier.dart`.

Responsibilities:
- load saved locale preference
- load saved theme preference
- update locale/theme on user action
- notify the app to rebuild UI after preference change

This provider is included in the `VerdeliaApp` state tree so language and theme are global.

---

## 5. High-level runtime flow

The app follows this general architecture:

1. `main()` runs.
2. `setupLocator()` registers all services.
3. `LocaleProvider` loads saved locale/theme.
4. `AppUserNotifier.initializeAuthState()` restores login status and token state.
5. `AppRouter` checks auth state for each route.
6. `HomePage` renders the shell with catalog, suppliers, recipes, games, and profile.
7. Feature screens consume notifiers from `Provider`.
8. Notifiers call service implementations from the locator.
9. Service implementations call `StorageServiceImpl` for persistence and backend requests.
10. Domain models are parsed and returned to the UI.
11. UI updates trigger rebuilds and refreshes through `notifyListeners()`.

---

## 6. Architectural patterns used in the app

This project uses a hybrid architecture built on a few strong patterns:

- Provider state management for global app state
- Service locator via GetIt
- Repository-like service implementations for persistence and API calls
- Domain models in `verdelia_core`
- Feature packages organized by responsibility
- Screen-level state and notifier-driven UI composition
- Traceable service responses using caller keys and stored success/failure metadata

This is a clean modular structure for a mid-sized Flutter application, with a clear separation between:

- model layer (`verdelia_core`)
- data / API implementation (`business`, `impl_app`, `impl_mediation`)
- state layer (`event`)
- UI layer (`login`, `product_catalog`, `provider_store`, `tabbed_home`, etc.)

---

## 7. Summary

The app is a modular Flutter monorepo centered around:

- `launcher` for bootstrapping
- `verdelia_core` for domain contracts/models
- `business` for implementation of business services
- `event` for state management / view models
- feature packages for login, catalog, recipes, suppliers, dashboards, scanning, and selling flows

The main business logic is driven by:

- authentication state (`AppUserNotifier`)
- product catalog (`ProductNotifier`)
- local and API cart state (`CartChangeNotifier`)
- order processing (`OrderService` + notifier layer)
- supplier and personnel logic
- delivery and finance processing
- locale/theme persistence via `LocaleProvider`

This makes the app very modular while still allowing global data and route access through `Provider` and the locator container.
