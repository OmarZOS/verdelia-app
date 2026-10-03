import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Verdelia'**
  String get appName;

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Verdelia!'**
  String get welcomeMessage;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again later.'**
  String get errorOccurred;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products to display.'**
  String get noProductsFound;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addToCart;

  /// No description provided for @aboutProvider.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutProvider;

  /// No description provided for @productQuantity.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get productQuantity;

  /// No description provided for @productReference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get productReference;

  /// No description provided for @priceText.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceText;

  /// No description provided for @noAppUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noAppUsersFound;

  /// No description provided for @successfullLoginMsg.
  ///
  /// In en, this message translates to:
  /// **'Successfully signed up.'**
  String get successfullLoginMsg;

  /// No description provided for @welcomeBackMsg.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBackMsg;

  /// No description provided for @loginText.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginText;

  /// No description provided for @pleaseLoginMsg.
  ///
  /// In en, this message translates to:
  /// **'Please login to your account'**
  String get pleaseLoginMsg;

  /// No description provided for @pleaseInputUsernameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username'**
  String get pleaseInputUsernameMsg;

  /// No description provided for @pleaseInputPasswordMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseInputPasswordMsg;

  /// No description provided for @passwordLengthConstraintMsg.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordLengthConstraintMsg;

  /// No description provided for @suggestRegistrationMsg.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get suggestRegistrationMsg;

  /// No description provided for @suggest3rdPartyLogintMsg.
  ///
  /// In en, this message translates to:
  /// **'Or login with'**
  String get suggest3rdPartyLogintMsg;

  /// No description provided for @pleaseInputusernameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get pleaseInputusernameMsg;

  /// No description provided for @pleaseInputpasswordMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get pleaseInputpasswordMsg;

  /// No description provided for @pleaseInputUserTypeMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a user type'**
  String get pleaseInputUserTypeMsg;

  /// No description provided for @pleaseInputFirstNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a first name'**
  String get pleaseInputFirstNameMsg;

  /// No description provided for @pleaseInputLastNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a last name'**
  String get pleaseInputLastNameMsg;

  /// No description provided for @pleaseInputBirthdateMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select your birthdate'**
  String get pleaseInputBirthdateMsg;

  /// No description provided for @pleaseInputLocationNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please input location name'**
  String get pleaseInputLocationNameMsg;

  /// No description provided for @pleaseInputgenderMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get pleaseInputgenderMsg;

  /// No description provided for @pleaseInputnationalityMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a nationality'**
  String get pleaseInputnationalityMsg;

  /// No description provided for @pleaseInputBloodTypeMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a blood type'**
  String get pleaseInputBloodTypeMsg;

  /// No description provided for @pleaseInputCountryMsg.
  ///
  /// In en, this message translates to:
  /// **'Please select a country'**
  String get pleaseInputCountryMsg;

  /// No description provided for @birthdayText.
  ///
  /// In en, this message translates to:
  /// **'Birthdate'**
  String get birthdayText;

  /// No description provided for @loginSuccessfullMsg.
  ///
  /// In en, this message translates to:
  /// **'Successfully signed up.'**
  String get loginSuccessfullMsg;

  /// No description provided for @registerText.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerText;

  /// No description provided for @registerationFormText.
  ///
  /// In en, this message translates to:
  /// **'Registration Form'**
  String get registerationFormText;

  /// No description provided for @usernameText.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameText;

  /// No description provided for @passwordText.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordText;

  /// No description provided for @userTypeText.
  ///
  /// In en, this message translates to:
  /// **'User Type'**
  String get userTypeText;

  /// No description provided for @firstNameText.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstNameText;

  /// No description provided for @lastNameText.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastNameText;

  /// No description provided for @genderText.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get genderText;

  /// No description provided for @nationalityText.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationalityText;

  /// No description provided for @bloodTypeText.
  ///
  /// In en, this message translates to:
  /// **'Blood Type'**
  String get bloodTypeText;

  /// No description provided for @latitudeText.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeText;

  /// No description provided for @longitudeText.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeText;

  /// No description provided for @locationNameText.
  ///
  /// In en, this message translates to:
  /// **'Location Name'**
  String get locationNameText;

  /// No description provided for @locationText.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationText;

  /// No description provided for @myLocationText.
  ///
  /// In en, this message translates to:
  /// **'My Location'**
  String get myLocationText;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @mapNotAvailableText.
  ///
  /// In en, this message translates to:
  /// **'Map actually not available on this device'**
  String get mapNotAvailableText;

  /// No description provided for @pdfNotSupportedOnWeb.
  ///
  /// In en, this message translates to:
  /// **'PDF files are not supported on web. Please use a mobile device.'**
  String get pdfNotSupportedOnWeb;

  /// No description provided for @registrationConditionsText.
  ///
  /// In en, this message translates to:
  /// **'Conditions of registration'**
  String get registrationConditionsText;

  /// No description provided for @streetText.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get streetText;

  /// No description provided for @cityText.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityText;

  /// No description provided for @postalCodeText.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCodeText;

  /// No description provided for @countryText.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryText;

  /// No description provided for @clientText.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get clientText;

  /// No description provided for @genderTextList.
  ///
  /// In en, this message translates to:
  /// **'Male,Female,Other'**
  String get genderTextList;

  /// No description provided for @nationalityTextList.
  ///
  /// In en, this message translates to:
  /// **'Algerian,Other'**
  String get nationalityTextList;

  /// No description provided for @missingText.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get missingText;

  /// No description provided for @productdeletionConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product?'**
  String get productdeletionConfirmationMessage;

  /// No description provided for @cartAddConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm Add to Cart'**
  String get cartAddConfirmationMessage;

  /// No description provided for @updateProductText.
  ///
  /// In en, this message translates to:
  /// **'Update Product'**
  String get updateProductText;

  /// No description provided for @pleaseInputProductNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name'**
  String get pleaseInputProductNameMsg;

  /// No description provided for @pleaseInputProductPriceMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product price'**
  String get pleaseInputProductPriceMsg;

  /// No description provided for @pleaseInputProductBrandMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product brand'**
  String get pleaseInputProductBrandMsg;

  /// No description provided for @pleaseInputProductBarcodeMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product bar code'**
  String get pleaseInputProductBarcodeMsg;

  /// No description provided for @pleaseInputvalidnumberMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseInputvalidnumberMsg;

  /// No description provided for @pleaseInputProductDescriptionMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product description'**
  String get pleaseInputProductDescriptionMsg;

  /// No description provided for @pleaseInputProductQuantityMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a product amount'**
  String get pleaseInputProductQuantityMsg;

  /// No description provided for @instructionsText.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsText;

  /// No description provided for @numberConstraintMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number between 0 and 999999'**
  String get numberConstraintMsg;

  /// No description provided for @productQuantityText.
  ///
  /// In en, this message translates to:
  /// **'Product Amount'**
  String get productQuantityText;

  /// No description provided for @productDescriptionText.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescriptionText;

  /// No description provided for @descriptionCharacterConstraintMsg.
  ///
  /// In en, this message translates to:
  /// **'Character limit: 300.'**
  String get descriptionCharacterConstraintMsg;

  /// No description provided for @pickImageMsg.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get pickImageMsg;

  /// No description provided for @submitText.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitText;

  /// No description provided for @productNameTxt.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productNameTxt;

  /// No description provided for @productBrandTxt.
  ///
  /// In en, this message translates to:
  /// **'Product Brand'**
  String get productBrandTxt;

  /// No description provided for @productBarcodeTxt.
  ///
  /// In en, this message translates to:
  /// **'Product Barcode'**
  String get productBarcodeTxt;

  /// No description provided for @productPriceTxt.
  ///
  /// In en, this message translates to:
  /// **'Product Price'**
  String get productPriceTxt;

  /// No description provided for @categoriesNotFoundTxt.
  ///
  /// In en, this message translates to:
  /// **'Categories not found'**
  String get categoriesNotFoundTxt;

  /// No description provided for @noImageSelectedTxt.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelectedTxt;

  /// No description provided for @addProductTxt.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addProductTxt;

  /// No description provided for @orderNowTxt.
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNowTxt;

  /// No description provided for @subtotalTxt.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotalTxt;

  /// No description provided for @totalTxt.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalTxt;

  /// No description provided for @confirmOrderTxt.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrderTxt;

  /// No description provided for @searchTxt.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTxt;

  /// No description provided for @emptyCartTxt.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty!'**
  String get emptyCartTxt;

  /// No description provided for @taxTxt.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxTxt;

  /// No description provided for @discountText.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountText;

  /// No description provided for @cancelTxt.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelTxt;

  /// No description provided for @confirmTxt.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmTxt;

  /// No description provided for @confirmationTxt.
  ///
  /// In en, this message translates to:
  /// **'confirmation'**
  String get confirmationTxt;

  /// No description provided for @addSupplierTxt.
  ///
  /// In en, this message translates to:
  /// **'Add Supplier'**
  String get addSupplierTxt;

  /// No description provided for @addBusinessNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter a business name'**
  String get addBusinessNameMsg;

  /// No description provided for @supplierNameMsg.
  ///
  /// In en, this message translates to:
  /// **'Supplier Name'**
  String get supplierNameMsg;

  /// No description provided for @insertCoordinatesMsg.
  ///
  /// In en, this message translates to:
  /// **'Insert coordinates'**
  String get insertCoordinatesMsg;

  /// No description provided for @addContactInfoMsg.
  ///
  /// In en, this message translates to:
  /// **'Add Contact Info'**
  String get addContactInfoMsg;

  /// No description provided for @contactInfoMsg.
  ///
  /// In en, this message translates to:
  /// **'Contact information'**
  String get contactInfoMsg;

  /// No description provided for @pleaseInputContactInfoMsg.
  ///
  /// In en, this message translates to:
  /// **'Please enter contact info'**
  String get pleaseInputContactInfoMsg;

  /// No description provided for @latitudeMsg.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeMsg;

  /// No description provided for @longitudeMsg.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeMsg;

  /// No description provided for @setLocationMsg.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get setLocationMsg;

  /// No description provided for @addIngredientMsg.
  ///
  /// In en, this message translates to:
  /// **'Add Ingredient'**
  String get addIngredientMsg;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully deleted item'**
  String get deleteSuccess;

  /// No description provided for @putSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully added item'**
  String get putSuccess;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated item'**
  String get updateSuccess;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to the server'**
  String get serverError;

  /// No description provided for @notFoundError.
  ///
  /// In en, this message translates to:
  /// **'Object not found'**
  String get notFoundError;

  /// No description provided for @deleteFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete storage item'**
  String get deleteFailure;

  /// No description provided for @getFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to load item'**
  String get getFailure;

  /// No description provided for @putFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item'**
  String get putFailure;

  /// No description provided for @updateFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to update item'**
  String get updateFailure;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'{price} DA'**
  String price(Object price);

  /// No description provided for @ingredientSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Ingredient'**
  String get ingredientSelect;

  /// No description provided for @ingredientSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Ingredient'**
  String get ingredientSearch;

  /// No description provided for @ingredientQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter Amount'**
  String get ingredientQuantity;

  /// No description provided for @addText.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addText;

  /// No description provided for @hoursTextValue.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours'**
  String hoursTextValue(int hours);

  /// No description provided for @minutesTextValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes.'**
  String minutesTextValue(int minutes);

  /// No description provided for @preparationTimeText.
  ///
  /// In en, this message translates to:
  /// **'Preparation Time: {hours} hours, {minutes} minutes'**
  String preparationTimeText(int hours, int minutes);

  /// No description provided for @noDescriptionAvailableText.
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailableText;

  /// No description provided for @noInstructionsAvailableText.
  ///
  /// In en, this message translates to:
  /// **'No instructions available.'**
  String get noInstructionsAvailableText;

  /// No description provided for @noPreparationTimeText.
  ///
  /// In en, this message translates to:
  /// **'No preparation time available.'**
  String get noPreparationTimeText;

  /// No description provided for @productsText.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsText;

  /// No description provided for @providersText.
  ///
  /// In en, this message translates to:
  /// **'Providers'**
  String get providersText;

  /// No description provided for @gamesText.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get gamesText;

  /// No description provided for @selectLanguageText.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguageText;

  /// No description provided for @profileText.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileText;

  /// No description provided for @userInfoText.
  ///
  /// In en, this message translates to:
  /// **'User Informations'**
  String get userInfoText;

  /// No description provided for @personalInfoText.
  ///
  /// In en, this message translates to:
  /// **'Personal Informations'**
  String get personalInfoText;

  /// No description provided for @locationInfoText.
  ///
  /// In en, this message translates to:
  /// **'Location Informations'**
  String get locationInfoText;

  /// No description provided for @orderAmountText.
  ///
  /// In en, this message translates to:
  /// **'Amount: {amount}'**
  String orderAmountText(String amount);

  /// No description provided for @allText.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allText;

  /// No description provided for @cartText.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartText;

  /// No description provided for @ordersText.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersText;

  /// No description provided for @noOrdersTxt.
  ///
  /// In en, this message translates to:
  /// **'No orders yet.'**
  String get noOrdersTxt;

  /// No description provided for @orderIdentifierTxt.
  ///
  /// In en, this message translates to:
  /// **'Identifier: {orderId}'**
  String orderIdentifierTxt(String orderId);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @languageText.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageText;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current language: {currentLang}'**
  String currentLanguage(String currentLang);

  /// No description provided for @darkModeText.
  ///
  /// In en, this message translates to:
  /// **'Toggle dark mode'**
  String get darkModeText;

  /// No description provided for @profileUpdateText.
  ///
  /// In en, this message translates to:
  /// **'Update profile informations'**
  String get profileUpdateText;

  /// No description provided for @passwordUpdateText.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get passwordUpdateText;

  /// No description provided for @showMoreText.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMoreText;

  /// No description provided for @copiedToClipboardText.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboardText;

  /// No description provided for @tapForDetailsText.
  ///
  /// In en, this message translates to:
  /// **'Tap for details'**
  String get tapForDetailsText;

  /// No description provided for @orText.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get orText;

  /// No description provided for @noAccountText.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccountText;

  /// No description provided for @forgotPasswordText.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordText;

  /// No description provided for @heightText.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightText;

  /// No description provided for @widthText.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get widthText;

  /// No description provided for @imageProcessingErrorText.
  ///
  /// In en, this message translates to:
  /// **'Image processing error'**
  String get imageProcessingErrorText;

  /// No description provided for @accountText.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountText;

  /// No description provided for @appearanceText.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceText;

  /// No description provided for @aboutAppTab.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get aboutAppTab;

  /// No description provided for @featuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Features'**
  String get featuresTitle;

  /// No description provided for @feature1.
  ///
  /// In en, this message translates to:
  /// **'🛒 **Gluten-Free Online Store** - Shop with confidence for certified gluten-free products with direct delivery.'**
  String get feature1;

  /// No description provided for @feature2.
  ///
  /// In en, this message translates to:
  /// **'🎮 **Educational Mini-Games** - Learn to identify safe foods in a fun way with our interactive games.'**
  String get feature2;

  /// No description provided for @feature4.
  ///
  /// In en, this message translates to:
  /// **'📍 **Local Business Directory** - Find certified gluten-free grocery stores and restaurants near you.'**
  String get feature4;

  /// No description provided for @contactUsTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUsTitle;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'verdelia.team@gmail.com'**
  String get contactEmail;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'+213-XXX-XXX-XXX'**
  String get contactPhone;

  /// No description provided for @illnessOverviewContent.
  ///
  /// In en, this message translates to:
  /// **'Celiac disease is an autoimmune disorder where gluten ingestion damages the small intestine. It can cause digestive problems, nutritional deficiencies, and other complications. Strict lifelong gluten avoidance is the only effective treatment.'**
  String get illnessOverviewContent;

  /// No description provided for @symptom1.
  ///
  /// In en, this message translates to:
  /// **'💨 **Digestive Issues** - Bloating, diarrhea, constipation, nausea and vomiting.'**
  String get symptom1;

  /// No description provided for @symptom2.
  ///
  /// In en, this message translates to:
  /// **'⚡ **Chronic Fatigue** - Caused by malabsorption of essential nutrients.'**
  String get symptom2;

  /// No description provided for @symptom3.
  ///
  /// In en, this message translates to:
  /// **'🦴 **Bone Complications** - Increased risk of osteoporosis due to poor calcium and vitamin D absorption.'**
  String get symptom3;

  /// No description provided for @treatmentContent.
  ///
  /// In en, this message translates to:
  /// **'Treatment requires strict lifelong gluten-free diet. Patients must avoid wheat, barley, rye and their derivatives. Nutritional support and tools like Verdelia help prevent accidental exposure.'**
  String get treatmentContent;

  /// No description provided for @resource1.
  ///
  /// In en, this message translates to:
  /// **'📖 **Celiac Disease Foundation** - [www.celiac.org](https://www.celiac.org)'**
  String get resource1;

  /// No description provided for @resource2.
  ///
  /// In en, this message translates to:
  /// **'📱 **Interactive Shopping Guide** - Built-in app feature to scan suspicious ingredient lists.'**
  String get resource2;

  /// No description provided for @resource3.
  ///
  /// In en, this message translates to:
  /// **'👩‍⚕️ **Specialist Directory** - Find gastroenterologists and nutritionists specializing in celiac disease near you.'**
  String get resource3;

  /// No description provided for @resourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Useful Resources'**
  String get resourcesTitle;

  /// No description provided for @userCredentialsText.
  ///
  /// In en, this message translates to:
  /// **'Your login credentials include your username and password. Make sure to keep them secure and do not share them with anyone.'**
  String get userCredentialsText;

  /// No description provided for @processingRequest.
  ///
  /// In en, this message translates to:
  /// **'Processing your request...'**
  String get processingRequest;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @locationInformation.
  ///
  /// In en, this message translates to:
  /// **'Location Information'**
  String get locationInformation;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @saveSupplier.
  ///
  /// In en, this message translates to:
  /// **'Save Supplier'**
  String get saveSupplier;

  /// No description provided for @healthText.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthText;

  /// No description provided for @illnessOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'What is Celiac Disease?'**
  String get illnessOverviewTitle;

  /// No description provided for @symptomsTitle.
  ///
  /// In en, this message translates to:
  /// **'Common Symptoms'**
  String get symptomsTitle;

  /// No description provided for @illnessInfoTab.
  ///
  /// In en, this message translates to:
  /// **'Informations'**
  String get illnessInfoTab;

  /// No description provided for @appPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get appPurposeTitle;

  /// No description provided for @treatmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Treatment & Management'**
  String get treatmentTitle;

  /// No description provided for @internal_server_error.
  ///
  /// In en, this message translates to:
  /// **'Internal server error. Please try again later.'**
  String get internal_server_error;

  /// No description provided for @http_exception.
  ///
  /// In en, this message translates to:
  /// **'HTTP request failed. Check your connection.'**
  String get http_exception;

  /// No description provided for @integrity_error.
  ///
  /// In en, this message translates to:
  /// **'Data integrity violation. The operation cannot be completed.'**
  String get integrity_error;

  /// No description provided for @data_error.
  ///
  /// In en, this message translates to:
  /// **'Invalid data format. Please verify your input.'**
  String get data_error;

  /// No description provided for @operational_error.
  ///
  /// In en, this message translates to:
  /// **'An operational error occurred. Contact support if the issue persists.'**
  String get operational_error;

  /// No description provided for @programming_error.
  ///
  /// In en, this message translates to:
  /// **'A programming error occurred. Developers have been notified.'**
  String get programming_error;

  /// No description provided for @database_error.
  ///
  /// In en, this message translates to:
  /// **'Database operation failed. Try again or contact support.'**
  String get database_error;

  /// No description provided for @internal_error.
  ///
  /// In en, this message translates to:
  /// **'An internal system error occurred.'**
  String get internal_error;

  /// No description provided for @interface_error.
  ///
  /// In en, this message translates to:
  /// **'Interface communication failed. Check configurations.'**
  String get interface_error;

  /// No description provided for @statement_error.
  ///
  /// In en, this message translates to:
  /// **'Invalid SQL statement. Syntax or logic error detected.'**
  String get statement_error;

  /// No description provided for @incorrect_credentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password'**
  String get incorrect_credentials;

  /// No description provided for @sqlalchemy_error.
  ///
  /// In en, this message translates to:
  /// **'SQLAlchemy database error. Check query or connection.'**
  String get sqlalchemy_error;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @passwordChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get passwordChangeTitle;

  /// No description provided for @passwordChangeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be different from previous passwords'**
  String get passwordChangeSubtitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get currentPasswordHint;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get newPasswordHint;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @confirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get confirmPasswordHint;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordButton;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password must contain:'**
  String get passwordRequirements;

  /// No description provided for @passwordLengthRequirement.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get passwordLengthRequirement;

  /// No description provided for @passwordUppercaseRequirement.
  ///
  /// In en, this message translates to:
  /// **'At least 1 uppercase letter'**
  String get passwordUppercaseRequirement;

  /// No description provided for @passwordNumberRequirement.
  ///
  /// In en, this message translates to:
  /// **'At least 1 number'**
  String get passwordNumberRequirement;

  /// No description provided for @passwordChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully!'**
  String get passwordChangeSuccess;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get weakPassword;

  /// No description provided for @mediumPassword.
  ///
  /// In en, this message translates to:
  /// **'Medium strength'**
  String get mediumPassword;

  /// No description provided for @strongPassword.
  ///
  /// In en, this message translates to:
  /// **'Strong password'**
  String get strongPassword;

  /// No description provided for @categoryText.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryText;

  /// No description provided for @currentPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Current password is required'**
  String get currentPasswordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @newPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'New password is required'**
  String get newPasswordRequired;

  /// No description provided for @passwordUppercaseError.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one uppercase letter'**
  String get passwordUppercaseError;

  /// No description provided for @passwordNumberError.
  ///
  /// In en, this message translates to:
  /// **'Must contain at least one number'**
  String get passwordNumberError;

  /// No description provided for @passwordSameAsCurrent.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from current password'**
  String get passwordSameAsCurrent;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @changePhotoText.
  ///
  /// In en, this message translates to:
  /// **'Change Profile Photo'**
  String get changePhotoText;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Field is required'**
  String get fieldRequired;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdateSuccess;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @personalInformation.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @logoutText.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutText;

  /// No description provided for @continueAsGuestText.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuestText;

  /// No description provided for @ingredientText.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get ingredientText;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsTitle;

  /// No description provided for @termsContent.
  ///
  /// In en, this message translates to:
  /// **'By using this app you agree to:'**
  String get termsContent;

  /// No description provided for @termsPoint1.
  ///
  /// In en, this message translates to:
  /// **'Use the app only for personal purposes'**
  String get termsPoint1;

  /// No description provided for @guideTitle.
  ///
  /// In en, this message translates to:
  /// **'User Guide'**
  String get guideTitle;

  /// No description provided for @guideStep1.
  ///
  /// In en, this message translates to:
  /// **'Create your profile to save preferences'**
  String get guideStep1;

  /// No description provided for @guideStep3.
  ///
  /// In en, this message translates to:
  /// **'Bookmark favorites for quick access'**
  String get guideStep3;

  /// No description provided for @disclaimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Disclaimer'**
  String get disclaimerTitle;

  /// No description provided for @versionText.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get versionText;

  /// No description provided for @providedBy.
  ///
  /// In en, this message translates to:
  /// **'Provided by'**
  String get providedBy;

  /// No description provided for @unknownProvider.
  ///
  /// In en, this message translates to:
  /// **'Unknown provider'**
  String get unknownProvider;

  /// No description provided for @callProvider.
  ///
  /// In en, this message translates to:
  /// **'Call provider'**
  String get callProvider;

  /// No description provided for @emailProvider.
  ///
  /// In en, this message translates to:
  /// **'Email provider'**
  String get emailProvider;

  /// No description provided for @viewOnMap.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get viewOnMap;

  /// No description provided for @providerContactOptions.
  ///
  /// In en, this message translates to:
  /// **'Contact Options'**
  String get providerContactOptions;

  /// No description provided for @supplierText.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplierText;

  /// No description provided for @legalDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get legalDocumentsTitle;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @termsAgreementText.
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Use governing my use of Verdelia'**
  String get termsAgreementText;

  /// No description provided for @privacyAgreementText.
  ///
  /// In en, this message translates to:
  /// **'I agree to how Verdelia collects and processes my data'**
  String get privacyAgreementText;

  /// No description provided for @readFullDocument.
  ///
  /// In en, this message translates to:
  /// **'Read full document'**
  String get readFullDocument;

  /// No description provided for @acceptAllTermsError.
  ///
  /// In en, this message translates to:
  /// **'You must accept both documents to continue'**
  String get acceptAllTermsError;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @availableText.
  ///
  /// In en, this message translates to:
  /// **'{amount} Available'**
  String availableText(String amount);

  /// No description provided for @ingredientUnits.
  ///
  /// In en, this message translates to:
  /// **'Gram,Kilogram,Milligram,Pound,Ounce,Milliliter,Liter,Cup,Tablespoon,Teaspoon,Pinch'**
  String get ingredientUnits;

  /// No description provided for @unitText.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitText;

  /// No description provided for @amountText.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountText;

  /// No description provided for @otherProductsFromSupplier.
  ///
  /// In en, this message translates to:
  /// **'Also from: {supplier_name}'**
  String otherProductsFromSupplier(String supplier_name);

  /// No description provided for @productsFromSupplier.
  ///
  /// In en, this message translates to:
  /// **'Provided by: {supplier_name}'**
  String productsFromSupplier(String supplier_name);

  /// No description provided for @similarProductsFromCategory.
  ///
  /// In en, this message translates to:
  /// **'Products from: {category_name}'**
  String similarProductsFromCategory(String category_name);

  /// No description provided for @noOtherProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available from this supplier.'**
  String get noOtherProductsAvailable;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @imagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to pick image'**
  String get imagePickFailed;

  /// No description provided for @changeImage.
  ///
  /// In en, this message translates to:
  /// **'Change Image'**
  String get changeImage;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select Image'**
  String get selectImage;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Image'**
  String get uploadImage;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove Image'**
  String get removeImage;

  /// No description provided for @noImageSelected.
  ///
  /// In en, this message translates to:
  /// **'No image selected'**
  String get noImageSelected;

  /// No description provided for @searchSuppliersText.
  ///
  /// In en, this message translates to:
  /// **'Search suppliers...'**
  String get searchSuppliersText;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @selectOrganisationHintText.
  ///
  /// In en, this message translates to:
  /// **'Please select an organisation'**
  String get selectOrganisationHintText;

  /// No description provided for @providerImage.
  ///
  /// In en, this message translates to:
  /// **'Provider Image'**
  String get providerImage;

  /// No description provided for @selectOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Select Organisation'**
  String get selectOrganisation;

  /// No description provided for @searchOrganisations.
  ///
  /// In en, this message translates to:
  /// **'Search Organisations'**
  String get searchOrganisations;

  /// No description provided for @noOrganisationsFound.
  ///
  /// In en, this message translates to:
  /// **'No organisations found'**
  String get noOrganisationsFound;

  /// No description provided for @createNew.
  ///
  /// In en, this message translates to:
  /// **'Create New'**
  String get createNew;

  /// No description provided for @organisationText.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get organisationText;

  /// No description provided for @by_organisation.
  ///
  /// In en, this message translates to:
  /// **'By {org_name}'**
  String by_organisation(String org_name);

  /// No description provided for @no_location_information_available.
  ///
  /// In en, this message translates to:
  /// **'No available information about location'**
  String get no_location_information_available;

  /// No description provided for @orderFor.
  ///
  /// In en, this message translates to:
  /// **'Order for'**
  String get orderFor;

  /// No description provided for @missingProductName.
  ///
  /// In en, this message translates to:
  /// **'Product name missing'**
  String get missingProductName;

  /// No description provided for @amountTxtDisplay.
  ///
  /// In en, this message translates to:
  /// **'{amount} {quantifier}'**
  String amountTxtDisplay(String amount, String quantifier);

  /// No description provided for @quantifier_g.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get quantifier_g;

  /// No description provided for @quantifier_kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get quantifier_kg;

  /// No description provided for @quantifier_mg.
  ///
  /// In en, this message translates to:
  /// **'mg'**
  String get quantifier_mg;

  /// No description provided for @quantifier_L.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get quantifier_L;

  /// No description provided for @quantifier_mL.
  ///
  /// In en, this message translates to:
  /// **'mL'**
  String get quantifier_mL;

  /// No description provided for @quantifier_pc.
  ///
  /// In en, this message translates to:
  /// **'piece'**
  String get quantifier_pc;

  /// No description provided for @quantifier_pkg.
  ///
  /// In en, this message translates to:
  /// **'package'**
  String get quantifier_pkg;

  /// No description provided for @quantifier_box.
  ///
  /// In en, this message translates to:
  /// **'box'**
  String get quantifier_box;

  /// No description provided for @quantifier_bag.
  ///
  /// In en, this message translates to:
  /// **'bag'**
  String get quantifier_bag;

  /// No description provided for @quantifier_slice.
  ///
  /// In en, this message translates to:
  /// **'slice'**
  String get quantifier_slice;

  /// No description provided for @quantifier_cup.
  ///
  /// In en, this message translates to:
  /// **'cup'**
  String get quantifier_cup;

  /// No description provided for @order_number.
  ///
  /// In en, this message translates to:
  /// **'Order Number: {n}'**
  String order_number(String n);

  /// No description provided for @orderItemsTxt.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItemsTxt;

  /// No description provided for @dateTimeNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Date not available'**
  String get dateTimeNotAvailable;

  /// No description provided for @dateTimeFormat.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}/{year} {hour}:{min}'**
  String dateTimeFormat(Object day, Object hour, Object min, Object month, Object year);

  /// No description provided for @dateFormat.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}/{year}'**
  String dateFormat(int day, int month, int year);

  /// No description provided for @completedTxt.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedTxt;

  /// No description provided for @deliveredTxt.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveredTxt;

  /// No description provided for @pendingTxt.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTxt;

  /// No description provided for @cancelledTxt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledTxt;

  /// No description provided for @processingTxt.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingTxt;

  /// No description provided for @unknownTxt.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownTxt;

  /// No description provided for @spentTxt.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spentTxt;

  /// No description provided for @qtyTxt.
  ///
  /// In en, this message translates to:
  /// **'Qty: {quantity} × {price}'**
  String qtyTxt(int quantity, String price);

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingOrders;

  /// No description provided for @loadingOrderDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading order details...'**
  String get loadingOrderDetails;

  /// No description provided for @failedToLoadDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load details'**
  String get failedToLoadDetails;

  /// No description provided for @yourOrdersWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your orders will appear here'**
  String get yourOrdersWillAppearHere;

  /// No description provided for @refreshTxt.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshTxt;

  /// No description provided for @yourOrderStats.
  ///
  /// In en, this message translates to:
  /// **'Your Order Stats'**
  String get yourOrderStats;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @uploadingImage.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploadingImage;

  /// No description provided for @laterText.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterText;

  /// No description provided for @failedAuthAfterSignIn.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed after signing in.'**
  String get failedAuthAfterSignIn;

  /// No description provided for @loginTimeoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Login timed out. Please try again.'**
  String get loginTimeoutMsg;

  /// No description provided for @failedLogin.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Check your credentials.'**
  String get failedLogin;

  /// No description provided for @signInWithText.
  ///
  /// In en, this message translates to:
  /// **'Sign in with'**
  String get signInWithText;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @loggingOutText.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOutText;

  /// No description provided for @logoutConsentText.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConsentText;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @alignBarcode.
  ///
  /// In en, this message translates to:
  /// **'Align barcode within the frame'**
  String get alignBarcode;

  /// No description provided for @positionBarcode.
  ///
  /// In en, this message translates to:
  /// **'Position the barcode inside the scanning area for automatic detection'**
  String get positionBarcode;

  /// No description provided for @barcodeScanSuccess.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanned successfully!'**
  String get barcodeScanSuccess;

  /// No description provided for @initCam.
  ///
  /// In en, this message translates to:
  /// **'Initializing Camera...'**
  String get initCam;

  /// No description provided for @captureProduct.
  ///
  /// In en, this message translates to:
  /// **'Capture Product'**
  String get captureProduct;

  /// No description provided for @positionProductInFrame.
  ///
  /// In en, this message translates to:
  /// **'Position Product in Frame'**
  String get positionProductInFrame;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Ensure good lighting and clear focus'**
  String get scanHint;

  /// No description provided for @tapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to Capture'**
  String get tapHint;

  /// No description provided for @reviewPhoto.
  ///
  /// In en, this message translates to:
  /// **'Review Photo'**
  String get reviewPhoto;

  /// No description provided for @croppedToFrame.
  ///
  /// In en, this message translates to:
  /// **'Cropped to frame'**
  String get croppedToFrame;

  /// No description provided for @usePhoto.
  ///
  /// In en, this message translates to:
  /// **'Use This Photo'**
  String get usePhoto;

  /// No description provided for @takeAgain.
  ///
  /// In en, this message translates to:
  /// **'Take Again'**
  String get takeAgain;

  /// No description provided for @processingImage.
  ///
  /// In en, this message translates to:
  /// **'Processing Image...'**
  String get processingImage;

  /// No description provided for @waitText.
  ///
  /// In en, this message translates to:
  /// **'This may take a few seconds'**
  String get waitText;

  /// No description provided for @aiAnalysing.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing your product...'**
  String get aiAnalysing;

  /// No description provided for @aiAssistantSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically fill product details'**
  String get aiAssistantSubtitle;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Product Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @productDetailsFilled.
  ///
  /// In en, this message translates to:
  /// **'Product details filled automatically!'**
  String get productDetailsFilled;

  /// No description provided for @scanQR.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQR;

  /// No description provided for @scannerHint.
  ///
  /// In en, this message translates to:
  /// **'Position QR Code in Frame'**
  String get scannerHint;

  /// No description provided for @alignQR.
  ///
  /// In en, this message translates to:
  /// **'Align the QR code within the scanning area for automatic detection'**
  String get alignQR;

  /// No description provided for @manualInput.
  ///
  /// In en, this message translates to:
  /// **'Manual Input'**
  String get manualInput;

  /// No description provided for @qrSuccess.
  ///
  /// In en, this message translates to:
  /// **'QR Code scanned successfully!'**
  String get qrSuccess;

  /// No description provided for @manualQR.
  ///
  /// In en, this message translates to:
  /// **'Enter QR Code Manually'**
  String get manualQR;

  /// No description provided for @manualQRHint.
  ///
  /// In en, this message translates to:
  /// **'Paste or type QR code content...'**
  String get manualQRHint;

  /// No description provided for @scannerTxt.
  ///
  /// In en, this message translates to:
  /// **'Scanner'**
  String get scannerTxt;

  /// No description provided for @takeProductPhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Product Photo'**
  String get takeProductPhoto;

  /// No description provided for @aiWillAnalyseImage.
  ///
  /// In en, this message translates to:
  /// **'AI will analyze the product image'**
  String get aiWillAnalyseImage;

  /// No description provided for @automaticallyFillDetailsFromBarcode.
  ///
  /// In en, this message translates to:
  /// **'Automatically fill details from barcode'**
  String get automaticallyFillDetailsFromBarcode;

  /// No description provided for @aiGenerated.
  ///
  /// In en, this message translates to:
  /// **'AI-Generated'**
  String get aiGenerated;

  /// No description provided for @databaseFetched.
  ///
  /// In en, this message translates to:
  /// **'Retrieved from database'**
  String get databaseFetched;

  /// No description provided for @userInput.
  ///
  /// In en, this message translates to:
  /// **'User-Provided'**
  String get userInput;

  /// No description provided for @notificationOrderReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Received! 🎉'**
  String get notificationOrderReceivedTitle;

  /// No description provided for @notificationRoleInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Team Invitation'**
  String get notificationRoleInvitationTitle;

  /// No description provided for @notificationProductUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Updated'**
  String get notificationProductUpdatedTitle;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @notificationOrderReceivedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ready for processing'**
  String get notificationOrderReceivedSubtitle;

  /// No description provided for @notificationProductUpdatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New changes available'**
  String get notificationProductUpdatedSubtitle;

  /// No description provided for @notificationOrderReceivedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully received and is being processed. You can track its status in your orders.'**
  String get notificationOrderReceivedMessage;

  /// No description provided for @notificationRoleInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'You have been invited to join \"{ruleName}\" as {ruleType}. Accept to get started!'**
  String notificationRoleInvitationMessage(String ruleName, String ruleType);

  /// No description provided for @notificationRoleInvitationDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'You have been invited to join a team.'**
  String get notificationRoleInvitationDefaultMessage;

  /// No description provided for @notificationProductUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'A product you are following has been updated with new features and improvements. Check it out!'**
  String get notificationProductUpdatedMessage;

  /// No description provided for @notificationDefaultMessage.
  ///
  /// In en, this message translates to:
  /// **'You have a new notification'**
  String get notificationDefaultMessage;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeMinutesAgoPlural.
  ///
  /// In en, this message translates to:
  /// **'{minutes} mins ago'**
  String timeMinutesAgoPlural(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hr ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeHoursAgoPlural.
  ///
  /// In en, this message translates to:
  /// **'{hours} hrs ago'**
  String timeHoursAgoPlural(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} day ago'**
  String timeDaysAgo(int days);

  /// No description provided for @timeDaysAgoPlural.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgoPlural(int days);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks} week ago'**
  String timeWeeksAgo(int weeks);

  /// No description provided for @timeWeeksAgoPlural.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String timeWeeksAgoPlural(int weeks);

  /// No description provided for @timeDate.
  ///
  /// In en, this message translates to:
  /// **'{day}/{month}/{year}'**
  String timeDate(int day, int month, int year);

  /// No description provided for @actionTrackOrder.
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get actionTrackOrder;

  /// No description provided for @actionDownloadInvoice.
  ///
  /// In en, this message translates to:
  /// **'Download Invoice'**
  String get actionDownloadInvoice;

  /// No description provided for @actionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// No description provided for @actionDecline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get actionDecline;

  /// No description provided for @actionViewTeam.
  ///
  /// In en, this message translates to:
  /// **'View Team'**
  String get actionViewTeam;

  /// No description provided for @actionSeeChanges.
  ///
  /// In en, this message translates to:
  /// **'See Changes'**
  String get actionSeeChanges;

  /// No description provided for @actionUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get actionUpdateNow;

  /// No description provided for @actionViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get actionViewDetails;

  /// No description provided for @status_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get status_pending;

  /// No description provided for @status_rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get status_rejected;

  /// No description provided for @status_suspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get status_suspended;

  /// No description provided for @status_obsolete.
  ///
  /// In en, this message translates to:
  /// **'Obsolete'**
  String get status_obsolete;

  /// No description provided for @status_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get status_active;

  /// No description provided for @status_inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get status_inactive;

  /// No description provided for @inventory_view_title.
  ///
  /// In en, this message translates to:
  /// **'View Inventory'**
  String get inventory_view_title;

  /// No description provided for @inventory_view_description.
  ///
  /// In en, this message translates to:
  /// **'Can view current inventory levels and stock'**
  String get inventory_view_description;

  /// No description provided for @inventory_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Inventory'**
  String get inventory_manage_title;

  /// No description provided for @inventory_manage_description.
  ///
  /// In en, this message translates to:
  /// **'Can update stock levels and manage products'**
  String get inventory_manage_description;

  /// No description provided for @orders_view_title.
  ///
  /// In en, this message translates to:
  /// **'View Orders'**
  String get orders_view_title;

  /// No description provided for @orders_view_description.
  ///
  /// In en, this message translates to:
  /// **'Can view customer and supplier orders'**
  String get orders_view_description;

  /// No description provided for @orders_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Orders'**
  String get orders_manage_title;

  /// No description provided for @orders_manage_description.
  ///
  /// In en, this message translates to:
  /// **'Can create, edit, and process orders'**
  String get orders_manage_description;

  /// No description provided for @personnel_view_title.
  ///
  /// In en, this message translates to:
  /// **'View Team'**
  String get personnel_view_title;

  /// No description provided for @personnel_view_description.
  ///
  /// In en, this message translates to:
  /// **'Can view other team members'**
  String get personnel_view_description;

  /// No description provided for @personnel_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Team'**
  String get personnel_manage_title;

  /// No description provided for @personnel_manage_description.
  ///
  /// In en, this message translates to:
  /// **'Can add/remove team members and set permissions'**
  String get personnel_manage_description;

  /// No description provided for @manage_permissions.
  ///
  /// In en, this message translates to:
  /// **'Manage Permissions'**
  String get manage_permissions;

  /// No description provided for @save_permissions.
  ///
  /// In en, this message translates to:
  /// **'Save Permissions'**
  String get save_permissions;

  /// No description provided for @no_username.
  ///
  /// In en, this message translates to:
  /// **'No username'**
  String get no_username;

  /// No description provided for @category_inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory Management'**
  String get category_inventory;

  /// No description provided for @category_orders.
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get category_orders;

  /// No description provided for @category_personnel.
  ///
  /// In en, this message translates to:
  /// **'Personnel Management'**
  String get category_personnel;

  /// No description provided for @roleStaff.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleStaff;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get roleSupervisor;

  /// No description provided for @roleViewer.
  ///
  /// In en, this message translates to:
  /// **'Viewer'**
  String get roleViewer;

  /// No description provided for @roleNoPrivileges.
  ///
  /// In en, this message translates to:
  /// **'No Privileges'**
  String get roleNoPrivileges;

  /// No description provided for @actionManagePermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get actionManagePermissions;

  /// No description provided for @actionNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get actionNotify;

  /// No description provided for @pendingInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'This user has a pending invitation.'**
  String get pendingInvitationMessage;

  /// No description provided for @actionResendInvite.
  ///
  /// In en, this message translates to:
  /// **'Resend Invitation'**
  String get actionResendInvite;

  /// No description provided for @actionCancelInvite.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get actionCancelInvite;

  /// No description provided for @suppliersCountCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{totalSuppliers,plural, =0{No locations}=1{1 location}other{{totalSuppliers} locations}} • {categoryCount,plural, =0{no category}=1{1 in category}other{{categoryCount} in category}}'**
  String suppliersCountCategoryCount(int totalSuppliers, int categoryCount);

  /// No description provided for @myBusinessesTitle.
  ///
  /// In en, this message translates to:
  /// **'My Businesses'**
  String get myBusinessesTitle;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @filteredTxt.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get filteredTxt;

  /// No description provided for @noBusinessesFound.
  ///
  /// In en, this message translates to:
  /// **'No businesses found'**
  String get noBusinessesFound;

  /// No description provided for @adjustFilterBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get adjustFilterBusinessHint;

  /// No description provided for @addFirstBusinessHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first business to get started'**
  String get addFirstBusinessHint;

  /// No description provided for @addMemberText.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMemberText;

  /// No description provided for @addTeamMemberText.
  ///
  /// In en, this message translates to:
  /// **'Add Team Member'**
  String get addTeamMemberText;

  /// No description provided for @addUsersToManageText.
  ///
  /// In en, this message translates to:
  /// **'Add users to manage {supplierName}'**
  String addUsersToManageText(String supplierName);

  /// No description provided for @scanQrCodeText.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCodeText;

  /// No description provided for @scanUserProfileQrText.
  ///
  /// In en, this message translates to:
  /// **'Scan user profile QR code'**
  String get scanUserProfileQrText;

  /// No description provided for @searchAndInviteText.
  ///
  /// In en, this message translates to:
  /// **'Search & Invite'**
  String get searchAndInviteText;

  /// No description provided for @searchAndInviteExistingUsersText.
  ///
  /// In en, this message translates to:
  /// **'Search and invite existing users'**
  String get searchAndInviteExistingUsersText;

  /// No description provided for @cancelText.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelText;

  /// No description provided for @cancelInvitationTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get cancelInvitationTitle;

  /// No description provided for @cancelInvitationMessage.
  ///
  /// In en, this message translates to:
  /// **'Cancel invitation? This cannot be undone.'**
  String get cancelInvitationMessage;

  /// No description provided for @cancelInvitationAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get cancelInvitationAction;

  /// No description provided for @removeTeamMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Team Member'**
  String get removeTeamMemberTitle;

  /// No description provided for @removeTeamMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'Remove {userName} from {supplierName}?'**
  String removeTeamMemberMessage(String userName, String supplierName);

  /// No description provided for @removeAction.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeAction;

  /// No description provided for @personnelManagement.
  ///
  /// In en, this message translates to:
  /// **'Personnel Management'**
  String get personnelManagement;

  /// No description provided for @privilegesUpdatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Updated privileges for {userName}'**
  String privilegesUpdatedMessage(String userName);

  /// No description provided for @privilegesUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update privileges'**
  String get privilegesUpdateFailedMessage;

  /// No description provided for @privilegesUpdateError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while updating privileges'**
  String get privilegesUpdateError;

  /// No description provided for @barcodeText.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcodeText;

  /// No description provided for @barcodeCopiedText.
  ///
  /// In en, this message translates to:
  /// **'Barcode copied to clipboard'**
  String get barcodeCopiedText;

  /// No description provided for @sourceText.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceText;

  /// No description provided for @modelText.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get modelText;

  /// No description provided for @recentText.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentText;

  /// No description provided for @productDetailsText.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailsText;

  /// No description provided for @createdText.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdText;

  /// No description provided for @lastUpdatedText.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastUpdatedText;

  /// No description provided for @priceUpdatedText.
  ///
  /// In en, this message translates to:
  /// **'Price Updated'**
  String get priceUpdatedText;

  /// No description provided for @noProductDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Not Found'**
  String get noProductDataTitle;

  /// No description provided for @noProductDataDescription.
  ///
  /// In en, this message translates to:
  /// **'No product information found for this barcode. The product may be new or not in our database yet.'**
  String get noProductDataDescription;

  /// No description provided for @noProductDataHelp.
  ///
  /// In en, this message translates to:
  /// **'You can try scanning again or add the product details manually.'**
  String get noProductDataHelp;

  /// No description provided for @scanAgainText.
  ///
  /// In en, this message translates to:
  /// **'Scan Again'**
  String get scanAgainText;

  /// No description provided for @addManuallyText.
  ///
  /// In en, this message translates to:
  /// **'Add Product Manually'**
  String get addManuallyText;

  /// No description provided for @ownedText.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get ownedText;

  /// No description provided for @managedText.
  ///
  /// In en, this message translates to:
  /// **'Managed'**
  String get managedText;

  /// No description provided for @noOwnedBusinessesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Owned Businesses'**
  String get noOwnedBusinessesTitle;

  /// No description provided for @noOwnedBusinessesDescription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t own any businesses yet'**
  String get noOwnedBusinessesDescription;

  /// No description provided for @noManagedBusinessesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Managed Businesses'**
  String get noManagedBusinessesTitle;

  /// No description provided for @noManagedBusinessesDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'re not managing any businesses'**
  String get noManagedBusinessesDescription;

  /// No description provided for @noBusinessesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Businesses'**
  String get noBusinessesTitle;

  /// No description provided for @noBusinessesDescription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t own or manage any businesses yet'**
  String get noBusinessesDescription;

  /// No description provided for @noResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get noResultsTitle;

  /// No description provided for @adjustSearchFiltersText.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get adjustSearchFiltersText;

  /// No description provided for @orderManagement.
  ///
  /// In en, this message translates to:
  /// **'Order Management'**
  String get orderManagement;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @selectSupplier.
  ///
  /// In en, this message translates to:
  /// **'Select Supplier'**
  String get selectSupplier;

  /// No description provided for @noOrderManagementPrivileges.
  ///
  /// In en, this message translates to:
  /// **'No order management privileges'**
  String get noOrderManagementPrivileges;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// No description provided for @noPendingOrders.
  ///
  /// In en, this message translates to:
  /// **'No pending orders'**
  String get noPendingOrders;

  /// No description provided for @noProcessingOrders.
  ///
  /// In en, this message translates to:
  /// **'No orders in processing'**
  String get noProcessingOrders;

  /// No description provided for @noCompletedOrders.
  ///
  /// In en, this message translates to:
  /// **'No completed orders'**
  String get noCompletedOrders;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @noOrdersFoundForStatus.
  ///
  /// In en, this message translates to:
  /// **'No orders found for this status'**
  String get noOrdersFoundForStatus;

  /// No description provided for @financeAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Finance & Pricing'**
  String get financeAndPricing;

  /// No description provided for @manageInvoicesAndConfigurePricing.
  ///
  /// In en, this message translates to:
  /// **'Manage invoices & configure pricing'**
  String get manageInvoicesAndConfigurePricing;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportData;

  /// No description provided for @exportingData.
  ///
  /// In en, this message translates to:
  /// **'Exporting data...'**
  String get exportingData;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisQuarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get thisQuarter;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get invoices;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @pricing.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricing;

  /// No description provided for @newInvoice.
  ///
  /// In en, this message translates to:
  /// **'New Invoice'**
  String get newInvoice;

  /// No description provided for @selectSupplierFirstText.
  ///
  /// In en, this message translates to:
  /// **'Select a Supplier First'**
  String get selectSupplierFirstText;

  /// No description provided for @selectSupplierToViewText.
  ///
  /// In en, this message translates to:
  /// **'Please select a supplier to view their product inventory'**
  String get selectSupplierToViewText;

  /// No description provided for @noProductsText.
  ///
  /// In en, this message translates to:
  /// **'No Products Available'**
  String get noProductsText;

  /// No description provided for @noProductsFoundText.
  ///
  /// In en, this message translates to:
  /// **'No Products Found'**
  String get noProductsFoundText;

  /// No description provided for @tryDifferentSearchText.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term or browse other suppliers'**
  String get tryDifferentSearchText;

  /// No description provided for @addFirstProductText.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start selling'**
  String get addFirstProductText;

  /// No description provided for @quickTransactions.
  ///
  /// In en, this message translates to:
  /// **'Quick Transactions'**
  String get quickTransactions;

  /// No description provided for @barcodeScanningComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Barcode scanning coming soon'**
  String get barcodeScanningComingSoon;

  /// No description provided for @chooseStoreToViewProducts.
  ///
  /// In en, this message translates to:
  /// **'Choose a store to view products'**
  String get chooseStoreToViewProducts;

  /// No description provided for @added.
  ///
  /// In en, this message translates to:
  /// **'Added'**
  String get added;

  /// No description provided for @noInventoryPrivilegesText.
  ///
  /// In en, this message translates to:
  /// **'Inventory Access Restricted'**
  String get noInventoryPrivilegesText;

  /// No description provided for @toCart.
  ///
  /// In en, this message translates to:
  /// **'to cart'**
  String get toCart;

  /// No description provided for @businesses.
  ///
  /// In en, this message translates to:
  /// **'Businesses'**
  String get businesses;

  /// No description provided for @inventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventory;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @pointOfSale.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get pointOfSale;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @createNewOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Order'**
  String get createNewOrder;

  /// No description provided for @openCart.
  ///
  /// In en, this message translates to:
  /// **'Open Cart'**
  String get openCart;

  /// No description provided for @createNewInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createNewInvoice;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @accessRequired.
  ///
  /// In en, this message translates to:
  /// **'Access Required'**
  String get accessRequired;

  /// No description provided for @pleaseLoginToAccessDashboard.
  ///
  /// In en, this message translates to:
  /// **'Please log in to access the dashboard.'**
  String get pleaseLoginToAccessDashboard;

  /// No description provided for @needBusinessAssignment.
  ///
  /// In en, this message translates to:
  /// **'You need to be assigned to a business to access management features.'**
  String get needBusinessAssignment;

  /// No description provided for @contactAdminOrJoinTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact your administrator or join a business team.'**
  String get contactAdminOrJoinTeam;

  /// No description provided for @checkAccessStatus.
  ///
  /// In en, this message translates to:
  /// **'Check Access Status'**
  String get checkAccessStatus;

  /// No description provided for @viewPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'View Pending Invitations'**
  String get viewPendingInvitations;

  /// No description provided for @pendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvitations;

  /// No description provided for @noPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get noPendingInvitations;

  /// No description provided for @unknownBusiness.
  ///
  /// In en, this message translates to:
  /// **'Unknown Business'**
  String get unknownBusiness;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted!'**
  String get invitationAccepted;

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined.'**
  String get invitationDeclined;

  /// No description provided for @noRoleAssigned.
  ///
  /// In en, this message translates to:
  /// **'No role assigned'**
  String get noRoleAssigned;

  /// No description provided for @noAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'No Analytics Data'**
  String get noAnalyticsData;

  /// No description provided for @generateInvoicesToSeeAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Generate invoices to see analytics data'**
  String get generateInvoicesToSeeAnalytics;

  /// No description provided for @financialOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get financialOverview;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @netProfit.
  ///
  /// In en, this message translates to:
  /// **'Net Profit'**
  String get netProfit;

  /// No description provided for @growthRate.
  ///
  /// In en, this message translates to:
  /// **'Growth Rate'**
  String get growthRate;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @averageOrder.
  ///
  /// In en, this message translates to:
  /// **'Average Order'**
  String get averageOrder;

  /// No description provided for @taxCollected.
  ///
  /// In en, this message translates to:
  /// **'Tax Collected'**
  String get taxCollected;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get recentTransactions;

  /// No description provided for @last5Transactions.
  ///
  /// In en, this message translates to:
  /// **'Last 5 transactions'**
  String get last5Transactions;

  /// No description provided for @viewAllTransactions.
  ///
  /// In en, this message translates to:
  /// **'View All Transactions'**
  String get viewAllTransactions;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @profit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get profit;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @tax.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// No description provided for @refund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @refunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get refunded;

  /// No description provided for @invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoice;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @noInvoicesYet.
  ///
  /// In en, this message translates to:
  /// **'No Invoices Yet'**
  String get noInvoicesYet;

  /// No description provided for @noInvoicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Your invoices will appear here once you complete sales'**
  String get noInvoicesDescription;

  /// No description provided for @createFirstInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create First Invoice'**
  String get createFirstInvoice;

  /// No description provided for @loadingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Loading invoices...'**
  String get loadingInvoices;

  /// No description provided for @card.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get card;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @bankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get bankTransfer;

  /// No description provided for @mobilePayment.
  ///
  /// In en, this message translates to:
  /// **'Mobile Payment'**
  String get mobilePayment;

  /// No description provided for @sharingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Sharing invoice'**
  String get sharingInvoice;

  /// No description provided for @downloadingInvoice.
  ///
  /// In en, this message translates to:
  /// **'Downloading invoice'**
  String get downloadingInvoice;

  /// No description provided for @invoiceDetails.
  ///
  /// In en, this message translates to:
  /// **'Invoice Details'**
  String get invoiceDetails;

  /// No description provided for @currencySymbol.
  ///
  /// In en, this message translates to:
  /// **'DZD'**
  String get currencySymbol;

  /// No description provided for @currencyCode.
  ///
  /// In en, this message translates to:
  /// **'USD'**
  String get currencyCode;

  /// No description provided for @accessRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Refreshed access'**
  String get accessRefreshed;

  /// No description provided for @manageSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Manage Suppliers'**
  String get manageSuppliers;

  /// No description provided for @addFirstProduct.
  ///
  /// In en, this message translates to:
  /// **'Add first product'**
  String get addFirstProduct;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @addService.
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// No description provided for @serviceDiscount.
  ///
  /// In en, this message translates to:
  /// **'{percent}% {label}'**
  String serviceDiscount(String percent, String label);

  /// No description provided for @serviceDiscountOff.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get serviceDiscountOff;

  /// No description provided for @servicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get servicesAvailable;

  /// No description provided for @loadingServices.
  ///
  /// In en, this message translates to:
  /// **'Loading services'**
  String get loadingServices;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait'**
  String get pleaseWait;

  /// No description provided for @noServicesFound.
  ///
  /// In en, this message translates to:
  /// **'No services found'**
  String get noServicesFound;

  /// No description provided for @noServicesDescription.
  ///
  /// In en, this message translates to:
  /// **'Add your first service to start offering healthcare services to patients.'**
  String get noServicesDescription;

  /// No description provided for @proTip.
  ///
  /// In en, this message translates to:
  /// **'Pro Tip'**
  String get proTip;

  /// No description provided for @addServicesToManage.
  ///
  /// In en, this message translates to:
  /// **'Add services to manage appointments, pricing, and resource allocation efficiently.'**
  String get addServicesToManage;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get searchServices;

  /// No description provided for @profitMargin.
  ///
  /// In en, this message translates to:
  /// **'margin'**
  String get profitMargin;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @serviceDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get serviceDescription;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get createdAt;

  /// No description provided for @deletedAt.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deletedAt;

  /// No description provided for @basePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get basePrice;

  /// No description provided for @finalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final Price'**
  String get finalPrice;

  /// No description provided for @totalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get totalCost;

  /// No description provided for @discountApplied.
  ///
  /// In en, this message translates to:
  /// **'Discount applied from base price'**
  String get discountApplied;

  /// No description provided for @resourceRequirements.
  ///
  /// In en, this message translates to:
  /// **'Resource Requirements'**
  String get resourceRequirements;

  /// No description provided for @staffRequirements.
  ///
  /// In en, this message translates to:
  /// **'Staff Requirements'**
  String get staffRequirements;

  /// No description provided for @totalResourceCost.
  ///
  /// In en, this message translates to:
  /// **'Total Resource Cost'**
  String get totalResourceCost;

  /// No description provided for @totalStaffCost.
  ///
  /// In en, this message translates to:
  /// **'Total Staff Cost'**
  String get totalStaffCost;

  /// No description provided for @costSummary.
  ///
  /// In en, this message translates to:
  /// **'Cost Summary'**
  String get costSummary;

  /// No description provided for @resourceCost.
  ///
  /// In en, this message translates to:
  /// **'Resource Cost'**
  String get resourceCost;

  /// No description provided for @staffCost.
  ///
  /// In en, this message translates to:
  /// **'Staff Cost'**
  String get staffCost;

  /// No description provided for @totalServiceCost.
  ///
  /// In en, this message translates to:
  /// **'Total Service Cost'**
  String get totalServiceCost;

  /// No description provided for @servicePrice.
  ///
  /// In en, this message translates to:
  /// **'Service Price'**
  String get servicePrice;

  /// No description provided for @businessOperations.
  ///
  /// In en, this message translates to:
  /// **'Business Operations'**
  String get businessOperations;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partial;

  /// No description provided for @noBusinessOperations.
  ///
  /// In en, this message translates to:
  /// **'No Business Operations'**
  String get noBusinessOperations;

  /// No description provided for @generateOperationsToSeeData.
  ///
  /// In en, this message translates to:
  /// **'Generate business operations to see detailed analytics and transaction data'**
  String get generateOperationsToSeeData;

  /// No description provided for @exportOperations.
  ///
  /// In en, this message translates to:
  /// **'Export Operations'**
  String get exportOperations;

  /// No description provided for @viewAllBusinessTransactions.
  ///
  /// In en, this message translates to:
  /// **'View all business transactions and operations'**
  String get viewAllBusinessTransactions;

  /// No description provided for @topSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Top Suppliers'**
  String get topSuppliers;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @carts.
  ///
  /// In en, this message translates to:
  /// **'Carts'**
  String get carts;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @byStatus.
  ///
  /// In en, this message translates to:
  /// **'By Status'**
  String get byStatus;

  /// No description provided for @bySource.
  ///
  /// In en, this message translates to:
  /// **'By Source'**
  String get bySource;

  /// No description provided for @operationDetails.
  ///
  /// In en, this message translates to:
  /// **'Operation Details'**
  String get operationDetails;

  /// No description provided for @transactionDetails.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transactionDetails;

  /// No description provided for @cartBasedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Cart-based Transaction'**
  String get cartBasedTransaction;

  /// No description provided for @orderBasedTransaction.
  ///
  /// In en, this message translates to:
  /// **'Order-based Transaction'**
  String get orderBasedTransaction;

  /// No description provided for @operationSummary.
  ///
  /// In en, this message translates to:
  /// **'Operation Summary'**
  String get operationSummary;

  /// No description provided for @operationId.
  ///
  /// In en, this message translates to:
  /// **'Operation ID'**
  String get operationId;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @seller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get seller;

  /// No description provided for @cartBased.
  ///
  /// In en, this message translates to:
  /// **'Cart-based'**
  String get cartBased;

  /// No description provided for @orderBased.
  ///
  /// In en, this message translates to:
  /// **'Order-based'**
  String get orderBased;

  /// No description provided for @paymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Payment Details'**
  String get paymentDetails;

  /// No description provided for @totalDeposited.
  ///
  /// In en, this message translates to:
  /// **'Total Deposited'**
  String get totalDeposited;

  /// No description provided for @balanceDue.
  ///
  /// In en, this message translates to:
  /// **'Balance Due'**
  String get balanceDue;

  /// No description provided for @processPayment.
  ///
  /// In en, this message translates to:
  /// **'Process Payment'**
  String get processPayment;

  /// No description provided for @sendReminder.
  ///
  /// In en, this message translates to:
  /// **'Send Reminder'**
  String get sendReminder;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @sharingOperation.
  ///
  /// In en, this message translates to:
  /// **'Sharing operation...'**
  String get sharingOperation;

  /// No description provided for @printingOperation.
  ///
  /// In en, this message translates to:
  /// **'Printing operation...'**
  String get printingOperation;

  /// No description provided for @processingPayment.
  ///
  /// In en, this message translates to:
  /// **'Processing payment...'**
  String get processingPayment;

  /// No description provided for @sendingReminder.
  ///
  /// In en, this message translates to:
  /// **'Sending reminder...'**
  String get sendingReminder;

  /// No description provided for @noItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// No description provided for @itemsWillBeLoadedFromServer.
  ///
  /// In en, this message translates to:
  /// **'Items will be loaded from the server'**
  String get itemsWillBeLoadedFromServer;

  /// No description provided for @loadItems.
  ///
  /// In en, this message translates to:
  /// **'Load Items'**
  String get loadItems;

  /// No description provided for @loadingItems.
  ///
  /// In en, this message translates to:
  /// **'Loading items...'**
  String get loadingItems;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @fullyPaid.
  ///
  /// In en, this message translates to:
  /// **'Fully Paid'**
  String get fullyPaid;

  /// No description provided for @partiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaid;

  /// No description provided for @cart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cart;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @noSuppliersAvailable.
  ///
  /// In en, this message translates to:
  /// **'No suppliers available'**
  String get noSuppliersAvailable;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @browseAndSelectServices.
  ///
  /// In en, this message translates to:
  /// **'Browse and select services'**
  String get browseAndSelectServices;

  /// No description provided for @noServicesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No services available'**
  String get noServicesAvailable;

  /// No description provided for @servicesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Services will appear here when available'**
  String get servicesWillAppearHere;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;

  /// No description provided for @preparingServiceCatalog.
  ///
  /// In en, this message translates to:
  /// **'Preparing your service catalog'**
  String get preparingServiceCatalog;

  /// No description provided for @refreshServices.
  ///
  /// In en, this message translates to:
  /// **'Refresh Services'**
  String get refreshServices;

  /// No description provided for @transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transaction;

  /// No description provided for @documentType.
  ///
  /// In en, this message translates to:
  /// **'Document Type'**
  String get documentType;

  /// No description provided for @operationType.
  ///
  /// In en, this message translates to:
  /// **'Operation Type'**
  String get operationType;

  /// No description provided for @invoiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Invoice Status'**
  String get invoiceStatus;

  /// No description provided for @deposited.
  ///
  /// In en, this message translates to:
  /// **'Deposited'**
  String get deposited;

  /// No description provided for @productsAndServices.
  ///
  /// In en, this message translates to:
  /// **'Products & Services'**
  String get productsAndServices;

  /// No description provided for @eShopping.
  ///
  /// In en, this message translates to:
  /// **'E-shopping'**
  String get eShopping;

  /// No description provided for @inStorePurchase.
  ///
  /// In en, this message translates to:
  /// **'In-store'**
  String get inStorePurchase;

  /// No description provided for @serviceRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get serviceRepair;

  /// No description provided for @serviceMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get serviceMaintenance;

  /// No description provided for @serviceFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get serviceFix;

  /// No description provided for @serviceConsultation.
  ///
  /// In en, this message translates to:
  /// **'Consultation'**
  String get serviceConsultation;

  /// No description provided for @serviceAdvice.
  ///
  /// In en, this message translates to:
  /// **'Advice'**
  String get serviceAdvice;

  /// No description provided for @serviceInstallation.
  ///
  /// In en, this message translates to:
  /// **'Installation'**
  String get serviceInstallation;

  /// No description provided for @serviceSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get serviceSetup;

  /// No description provided for @serviceDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get serviceDelivery;

  /// No description provided for @serviceShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get serviceShipping;

  /// No description provided for @serviceCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get serviceCleaning;

  /// No description provided for @serviceHousekeeping.
  ///
  /// In en, this message translates to:
  /// **'Housekeeping'**
  String get serviceHousekeeping;

  /// No description provided for @serviceDesign.
  ///
  /// In en, this message translates to:
  /// **'Design'**
  String get serviceDesign;

  /// No description provided for @serviceCreative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get serviceCreative;

  /// No description provided for @serviceTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get serviceTraining;

  /// No description provided for @serviceEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get serviceEducation;

  /// No description provided for @serviceMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get serviceMedical;

  /// No description provided for @serviceHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get serviceHealth;

  /// No description provided for @serviceTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get serviceTech;

  /// No description provided for @serviceIT.
  ///
  /// In en, this message translates to:
  /// **'IT'**
  String get serviceIT;

  /// No description provided for @serviceGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Services'**
  String get serviceGeneral;

  /// No description provided for @serviceBloodTesting.
  ///
  /// In en, this message translates to:
  /// **'Blood Testing'**
  String get serviceBloodTesting;

  /// No description provided for @serviceDiagnosticImaging.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic Imaging'**
  String get serviceDiagnosticImaging;

  /// No description provided for @servicePathologyTests.
  ///
  /// In en, this message translates to:
  /// **'Pathology Tests'**
  String get servicePathologyTests;

  /// No description provided for @serviceUrineAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Urine Analysis'**
  String get serviceUrineAnalysis;

  /// No description provided for @serviceAllergyTesting.
  ///
  /// In en, this message translates to:
  /// **'Allergy Testing'**
  String get serviceAllergyTesting;

  /// No description provided for @serviceGeneticTesting.
  ///
  /// In en, this message translates to:
  /// **'Genetic Testing'**
  String get serviceGeneticTesting;

  /// No description provided for @serviceVaccination.
  ///
  /// In en, this message translates to:
  /// **'Vaccination'**
  String get serviceVaccination;

  /// No description provided for @serviceHealthCheckup.
  ///
  /// In en, this message translates to:
  /// **'Health Check-up'**
  String get serviceHealthCheckup;

  /// No description provided for @serviceDentalCare.
  ///
  /// In en, this message translates to:
  /// **'Dental Care'**
  String get serviceDentalCare;

  /// No description provided for @serviceMinorSurgery.
  ///
  /// In en, this message translates to:
  /// **'Minor Surgery'**
  String get serviceMinorSurgery;

  /// No description provided for @serviceWoundCare.
  ///
  /// In en, this message translates to:
  /// **'Wound Care'**
  String get serviceWoundCare;

  /// No description provided for @serviceIVTherapy.
  ///
  /// In en, this message translates to:
  /// **'IV Therapy'**
  String get serviceIVTherapy;

  /// No description provided for @servicePhysiotherapy.
  ///
  /// In en, this message translates to:
  /// **'Physiotherapy'**
  String get servicePhysiotherapy;

  /// No description provided for @serviceAcupuncture.
  ///
  /// In en, this message translates to:
  /// **'Acupuncture'**
  String get serviceAcupuncture;

  /// No description provided for @serviceNutritionCounseling.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Counseling'**
  String get serviceNutritionCounseling;

  /// No description provided for @serviceMentalHealthCounseling.
  ///
  /// In en, this message translates to:
  /// **'Mental Health Counseling'**
  String get serviceMentalHealthCounseling;

  /// No description provided for @serviceFirstAidTraining.
  ///
  /// In en, this message translates to:
  /// **'First Aid Training'**
  String get serviceFirstAidTraining;

  /// No description provided for @servicePrenatalCare.
  ///
  /// In en, this message translates to:
  /// **'Prenatal Care'**
  String get servicePrenatalCare;

  /// No description provided for @servicePediatricCare.
  ///
  /// In en, this message translates to:
  /// **'Pediatric Care'**
  String get servicePediatricCare;

  /// No description provided for @serviceGeriatricCare.
  ///
  /// In en, this message translates to:
  /// **'Geriatric Care'**
  String get serviceGeriatricCare;

  /// No description provided for @serviceSportsMedicine.
  ///
  /// In en, this message translates to:
  /// **'Sports Medicine'**
  String get serviceSportsMedicine;

  /// No description provided for @serviceGeneralMedical.
  ///
  /// In en, this message translates to:
  /// **'General Medical Service'**
  String get serviceGeneralMedical;

  /// No description provided for @supplierCategoryRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get supplierCategoryRestaurant;

  /// No description provided for @supplierCategoryBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get supplierCategoryBakery;

  /// No description provided for @supplierCategoryFactory.
  ///
  /// In en, this message translates to:
  /// **'Factory'**
  String get supplierCategoryFactory;

  /// No description provided for @supplierCategorySupermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get supplierCategorySupermarket;

  /// No description provided for @supplierCategoryGroceryStore.
  ///
  /// In en, this message translates to:
  /// **'Grocery Store'**
  String get supplierCategoryGroceryStore;

  /// No description provided for @supplierCategoryDistributor.
  ///
  /// In en, this message translates to:
  /// **'Distributor'**
  String get supplierCategoryDistributor;

  /// No description provided for @supplierCategoryCafe.
  ///
  /// In en, this message translates to:
  /// **'Cafe'**
  String get supplierCategoryCafe;

  /// No description provided for @supplierCategoryButcher.
  ///
  /// In en, this message translates to:
  /// **'Butcher'**
  String get supplierCategoryButcher;

  /// No description provided for @supplierCategoryDairy.
  ///
  /// In en, this message translates to:
  /// **'Dairy'**
  String get supplierCategoryDairy;

  /// No description provided for @supplierCategoryBeverage.
  ///
  /// In en, this message translates to:
  /// **'Beverage'**
  String get supplierCategoryBeverage;

  /// No description provided for @suppliers.
  ///
  /// In en, this message translates to:
  /// **'Suppliers'**
  String get suppliers;

  /// No description provided for @noSuppliersFound.
  ///
  /// In en, this message translates to:
  /// **'No suppliers found'**
  String get noSuppliersFound;

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// No description provided for @supplierType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get supplierType;

  /// No description provided for @supplierContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get supplierContact;

  /// No description provided for @supplierAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get supplierAddress;

  /// No description provided for @supplierRating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get supplierRating;

  /// No description provided for @supplierProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get supplierProducts;

  /// No description provided for @viewSupplierDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewSupplierDetails;

  /// No description provided for @noInvoicesFound.
  ///
  /// In en, this message translates to:
  /// **'No invoices found'**
  String get noInvoicesFound;

  /// No description provided for @noResultsForFilter.
  ///
  /// In en, this message translates to:
  /// **'No results for current filter'**
  String get noResultsForFilter;

  /// No description provided for @createYourFirstInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create your first invoice to get started'**
  String get createYourFirstInvoice;

  /// No description provided for @tryDifferentFilter.
  ///
  /// In en, this message translates to:
  /// **'Try a different filter or search term'**
  String get tryDifferentFilter;

  /// No description provided for @createInvoice.
  ///
  /// In en, this message translates to:
  /// **'Create Invoice'**
  String get createInvoice;

  /// No description provided for @searchInvoices.
  ///
  /// In en, this message translates to:
  /// **'Search invoices...'**
  String get searchInvoices;

  /// No description provided for @advancedFilter.
  ///
  /// In en, this message translates to:
  /// **'Advanced Filter'**
  String get advancedFilter;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @amountRange.
  ///
  /// In en, this message translates to:
  /// **'Amount Range'**
  String get amountRange;

  /// No description provided for @minAmount.
  ///
  /// In en, this message translates to:
  /// **'Min Amount'**
  String get minAmount;

  /// No description provided for @maxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max Amount'**
  String get maxAmount;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @quote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get quote;

  /// No description provided for @allDocuments.
  ///
  /// In en, this message translates to:
  /// **'All Documents'**
  String get allDocuments;

  /// No description provided for @editDocument.
  ///
  /// In en, this message translates to:
  /// **'Edit Document'**
  String get editDocument;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @shareDocument.
  ///
  /// In en, this message translates to:
  /// **'Share Document'**
  String get shareDocument;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get markAsPaid;

  /// No description provided for @deleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Delete Document'**
  String get deleteDocument;

  /// No description provided for @createNewDocument.
  ///
  /// In en, this message translates to:
  /// **'Create New Document'**
  String get createNewDocument;

  /// No description provided for @createInvoiceDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a new invoice'**
  String get createInvoiceDescription;

  /// No description provided for @createReceiptDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a payment receipt'**
  String get createReceiptDescription;

  /// No description provided for @createQuoteDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a quotation'**
  String get createQuoteDescription;

  /// No description provided for @documentMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Document marked as paid'**
  String get documentMarkedAsPaid;

  /// No description provided for @failedToUpdate.
  ///
  /// In en, this message translates to:
  /// **'Failed to update document'**
  String get failedToUpdate;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @deleteDocumentConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this document?'**
  String get deleteDocumentConfirmation;

  /// No description provided for @documentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Document deleted'**
  String get documentDeleted;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete document'**
  String get failedToDelete;

  /// No description provided for @totalInvoices.
  ///
  /// In en, this message translates to:
  /// **'Total Invoices'**
  String get totalInvoices;

  /// No description provided for @averageInvoice.
  ///
  /// In en, this message translates to:
  /// **'Average Invoice'**
  String get averageInvoice;

  /// No description provided for @pendingInvoices.
  ///
  /// In en, this message translates to:
  /// **'Pending Invoices'**
  String get pendingInvoices;

  /// No description provided for @paidInvoices.
  ///
  /// In en, this message translates to:
  /// **'Paid Invoices'**
  String get paidInvoices;

  /// No description provided for @overdueInvoices.
  ///
  /// In en, this message translates to:
  /// **'Overdue Invoices'**
  String get overdueInvoices;

  /// No description provided for @revenueThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Revenue This Month'**
  String get revenueThisMonth;

  /// No description provided for @revenueLastMonth.
  ///
  /// In en, this message translates to:
  /// **'Revenue Last Month'**
  String get revenueLastMonth;

  /// No description provided for @topClients.
  ///
  /// In en, this message translates to:
  /// **'Top Clients'**
  String get topClients;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @customRange.
  ///
  /// In en, this message translates to:
  /// **'Custom Range'**
  String get customRange;

  /// No description provided for @exportAsCsv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportAsCsv;

  /// No description provided for @exportAsExcel.
  ///
  /// In en, this message translates to:
  /// **'Export as Excel'**
  String get exportAsExcel;

  /// No description provided for @exportAsPdf.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get exportAsPdf;

  /// No description provided for @exportAll.
  ///
  /// In en, this message translates to:
  /// **'Export All'**
  String get exportAll;

  /// No description provided for @exportSelected.
  ///
  /// In en, this message translates to:
  /// **'Export Selected'**
  String get exportSelected;

  /// No description provided for @exportSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Export successful'**
  String get exportSuccessful;

  /// No description provided for @filterApplied.
  ///
  /// In en, this message translates to:
  /// **'Filter applied'**
  String get filterApplied;

  /// No description provided for @filterCleared.
  ///
  /// In en, this message translates to:
  /// **'Filter cleared'**
  String get filterCleared;

  /// No description provided for @documentSaved.
  ///
  /// In en, this message translates to:
  /// **'Document saved successfully'**
  String get documentSaved;

  /// No description provided for @paymentRecorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get paymentRecorded;

  /// No description provided for @noDocumentsToExport.
  ///
  /// In en, this message translates to:
  /// **'No documents to export'**
  String get noDocumentsToExport;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed. Please try again.'**
  String get exportFailed;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load documents'**
  String get loadFailed;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet.'**
  String get connectionError;

  /// No description provided for @serverErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverErrorGeneric;

  /// No description provided for @loadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading more...'**
  String get loadingMore;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @processingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processingEllipsis;

  /// No description provided for @documentNumber.
  ///
  /// In en, this message translates to:
  /// **'Document #'**
  String get documentNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get dueDate;

  /// No description provided for @issueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue Date'**
  String get issueDate;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms'**
  String get terms;

  /// No description provided for @addItem.
  ///
  /// In en, this message translates to:
  /// **'Add Item'**
  String get addItem;

  /// No description provided for @removeItem.
  ///
  /// In en, this message translates to:
  /// **'Remove Item'**
  String get removeItem;

  /// No description provided for @calculateTotal.
  ///
  /// In en, this message translates to:
  /// **'Calculate Total'**
  String get calculateTotal;

  /// No description provided for @sendEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Email'**
  String get sendEmail;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @reject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @filterByDate.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date'**
  String get filterByDate;

  /// No description provided for @filterByAmount.
  ///
  /// In en, this message translates to:
  /// **'Filter by Amount'**
  String get filterByAmount;

  /// No description provided for @filterByStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Status'**
  String get filterByStatus;

  /// No description provided for @filterByType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Type'**
  String get filterByType;

  /// No description provided for @filterByClient.
  ///
  /// In en, this message translates to:
  /// **'Filter by Client'**
  String get filterByClient;

  /// No description provided for @filterBySupplier.
  ///
  /// In en, this message translates to:
  /// **'Filter by Supplier'**
  String get filterBySupplier;

  /// No description provided for @january.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get january;

  /// No description provided for @february.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get february;

  /// No description provided for @march.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get march;

  /// No description provided for @april.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get april;

  /// No description provided for @may.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get may;

  /// No description provided for @june.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get june;

  /// No description provided for @july.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get july;

  /// No description provided for @august.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get august;

  /// No description provided for @september.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get september;

  /// No description provided for @october.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get october;

  /// No description provided for @november.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get november;

  /// No description provided for @december.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get december;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// No description provided for @daysFromNow.
  ///
  /// In en, this message translates to:
  /// **'{count} days from now'**
  String daysFromNow(int count);

  /// No description provided for @deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get deposit;

  /// No description provided for @pendingCart.
  ///
  /// In en, this message translates to:
  /// **'Pending Cart'**
  String get pendingCart;

  /// No description provided for @depositReceived.
  ///
  /// In en, this message translates to:
  /// **'Deposit Received'**
  String get depositReceived;

  /// No description provided for @depositCoversFull.
  ///
  /// In en, this message translates to:
  /// **'Deposit Covers Full'**
  String get depositCoversFull;

  /// No description provided for @depositPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial Deposit'**
  String get depositPartial;

  /// No description provided for @depositFullyCovered.
  ///
  /// In en, this message translates to:
  /// **'Deposit Fully Covered'**
  String get depositFullyCovered;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @person.
  ///
  /// In en, this message translates to:
  /// **'Person'**
  String get person;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @directInvoice.
  ///
  /// In en, this message translates to:
  /// **'Direct Invoice'**
  String get directInvoice;

  /// No description provided for @serviceBased.
  ///
  /// In en, this message translates to:
  /// **'Service Based'**
  String get serviceBased;

  /// No description provided for @directDeposit.
  ///
  /// In en, this message translates to:
  /// **'Direct Deposit'**
  String get directDeposit;

  /// No description provided for @financialDocuments.
  ///
  /// In en, this message translates to:
  /// **'Financial Documents'**
  String get financialDocuments;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummary;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @count.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// No description provided for @paymentProgress.
  ///
  /// In en, this message translates to:
  /// **'Payment Progress'**
  String get paymentProgress;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocumentsFound;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Loading documents...'**
  String get loadingDocuments;

  /// No description provided for @errorLoadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Error Loading Documents'**
  String get errorLoadingDocuments;

  /// No description provided for @again.
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get again;

  /// No description provided for @nServicesSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No services selected}=1{1 service selected}other{{count} services selected}}'**
  String nServicesSelected(int count);

  /// No description provided for @configureService.
  ///
  /// In en, this message translates to:
  /// **'Configure Service'**
  String get configureService;

  /// No description provided for @scheduleService.
  ///
  /// In en, this message translates to:
  /// **'Schedule Service'**
  String get scheduleService;

  /// No description provided for @serviceWillBeScheduled.
  ///
  /// In en, this message translates to:
  /// **'Service will be scheduled'**
  String get serviceWillBeScheduled;

  /// No description provided for @addSchedulingInfo.
  ///
  /// In en, this message translates to:
  /// **'Add scheduling information'**
  String get addSchedulingInfo;

  /// No description provided for @scheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Date'**
  String get scheduledDate;

  /// No description provided for @scheduledTime.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Time'**
  String get scheduledTime;

  /// No description provided for @specialInstructions.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get specialInstructions;

  /// No description provided for @addNotesHere.
  ///
  /// In en, this message translates to:
  /// **'Add notes here...'**
  String get addNotesHere;

  /// No description provided for @serviceParameters.
  ///
  /// In en, this message translates to:
  /// **'Service Parameters'**
  String get serviceParameters;

  /// No description provided for @customizeServiceParameters.
  ///
  /// In en, this message translates to:
  /// **'Customize service parameters'**
  String get customizeServiceParameters;

  /// No description provided for @saveConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Save Configuration'**
  String get saveConfiguration;

  /// No description provided for @services_view_title.
  ///
  /// In en, this message translates to:
  /// **'View Services'**
  String get services_view_title;

  /// No description provided for @services_view_description.
  ///
  /// In en, this message translates to:
  /// **'View available services and pricing'**
  String get services_view_description;

  /// No description provided for @services_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Services'**
  String get services_manage_title;

  /// No description provided for @services_manage_description.
  ///
  /// In en, this message translates to:
  /// **'Add, edit, and remove services'**
  String get services_manage_description;

  /// No description provided for @pos_view_title.
  ///
  /// In en, this message translates to:
  /// **'View POS'**
  String get pos_view_title;

  /// No description provided for @pos_view_description.
  ///
  /// In en, this message translates to:
  /// **'View point of sale transactions'**
  String get pos_view_description;

  /// No description provided for @pos_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage POS'**
  String get pos_manage_title;

  /// No description provided for @pos_manage_description.
  ///
  /// In en, this message translates to:
  /// **'Process sales and manage POS operations'**
  String get pos_manage_description;

  /// No description provided for @operations_view_title.
  ///
  /// In en, this message translates to:
  /// **'View Operations'**
  String get operations_view_title;

  /// No description provided for @operations_view_description.
  ///
  /// In en, this message translates to:
  /// **'View operational reports and metrics'**
  String get operations_view_description;

  /// No description provided for @operations_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Operations'**
  String get operations_manage_title;

  /// No description provided for @operations_manage_description.
  ///
  /// In en, this message translates to:
  /// **'Configure system operations and settings'**
  String get operations_manage_description;

  /// No description provided for @finance_view_title.
  ///
  /// In en, this message translates to:
  /// **'View Finance'**
  String get finance_view_title;

  /// No description provided for @finance_view_description.
  ///
  /// In en, this message translates to:
  /// **'View financial reports and transactions'**
  String get finance_view_description;

  /// No description provided for @finance_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Finance'**
  String get finance_manage_title;

  /// No description provided for @finance_manage_description.
  ///
  /// In en, this message translates to:
  /// **'Manage financial operations and accounting'**
  String get finance_manage_description;

  /// No description provided for @category_services.
  ///
  /// In en, this message translates to:
  /// **'Services Management'**
  String get category_services;

  /// No description provided for @category_pos.
  ///
  /// In en, this message translates to:
  /// **'POS Management'**
  String get category_pos;

  /// No description provided for @category_operations.
  ///
  /// In en, this message translates to:
  /// **'Operations Management'**
  String get category_operations;

  /// No description provided for @category_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance Management'**
  String get category_finance;

  /// No description provided for @permissionScore.
  ///
  /// In en, this message translates to:
  /// **'Permission Score'**
  String get permissionScore;

  /// No description provided for @privileges.
  ///
  /// In en, this message translates to:
  /// **'Privileges'**
  String get privileges;

  /// No description provided for @savePrivileges.
  ///
  /// In en, this message translates to:
  /// **'Save Privileges'**
  String get savePrivileges;

  /// No description provided for @privilegesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Privileges updated successfully'**
  String get privilegesUpdated;

  /// No description provided for @confirmPrivilegeChange.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change privileges?'**
  String get confirmPrivilegeChange;

  /// No description provided for @noPrivilegesSelected.
  ///
  /// In en, this message translates to:
  /// **'No privileges selected'**
  String get noPrivilegesSelected;

  /// No description provided for @fullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get fullAccess;

  /// No description provided for @limitedAccess.
  ///
  /// In en, this message translates to:
  /// **'Limited Access'**
  String get limitedAccess;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View Only'**
  String get viewOnly;

  /// No description provided for @manageAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage Access'**
  String get manageAccess;

  /// No description provided for @togglePrivilegeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle privilege'**
  String get togglePrivilegeTooltip;

  /// No description provided for @categoryToggleTooltip.
  ///
  /// In en, this message translates to:
  /// **'Toggle all category privileges'**
  String get categoryToggleTooltip;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @last.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get last;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @activeSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Active Suppliers'**
  String get activeSuppliers;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @accountsReceivable.
  ///
  /// In en, this message translates to:
  /// **'Accounts Receivable'**
  String get accountsReceivable;

  /// No description provided for @accountsPayable.
  ///
  /// In en, this message translates to:
  /// **'Accounts Payable'**
  String get accountsPayable;

  /// No description provided for @cashFlow.
  ///
  /// In en, this message translates to:
  /// **'Cash Flow'**
  String get cashFlow;

  /// No description provided for @roi.
  ///
  /// In en, this message translates to:
  /// **'ROI'**
  String get roi;

  /// No description provided for @breakEven.
  ///
  /// In en, this message translates to:
  /// **'Break Even'**
  String get breakEven;

  /// No description provided for @revenueGrowth.
  ///
  /// In en, this message translates to:
  /// **'Revenue Growth'**
  String get revenueGrowth;

  /// No description provided for @customerLifetimeValue.
  ///
  /// In en, this message translates to:
  /// **'Customer Lifetime Value'**
  String get customerLifetimeValue;

  /// No description provided for @dailyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Daily Revenue'**
  String get dailyRevenue;

  /// No description provided for @weeklyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Weekly Revenue'**
  String get weeklyRevenue;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @yearlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Yearly Revenue'**
  String get yearlyRevenue;

  /// No description provided for @revenueTrend.
  ///
  /// In en, this message translates to:
  /// **'Revenue Trend'**
  String get revenueTrend;

  /// No description provided for @profitTrend.
  ///
  /// In en, this message translates to:
  /// **'Profit Trend'**
  String get profitTrend;

  /// No description provided for @expenseBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Expense Breakdown'**
  String get expenseBreakdown;

  /// No description provided for @categoryBreakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get categoryBreakdown;

  /// No description provided for @filterByCustomer.
  ///
  /// In en, this message translates to:
  /// **'Filter by Customer'**
  String get filterByCustomer;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @exportAsCSV.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get exportAsCSV;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @downloadReport.
  ///
  /// In en, this message translates to:
  /// **'Download Report'**
  String get downloadReport;

  /// No description provided for @printReport.
  ///
  /// In en, this message translates to:
  /// **'Print Report'**
  String get printReport;

  /// No description provided for @shareReport.
  ///
  /// In en, this message translates to:
  /// **'Share Report'**
  String get shareReport;

  /// No description provided for @saveReport.
  ///
  /// In en, this message translates to:
  /// **'Save Report'**
  String get saveReport;

  /// No description provided for @refreshData.
  ///
  /// In en, this message translates to:
  /// **'Refresh Data'**
  String get refreshData;

  /// No description provided for @dataExportedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully'**
  String get dataExportedSuccessfully;

  /// No description provided for @reportGeneratedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGeneratedSuccessfully;

  /// No description provided for @noDataToExport.
  ///
  /// In en, this message translates to:
  /// **'No data to export'**
  String get noDataToExport;

  /// No description provided for @loadingFinancialData.
  ///
  /// In en, this message translates to:
  /// **'Loading financial data...'**
  String get loadingFinancialData;

  /// No description provided for @calculatingStatistics.
  ///
  /// In en, this message translates to:
  /// **'Calculating statistics...'**
  String get calculatingStatistics;

  /// No description provided for @hoverForDetails.
  ///
  /// In en, this message translates to:
  /// **'Hover for details'**
  String get hoverForDetails;

  /// No description provided for @clickToViewDetails.
  ///
  /// In en, this message translates to:
  /// **'Click to view details'**
  String get clickToViewDetails;

  /// No description provided for @doubleClickToEdit.
  ///
  /// In en, this message translates to:
  /// **'Double click to edit'**
  String get doubleClickToEdit;

  /// No description provided for @dragToResize.
  ///
  /// In en, this message translates to:
  /// **'Drag to resize'**
  String get dragToResize;

  /// No description provided for @noTransactionsFound.
  ///
  /// In en, this message translates to:
  /// **'No transactions found'**
  String get noTransactionsFound;

  /// No description provided for @noRevenueData.
  ///
  /// In en, this message translates to:
  /// **'No revenue data available'**
  String get noRevenueData;

  /// No description provided for @noExpenseData.
  ///
  /// In en, this message translates to:
  /// **'No expense data available'**
  String get noExpenseData;

  /// No description provided for @noProfitData.
  ///
  /// In en, this message translates to:
  /// **'No profit data available'**
  String get noProfitData;

  /// No description provided for @summary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get summary;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @detailedView.
  ///
  /// In en, this message translates to:
  /// **'Detailed View'**
  String get detailedView;

  /// No description provided for @quickView.
  ///
  /// In en, this message translates to:
  /// **'Quick View'**
  String get quickView;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get trends;

  /// No description provided for @comparison.
  ///
  /// In en, this message translates to:
  /// **'Comparison'**
  String get comparison;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @actual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actual;

  /// No description provided for @variance.
  ///
  /// In en, this message translates to:
  /// **'Variance'**
  String get variance;

  /// No description provided for @achievement.
  ///
  /// In en, this message translates to:
  /// **'Achievement'**
  String get achievement;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @projection.
  ///
  /// In en, this message translates to:
  /// **'Projection'**
  String get projection;

  /// No description provided for @estimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate'**
  String get estimate;

  /// No description provided for @vsLastPeriod.
  ///
  /// In en, this message translates to:
  /// **'vs Last Period'**
  String get vsLastPeriod;

  /// No description provided for @vsLastYear.
  ///
  /// In en, this message translates to:
  /// **'vs Last Year'**
  String get vsLastYear;

  /// No description provided for @vsTarget.
  ///
  /// In en, this message translates to:
  /// **'vs Target'**
  String get vsTarget;

  /// No description provided for @vsBudget.
  ///
  /// In en, this message translates to:
  /// **'vs Budget'**
  String get vsBudget;

  /// No description provided for @vsAverage.
  ///
  /// In en, this message translates to:
  /// **'vs Average'**
  String get vsAverage;

  /// No description provided for @quickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get quickStats;

  /// No description provided for @todayRevenue.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Revenue'**
  String get todayRevenue;

  /// No description provided for @weekRevenue.
  ///
  /// In en, this message translates to:
  /// **'Week\'s Revenue'**
  String get weekRevenue;

  /// No description provided for @monthRevenue.
  ///
  /// In en, this message translates to:
  /// **'Month\'s Revenue'**
  String get monthRevenue;

  /// No description provided for @yearRevenue.
  ///
  /// In en, this message translates to:
  /// **'Year\'s Revenue'**
  String get yearRevenue;

  /// No description provided for @revenuePerCustomer.
  ///
  /// In en, this message translates to:
  /// **'Revenue per Customer'**
  String get revenuePerCustomer;

  /// No description provided for @averageTransaction.
  ///
  /// In en, this message translates to:
  /// **'Average Transaction'**
  String get averageTransaction;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'minutes ago'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'hours ago'**
  String get hoursAgo;

  /// No description provided for @daysAgoLower.
  ///
  /// In en, this message translates to:
  /// **'days ago'**
  String get daysAgoLower;

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'weeks ago'**
  String get weeksAgo;

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'months ago'**
  String get monthsAgo;

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'years ago'**
  String get yearsAgo;

  /// No description provided for @documentsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Documents Count'**
  String get documentsCountLabel;

  /// No description provided for @totalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Total Documents'**
  String get totalDocuments;

  /// No description provided for @averageDocument.
  ///
  /// In en, this message translates to:
  /// **'Average per Document'**
  String get averageDocument;

  /// No description provided for @stock.
  ///
  /// In en, this message translates to:
  /// **'Stock: {stock}'**
  String stock(String stock);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'Items: {count}'**
  String itemsCount(int count);

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'{cartItemCount, plural,  =0 {No items}  one {# item}  other {# items}} ({itemCount, plural,  =0 {no products}  one {one product}  other {{itemCount} products}}, {serviceCount, plural,  =0 {no services}  one {one service}  other {{serviceCount} services}})'**
  String items(int cartItemCount, int itemCount, int serviceCount);

  /// No description provided for @itemsText.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsText;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @orderConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed'**
  String get orderConfirmed;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed successfully'**
  String get orderPlacedSuccessfully;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @guestCustomer.
  ///
  /// In en, this message translates to:
  /// **'Guest Customer'**
  String get guestCustomer;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'Order Items'**
  String get orderItems;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @deliveryType.
  ///
  /// In en, this message translates to:
  /// **'Delivery Type'**
  String get deliveryType;

  /// No description provided for @pickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// No description provided for @pickupDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick up from store location'**
  String get pickupDesc;

  /// No description provided for @delivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// No description provided for @deliveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Same day delivery available'**
  String get deliveryDesc;

  /// No description provided for @shipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get shipping;

  /// No description provided for @shippingDesc.
  ///
  /// In en, this message translates to:
  /// **'Standard shipping (3-5 business days)'**
  String get shippingDesc;

  /// No description provided for @orderNotes.
  ///
  /// In en, this message translates to:
  /// **'Order Notes'**
  String get orderNotes;

  /// No description provided for @notesHint.
  ///
  /// In en, this message translates to:
  /// **'Special instructions, delivery notes, etc.'**
  String get notesHint;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @searchCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search customers...'**
  String get searchCustomers;

  /// No description provided for @invoiceReceipt.
  ///
  /// In en, this message translates to:
  /// **'Invoice + Receipt'**
  String get invoiceReceipt;

  /// No description provided for @receiptOnly.
  ///
  /// In en, this message translates to:
  /// **'Receipt Only'**
  String get receiptOnly;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @paymentType.
  ///
  /// In en, this message translates to:
  /// **'Payment Type'**
  String get paymentType;

  /// No description provided for @fullPayment.
  ///
  /// In en, this message translates to:
  /// **'Full Payment'**
  String get fullPayment;

  /// No description provided for @depositOnly.
  ///
  /// In en, this message translates to:
  /// **'Deposit Only'**
  String get depositOnly;

  /// No description provided for @check.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get check;

  /// No description provided for @cardDetails.
  ///
  /// In en, this message translates to:
  /// **'Card Details'**
  String get cardDetails;

  /// No description provided for @cardType.
  ///
  /// In en, this message translates to:
  /// **'Card Type'**
  String get cardType;

  /// No description provided for @cardNumber.
  ///
  /// In en, this message translates to:
  /// **'Card Number'**
  String get cardNumber;

  /// No description provided for @expiryDate.
  ///
  /// In en, this message translates to:
  /// **'Expiry Date'**
  String get expiryDate;

  /// No description provided for @bankTransferDetails.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer Details'**
  String get bankTransferDetails;

  /// No description provided for @bankName.
  ///
  /// In en, this message translates to:
  /// **'Bank Name'**
  String get bankName;

  /// No description provided for @accountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get accountNumber;

  /// No description provided for @reference.
  ///
  /// In en, this message translates to:
  /// **'Reference'**
  String get reference;

  /// No description provided for @mobilePaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Mobile Payment Details'**
  String get mobilePaymentDetails;

  /// No description provided for @serviceProvider.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get serviceProvider;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @checkDetails.
  ///
  /// In en, this message translates to:
  /// **'Check Details'**
  String get checkDetails;

  /// No description provided for @checkPaymentNote.
  ///
  /// In en, this message translates to:
  /// **'Payment by check will be processed once received and cleared.'**
  String get checkPaymentNote;

  /// No description provided for @printDocument.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get printDocument;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @selectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get selectCustomer;

  /// No description provided for @searchForCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search for customer'**
  String get searchForCustomer;

  /// No description provided for @searchCustomersHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or phone...'**
  String get searchCustomersHint;

  /// No description provided for @searchCustomerInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter customer name, email, or phone number to search'**
  String get searchCustomerInstructions;

  /// No description provided for @addNewCustomer.
  ///
  /// In en, this message translates to:
  /// **'Add New Customer'**
  String get addNewCustomer;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @noCustomersFound.
  ///
  /// In en, this message translates to:
  /// **'No customers found'**
  String get noCustomersFound;

  /// No description provided for @adjustSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get adjustSearchTerms;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search results'**
  String get searchResults;

  /// No description provided for @addNewCustomerInstruction.
  ///
  /// In en, this message translates to:
  /// **'Create a new customer profile to add them to the system'**
  String get addNewCustomerInstruction;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @customerDetails.
  ///
  /// In en, this message translates to:
  /// **'Customer Details'**
  String get customerDetails;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @editCustomer.
  ///
  /// In en, this message translates to:
  /// **'Edit Customer'**
  String get editCustomer;

  /// No description provided for @removeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Remove Customer'**
  String get removeCustomer;

  /// No description provided for @checkoutHelp.
  ///
  /// In en, this message translates to:
  /// **'Checkout Help'**
  String get checkoutHelp;

  /// No description provided for @customerHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Select or search for a customer to associate with this order'**
  String get customerHelpDescription;

  /// No description provided for @documentTypeHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose the type of document you want to generate'**
  String get documentTypeHelpDescription;

  /// No description provided for @paymentMethodHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred payment method'**
  String get paymentMethodHelpDescription;

  /// No description provided for @notesParametersHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Add notes and custom parameters to this order'**
  String get notesParametersHelpDescription;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @notesParameters.
  ///
  /// In en, this message translates to:
  /// **'Notes & Parameters'**
  String get notesParameters;

  /// No description provided for @parameters.
  ///
  /// In en, this message translates to:
  /// **'Parameters'**
  String get parameters;

  /// No description provided for @addParameter.
  ///
  /// In en, this message translates to:
  /// **'Add Parameter'**
  String get addParameter;

  /// No description provided for @editParameter.
  ///
  /// In en, this message translates to:
  /// **'Edit Parameter'**
  String get editParameter;

  /// No description provided for @noParametersAdded.
  ///
  /// In en, this message translates to:
  /// **'No parameters added'**
  String get noParametersAdded;

  /// No description provided for @addParametersToCustomizeOrder.
  ///
  /// In en, this message translates to:
  /// **'Add parameters to customize this order'**
  String get addParametersToCustomizeOrder;

  /// No description provided for @changeCustomer.
  ///
  /// In en, this message translates to:
  /// **'Change Customer'**
  String get changeCustomer;

  /// No description provided for @installment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get installment;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @addParameterDescription.
  ///
  /// In en, this message translates to:
  /// **'Add a custom parameter to this order'**
  String get addParameterDescription;

  /// No description provided for @parameterKey.
  ///
  /// In en, this message translates to:
  /// **'Parameter Key'**
  String get parameterKey;

  /// No description provided for @parameterKeyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Priority, Special Instructions'**
  String get parameterKeyHint;

  /// No description provided for @parameterKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a key'**
  String get parameterKeyRequired;

  /// No description provided for @parameterKeyTooLong.
  ///
  /// In en, this message translates to:
  /// **'Key is too long (max 50 characters)'**
  String get parameterKeyTooLong;

  /// No description provided for @parameterValue.
  ///
  /// In en, this message translates to:
  /// **'Parameter Value'**
  String get parameterValue;

  /// No description provided for @parameterValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., High, Handle with care'**
  String get parameterValueHint;

  /// No description provided for @parameterValueRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a value'**
  String get parameterValueRequired;

  /// No description provided for @parameterValueTooLong.
  ///
  /// In en, this message translates to:
  /// **'Value is too long (max 200 characters)'**
  String get parameterValueTooLong;

  /// No description provided for @suggestedParameters.
  ///
  /// In en, this message translates to:
  /// **'Suggested Parameters'**
  String get suggestedParameters;

  /// No description provided for @saveLabel.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// No description provided for @pleaseSelectCustomer.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer'**
  String get pleaseSelectCustomer;

  /// No description provided for @cartEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmpty;

  /// No description provided for @pleaseEnterCardDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter card details'**
  String get pleaseEnterCardDetails;

  /// No description provided for @pleaseEnterBankDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter bank details'**
  String get pleaseEnterBankDetails;

  /// No description provided for @pleaseEnterMobilePaymentDetails.
  ///
  /// In en, this message translates to:
  /// **'Please select mobile payment provider'**
  String get pleaseEnterMobilePaymentDetails;

  /// No description provided for @visa.
  ///
  /// In en, this message translates to:
  /// **'VISA'**
  String get visa;

  /// No description provided for @mastercard.
  ///
  /// In en, this message translates to:
  /// **'MasterCard'**
  String get mastercard;

  /// No description provided for @amex.
  ///
  /// In en, this message translates to:
  /// **'American Express'**
  String get amex;

  /// No description provided for @orangeMoney.
  ///
  /// In en, this message translates to:
  /// **'Orange Money'**
  String get orangeMoney;

  /// No description provided for @ooredooMoney.
  ///
  /// In en, this message translates to:
  /// **'Ooredoo Money'**
  String get ooredooMoney;

  /// No description provided for @nedjmaPay.
  ///
  /// In en, this message translates to:
  /// **'Nedjma Pay'**
  String get nedjmaPay;

  /// No description provided for @paypal.
  ///
  /// In en, this message translates to:
  /// **'PayPal'**
  String get paypal;

  /// No description provided for @stcPay.
  ///
  /// In en, this message translates to:
  /// **'STC Pay'**
  String get stcPay;

  /// No description provided for @saveToPreferences.
  ///
  /// In en, this message translates to:
  /// **'Save to preferences for future use'**
  String get saveToPreferences;

  /// No description provided for @savedParameters.
  ///
  /// In en, this message translates to:
  /// **'Saved Parameters'**
  String get savedParameters;

  /// No description provided for @currentParameters.
  ///
  /// In en, this message translates to:
  /// **'Current Parameters'**
  String get currentParameters;

  /// No description provided for @noSavedParameters.
  ///
  /// In en, this message translates to:
  /// **'No saved parameters yet'**
  String get noSavedParameters;

  /// No description provided for @manageSavedParameters.
  ///
  /// In en, this message translates to:
  /// **'Manage Saved Parameters'**
  String get manageSavedParameters;

  /// No description provided for @selectCustomerForOrder.
  ///
  /// In en, this message translates to:
  /// **'Select a customer for this order'**
  String get selectCustomerForOrder;

  /// No description provided for @searchForCustomers.
  ///
  /// In en, this message translates to:
  /// **'Search for customers'**
  String get searchForCustomers;

  /// No description provided for @enterNameOrEmailToFindCustomers.
  ///
  /// In en, this message translates to:
  /// **'Enter name, username or email to find customers'**
  String get enterNameOrEmailToFindCustomers;

  /// No description provided for @allCustomers.
  ///
  /// In en, this message translates to:
  /// **'All customers'**
  String get allCustomers;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @newCustomerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'New customer creation coming soon'**
  String get newCustomerComingSoon;

  /// No description provided for @selectPaymentType.
  ///
  /// In en, this message translates to:
  /// **'Select how you want to pay'**
  String get selectPaymentType;

  /// No description provided for @fullPaymentDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay the full amount now'**
  String get fullPaymentDesc;

  /// No description provided for @fullPaymentApplied.
  ///
  /// In en, this message translates to:
  /// **'Full Payment Applied'**
  String get fullPaymentApplied;

  /// No description provided for @fullPaymentDescDetail.
  ///
  /// In en, this message translates to:
  /// **'You will be charged the full amount immediately'**
  String get fullPaymentDescDetail;

  /// No description provided for @depositOnlyDesc.
  ///
  /// In en, this message translates to:
  /// **'Pay a deposit now, balance later'**
  String get depositOnlyDesc;

  /// No description provided for @enterDepositAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter deposit amount'**
  String get enterDepositAmount;

  /// No description provided for @enterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get enterAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining amount'**
  String get remainingAmount;

  /// No description provided for @installmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Schedule payment for later'**
  String get installmentDesc;

  /// No description provided for @selectInstallmentDate.
  ///
  /// In en, this message translates to:
  /// **'Select installment date'**
  String get selectInstallmentDate;

  /// No description provided for @installmentDate.
  ///
  /// In en, this message translates to:
  /// **'Installment Date'**
  String get installmentDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDate;

  /// No description provided for @installmentNote.
  ///
  /// In en, this message translates to:
  /// **'The full amount will be charged on the selected date'**
  String get installmentNote;

  /// No description provided for @persons.
  ///
  /// In en, this message translates to:
  /// **'Persons'**
  String get persons;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @searchForPersons.
  ///
  /// In en, this message translates to:
  /// **'Search for persons'**
  String get searchForPersons;

  /// No description provided for @enterNameToFindPersons.
  ///
  /// In en, this message translates to:
  /// **'Enter a name to find persons'**
  String get enterNameToFindPersons;

  /// No description provided for @noPersonsFound.
  ///
  /// In en, this message translates to:
  /// **'No persons found'**
  String get noPersonsFound;

  /// No description provided for @tryDifferentName.
  ///
  /// In en, this message translates to:
  /// **'Try a different name'**
  String get tryDifferentName;

  /// No description provided for @recentCustomers.
  ///
  /// In en, this message translates to:
  /// **'Recent customers'**
  String get recentCustomers;

  /// No description provided for @noCustomersYet.
  ///
  /// In en, this message translates to:
  /// **'No customers yet'**
  String get noCustomersYet;

  /// No description provided for @startByAddingCustomers.
  ///
  /// In en, this message translates to:
  /// **'Start by adding customers from below'**
  String get startByAddingCustomers;

  /// No description provided for @personAccounts.
  ///
  /// In en, this message translates to:
  /// **'Person Accounts'**
  String get personAccounts;

  /// No description provided for @userAccounts.
  ///
  /// In en, this message translates to:
  /// **'User Accounts'**
  String get userAccounts;

  /// No description provided for @confirmCheckout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Checkout'**
  String get confirmCheckout;

  /// No description provided for @checkoutSummary.
  ///
  /// In en, this message translates to:
  /// **'Checkout Summary'**
  String get checkoutSummary;

  /// No description provided for @mobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile Money'**
  String get mobileMoney;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @orderSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Order Successful'**
  String get orderSuccessful;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @viewOrders.
  ///
  /// In en, this message translates to:
  /// **'View Orders'**
  String get viewOrders;

  /// No description provided for @confirmAndPay.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Pay'**
  String get confirmAndPay;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @processingOrder.
  ///
  /// In en, this message translates to:
  /// **'Processing your order...'**
  String get processingOrder;

  /// No description provided for @cartEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyError;

  /// No description provided for @customerRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please select a customer'**
  String get customerRequiredError;

  /// No description provided for @loginRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Please log in to checkout'**
  String get loginRequiredError;

  /// No description provided for @checkoutError.
  ///
  /// In en, this message translates to:
  /// **'Checkout Error'**
  String get checkoutError;

  /// No description provided for @itemsHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Review the items in your cart before checkout. You can modify quantities if needed.'**
  String get itemsHelpDescription;

  /// No description provided for @deliveryHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose whether the customer will pick up the order or if it needs to be delivered.'**
  String get deliveryHelpDescription;

  /// No description provided for @deliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'Delivery Details'**
  String get deliveryDetails;

  /// No description provided for @packageDetails.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packageDetails;

  /// No description provided for @packageCount.
  ///
  /// In en, this message translates to:
  /// **'Package Count'**
  String get packageCount;

  /// No description provided for @totalWeight.
  ///
  /// In en, this message translates to:
  /// **'Total Weight (kg)'**
  String get totalWeight;

  /// No description provided for @dimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions (L×W×H)'**
  String get dimensions;

  /// No description provided for @goodsDescription.
  ///
  /// In en, this message translates to:
  /// **'Goods Description'**
  String get goodsDescription;

  /// No description provided for @deliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get deliveryAddress;

  /// No description provided for @shippingMethod.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get shippingMethod;

  /// No description provided for @estimatedDeliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery Fee'**
  String get estimatedDeliveryFee;

  /// No description provided for @priceMayChange.
  ///
  /// In en, this message translates to:
  /// **'Price may change based on final details'**
  String get priceMayChange;

  /// No description provided for @useCustomerAddress.
  ///
  /// In en, this message translates to:
  /// **'Use Customer Address'**
  String get useCustomerAddress;

  /// No description provided for @changeAddress.
  ///
  /// In en, this message translates to:
  /// **'Change Address'**
  String get changeAddress;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Select Delivery Address'**
  String get selectAddress;

  /// No description provided for @addressSelected.
  ///
  /// In en, this message translates to:
  /// **'Address selected'**
  String get addressSelected;

  /// No description provided for @addressFilled.
  ///
  /// In en, this message translates to:
  /// **'Address filled from customer information'**
  String get addressFilled;

  /// No description provided for @calculatePrice.
  ///
  /// In en, this message translates to:
  /// **'Calculate Price'**
  String get calculatePrice;

  /// No description provided for @standard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standard;

  /// No description provided for @express.
  ///
  /// In en, this message translates to:
  /// **'Express'**
  String get express;

  /// No description provided for @overnight.
  ///
  /// In en, this message translates to:
  /// **'Overnight'**
  String get overnight;

  /// No description provided for @freight.
  ///
  /// In en, this message translates to:
  /// **'Freight'**
  String get freight;

  /// No description provided for @enterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter delivery address'**
  String get enterAddress;

  /// No description provided for @deliveryFee.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// No description provided for @estimatedPrice.
  ///
  /// In en, this message translates to:
  /// **'Estimated Price'**
  String get estimatedPrice;

  /// No description provided for @weightRequired.
  ///
  /// In en, this message translates to:
  /// **'Weight is required'**
  String get weightRequired;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Delivery address is required'**
  String get addressRequired;

  /// No description provided for @invalidWeight.
  ///
  /// In en, this message translates to:
  /// **'Invalid weight value'**
  String get invalidWeight;

  /// No description provided for @loadingPrice.
  ///
  /// In en, this message translates to:
  /// **'Calculating price...'**
  String get loadingPrice;

  /// No description provided for @deliveryOptions.
  ///
  /// In en, this message translates to:
  /// **'Delivery Options'**
  String get deliveryOptions;

  /// No description provided for @freeDelivery.
  ///
  /// In en, this message translates to:
  /// **'Free Delivery'**
  String get freeDelivery;

  /// No description provided for @paidDelivery.
  ///
  /// In en, this message translates to:
  /// **'Paid Delivery'**
  String get paidDelivery;

  /// No description provided for @scheduleDelivery.
  ///
  /// In en, this message translates to:
  /// **'Schedule Delivery'**
  String get scheduleDelivery;

  /// No description provided for @deliveryDate.
  ///
  /// In en, this message translates to:
  /// **'Delivery Date'**
  String get deliveryDate;

  /// No description provided for @deliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Delivery Time'**
  String get deliveryTime;

  /// No description provided for @trackingNumber.
  ///
  /// In en, this message translates to:
  /// **'Tracking Number'**
  String get trackingNumber;

  /// No description provided for @carrier.
  ///
  /// In en, this message translates to:
  /// **'Carrier'**
  String get carrier;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @signatureRequired.
  ///
  /// In en, this message translates to:
  /// **'Signature Required'**
  String get signatureRequired;

  /// No description provided for @fragile.
  ///
  /// In en, this message translates to:
  /// **'Fragile'**
  String get fragile;

  /// No description provided for @perishable.
  ///
  /// In en, this message translates to:
  /// **'Perishable'**
  String get perishable;

  /// No description provided for @hazardous.
  ///
  /// In en, this message translates to:
  /// **'Hazardous'**
  String get hazardous;

  /// No description provided for @bulk.
  ///
  /// In en, this message translates to:
  /// **'Bulk'**
  String get bulk;

  /// No description provided for @confirmDelivery.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delivery'**
  String get confirmDelivery;

  /// No description provided for @deliveryConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Delivery Confirmed'**
  String get deliveryConfirmed;

  /// No description provided for @deliveryPending.
  ///
  /// In en, this message translates to:
  /// **'Delivery Pending'**
  String get deliveryPending;

  /// No description provided for @deliveryInTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get deliveryInTransit;

  /// No description provided for @deliveryOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get deliveryOutForDelivery;

  /// No description provided for @deliveryDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryDelivered;

  /// No description provided for @deliveryFailed.
  ///
  /// In en, this message translates to:
  /// **'Delivery Failed'**
  String get deliveryFailed;

  /// No description provided for @deliveryCancelled.
  ///
  /// In en, this message translates to:
  /// **'Delivery Cancelled'**
  String get deliveryCancelled;

  /// No description provided for @deliveryReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get deliveryReturned;

  /// No description provided for @trackDelivery.
  ///
  /// In en, this message translates to:
  /// **'Track Delivery'**
  String get trackDelivery;

  /// No description provided for @viewDeliveryDetails.
  ///
  /// In en, this message translates to:
  /// **'View Delivery Details'**
  String get viewDeliveryDetails;

  /// No description provided for @editDelivery.
  ///
  /// In en, this message translates to:
  /// **'Edit Delivery'**
  String get editDelivery;

  /// No description provided for @cancelDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cancel Delivery'**
  String get cancelDelivery;

  /// No description provided for @rescheduleDelivery.
  ///
  /// In en, this message translates to:
  /// **'Reschedule Delivery'**
  String get rescheduleDelivery;

  /// No description provided for @deliveryHistory.
  ///
  /// In en, this message translates to:
  /// **'Delivery History'**
  String get deliveryHistory;

  /// No description provided for @upcomingDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Deliveries'**
  String get upcomingDeliveries;

  /// No description provided for @pastDeliveries.
  ///
  /// In en, this message translates to:
  /// **'Past Deliveries'**
  String get pastDeliveries;

  /// No description provided for @deliveryStatus.
  ///
  /// In en, this message translates to:
  /// **'Delivery Status'**
  String get deliveryStatus;

  /// No description provided for @recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get recipient;

  /// No description provided for @sender.
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// No description provided for @pickupLocation.
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// No description provided for @deliveryLocation.
  ///
  /// In en, this message translates to:
  /// **'Delivery Location'**
  String get deliveryLocation;

  /// No description provided for @expectedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Expected Delivery'**
  String get expectedDelivery;

  /// No description provided for @actualDelivery.
  ///
  /// In en, this message translates to:
  /// **'Actual Delivery'**
  String get actualDelivery;

  /// No description provided for @deliveryNotes.
  ///
  /// In en, this message translates to:
  /// **'Delivery Notes'**
  String get deliveryNotes;

  /// No description provided for @proofOfDelivery.
  ///
  /// In en, this message translates to:
  /// **'Proof of Delivery'**
  String get proofOfDelivery;

  /// No description provided for @signature.
  ///
  /// In en, this message translates to:
  /// **'Signature'**
  String get signature;

  /// No description provided for @photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @damageReport.
  ///
  /// In en, this message translates to:
  /// **'Damage Report'**
  String get damageReport;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rateDelivery.
  ///
  /// In en, this message translates to:
  /// **'Rate Delivery'**
  String get rateDelivery;

  /// No description provided for @deliveryRating.
  ///
  /// In en, this message translates to:
  /// **'Delivery Rating'**
  String get deliveryRating;

  /// No description provided for @driverName.
  ///
  /// In en, this message translates to:
  /// **'Driver Name'**
  String get driverName;

  /// No description provided for @vehicleNumber.
  ///
  /// In en, this message translates to:
  /// **'Vehicle Number'**
  String get vehicleNumber;

  /// No description provided for @contactDriver.
  ///
  /// In en, this message translates to:
  /// **'Contact Driver'**
  String get contactDriver;

  /// No description provided for @shareLocation.
  ///
  /// In en, this message translates to:
  /// **'Share Location'**
  String get shareLocation;

  /// No description provided for @liveTracking.
  ///
  /// In en, this message translates to:
  /// **'Live Tracking'**
  String get liveTracking;

  /// No description provided for @eTA.
  ///
  /// In en, this message translates to:
  /// **'Estimated Time of Arrival'**
  String get eTA;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @deliveryProof.
  ///
  /// In en, this message translates to:
  /// **'Delivery Proof'**
  String get deliveryProof;

  /// No description provided for @confirmReceipt.
  ///
  /// In en, this message translates to:
  /// **'Confirm Receipt'**
  String get confirmReceipt;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @needHelp.
  ///
  /// In en, this message translates to:
  /// **'Need Help?'**
  String get needHelp;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @enterStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter street address'**
  String get enterStreetAddress;

  /// No description provided for @streetAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Street address is required'**
  String get streetAddressRequired;

  /// No description provided for @enterCity.
  ///
  /// In en, this message translates to:
  /// **'Enter city'**
  String get enterCity;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @enterPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Enter postal code'**
  String get enterPostalCode;

  /// No description provided for @stateProvince.
  ///
  /// In en, this message translates to:
  /// **'State/Province'**
  String get stateProvince;

  /// No description provided for @enterState.
  ///
  /// In en, this message translates to:
  /// **'Enter state/province'**
  String get enterState;

  /// No description provided for @enterCountry.
  ///
  /// In en, this message translates to:
  /// **'Enter country'**
  String get enterCountry;

  /// No description provided for @countryRequired.
  ///
  /// In en, this message translates to:
  /// **'Country is required'**
  String get countryRequired;

  /// No description provided for @addressType.
  ///
  /// In en, this message translates to:
  /// **'Address Type'**
  String get addressType;

  /// No description provided for @additionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional Details'**
  String get additionalDetails;

  /// No description provided for @building.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get building;

  /// No description provided for @enterBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building name/number'**
  String get enterBuilding;

  /// No description provided for @apartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment'**
  String get apartment;

  /// No description provided for @enterApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment/Unit number'**
  String get enterApartment;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @enterFloor.
  ///
  /// In en, this message translates to:
  /// **'Floor number'**
  String get enterFloor;

  /// No description provided for @landmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get landmark;

  /// No description provided for @enterLandmark.
  ///
  /// In en, this message translates to:
  /// **'Nearby landmark'**
  String get enterLandmark;

  /// No description provided for @quickFill.
  ///
  /// In en, this message translates to:
  /// **'Quick Fill'**
  String get quickFill;

  /// No description provided for @addressComplete.
  ///
  /// In en, this message translates to:
  /// **'Address Complete'**
  String get addressComplete;

  /// No description provided for @addressIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get addressIncomplete;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select a country'**
  String get selectCountry;

  /// No description provided for @homeAddress.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeAddress;

  /// No description provided for @workAddress.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workAddress;

  /// No description provided for @businessAddress.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get businessAddress;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address'**
  String get shippingAddress;

  /// No description provided for @billingAddress.
  ///
  /// In en, this message translates to:
  /// **'Billing Address'**
  String get billingAddress;

  /// No description provided for @otherAddress.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherAddress;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @invalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid format'**
  String get invalidFormat;

  /// No description provided for @addressSaved.
  ///
  /// In en, this message translates to:
  /// **'Address saved successfully'**
  String get addressSaved;

  /// No description provided for @addressUpdated.
  ///
  /// In en, this message translates to:
  /// **'Address updated successfully'**
  String get addressUpdated;

  /// No description provided for @addressDeleted.
  ///
  /// In en, this message translates to:
  /// **'Address deleted'**
  String get addressDeleted;

  /// No description provided for @saveAddress.
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// No description provided for @updateAddress.
  ///
  /// In en, this message translates to:
  /// **'Update Address'**
  String get updateAddress;

  /// No description provided for @deleteAddress.
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddress;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'Add New Address'**
  String get addNewAddress;

  /// No description provided for @editAddress.
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// No description provided for @defaultAddress.
  ///
  /// In en, this message translates to:
  /// **'Default Address'**
  String get defaultAddress;

  /// No description provided for @setAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get setAsDefault;

  /// No description provided for @removeDefault.
  ///
  /// In en, this message translates to:
  /// **'Remove Default'**
  String get removeDefault;

  /// No description provided for @noAddresses.
  ///
  /// In en, this message translates to:
  /// **'No addresses saved'**
  String get noAddresses;

  /// No description provided for @addYourFirstAddress.
  ///
  /// In en, this message translates to:
  /// **'Add your first address'**
  String get addYourFirstAddress;

  /// No description provided for @addressBook.
  ///
  /// In en, this message translates to:
  /// **'Address Book'**
  String get addressBook;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locating;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get locationPermission;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to use your current location'**
  String get locationPermissionMessage;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get enableLocation;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get locationNotFound;

  /// No description provided for @searchLocation.
  ///
  /// In en, this message translates to:
  /// **'Search location'**
  String get searchLocation;

  /// No description provided for @selectOnMap.
  ///
  /// In en, this message translates to:
  /// **'Select on Map'**
  String get selectOnMap;

  /// No description provided for @verifyAddress.
  ///
  /// In en, this message translates to:
  /// **'Verify Address'**
  String get verifyAddress;

  /// No description provided for @addressVerified.
  ///
  /// In en, this message translates to:
  /// **'Address verified'**
  String get addressVerified;

  /// No description provided for @addressNotVerified.
  ///
  /// In en, this message translates to:
  /// **'Address could not be verified'**
  String get addressNotVerified;

  /// No description provided for @suggestedAddress.
  ///
  /// In en, this message translates to:
  /// **'Suggested Address'**
  String get suggestedAddress;

  /// No description provided for @useSuggested.
  ///
  /// In en, this message translates to:
  /// **'Use Suggested Address'**
  String get useSuggested;

  /// No description provided for @keepOriginal.
  ///
  /// In en, this message translates to:
  /// **'Keep Original'**
  String get keepOriginal;

  /// No description provided for @streetNumber.
  ///
  /// In en, this message translates to:
  /// **'Street Number'**
  String get streetNumber;

  /// No description provided for @neighborhood.
  ///
  /// In en, this message translates to:
  /// **'Neighborhood'**
  String get neighborhood;

  /// No description provided for @sublocality.
  ///
  /// In en, this message translates to:
  /// **'Sublocality'**
  String get sublocality;

  /// No description provided for @administrativeArea.
  ///
  /// In en, this message translates to:
  /// **'Administrative Area'**
  String get administrativeArea;

  /// No description provided for @subAdministrativeArea.
  ///
  /// In en, this message translates to:
  /// **'Sub-Administrative Area'**
  String get subAdministrativeArea;

  /// No description provided for @postalTown.
  ///
  /// In en, this message translates to:
  /// **'Postal Town'**
  String get postalTown;

  /// No description provided for @premise.
  ///
  /// In en, this message translates to:
  /// **'Premise'**
  String get premise;

  /// No description provided for @subpremise.
  ///
  /// In en, this message translates to:
  /// **'Subpremise'**
  String get subpremise;

  /// No description provided for @plusCode.
  ///
  /// In en, this message translates to:
  /// **'Plus Code'**
  String get plusCode;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on Map'**
  String get showOnMap;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @copyAddress.
  ///
  /// In en, this message translates to:
  /// **'Copy Address'**
  String get copyAddress;

  /// No description provided for @shareAddress.
  ///
  /// In en, this message translates to:
  /// **'Share Address'**
  String get shareAddress;

  /// No description provided for @qrCode.
  ///
  /// In en, this message translates to:
  /// **'QR Code'**
  String get qrCode;

  /// No description provided for @labelHome.
  ///
  /// In en, this message translates to:
  /// **'🏠 Home'**
  String get labelHome;

  /// No description provided for @labelWork.
  ///
  /// In en, this message translates to:
  /// **'💼 Work'**
  String get labelWork;

  /// No description provided for @labelFamily.
  ///
  /// In en, this message translates to:
  /// **'👪 Family'**
  String get labelFamily;

  /// No description provided for @labelFriend.
  ///
  /// In en, this message translates to:
  /// **'👤 Friend'**
  String get labelFriend;

  /// No description provided for @labelOther.
  ///
  /// In en, this message translates to:
  /// **'📍 Other'**
  String get labelOther;

  /// No description provided for @customLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom Label'**
  String get customLabel;

  /// No description provided for @enterLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter label'**
  String get enterLabel;

  /// No description provided for @deliveryInstructions.
  ///
  /// In en, this message translates to:
  /// **'Delivery Instructions'**
  String get deliveryInstructions;

  /// No description provided for @enterInstructions.
  ///
  /// In en, this message translates to:
  /// **'Enter delivery instructions'**
  String get enterInstructions;

  /// No description provided for @gateCode.
  ///
  /// In en, this message translates to:
  /// **'Gate Code'**
  String get gateCode;

  /// No description provided for @enterGateCode.
  ///
  /// In en, this message translates to:
  /// **'Enter gate/building code'**
  String get enterGateCode;

  /// No description provided for @preferredDeliveryTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred Delivery Time'**
  String get preferredDeliveryTime;

  /// No description provided for @leaveAtDoor.
  ///
  /// In en, this message translates to:
  /// **'Leave at door'**
  String get leaveAtDoor;

  /// No description provided for @requireSignature.
  ///
  /// In en, this message translates to:
  /// **'Require signature'**
  String get requireSignature;

  /// No description provided for @callOnArrival.
  ///
  /// In en, this message translates to:
  /// **'Call on arrival'**
  String get callOnArrival;

  /// No description provided for @formatAsSingleLine.
  ///
  /// In en, this message translates to:
  /// **'Single Line Format'**
  String get formatAsSingleLine;

  /// No description provided for @formatAsMultiLine.
  ///
  /// In en, this message translates to:
  /// **'Multi-Line Format'**
  String get formatAsMultiLine;

  /// No description provided for @copyFormatted.
  ///
  /// In en, this message translates to:
  /// **'Copy Formatted'**
  String get copyFormatted;

  /// No description provided for @standardFormat.
  ///
  /// In en, this message translates to:
  /// **'Standard Format'**
  String get standardFormat;

  /// No description provided for @localFormat.
  ///
  /// In en, this message translates to:
  /// **'Local Format'**
  String get localFormat;

  /// No description provided for @internationalFormat.
  ///
  /// In en, this message translates to:
  /// **'International Format'**
  String get internationalFormat;

  /// No description provided for @lengthHint.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get lengthHint;

  /// No description provided for @widthHint.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get widthHint;

  /// No description provided for @heightHint.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get heightHint;

  /// No description provided for @goodsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what is being delivered'**
  String get goodsDescriptionHint;

  /// No description provided for @hsCode.
  ///
  /// In en, this message translates to:
  /// **'HS Code'**
  String get hsCode;

  /// No description provided for @hsCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Harmonized System code'**
  String get hsCodeHint;

  /// No description provided for @standardShipping.
  ///
  /// In en, this message translates to:
  /// **'Standard Shipping'**
  String get standardShipping;

  /// No description provided for @expressShipping.
  ///
  /// In en, this message translates to:
  /// **'Express Shipping'**
  String get expressShipping;

  /// No description provided for @overnightShipping.
  ///
  /// In en, this message translates to:
  /// **'Overnight Shipping'**
  String get overnightShipping;

  /// No description provided for @freightShipping.
  ///
  /// In en, this message translates to:
  /// **'Freight Shipping'**
  String get freightShipping;

  /// No description provided for @selectDeliveryType.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to receive your order'**
  String get selectDeliveryType;

  /// No description provided for @totalDeliveryCost.
  ///
  /// In en, this message translates to:
  /// **'Total Delivery Cost'**
  String get totalDeliveryCost;

  /// No description provided for @fillAddressAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Fill address from customer profile automatically'**
  String get fillAddressAutomatically;

  /// No description provided for @weightUnit.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get weightUnit;

  /// No description provided for @dimensionUnitCm.
  ///
  /// In en, this message translates to:
  /// **'cm'**
  String get dimensionUnitCm;

  /// No description provided for @enterPackageDimensions.
  ///
  /// In en, this message translates to:
  /// **'Enter package dimensions for accurate shipping'**
  String get enterPackageDimensions;

  /// No description provided for @dimensionUnitM.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get dimensionUnitM;

  /// No description provided for @paidCart.
  ///
  /// In en, this message translates to:
  /// **'Paid Cart'**
  String get paidCart;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @deposits.
  ///
  /// In en, this message translates to:
  /// **'Deposits'**
  String get deposits;

  /// No description provided for @customerType.
  ///
  /// In en, this message translates to:
  /// **'Customer Type'**
  String get customerType;

  /// No description provided for @customerId.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get customerId;

  /// No description provided for @personId.
  ///
  /// In en, this message translates to:
  /// **'Person ID'**
  String get personId;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not Assigned'**
  String get notAssigned;

  /// No description provided for @documentDetails.
  ///
  /// In en, this message translates to:
  /// **'Document Details'**
  String get documentDetails;

  /// No description provided for @daysIssued.
  ///
  /// In en, this message translates to:
  /// **'Days Issued'**
  String get daysIssued;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @sourceType.
  ///
  /// In en, this message translates to:
  /// **'Source Type'**
  String get sourceType;

  /// No description provided for @makePayment.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String makePayment(String amount);

  /// No description provided for @copyLink.
  ///
  /// In en, this message translates to:
  /// **'Copy Link'**
  String get copyLink;

  /// No description provided for @shareViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Share via Email'**
  String get shareViaEmail;

  /// No description provided for @shareViaMessage.
  ///
  /// In en, this message translates to:
  /// **'Share via Message'**
  String get shareViaMessage;

  /// No description provided for @downloadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Downloading document...'**
  String get downloadingDocument;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete!'**
  String get downloadComplete;

  /// No description provided for @cart_with_payments.
  ///
  /// In en, this message translates to:
  /// **'Cart with Payments'**
  String get cart_with_payments;

  /// No description provided for @pending_cart.
  ///
  /// In en, this message translates to:
  /// **'Pending Cart'**
  String get pending_cart;

  /// No description provided for @pending_cart_lower.
  ///
  /// In en, this message translates to:
  /// **'Pending Cart'**
  String get pending_cart_lower;

  /// No description provided for @deposited_status.
  ///
  /// In en, this message translates to:
  /// **'Deposited'**
  String get deposited_status;

  /// No description provided for @partially_paid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partially_paid;

  /// No description provided for @cart_based.
  ///
  /// In en, this message translates to:
  /// **'Cart Based'**
  String get cart_based;

  /// No description provided for @invoice_based.
  ///
  /// In en, this message translates to:
  /// **'Invoice Based'**
  String get invoice_based;

  /// No description provided for @order_based.
  ///
  /// In en, this message translates to:
  /// **'Order Based'**
  String get order_based;

  /// No description provided for @direct_deposit.
  ///
  /// In en, this message translates to:
  /// **'Direct Deposit'**
  String get direct_deposit;

  /// No description provided for @direct_receipt.
  ///
  /// In en, this message translates to:
  /// **'Direct Receipt'**
  String get direct_receipt;

  /// No description provided for @mixed_payments.
  ///
  /// In en, this message translates to:
  /// **'Mixed Payments'**
  String get mixed_payments;

  /// No description provided for @payment_only.
  ///
  /// In en, this message translates to:
  /// **'Payment Only'**
  String get payment_only;

  /// No description provided for @no_payments.
  ///
  /// In en, this message translates to:
  /// **'No Payments'**
  String get no_payments;

  /// No description provided for @addDeposit.
  ///
  /// In en, this message translates to:
  /// **'Add Deposit'**
  String get addDeposit;

  /// No description provided for @submitDeposit.
  ///
  /// In en, this message translates to:
  /// **'Submit Deposit'**
  String get submitDeposit;

  /// No description provided for @submitPayment.
  ///
  /// In en, this message translates to:
  /// **'Submit Payment'**
  String get submitPayment;

  /// No description provided for @depositDetails.
  ///
  /// In en, this message translates to:
  /// **'Deposit Details'**
  String get depositDetails;

  /// No description provided for @installmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Installment Details'**
  String get installmentDetails;

  /// No description provided for @installmentScheduled.
  ///
  /// In en, this message translates to:
  /// **'Installment scheduled for selected date'**
  String get installmentScheduled;

  /// No description provided for @depositAmount.
  ///
  /// In en, this message translates to:
  /// **'Deposit Amount'**
  String get depositAmount;

  /// No description provided for @notesOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional notes...'**
  String get notesOptional;

  /// No description provided for @enterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get enterValidAmount;

  /// No description provided for @selectDateForInstallment.
  ///
  /// In en, this message translates to:
  /// **'Please select a date for the installment'**
  String get selectDateForInstallment;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @additionalDepositSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Additional deposit submitted successfully'**
  String get additionalDepositSubmitted;

  /// No description provided for @depositSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Deposit submitted successfully'**
  String get depositSubmitted;

  /// No description provided for @paymentSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Payment submitted successfully'**
  String get paymentSubmitted;

  /// No description provided for @customerName.
  ///
  /// In en, this message translates to:
  /// **'Customer Name'**
  String get customerName;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get notAvailable;

  /// No description provided for @hasAccount.
  ///
  /// In en, this message translates to:
  /// **'Has Account'**
  String get hasAccount;

  /// No description provided for @noDocumentsMatchQuery.
  ///
  /// In en, this message translates to:
  /// **'No documents match'**
  String get noDocumentsMatchQuery;

  /// No description provided for @documentsWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Documents will appear here once they are created'**
  String get documentsWillAppearHere;

  /// No description provided for @tip.
  ///
  /// In en, this message translates to:
  /// **'💡 Tip'**
  String get tip;

  /// No description provided for @youHaveTotalDocuments.
  ///
  /// In en, this message translates to:
  /// **'You have {count} total documents.'**
  String youHaveTotalDocuments(int count);

  /// No description provided for @tryDifferentFilters.
  ///
  /// In en, this message translates to:
  /// **'Try different filters or search terms.'**
  String get tryDifferentFilters;

  /// No description provided for @editService.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// No description provided for @createService.
  ///
  /// In en, this message translates to:
  /// **'Create Service'**
  String get createService;

  /// No description provided for @serviceName.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceName;

  /// No description provided for @enterServiceName.
  ///
  /// In en, this message translates to:
  /// **'Enter service name'**
  String get enterServiceName;

  /// No description provided for @serviceNameRequiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Service name is required'**
  String get serviceNameRequiredLabel;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @enterDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter service description'**
  String get enterDescription;

  /// No description provided for @categoryId.
  ///
  /// In en, this message translates to:
  /// **'Category ID'**
  String get categoryId;

  /// No description provided for @enterCategoryId.
  ///
  /// In en, this message translates to:
  /// **'Enter category ID'**
  String get enterCategoryId;

  /// No description provided for @providerId.
  ///
  /// In en, this message translates to:
  /// **'Provider ID'**
  String get providerId;

  /// No description provided for @enterProviderId.
  ///
  /// In en, this message translates to:
  /// **'Enter provider ID'**
  String get enterProviderId;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutes;

  /// No description provided for @enterDuration.
  ///
  /// In en, this message translates to:
  /// **'Enter duration in minutes'**
  String get enterDuration;

  /// No description provided for @durationRequired.
  ///
  /// In en, this message translates to:
  /// **'Duration is required'**
  String get durationRequired;

  /// No description provided for @durationPositive.
  ///
  /// In en, this message translates to:
  /// **'Duration must be positive'**
  String get durationPositive;

  /// No description provided for @enterBasePrice.
  ///
  /// In en, this message translates to:
  /// **'Enter base price'**
  String get enterBasePrice;

  /// No description provided for @basePriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Base price is required'**
  String get basePriceRequired;

  /// No description provided for @pricePositive.
  ///
  /// In en, this message translates to:
  /// **'Price must be positive'**
  String get pricePositive;

  /// No description provided for @enterFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter final price'**
  String get enterFinalPrice;

  /// No description provided for @finalPriceRequired.
  ///
  /// In en, this message translates to:
  /// **'Final price is required'**
  String get finalPriceRequired;

  /// No description provided for @pricingConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Pricing Configuration'**
  String get pricingConfiguration;

  /// No description provided for @ageGroup.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get ageGroup;

  /// No description provided for @enterAgeGroup.
  ///
  /// In en, this message translates to:
  /// **'e.g., Adult, Child'**
  String get enterAgeGroup;

  /// No description provided for @sampleType.
  ///
  /// In en, this message translates to:
  /// **'Sample Type'**
  String get sampleType;

  /// No description provided for @enterSampleType.
  ///
  /// In en, this message translates to:
  /// **'e.g., Blood, Urine'**
  String get enterSampleType;

  /// No description provided for @specialistConsultation.
  ///
  /// In en, this message translates to:
  /// **'Specialist Consultation'**
  String get specialistConsultation;

  /// No description provided for @governmentFunded.
  ///
  /// In en, this message translates to:
  /// **'Government Funded'**
  String get governmentFunded;

  /// No description provided for @consultationIncluded.
  ///
  /// In en, this message translates to:
  /// **'Consultation Included'**
  String get consultationIncluded;

  /// No description provided for @digitalImaging.
  ///
  /// In en, this message translates to:
  /// **'Digital Imaging'**
  String get digitalImaging;

  /// No description provided for @materialOptions.
  ///
  /// In en, this message translates to:
  /// **'Material Options'**
  String get materialOptions;

  /// No description provided for @addMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterial;

  /// No description provided for @enterMaterial.
  ///
  /// In en, this message translates to:
  /// **'e.g., Gold, Silver'**
  String get enterMaterial;

  /// No description provided for @includes.
  ///
  /// In en, this message translates to:
  /// **'Includes'**
  String get includes;

  /// No description provided for @addInclude.
  ///
  /// In en, this message translates to:
  /// **'Add Include'**
  String get addInclude;

  /// No description provided for @enterInclude.
  ///
  /// In en, this message translates to:
  /// **'e.g., Free consultation'**
  String get enterInclude;

  /// No description provided for @addResource.
  ///
  /// In en, this message translates to:
  /// **'Add Resource'**
  String get addResource;

  /// No description provided for @noResourcesAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'No resources added yet'**
  String get noResourcesAddedLabel;

  /// No description provided for @addStaff.
  ///
  /// In en, this message translates to:
  /// **'Add Staff'**
  String get addStaff;

  /// No description provided for @noStaffAddedLabel.
  ///
  /// In en, this message translates to:
  /// **'No staff added yet'**
  String get noStaffAddedLabel;

  /// No description provided for @serviceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Service updated successfully'**
  String get serviceUpdated;

  /// No description provided for @serviceCreated.
  ///
  /// In en, this message translates to:
  /// **'Service created successfully'**
  String get serviceCreated;

  /// No description provided for @updateService.
  ///
  /// In en, this message translates to:
  /// **'Update Service'**
  String get updateService;

  /// No description provided for @noDiscount.
  ///
  /// In en, this message translates to:
  /// **'No discount'**
  String get noDiscount;

  /// No description provided for @minutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @scrollToTop.
  ///
  /// In en, this message translates to:
  /// **'Scroll to top'**
  String get scrollToTop;

  /// No description provided for @enterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter price'**
  String get enterPrice;

  /// No description provided for @priceRequired.
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get priceRequired;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get invalidPrice;

  /// No description provided for @typeAndPressEnter.
  ///
  /// In en, this message translates to:
  /// **'Type and press enter...'**
  String get typeAndPressEnter;

  /// No description provided for @finalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Final Price'**
  String get finalPriceLabel;

  /// No description provided for @walkInCustomer.
  ///
  /// In en, this message translates to:
  /// **'Walk-in Customer'**
  String get walkInCustomer;

  /// No description provided for @emptyCustomer.
  ///
  /// In en, this message translates to:
  /// **'Select Customer'**
  String get emptyCustomer;

  /// No description provided for @guestEmail.
  ///
  /// In en, this message translates to:
  /// **'guest@example.com'**
  String get guestEmail;

  /// No description provided for @guestLocation.
  ///
  /// In en, this message translates to:
  /// **'Store Location'**
  String get guestLocation;

  /// No description provided for @something_went_wrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get something_went_wrong;

  /// No description provided for @auth_required.
  ///
  /// In en, this message translates to:
  /// **'Authentication required. Please log in.'**
  String get auth_required;

  /// No description provided for @auth_decode_failed.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get auth_decode_failed;

  /// No description provided for @auth_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to perform this action.'**
  String get auth_unauthorized;

  /// No description provided for @user_auth_creation_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create account. Please try again.'**
  String get user_auth_creation_failed;

  /// No description provided for @user_net_failed.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your connection.'**
  String get user_net_failed;

  /// No description provided for @appuser_not_exists.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get appuser_not_exists;

  /// No description provided for @appuser_already_exists.
  ///
  /// In en, this message translates to:
  /// **'User already exists.'**
  String get appuser_already_exists;

  /// No description provided for @appusertype_not_exists.
  ///
  /// In en, this message translates to:
  /// **'User type not found.'**
  String get appusertype_not_exists;

  /// No description provided for @user_fetch_not_found.
  ///
  /// In en, this message translates to:
  /// **'User not found.'**
  String get user_fetch_not_found;

  /// No description provided for @user_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create user.'**
  String get user_insert_failed;

  /// No description provided for @user_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update user information.'**
  String get user_update_failed;

  /// No description provided for @user_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete user.'**
  String get user_delete_failed;

  /// No description provided for @person_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Person not found.'**
  String get person_not_exists;

  /// No description provided for @person_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create person record.'**
  String get person_insert_failed;

  /// No description provided for @person_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update person information.'**
  String get person_update_failed;

  /// No description provided for @person_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete person record.'**
  String get person_delete_failed;

  /// No description provided for @person_detail_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create person details.'**
  String get person_detail_insert_failed;

  /// No description provided for @person_details_not_found.
  ///
  /// In en, this message translates to:
  /// **'Person details not found.'**
  String get person_details_not_found;

  /// No description provided for @person_fetch_not_found.
  ///
  /// In en, this message translates to:
  /// **'Person not found.'**
  String get person_fetch_not_found;

  /// No description provided for @product_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Product not found.'**
  String get product_not_exists;

  /// No description provided for @product_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Product already exists.'**
  String get product_already_exists;

  /// No description provided for @product_category_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Product category not found.'**
  String get product_category_not_exists;

  /// No description provided for @product_quantity_not_enough.
  ///
  /// In en, this message translates to:
  /// **'Insufficient product quantity.'**
  String get product_quantity_not_enough;

  /// No description provided for @product_quantity_restore_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore product quantity.'**
  String get product_quantity_restore_failed;

  /// No description provided for @product_supplier_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Product supplier not found.'**
  String get product_supplier_not_exists;

  /// No description provided for @product_supplier_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Product supplier already exists.'**
  String get product_supplier_already_exists;

  /// No description provided for @product_fetch_not_found.
  ///
  /// In en, this message translates to:
  /// **'Product not found.'**
  String get product_fetch_not_found;

  /// No description provided for @product_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create product.'**
  String get product_insert_failed;

  /// No description provided for @product_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update product.'**
  String get product_update_failed;

  /// No description provided for @product_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product.'**
  String get product_delete_failed;

  /// No description provided for @product_search_not_found.
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get product_search_not_found;

  /// No description provided for @product_image_not_found.
  ///
  /// In en, this message translates to:
  /// **'Product image not found.'**
  String get product_image_not_found;

  /// No description provided for @supplier_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Supplier not found.'**
  String get supplier_not_exists;

  /// No description provided for @supplier_type_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Supplier type not found.'**
  String get supplier_type_not_exists;

  /// No description provided for @supplier_fetch_not_found.
  ///
  /// In en, this message translates to:
  /// **'Supplier not found.'**
  String get supplier_fetch_not_found;

  /// No description provided for @supplier_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create supplier.'**
  String get supplier_insert_failed;

  /// No description provided for @supplier_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update supplier.'**
  String get supplier_update_failed;

  /// No description provided for @supplier_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete supplier.'**
  String get supplier_delete_failed;

  /// No description provided for @organisation_not_found.
  ///
  /// In en, this message translates to:
  /// **'Organisation not found.'**
  String get organisation_not_found;

  /// No description provided for @organisation_name_used.
  ///
  /// In en, this message translates to:
  /// **'Organisation name is already in use.'**
  String get organisation_name_used;

  /// No description provided for @org_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Organisation already exists.'**
  String get org_already_exists;

  /// No description provided for @org_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create organisation.'**
  String get org_insert_failed;

  /// No description provided for @org_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update organisation.'**
  String get org_update_failed;

  /// No description provided for @org_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete organisation.'**
  String get org_delete_failed;

  /// No description provided for @ingredient_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Ingredient not found.'**
  String get ingredient_not_exists;

  /// No description provided for @ingredient_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Ingredient already exists.'**
  String get ingredient_already_exists;

  /// No description provided for @ingredient_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create ingredient.'**
  String get ingredient_insert_failed;

  /// No description provided for @ingredient_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update ingredient.'**
  String get ingredient_update_failed;

  /// No description provided for @ingredient_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete ingredient.'**
  String get ingredient_delete_failed;

  /// No description provided for @order_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get order_not_exists;

  /// No description provided for @order_fetch_not_found.
  ///
  /// In en, this message translates to:
  /// **'Order not found.'**
  String get order_fetch_not_found;

  /// No description provided for @order_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create order.'**
  String get order_insert_failed;

  /// No description provided for @order_insert_conflict.
  ///
  /// In en, this message translates to:
  /// **'Unable to create order due to conflict.'**
  String get order_insert_conflict;

  /// No description provided for @order_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update order.'**
  String get order_update_failed;

  /// No description provided for @order_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete order.'**
  String get order_delete_failed;

  /// No description provided for @invalid_order_status.
  ///
  /// In en, this message translates to:
  /// **'Invalid order status change.'**
  String get invalid_order_status;

  /// No description provided for @order_items_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove order items.'**
  String get order_items_delete_failed;

  /// No description provided for @order_item_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add item to order.'**
  String get order_item_insert_failed;

  /// No description provided for @cart_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Cart not found.'**
  String get cart_not_exists;

  /// No description provided for @cart_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create cart.'**
  String get cart_insert_failed;

  /// No description provided for @delivery_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Delivery not found.'**
  String get delivery_not_exists;

  /// No description provided for @delivery_update_failed_label.
  ///
  /// In en, this message translates to:
  /// **'Failed to update delivery.'**
  String get delivery_update_failed_label;

  /// No description provided for @delivery_cannot_be_updated.
  ///
  /// In en, this message translates to:
  /// **'Delivery cannot be updated in its current status.'**
  String get delivery_cannot_be_updated;

  /// No description provided for @delivery_bulk_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update deliveries.'**
  String get delivery_bulk_update_failed;

  /// No description provided for @delivery_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete delivery.'**
  String get delivery_delete_failed;

  /// No description provided for @delivery_bulk_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete deliveries.'**
  String get delivery_bulk_delete_failed;

  /// No description provided for @delivery_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create delivery.'**
  String get delivery_insert_failed;

  /// No description provided for @delivery_validation_failed.
  ///
  /// In en, this message translates to:
  /// **'Invalid delivery information.'**
  String get delivery_validation_failed;

  /// No description provided for @service_not_found.
  ///
  /// In en, this message translates to:
  /// **'Service not found.'**
  String get service_not_found;

  /// No description provided for @service_insert_conflict.
  ///
  /// In en, this message translates to:
  /// **'Service already exists.'**
  String get service_insert_conflict;

  /// No description provided for @service_category_not_found.
  ///
  /// In en, this message translates to:
  /// **'Service category not found.'**
  String get service_category_not_found;

  /// No description provided for @rule_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Staff assignment already exists.'**
  String get rule_already_exists;

  /// No description provided for @rule_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Staff assignment not found.'**
  String get rule_not_exists;

  /// No description provided for @rule_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create staff assignment.'**
  String get rule_insert_failed;

  /// No description provided for @rule_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update staff assignment.'**
  String get rule_update_failed;

  /// No description provided for @rule_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete staff assignment.'**
  String get rule_delete_failed;

  /// No description provided for @rule_invalid_status.
  ///
  /// In en, this message translates to:
  /// **'Invalid staff assignment status.'**
  String get rule_invalid_status;

  /// No description provided for @notification_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Notification not found.'**
  String get notification_not_exists;

  /// No description provided for @notification_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Notification already exists.'**
  String get notification_already_exists;

  /// No description provided for @notification_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create notification.'**
  String get notification_insert_failed;

  /// No description provided for @notification_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update notification.'**
  String get notification_update_failed;

  /// No description provided for @notification_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete notification.'**
  String get notification_delete_failed;

  /// No description provided for @notification_bulk_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create notifications.'**
  String get notification_bulk_insert_failed;

  /// No description provided for @location_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Location not found.'**
  String get location_not_exists;

  /// No description provided for @location_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update location.'**
  String get location_update_failed;

  /// No description provided for @location_fetch_not_found.
  ///
  /// In en, this message translates to:
  /// **'Location not found.'**
  String get location_fetch_not_found;

  /// No description provided for @location_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create location.'**
  String get location_insert_failed;

  /// No description provided for @location_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete location.'**
  String get location_delete_failed;

  /// No description provided for @address_not_found.
  ///
  /// In en, this message translates to:
  /// **'Address not found.'**
  String get address_not_found;

  /// No description provided for @payment_failed.
  ///
  /// In en, this message translates to:
  /// **'Payment processing failed.'**
  String get payment_failed;

  /// No description provided for @deposit_creation_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create deposit.'**
  String get deposit_creation_failed;

  /// No description provided for @image_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image.'**
  String get image_insert_failed;

  /// No description provided for @image_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update image.'**
  String get image_update_failed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed.'**
  String get failed;

  /// No description provided for @not_found.
  ///
  /// In en, this message translates to:
  /// **'Not found.'**
  String get not_found;

  /// No description provided for @network_timeout.
  ///
  /// In en, this message translates to:
  /// **'Network timeout. Please check your connection.'**
  String get network_timeout;

  /// No description provided for @validation_error.
  ///
  /// In en, this message translates to:
  /// **'Please check your input and try again.'**
  String get validation_error;

  /// No description provided for @rate_limited.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment.'**
  String get rate_limited;

  /// No description provided for @permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied.'**
  String get permission_denied;

  /// No description provided for @client_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Client not found.'**
  String get client_not_exists;

  /// No description provided for @created_successfully.
  ///
  /// In en, this message translates to:
  /// **'Created successfully!'**
  String get created_successfully;

  /// No description provided for @bad_request.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Please check your input.'**
  String get bad_request;

  /// No description provided for @unauthorized.
  ///
  /// In en, this message translates to:
  /// **'Please log in to continue.'**
  String get unauthorized;

  /// No description provided for @forbidden.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to access this resource.'**
  String get forbidden;

  /// No description provided for @conflict.
  ///
  /// In en, this message translates to:
  /// **'Resource conflict. Please try again.'**
  String get conflict;

  /// No description provided for @gone.
  ///
  /// In en, this message translates to:
  /// **'This resource is no longer available.'**
  String get gone;

  /// No description provided for @bad_gateway.
  ///
  /// In en, this message translates to:
  /// **'Service temporarily unavailable. Please try again later.'**
  String get bad_gateway;

  /// No description provided for @service_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Service is temporarily unavailable.'**
  String get service_unavailable;

  /// No description provided for @gateway_timeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get gateway_timeout;

  /// No description provided for @network_authentication_required.
  ///
  /// In en, this message translates to:
  /// **'Network authentication required.'**
  String get network_authentication_required;

  /// No description provided for @no_response_data.
  ///
  /// In en, this message translates to:
  /// **'No response data available.'**
  String get no_response_data;

  /// No description provided for @noIngredientsFound.
  ///
  /// In en, this message translates to:
  /// **'No ingredients found'**
  String get noIngredientsFound;

  /// No description provided for @manageIngredients.
  ///
  /// In en, this message translates to:
  /// **'Manage Ingredients'**
  String get manageIngredients;

  /// No description provided for @pleaseEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter amount'**
  String get pleaseEnterAmount;

  /// No description provided for @amountMustBeGreaterThanZero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be positive'**
  String get amountMustBeGreaterThanZero;

  /// No description provided for @returnBack.
  ///
  /// In en, this message translates to:
  /// **'Return to previous screen'**
  String get returnBack;

  /// No description provided for @viewPendingInvitationsLabel.
  ///
  /// In en, this message translates to:
  /// **'View Pending Invitations'**
  String get viewPendingInvitationsLabel;

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;

  /// No description provided for @activeAssignments.
  ///
  /// In en, this message translates to:
  /// **'Active Assignments'**
  String get activeAssignments;

  /// No description provided for @noActiveAssignments.
  ///
  /// In en, this message translates to:
  /// **'No Active Assignments'**
  String get noActiveAssignments;

  /// No description provided for @noActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any active assignments.'**
  String get noActiveDescription;

  /// No description provided for @noInvitationsOrAssignments.
  ///
  /// In en, this message translates to:
  /// **'No Invitations or Assignments'**
  String get noInvitationsOrAssignments;

  /// No description provided for @noInvitationsDescription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any pending invitations or active assignments.'**
  String get noInvitationsDescription;

  /// No description provided for @noPendingDescription.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any pending invitations.'**
  String get noPendingDescription;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingData;

  /// No description provided for @loadingInvitations.
  ///
  /// In en, this message translates to:
  /// **'Loading invitations...'**
  String get loadingInvitations;

  /// No description provided for @errorOccurredLabel.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorOccurredLabel;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @activeStatus.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @roleCode.
  ///
  /// In en, this message translates to:
  /// **'Role Code'**
  String get roleCode;

  /// No description provided for @expiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry'**
  String get expiry;

  /// No description provided for @noExpiry.
  ///
  /// In en, this message translates to:
  /// **'No expiry'**
  String get noExpiry;

  /// No description provided for @expiredDate.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredDate;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @inDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String inDays(int days);

  /// No description provided for @invitationAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted successfully'**
  String get invitationAcceptedSuccessfully;

  /// No description provided for @invitationDeclinedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined successfully'**
  String get invitationDeclinedSuccessfully;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get actionFailed;

  /// No description provided for @noInvitationsFound.
  ///
  /// In en, this message translates to:
  /// **'No invitations found'**
  String get noInvitationsFound;

  /// No description provided for @userNotAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'User not authenticated'**
  String get userNotAuthenticated;

  /// No description provided for @failedToLoadInvitations.
  ///
  /// In en, this message translates to:
  /// **'Failed to load invitations'**
  String get failedToLoadInvitations;

  /// No description provided for @markAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All as Read'**
  String get markAllAsRead;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock: {stock}'**
  String inStock(int stock);

  /// No description provided for @addProductsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add products to get started'**
  String get addProductsToGetStarted;

  /// No description provided for @addServicesToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add services to get started'**
  String get addServicesToGetStarted;

  /// No description provided for @selected.
  ///
  /// In en, this message translates to:
  /// **'Selected: {count}'**
  String selected(int count);

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available: {count}'**
  String available(int count);

  /// No description provided for @accessible.
  ///
  /// In en, this message translates to:
  /// **'accessible'**
  String get accessible;

  /// No description provided for @searchBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Search businesses...'**
  String get searchBusinesses;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResults;

  /// No description provided for @noBusinesses.
  ///
  /// In en, this message translates to:
  /// **'No businesses'**
  String get noBusinesses;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @manageAccessLabel.
  ///
  /// In en, this message translates to:
  /// **'Manage Access'**
  String get manageAccessLabel;

  /// No description provided for @privilegesFor.
  ///
  /// In en, this message translates to:
  /// **'Privileges for {userName}'**
  String privilegesFor(String userName);

  /// No description provided for @noPrivileges.
  ///
  /// In en, this message translates to:
  /// **'No privileges assigned.'**
  String get noPrivileges;

  /// No description provided for @addBusiness.
  ///
  /// In en, this message translates to:
  /// **'Add Business'**
  String get addBusiness;

  /// No description provided for @refreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data refreshed successfully'**
  String get refreshSuccess;

  /// No description provided for @searchAndInvite.
  ///
  /// In en, this message translates to:
  /// **'Search & Invite'**
  String get searchAndInvite;

  /// No description provided for @findUsersToAddTo.
  ///
  /// In en, this message translates to:
  /// **'Find users to add to {supplierName}'**
  String findUsersToAddTo(String supplierName);

  /// No description provided for @searchByNameUsernameOrRole.
  ///
  /// In en, this message translates to:
  /// **'Search by name, username, or role...'**
  String get searchByNameUsernameOrRole;

  /// No description provided for @searchForUsers.
  ///
  /// In en, this message translates to:
  /// **'Search for users'**
  String get searchForUsers;

  /// No description provided for @enterNameUsernameOrRole.
  ///
  /// In en, this message translates to:
  /// **'Enter a name, username, or role to find people'**
  String get enterNameUsernameOrRole;

  /// No description provided for @currentTeam.
  ///
  /// In en, this message translates to:
  /// **'Current Team'**
  String get currentTeam;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @tryAdjustingSearchTerms.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustingSearchTerms;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @team.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get team;

  /// No description provided for @userAlreadyInTeam.
  ///
  /// In en, this message translates to:
  /// **'User Already in Team'**
  String get userAlreadyInTeam;

  /// No description provided for @isAlreadyActiveMemberOf.
  ///
  /// In en, this message translates to:
  /// **'is already an active member of {supplierName}'**
  String isAlreadyActiveMemberOf(String supplierName);

  /// No description provided for @pendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitation'**
  String get pendingInvitation;

  /// No description provided for @hasPendingInvitationFor.
  ///
  /// In en, this message translates to:
  /// **'has a pending invitation for {supplierName}'**
  String hasPendingInvitationFor(String supplierName);

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @manager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get manager;

  /// No description provided for @staff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staff;

  /// No description provided for @loadingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Loading dashboard...'**
  String get loadingDashboard;

  /// No description provided for @noOrganisationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No organisations available.'**
  String get noOrganisationsAvailable;

  /// No description provided for @noSuppliersInOrganisation.
  ///
  /// In en, this message translates to:
  /// **'No suppliers in this organisation'**
  String get noSuppliersInOrganisation;

  /// No description provided for @pendingInvitationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get pendingInvitationsTooltip;

  /// No description provided for @createNewOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Create New Order'**
  String get createNewOrderLabel;

  /// No description provided for @createNewInvoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Create New Invoice'**
  String get createNewInvoiceLabel;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @cancelInvitationLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Invitation'**
  String get cancelInvitationLabel;

  /// No description provided for @noPendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'No pending invitation found'**
  String get noPendingInvitation;

  /// No description provided for @areYouSureYouWantToCancelTheInvitationFor.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel the invitation for {userName}?'**
  String areYouSureYouWantToCancelTheInvitationFor(String userName);

  /// No description provided for @invitationCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation cancelled successfully'**
  String get invitationCancelledSuccessfully;

  /// No description provided for @failedToCancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel invitation'**
  String get failedToCancelInvitation;

  /// No description provided for @activePrivileges.
  ///
  /// In en, this message translates to:
  /// **'Active Privileges'**
  String get activePrivileges;

  /// No description provided for @pendingPrivileges.
  ///
  /// In en, this message translates to:
  /// **'Pending Privileges'**
  String get pendingPrivileges;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires on {date}'**
  String expiresOn(String date);

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @canManage.
  ///
  /// In en, this message translates to:
  /// **'Can Manage'**
  String get canManage;

  /// No description provided for @canView.
  ///
  /// In en, this message translates to:
  /// **'Can View'**
  String get canView;

  /// No description provided for @failedToProcessInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to process invitation'**
  String get failedToProcessInvitation;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'documents'**
  String get documents;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @addDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocumentLabel;

  /// No description provided for @searchDocumentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Search Documents'**
  String get searchDocumentsLabel;

  /// No description provided for @searchByNumberOrCustomerLabel.
  ///
  /// In en, this message translates to:
  /// **'Search by number or customer'**
  String get searchByNumberOrCustomerLabel;

  /// No description provided for @payRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pay Remaining'**
  String get payRemainingLabel;

  /// No description provided for @paymentOutstandingLabel.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get paymentOutstandingLabel;

  /// No description provided for @paymentRemainingAfter.
  ///
  /// In en, this message translates to:
  /// **'{amount} remaining after this payment'**
  String paymentRemainingAfter(String amount);

  /// No description provided for @paymentSettlesFull.
  ///
  /// In en, this message translates to:
  /// **'This settles the full amount'**
  String get paymentSettlesFull;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get paymentAmountLabel;

  /// No description provided for @paymentMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get paymentMethodLabel;

  /// No description provided for @paymentNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get paymentNotesLabel;

  /// No description provided for @paymentNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get paymentNotesHint;

  /// No description provided for @productsLabel.
  ///
  /// In en, this message translates to:
  /// **'products'**
  String get productsLabel;

  /// No description provided for @paymentSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Pay {amount}'**
  String paymentSubmitButton(String amount);

  /// No description provided for @paymentMethodCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get paymentMethodCash;

  /// No description provided for @paymentMethodCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get paymentMethodCard;

  /// No description provided for @paymentMethodBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer'**
  String get paymentMethodBankTransfer;

  /// No description provided for @paymentMethodMobileMoney.
  ///
  /// In en, this message translates to:
  /// **'Mobile money'**
  String get paymentMethodMobileMoney;

  /// No description provided for @paymentErrorEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount'**
  String get paymentErrorEnterAmount;

  /// No description provided for @paymentErrorInvalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get paymentErrorInvalidNumber;

  /// No description provided for @paymentErrorMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get paymentErrorMustBePositive;

  /// No description provided for @paymentErrorExceedsDue.
  ///
  /// In en, this message translates to:
  /// **'Amount cannot exceed {amount}'**
  String paymentErrorExceedsDue(String amount);

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'{amount} paid via {method}.'**
  String paymentSuccessBody(String amount, String method);

  /// No description provided for @paymentQuickAmounts.
  ///
  /// In en, this message translates to:
  /// **'Quick amounts'**
  String get paymentQuickAmounts;

  /// No description provided for @paymentFullAmount.
  ///
  /// In en, this message translates to:
  /// **'Full amount'**
  String get paymentFullAmount;

  /// No description provided for @loadAnalyticsData.
  ///
  /// In en, this message translates to:
  /// **'Load analytics data'**
  String get loadAnalyticsData;

  /// No description provided for @collectionRate.
  ///
  /// In en, this message translates to:
  /// **'Collection rate'**
  String get collectionRate;

  /// No description provided for @totalTransactions.
  ///
  /// In en, this message translates to:
  /// **'Total transactions'**
  String get totalTransactions;

  /// No description provided for @totalCollected.
  ///
  /// In en, this message translates to:
  /// **'Total collected'**
  String get totalCollected;

  /// No description provided for @chooseSupplierHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the business you want to manage'**
  String get chooseSupplierHint;

  /// No description provided for @noOrganisation.
  ///
  /// In en, this message translates to:
  /// **'No organisation'**
  String get noOrganisation;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total outstanding'**
  String get totalOutstanding;

  /// No description provided for @unnamedProduct.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Product'**
  String get unnamedProduct;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @itemsLabel.
  ///
  /// In en, this message translates to:
  /// **'items'**
  String get itemsLabel;

  /// No description provided for @increaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity'**
  String get increaseQuantity;

  /// No description provided for @decreaseQuantity.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity'**
  String get decreaseQuantity;

  /// No description provided for @maxAvailable.
  ///
  /// In en, this message translates to:
  /// **'Max available: {count}'**
  String maxAvailable(int count);

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @defaultPrice.
  ///
  /// In en, this message translates to:
  /// **'Default price'**
  String get defaultPrice;

  /// No description provided for @customPrice.
  ///
  /// In en, this message translates to:
  /// **'Custom price'**
  String get customPrice;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @customPriceApplied.
  ///
  /// In en, this message translates to:
  /// **'Custom price applied'**
  String get customPriceApplied;

  /// No description provided for @customPriceAboveCatalog.
  ///
  /// In en, this message translates to:
  /// **'Custom price is above the default — no discount applied'**
  String get customPriceAboveCatalog;

  /// No description provided for @discountPreview.
  ///
  /// In en, this message translates to:
  /// **'{amount} off ({percent}%)'**
  String discountPreview(String amount, String percent);

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @addNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Add notes...'**
  String get addNotesHint;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @qtyTimesPrice.
  ///
  /// In en, this message translates to:
  /// **'{qty} × {price}'**
  String qtyTimesPrice(int qty, String price);

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @addToCartLabel.
  ///
  /// In en, this message translates to:
  /// **'Add to Cart'**
  String get addToCartLabel;

  /// No description provided for @deliveryDetailTitleWithId.
  ///
  /// In en, this message translates to:
  /// **'Delivery #{id}'**
  String deliveryDetailTitleWithId(int id);

  /// No description provided for @deliveryDetailRefreshTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get deliveryDetailRefreshTooltip;

  /// No description provided for @deliveryDetailEditTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get deliveryDetailEditTooltip;

  /// No description provided for @deliveryDetailRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get deliveryDetailRefreshing;

  /// No description provided for @deliveryDetailCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get deliveryDetailCopiedToClipboard;

  /// No description provided for @deliveryDetailSectionItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get deliveryDetailSectionItems;

  /// No description provided for @deliveryDetailSectionItemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String deliveryDetailSectionItemsCount(int count);

  /// No description provided for @deliveryDetailSectionDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get deliveryDetailSectionDestination;

  /// No description provided for @deliveryDetailSectionProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get deliveryDetailSectionProvider;

  /// No description provided for @deliveryDetailSectionShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping'**
  String get deliveryDetailSectionShipping;

  /// No description provided for @deliveryDetailSectionInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get deliveryDetailSectionInvoice;

  /// No description provided for @deliveryDetailSectionMetadata.
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get deliveryDetailSectionMetadata;

  /// No description provided for @deliveryDetailUpdatedJustNow.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get deliveryDetailUpdatedJustNow;

  /// No description provided for @deliveryDetailUpdatedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} min ago'**
  String deliveryDetailUpdatedMinutesAgo(int count);

  /// No description provided for @deliveryDetailUpdatedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} h ago'**
  String deliveryDetailUpdatedHoursAgo(int count);

  /// No description provided for @deliveryDetailUpdatedDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'Updated {count} d ago'**
  String deliveryDetailUpdatedDaysAgo(int count);

  /// No description provided for @deliveryDetailUpdatedOnDate.
  ///
  /// In en, this message translates to:
  /// **'Updated on {day}/{month}/{year}'**
  String deliveryDetailUpdatedOnDate(int day, int month, int year);

  /// No description provided for @deliveryDetailEmptyItems.
  ///
  /// In en, this message translates to:
  /// **'No items for this provider'**
  String get deliveryDetailEmptyItems;

  /// No description provided for @deliveryDetailEmptyDestination.
  ///
  /// In en, this message translates to:
  /// **'No destination details'**
  String get deliveryDetailEmptyDestination;

  /// No description provided for @deliveryDetailEmptyProvider.
  ///
  /// In en, this message translates to:
  /// **'No provider details'**
  String get deliveryDetailEmptyProvider;

  /// No description provided for @deliveryDetailEmptyShipping.
  ///
  /// In en, this message translates to:
  /// **'No shipping details'**
  String get deliveryDetailEmptyShipping;

  /// No description provided for @deliveryDetailEmptyInvoice.
  ///
  /// In en, this message translates to:
  /// **'No invoice details'**
  String get deliveryDetailEmptyInvoice;

  /// No description provided for @deliveryDetailEmptyMetadata.
  ///
  /// In en, this message translates to:
  /// **'No metadata available'**
  String get deliveryDetailEmptyMetadata;

  /// No description provided for @deliveryDetailItemQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'{count}×'**
  String deliveryDetailItemQuantityLabel(int count);

  /// No description provided for @deliveryDetailProductFallback.
  ///
  /// In en, this message translates to:
  /// **'Product #{id}'**
  String deliveryDetailProductFallback(int id);

  /// No description provided for @deliveryDetailItemSubline.
  ///
  /// In en, this message translates to:
  /// **'{brand} · {barcode} · #{productId}'**
  String deliveryDetailItemSubline(String brand, String barcode, int productId);

  /// No description provided for @deliveryDetailItemUnitLine.
  ///
  /// In en, this message translates to:
  /// **'{price} DA each · per {unit} · VAT {vat}%'**
  String deliveryDetailItemUnitLine(String price, String unit, String vat);

  /// No description provided for @deliveryDetailItemDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryDetailItemDelivered;

  /// No description provided for @deliveryDetailTotalsSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get deliveryDetailTotalsSubtotal;

  /// No description provided for @deliveryDetailTotalsDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get deliveryDetailTotalsDiscount;

  /// No description provided for @deliveryDetailTotalsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deliveryDetailTotalsTotal;

  /// No description provided for @deliveryDetailDiscountValue.
  ///
  /// In en, this message translates to:
  /// **'− {amount} DA'**
  String deliveryDetailDiscountValue(String amount);

  /// No description provided for @deliveryDetailPriceWithCurrency.
  ///
  /// In en, this message translates to:
  /// **'{price} DA'**
  String deliveryDetailPriceWithCurrency(String price);

  /// No description provided for @deliveryDetailFieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get deliveryDetailFieldAddress;

  /// No description provided for @deliveryDetailFieldStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get deliveryDetailFieldStreet;

  /// No description provided for @deliveryDetailFieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get deliveryDetailFieldCity;

  /// No description provided for @deliveryDetailFieldPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code'**
  String get deliveryDetailFieldPostalCode;

  /// No description provided for @deliveryDetailFieldCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get deliveryDetailFieldCountry;

  /// No description provided for @deliveryDetailFieldRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get deliveryDetailFieldRecipient;

  /// No description provided for @deliveryDetailFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get deliveryDetailFieldName;

  /// No description provided for @deliveryDetailFieldOrganisation.
  ///
  /// In en, this message translates to:
  /// **'Organisation'**
  String get deliveryDetailFieldOrganisation;

  /// No description provided for @deliveryDetailFieldProviderId.
  ///
  /// In en, this message translates to:
  /// **'Provider ID'**
  String get deliveryDetailFieldProviderId;

  /// No description provided for @deliveryDetailFieldMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get deliveryDetailFieldMethod;

  /// No description provided for @deliveryDetailFieldPackages.
  ///
  /// In en, this message translates to:
  /// **'Packages'**
  String get deliveryDetailFieldPackages;

  /// No description provided for @deliveryDetailFieldTotalWeight.
  ///
  /// In en, this message translates to:
  /// **'Total weight'**
  String get deliveryDetailFieldTotalWeight;

  /// No description provided for @deliveryDetailFieldDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get deliveryDetailFieldDimensions;

  /// No description provided for @deliveryDetailFieldGoods.
  ///
  /// In en, this message translates to:
  /// **'Goods'**
  String get deliveryDetailFieldGoods;

  /// No description provided for @deliveryDetailFieldHsCode.
  ///
  /// In en, this message translates to:
  /// **'HS code'**
  String get deliveryDetailFieldHsCode;

  /// No description provided for @deliveryDetailFieldMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get deliveryDetailFieldMerchant;

  /// No description provided for @deliveryDetailFieldInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get deliveryDetailFieldInstructions;

  /// No description provided for @deliveryDetailFieldFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get deliveryDetailFieldFee;

  /// No description provided for @deliveryDetailFieldInvoiceNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get deliveryDetailFieldInvoiceNumber;

  /// No description provided for @deliveryDetailFieldInvoiceType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get deliveryDetailFieldInvoiceType;

  /// No description provided for @deliveryDetailFieldInvoiceStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deliveryDetailFieldInvoiceStatus;

  /// No description provided for @deliveryDetailFieldStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get deliveryDetailFieldStatus;

  /// No description provided for @deliveryDetailFieldInvoiceTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get deliveryDetailFieldInvoiceTotal;

  /// No description provided for @deliveryDetailFieldInvoiceIssueDate.
  ///
  /// In en, this message translates to:
  /// **'Issue date'**
  String get deliveryDetailFieldInvoiceIssueDate;

  /// No description provided for @deliveryDetailFieldInvoiceDueDate.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get deliveryDetailFieldInvoiceDueDate;

  /// No description provided for @deliveryDetailFieldInvoiceTaxApplied.
  ///
  /// In en, this message translates to:
  /// **'Tax applied'**
  String get deliveryDetailFieldInvoiceTaxApplied;

  /// No description provided for @deliveryDetailFieldInvoiceNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get deliveryDetailFieldInvoiceNotes;

  /// No description provided for @deliveryDetailFieldCreated.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get deliveryDetailFieldCreated;

  /// No description provided for @deliveryDetailFieldUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get deliveryDetailFieldUpdated;

  /// No description provided for @deliveryDetailFieldDeliveryId.
  ///
  /// In en, this message translates to:
  /// **'Delivery ID'**
  String get deliveryDetailFieldDeliveryId;

  /// No description provided for @deliveryDetailFieldBrokerId.
  ///
  /// In en, this message translates to:
  /// **'Broker ID'**
  String get deliveryDetailFieldBrokerId;

  /// No description provided for @deliveryDetailFieldInvoiceRef.
  ///
  /// In en, this message translates to:
  /// **'Invoice ref'**
  String get deliveryDetailFieldInvoiceRef;

  /// No description provided for @deliveryDetailFieldSourceType.
  ///
  /// In en, this message translates to:
  /// **'Source type'**
  String get deliveryDetailFieldSourceType;

  /// No description provided for @deliveryDetailFieldSourceId.
  ///
  /// In en, this message translates to:
  /// **'Source ID'**
  String get deliveryDetailFieldSourceId;

  /// No description provided for @deliveryDetailFieldAddressId.
  ///
  /// In en, this message translates to:
  /// **'Address ID'**
  String get deliveryDetailFieldAddressId;

  /// No description provided for @deliveryDetailFieldCurrentAddressId.
  ///
  /// In en, this message translates to:
  /// **'Current address ID'**
  String get deliveryDetailFieldCurrentAddressId;

  /// No description provided for @deliveryDetailFieldItemCount.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get deliveryDetailFieldItemCount;

  /// No description provided for @deliveryDetailFieldBrokerEntry.
  ///
  /// In en, this message translates to:
  /// **'Broker {key}'**
  String deliveryDetailFieldBrokerEntry(String key);

  /// No description provided for @deliveryDetailPersonWithId.
  ///
  /// In en, this message translates to:
  /// **'Person #{id}'**
  String deliveryDetailPersonWithId(int id);

  /// No description provided for @deliveryDetailProviderWithId.
  ///
  /// In en, this message translates to:
  /// **'Provider #{id}'**
  String deliveryDetailProviderWithId(int id);

  /// No description provided for @deliveryDetailIdValue.
  ///
  /// In en, this message translates to:
  /// **'#{id}'**
  String deliveryDetailIdValue(int id);

  /// No description provided for @deliveryDetailPackageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 package} other{{count} packages}}'**
  String deliveryDetailPackageCount(int count);

  /// No description provided for @deliveryDetailWeightKg.
  ///
  /// In en, this message translates to:
  /// **'{weight} kg'**
  String deliveryDetailWeightKg(String weight);

  /// No description provided for @deliveryDetailPercentValue.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String deliveryDetailPercentValue(int value);

  /// No description provided for @deliveryDetailActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deliveryDetailActionCancel;

  /// No description provided for @deliveryDetailActionValidate.
  ///
  /// In en, this message translates to:
  /// **'Validate order'**
  String get deliveryDetailActionValidate;

  /// No description provided for @deliveryDetailCancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this delivery?'**
  String get deliveryDetailCancelDialogTitle;

  /// No description provided for @deliveryDetailCancelDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Delivery #{id} will be marked as cancelled. This cannot be undone.'**
  String deliveryDetailCancelDialogBody(int id);

  /// No description provided for @deliveryDetailCancelDialogKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get deliveryDetailCancelDialogKeep;

  /// No description provided for @deliveryDetailCancelDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel delivery'**
  String get deliveryDetailCancelDialogConfirm;

  /// No description provided for @deliveryDetailCancelSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery cancelled'**
  String get deliveryDetailCancelSuccess;

  /// No description provided for @deliveryDetailCancelFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel'**
  String get deliveryDetailCancelFailure;

  /// No description provided for @deliveryDetailValidateTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm delivery'**
  String get deliveryDetailValidateTitle;

  /// No description provided for @deliveryDetailValidateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Verify the details below before marking complete.'**
  String get deliveryDetailValidateSubtitle;

  /// No description provided for @deliveryDetailValidateBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get deliveryDetailValidateBack;

  /// No description provided for @deliveryDetailValidateConfirm.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get deliveryDetailValidateConfirm;

  /// No description provided for @deliveryDetailValidateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery #{id} validated'**
  String deliveryDetailValidateSuccess(int id);

  /// No description provided for @deliveryDetailValidateFailure.
  ///
  /// In en, this message translates to:
  /// **'Failed to update delivery'**
  String get deliveryDetailValidateFailure;

  /// No description provided for @deliveryStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get deliveryStatusPending;

  /// No description provided for @deliveryStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get deliveryStatusProcessing;

  /// No description provided for @deliveryStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get deliveryStatusConfirmed;

  /// No description provided for @deliveryStatusReadyForPickup.
  ///
  /// In en, this message translates to:
  /// **'Ready for pickup'**
  String get deliveryStatusReadyForPickup;

  /// No description provided for @deliveryStatusInTransit.
  ///
  /// In en, this message translates to:
  /// **'In transit'**
  String get deliveryStatusInTransit;

  /// No description provided for @deliveryStatusOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for delivery'**
  String get deliveryStatusOutForDelivery;

  /// No description provided for @deliveryStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get deliveryStatusDelivered;

  /// No description provided for @deliveryStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get deliveryStatusFailed;

  /// No description provided for @deliveryStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get deliveryStatusCancelled;

  /// No description provided for @deliveryStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get deliveryStatusReturned;

  /// No description provided for @deliveryStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get deliveryStatusRefunded;

  /// No description provided for @deliveryStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get deliveryStatusUnknown;

  /// No description provided for @deliveryStatusShipped.
  ///
  /// In en, this message translates to:
  /// **'Shipped'**
  String get deliveryStatusShipped;

  /// No description provided for @shippingMethodStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard Delivery'**
  String get shippingMethodStandard;

  /// No description provided for @shippingMethodExpress.
  ///
  /// In en, this message translates to:
  /// **'Express Delivery'**
  String get shippingMethodExpress;

  /// No description provided for @shippingMethodOvernight.
  ///
  /// In en, this message translates to:
  /// **'Overnight Delivery'**
  String get shippingMethodOvernight;

  /// No description provided for @shippingMethodFreight.
  ///
  /// In en, this message translates to:
  /// **'Freight Shipping'**
  String get shippingMethodFreight;

  /// No description provided for @shippingMethodPickup.
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get shippingMethodPickup;

  /// No description provided for @shippingMethodCourier.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get shippingMethodCourier;

  /// No description provided for @shippingMethodSameDay.
  ///
  /// In en, this message translates to:
  /// **'Same Day'**
  String get shippingMethodSameDay;

  /// No description provided for @shippingMethodInternational.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get shippingMethodInternational;

  /// No description provided for @invoiceTypeInvoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get invoiceTypeInvoice;

  /// No description provided for @invoiceTypeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get invoiceTypeReceipt;

  /// No description provided for @invoiceTypeProforma.
  ///
  /// In en, this message translates to:
  /// **'Proforma'**
  String get invoiceTypeProforma;

  /// No description provided for @invoiceStatusUnpaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get invoiceStatusUnpaidLabel;

  /// No description provided for @invoiceStatusPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoiceStatusPaidLabel;

  /// No description provided for @invoiceStatusCanceledLabel.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get invoiceStatusCanceledLabel;

  /// No description provided for @invoiceStatusPartiallyPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get invoiceStatusPartiallyPaidLabel;

  /// No description provided for @invoiceStatusOverdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get invoiceStatusOverdueLabel;

  /// No description provided for @invoiceStatusRefundedLabel.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get invoiceStatusRefundedLabel;

  /// No description provided for @deliveryCardNoDestination.
  ///
  /// In en, this message translates to:
  /// **'No destination'**
  String get deliveryCardNoDestination;

  /// No description provided for @deliveryCardLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load delivery details'**
  String get deliveryCardLoadFailed;

  /// No description provided for @deliveryDetailSectionCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get deliveryDetailSectionCustomer;

  /// No description provided for @deliveryDetailFieldUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get deliveryDetailFieldUsername;

  /// No description provided for @deliveryDetailFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get deliveryDetailFieldEmail;

  /// No description provided for @deliveryDetailFieldUserType.
  ///
  /// In en, this message translates to:
  /// **'User type'**
  String get deliveryDetailFieldUserType;

  /// No description provided for @deliveryDetailFieldPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get deliveryDetailFieldPhone;

  /// No description provided for @deliveryDetailFieldUserId.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get deliveryDetailFieldUserId;

  /// No description provided for @deliveryDetailActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get deliveryDetailActionAccept;

  /// No description provided for @deliveryDetailActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get deliveryDetailActionConfirm;

  /// No description provided for @deliveryDetailActionShip.
  ///
  /// In en, this message translates to:
  /// **'Ship'**
  String get deliveryDetailActionShip;

  /// No description provided for @deliveryDetailActionInTransit.
  ///
  /// In en, this message translates to:
  /// **'Mark In Transit'**
  String get deliveryDetailActionInTransit;

  /// No description provided for @deliveryDetailActionOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get deliveryDetailActionOutForDelivery;

  /// No description provided for @deliveryDetailActionDeliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get deliveryDetailActionDeliver;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @deliveryDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delivery details'**
  String get deliveryDetailsTitle;

  /// No description provided for @deliveryDetailsSectionProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get deliveryDetailsSectionProducts;

  /// No description provided for @deliveryDetailsSectionPackages.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get deliveryDetailsSectionPackages;

  /// No description provided for @deliveryDetailsSectionShipping.
  ///
  /// In en, this message translates to:
  /// **'Shipping Information'**
  String get deliveryDetailsSectionShipping;

  /// No description provided for @deliveryDetailsSectionAdditional.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get deliveryDetailsSectionAdditional;

  /// No description provided for @deliveryDetailsProductSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name, brand, or barcode'**
  String get deliveryDetailsProductSearchHint;

  /// No description provided for @deliveryDetailsProductFallback.
  ///
  /// In en, this message translates to:
  /// **'Product #{id}'**
  String deliveryDetailsProductFallback(int id);

  /// No description provided for @deliveryDetailsProductsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 product selected} other{{count} products selected}}'**
  String deliveryDetailsProductsSelected(int count);

  /// No description provided for @deliveryDetailsStockIn.
  ///
  /// In en, this message translates to:
  /// **'{count} in stock'**
  String deliveryDetailsStockIn(int count);

  /// No description provided for @deliveryDetailsStockOut.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get deliveryDetailsStockOut;

  /// No description provided for @deliveryDetailsNoProducts.
  ///
  /// In en, this message translates to:
  /// **'This delivery has no products attached.'**
  String get deliveryDetailsNoProducts;

  /// No description provided for @deliveryDetailsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No products match \"{query}\".'**
  String deliveryDetailsNoMatches(String query);

  /// No description provided for @deliveryDetailsDimensionLength.
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get deliveryDetailsDimensionLength;

  /// No description provided for @deliveryDetailsDimensionWidth.
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get deliveryDetailsDimensionWidth;

  /// No description provided for @deliveryDetailsDimensionHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get deliveryDetailsDimensionHeight;

  /// No description provided for @deliveryDetailsPackageWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Package {index} weight (kg)'**
  String deliveryDetailsPackageWeightLabel(int index);

  /// No description provided for @deliveryDetailsRemovePackage.
  ///
  /// In en, this message translates to:
  /// **'Remove package'**
  String get deliveryDetailsRemovePackage;

  /// No description provided for @deliveryDetailsAddPackage.
  ///
  /// In en, this message translates to:
  /// **'Add package'**
  String get deliveryDetailsAddPackage;

  /// No description provided for @deliveryDetailsPackageSummary.
  ///
  /// In en, this message translates to:
  /// **'Package count: {count}   Total weight: {weight} kg'**
  String deliveryDetailsPackageSummary(int count, String weight);

  /// No description provided for @deliveryDetailsFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee (DA)'**
  String get deliveryDetailsFeeLabel;

  /// No description provided for @deliveryDetailsFeeHelper.
  ///
  /// In en, this message translates to:
  /// **'Amount the customer pays the courier'**
  String get deliveryDetailsFeeHelper;

  /// No description provided for @deliveryDetailsShippingMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Shipping Method'**
  String get deliveryDetailsShippingMethodLabel;

  /// No description provided for @deliveryDetailsHsCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'HS Code'**
  String get deliveryDetailsHsCodeLabel;

  /// No description provided for @deliveryDetailsMerchantLabel.
  ///
  /// In en, this message translates to:
  /// **'Merchant Name'**
  String get deliveryDetailsMerchantLabel;

  /// No description provided for @deliveryDetailsGoodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Goods Description'**
  String get deliveryDetailsGoodsLabel;

  /// No description provided for @deliveryDetailsInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Special Instructions'**
  String get deliveryDetailsInstructionsLabel;

  /// No description provided for @deliveryDetailsSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get deliveryDetailsSaveButton;

  /// No description provided for @deliveryDetailsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save details'**
  String get deliveryDetailsSaveFailed;

  /// No description provided for @deliveryDetailsSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String deliveryDetailsSaveError(String message);

  /// No description provided for @deliveryDetailsValidationEnterWeight.
  ///
  /// In en, this message translates to:
  /// **'Enter weight'**
  String get deliveryDetailsValidationEnterWeight;

  /// No description provided for @deliveryDetailsValidationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get deliveryDetailsValidationRequired;

  /// No description provided for @deliveryDetailsValidationEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get deliveryDetailsValidationEnterAmount;

  /// No description provided for @deliveryDetailsValidationFeeNegative.
  ///
  /// In en, this message translates to:
  /// **'Fee cannot be negative'**
  String get deliveryDetailsValidationFeeNegative;

  /// No description provided for @deliveryActionAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get deliveryActionAccept;

  /// No description provided for @deliveryActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get deliveryActionConfirm;

  /// No description provided for @deliveryActionShip.
  ///
  /// In en, this message translates to:
  /// **'Ship'**
  String get deliveryActionShip;

  /// No description provided for @deliveryActionInTransit.
  ///
  /// In en, this message translates to:
  /// **'Mark In Transit'**
  String get deliveryActionInTransit;

  /// No description provided for @deliveryActionOutForDelivery.
  ///
  /// In en, this message translates to:
  /// **'Out for Delivery'**
  String get deliveryActionOutForDelivery;

  /// No description provided for @deliveryActionDeliver.
  ///
  /// In en, this message translates to:
  /// **'Deliver'**
  String get deliveryActionDeliver;

  /// No description provided for @deliveryActionFail.
  ///
  /// In en, this message translates to:
  /// **'Report Failure'**
  String get deliveryActionFail;

  /// No description provided for @deliveryActionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel Delivery'**
  String get deliveryActionCancel;

  /// No description provided for @deliveryActionReturn.
  ///
  /// In en, this message translates to:
  /// **'Mark Returned'**
  String get deliveryActionReturn;

  /// No description provided for @deliveryActionRefund.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get deliveryActionRefund;

  /// No description provided for @deliveryTransitionDeliveryId.
  ///
  /// In en, this message translates to:
  /// **'Delivery #{id}'**
  String deliveryTransitionDeliveryId(int id);

  /// No description provided for @deliveryTransitionReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to proceed'**
  String get deliveryTransitionReady;

  /// No description provided for @deliveryTransitionMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing requirements'**
  String get deliveryTransitionMissing;

  /// No description provided for @deliveryTransitionMissingHint.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Complete the missing item to continue.} other{Complete all {count} missing items to continue.}}'**
  String deliveryTransitionMissingHint(int count);

  /// No description provided for @deliveryTransitionWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get deliveryTransitionWorking;

  /// No description provided for @deliveryTransitionCommit.
  ///
  /// In en, this message translates to:
  /// **'{verb} Delivery'**
  String deliveryTransitionCommit(String verb);

  /// No description provided for @deliveryTransitionSuccess.
  ///
  /// In en, this message translates to:
  /// **'{verb} succeeded'**
  String deliveryTransitionSuccess(String verb);

  /// No description provided for @deliveryTransitionFailure.
  ///
  /// In en, this message translates to:
  /// **'{verb} failed'**
  String deliveryTransitionFailure(String verb);

  /// No description provided for @deliveryTransitionFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get deliveryTransitionFix;

  /// No description provided for @deliveryTransitionReqRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient specified'**
  String get deliveryTransitionReqRecipient;

  /// No description provided for @deliveryTransitionReqRecipientDesc.
  ///
  /// In en, this message translates to:
  /// **'The delivery needs a recipient or destination address.'**
  String get deliveryTransitionReqRecipientDesc;

  /// No description provided for @deliveryTransitionReqPackages.
  ///
  /// In en, this message translates to:
  /// **'At least one package'**
  String get deliveryTransitionReqPackages;

  /// No description provided for @deliveryTransitionReqPackagesDesc.
  ///
  /// In en, this message translates to:
  /// **'Declare packages and weight before confirming.'**
  String get deliveryTransitionReqPackagesDesc;

  /// No description provided for @deliveryTransitionReqProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider assigned'**
  String get deliveryTransitionReqProvider;

  /// No description provided for @deliveryTransitionReqCarrierAccepted.
  ///
  /// In en, this message translates to:
  /// **'Carrier accepted the handoff'**
  String get deliveryTransitionReqCarrierAccepted;

  /// No description provided for @deliveryTransitionReqCarrierAcceptedDesc.
  ///
  /// In en, this message translates to:
  /// **'This records that the carrier has taken physical custody.'**
  String get deliveryTransitionReqCarrierAcceptedDesc;

  /// No description provided for @deliveryTransitionReqTracking.
  ///
  /// In en, this message translates to:
  /// **'Carrier tracking shows movement'**
  String get deliveryTransitionReqTracking;

  /// No description provided for @deliveryTransitionReqTrackingDesc.
  ///
  /// In en, this message translates to:
  /// **'This records that the carrier reports the goods are moving.'**
  String get deliveryTransitionReqTrackingDesc;

  /// No description provided for @deliveryTransitionReqDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination address on file'**
  String get deliveryTransitionReqDestination;

  /// No description provided for @deliveryTransitionReqProof.
  ///
  /// In en, this message translates to:
  /// **'Proof of delivery captured'**
  String get deliveryTransitionReqProof;

  /// No description provided for @deliveryTransitionReqProofDesc.
  ///
  /// In en, this message translates to:
  /// **'Signature, photo, or scan received from the recipient.'**
  String get deliveryTransitionReqProofDesc;

  /// No description provided for @sourceDistribution.
  ///
  /// In en, this message translates to:
  /// **'Source Distribution'**
  String get sourceDistribution;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @productQuantifierTxt.
  ///
  /// In en, this message translates to:
  /// **'Quantifier'**
  String get productQuantifierTxt;

  /// No description provided for @productOriginTxt.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get productOriginTxt;

  /// No description provided for @productHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get productHiddenLabel;

  /// No description provided for @deleteProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get deleteProductTitle;

  /// No description provided for @deleteProductConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Deleting \"{productName}\" removes it from the catalog. Orders that reference it keep their historical record.'**
  String deleteProductConfirmation(String productName);

  /// No description provided for @thisProductFallback.
  ///
  /// In en, this message translates to:
  /// **'this product'**
  String get thisProductFallback;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @productDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeletedMessage;

  /// No description provided for @productDeleteFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product'**
  String get productDeleteFailedMessage;

  /// No description provided for @productNowVisibleMessage.
  ///
  /// In en, this message translates to:
  /// **'Product is now visible'**
  String get productNowVisibleMessage;

  /// No description provided for @productNowHiddenMessage.
  ///
  /// In en, this message translates to:
  /// **'Product is now hidden'**
  String get productNowHiddenMessage;

  /// No description provided for @productVisibilityUpdateFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to update visibility'**
  String get productVisibilityUpdateFailedMessage;

  /// No description provided for @editorModeBadge.
  ///
  /// In en, this message translates to:
  /// **'Editor mode'**
  String get editorModeBadge;

  /// No description provided for @pricingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricingSectionTitle;

  /// No description provided for @basePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Base price'**
  String get basePriceLabel;

  /// No description provided for @basePriceCaption.
  ///
  /// In en, this message translates to:
  /// **'Supplier cost'**
  String get basePriceCaption;

  /// No description provided for @finalPriceCaption.
  ///
  /// In en, this message translates to:
  /// **'Customer pays'**
  String get finalPriceCaption;

  /// No description provided for @marginLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin'**
  String get marginLabel;

  /// No description provided for @marginPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Margin %'**
  String get marginPercentLabel;

  /// No description provided for @setBasePriceHint.
  ///
  /// In en, this message translates to:
  /// **'Set a base price to see margin and ROI'**
  String get setBasePriceHint;

  /// No description provided for @hideAction.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideAction;

  /// No description provided for @showAction.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showAction;

  /// No description provided for @stockSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get stockSectionTitle;

  /// No description provided for @inStockLabel.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStockLabel;

  /// No description provided for @outOfStockLabel.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStockLabel;

  /// No description provided for @stockTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get stockTotalLabel;

  /// No description provided for @stockReservedLabel.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get stockReservedLabel;

  /// No description provided for @stockAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get stockAvailableLabel;

  /// No description provided for @metadataSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Product metadata'**
  String get metadataSectionTitle;

  /// No description provided for @metaIdLabel.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get metaIdLabel;

  /// No description provided for @metaCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get metaCategoryLabel;

  /// No description provided for @metaBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get metaBarcodeLabel;

  /// No description provided for @metaUnitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get metaUnitLabel;

  /// No description provided for @metaProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get metaProviderLabel;

  /// No description provided for @metaOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get metaOwnerLabel;

  /// No description provided for @metaOriginLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get metaOriginLabel;

  /// No description provided for @visibilityVisibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visibilityVisibleLabel;

  /// No description provided for @visibilityHiddenLabel.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get visibilityHiddenLabel;

  /// No description provided for @dangerZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZoneTitle;

  /// No description provided for @dangerZoneBody.
  ///
  /// In en, this message translates to:
  /// **'Deleting a product removes it from the catalog. Orders that reference it keep their historical record.'**
  String get dangerZoneBody;

  /// No description provided for @productVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get productVisibilityTitle;

  /// No description provided for @editServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editServiceTitle;

  /// No description provided for @createServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Service'**
  String get createServiceTitle;

  /// No description provided for @basicInformationSection.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformationSection;

  /// No description provided for @pricingSection.
  ///
  /// In en, this message translates to:
  /// **'Pricing'**
  String get pricingSection;

  /// No description provided for @pricingConfigurationSection.
  ///
  /// In en, this message translates to:
  /// **'Pricing Configuration'**
  String get pricingConfigurationSection;

  /// No description provided for @resourceRequirementsSection.
  ///
  /// In en, this message translates to:
  /// **'Resource Requirements'**
  String get resourceRequirementsSection;

  /// No description provided for @staffRequirementsSection.
  ///
  /// In en, this message translates to:
  /// **'Staff Requirements'**
  String get staffRequirementsSection;

  /// No description provided for @costSummarySection.
  ///
  /// In en, this message translates to:
  /// **'Cost Summary'**
  String get costSummarySection;

  /// No description provided for @serviceNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Name'**
  String get serviceNameLabel;

  /// No description provided for @serviceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter service name'**
  String get serviceNameHint;

  /// No description provided for @serviceNameRequiredField.
  ///
  /// In en, this message translates to:
  /// **'Service name is required'**
  String get serviceNameRequiredField;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Enter description'**
  String get descriptionHint;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationLabel;

  /// No description provided for @durationHint.
  ///
  /// In en, this message translates to:
  /// **'Enter duration'**
  String get durationHint;

  /// No description provided for @durationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid duration'**
  String get durationInvalid;

  /// No description provided for @minutesSuffix.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesSuffix;

  /// No description provided for @ageGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Age Group'**
  String get ageGroupLabel;

  /// No description provided for @ageGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Enter age group'**
  String get ageGroupHint;

  /// No description provided for @sampleTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Sample Type'**
  String get sampleTypeLabel;

  /// No description provided for @sampleTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter sample type'**
  String get sampleTypeHint;

  /// No description provided for @specialistConsultationLabel.
  ///
  /// In en, this message translates to:
  /// **'Specialist Consultation'**
  String get specialistConsultationLabel;

  /// No description provided for @governmentFundedLabel.
  ///
  /// In en, this message translates to:
  /// **'Government Funded'**
  String get governmentFundedLabel;

  /// No description provided for @consultationIncludedLabel.
  ///
  /// In en, this message translates to:
  /// **'Consultation Included'**
  String get consultationIncludedLabel;

  /// No description provided for @digitalImagingLabel.
  ///
  /// In en, this message translates to:
  /// **'Digital Imaging'**
  String get digitalImagingLabel;

  /// No description provided for @materialOptionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Material Options'**
  String get materialOptionsLabel;

  /// No description provided for @includesLabel.
  ///
  /// In en, this message translates to:
  /// **'Includes'**
  String get includesLabel;

  /// No description provided for @roleFallback.
  ///
  /// In en, this message translates to:
  /// **'Role #{roleId}'**
  String roleFallback(int roleId);

  /// No description provided for @validationProviderRequired.
  ///
  /// In en, this message translates to:
  /// **'A valid provider is required'**
  String get validationProviderRequired;

  /// No description provided for @validationCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'A valid category is required'**
  String get validationCategoryRequired;

  /// No description provided for @validationDurationPositive.
  ///
  /// In en, this message translates to:
  /// **'Duration must be greater than zero'**
  String get validationDurationPositive;

  /// No description provided for @validationBasePricePositive.
  ///
  /// In en, this message translates to:
  /// **'Base price must be greater than zero'**
  String get validationBasePricePositive;

  /// No description provided for @validationFinalPricePositive.
  ///
  /// In en, this message translates to:
  /// **'Final price must be greater than zero'**
  String get validationFinalPricePositive;

  /// No description provided for @validationFinalPriceExceedsBase.
  ///
  /// In en, this message translates to:
  /// **'Final price cannot be greater than the base price'**
  String get validationFinalPriceExceedsBase;

  /// No description provided for @unexpectedErrorWithDetail.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {detail}'**
  String unexpectedErrorWithDetail(String detail);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1 {1 hour} other {{hours} hours}} {minutes, plural, =1 {1 minute} other {{minutes} minutes}}'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationHoursOnly.
  ///
  /// In en, this message translates to:
  /// **'{hours, plural, =1 {1 hour} other {{hours} hours}}'**
  String durationHoursOnly(int hours);

  /// No description provided for @durationMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, =1 {1 minute} other {{minutes} minutes}}'**
  String durationMinutesOnly(int minutes);

  /// No description provided for @durationPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get durationPlaceholder;

  /// No description provided for @glutenFreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Gluten free'**
  String get glutenFreeLabel;

  /// No description provided for @containsGlutenLabel.
  ///
  /// In en, this message translates to:
  /// **'Contains gluten'**
  String get containsGlutenLabel;

  /// No description provided for @mayContainGlutenLabel.
  ///
  /// In en, this message translates to:
  /// **'May contain gluten'**
  String get mayContainGlutenLabel;

  /// No description provided for @importedFromAi.
  ///
  /// In en, this message translates to:
  /// **'AI-imported'**
  String get importedFromAi;

  /// No description provided for @importedFromSource.
  ///
  /// In en, this message translates to:
  /// **'Imported from {source}'**
  String importedFromSource(String source);

  /// No description provided for @metaImportedBrandLabel.
  ///
  /// In en, this message translates to:
  /// **'Imported brand'**
  String get metaImportedBrandLabel;

  /// No description provided for @metaImportSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Import source'**
  String get metaImportSourceLabel;

  /// No description provided for @metaImportConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Import confidence'**
  String get metaImportConfidenceLabel;

  /// No description provided for @expiresLabel.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresLabel;

  /// No description provided for @failedToLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load products'**
  String get failedToLoadProducts;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete supplier'**
  String get deleteTooltip;

  /// No description provided for @editTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit supplier'**
  String get editTooltip;

  /// No description provided for @modulePersonnel.
  ///
  /// In en, this message translates to:
  /// **'Personnel'**
  String get modulePersonnel;

  /// No description provided for @moduleInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get moduleInventory;

  /// No description provided for @moduleServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get moduleServices;

  /// No description provided for @moduleSeller.
  ///
  /// In en, this message translates to:
  /// **'Seller'**
  String get moduleSeller;

  /// No description provided for @moduleOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get moduleOrders;

  /// No description provided for @moduleOperations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get moduleOperations;

  /// No description provided for @moduleFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get moduleFinance;

  /// No description provided for @failedToLoadSuppliers.
  ///
  /// In en, this message translates to:
  /// **'Failed to load suppliers'**
  String get failedToLoadSuppliers;

  /// No description provided for @grandTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Grand total'**
  String get grandTotalLabel;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueLabel;

  /// No description provided for @roiLabel.
  ///
  /// In en, this message translates to:
  /// **'ROI'**
  String get roiLabel;

  /// No description provided for @discountLabel.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discountLabel;

  /// No description provided for @taxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get taxLabel;

  /// No description provided for @deliveryLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get deliveryLabel;

  /// No description provided for @productSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Product subtotal'**
  String get productSubtotalLabel;

  /// No description provided for @serviceSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Service subtotal'**
  String get serviceSubtotalLabel;

  /// No description provided for @grossSubtotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Gross subtotal'**
  String get grossSubtotalLabel;

  /// No description provided for @totalCostLabel.
  ///
  /// In en, this message translates to:
  /// **'Total cost'**
  String get totalCostLabel;

  /// No description provided for @commercialBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Commercial breakdown'**
  String get commercialBreakdownTitle;

  /// No description provided for @profitabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Profitability'**
  String get profitabilityTitle;

  /// No description provided for @itemsTitle.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get itemsTitle;

  /// No description provided for @servicesTitle.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicesTitle;

  /// No description provided for @cartDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart details'**
  String get cartDetailsTitle;

  /// No description provided for @cartIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Cart ID'**
  String get cartIdLabel;

  /// No description provided for @deliveryIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Delivery ID'**
  String get deliveryIdLabel;

  /// No description provided for @deliveryMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get deliveryMethodLabel;

  /// No description provided for @deliveryFeeLabel.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get deliveryFeeLabel;

  /// No description provided for @metaOperationLabel.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get metaOperationLabel;

  /// No description provided for @metaCreatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get metaCreatedLabel;

  /// No description provided for @metaStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get metaStatusLabel;

  /// No description provided for @vatLabel.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vatLabel;

  /// No description provided for @invoiceStatusPartiallyPaidValue.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get invoiceStatusPartiallyPaidValue;

  /// No description provided for @invoiceStatusCanceledValue.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get invoiceStatusCanceledValue;

  /// No description provided for @itemStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get itemStatusDelivered;

  /// No description provided for @itemStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get itemStatusProcessing;

  /// No description provided for @itemStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get itemStatusPending;

  /// No description provided for @itemStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get itemStatusCancelled;

  /// No description provided for @itemStatusReturned.
  ///
  /// In en, this message translates to:
  /// **'Returned'**
  String get itemStatusReturned;

  /// No description provided for @itemStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get itemStatusPartial;

  /// No description provided for @serviceStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get serviceStatusCompleted;

  /// No description provided for @serviceStatusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get serviceStatusScheduled;

  /// No description provided for @serviceStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get serviceStatusInProgress;

  /// No description provided for @serviceStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get serviceStatusProcessing;

  /// No description provided for @serviceStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get serviceStatusPending;

  /// No description provided for @serviceStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get serviceStatusCancelled;

  /// No description provided for @serviceStatusNoShow.
  ///
  /// In en, this message translates to:
  /// **'No show'**
  String get serviceStatusNoShow;

  /// No description provided for @costSegmentProducts.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get costSegmentProducts;

  /// No description provided for @costSegmentConsumables.
  ///
  /// In en, this message translates to:
  /// **'Consumables'**
  String get costSegmentConsumables;

  /// No description provided for @costSegmentAmortized.
  ///
  /// In en, this message translates to:
  /// **'Amortized'**
  String get costSegmentAmortized;

  /// No description provided for @costSegmentLabor.
  ///
  /// In en, this message translates to:
  /// **'Labor'**
  String get costSegmentLabor;

  /// No description provided for @costSegmentDelivery.
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get costSegmentDelivery;

  /// No description provided for @resourceKindConsumable.
  ///
  /// In en, this message translates to:
  /// **'consumable'**
  String get resourceKindConsumable;

  /// No description provided for @resourceKindAmortized.
  ///
  /// In en, this message translates to:
  /// **'amortized'**
  String get resourceKindAmortized;

  /// No description provided for @resourceFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Resource'**
  String get resourceFallbackName;

  /// No description provided for @productFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Product #{id}'**
  String productFallbackName(String id);

  /// No description provided for @serviceFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Service #{id}'**
  String serviceFallbackName(String id);

  /// No description provided for @documentsCountLabel2.
  ///
  /// In en, this message translates to:
  /// **'{count} documents'**
  String documentsCountLabel2(int count);

  /// No description provided for @addDocumentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocumentTooltip;

  /// No description provided for @customerLabelWithId.
  ///
  /// In en, this message translates to:
  /// **'Customer {id}'**
  String customerLabelWithId(int id);

  /// No description provided for @guestLabelWithId.
  ///
  /// In en, this message translates to:
  /// **'Guest #{id}'**
  String guestLabelWithId(int id);

  /// No description provided for @overdueDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days}d overdue'**
  String overdueDaysLabel(int days);

  /// No description provided for @filterByLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter by location'**
  String get filterByLocationTooltip;

  /// No description provided for @expiresLabelSuffix.
  ///
  /// In en, this message translates to:
  /// **'Expires'**
  String get expiresLabelSuffix;

  /// No description provided for @activeStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatusLabel;

  /// No description provided for @pendingStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatusLabel;

  /// No description provided for @privilegeByCode.
  ///
  /// In en, this message translates to:
  /// **'{code, select, 1 {Admin} 2 {Manage Personnel} 3 {View Personnel} 4 {Manage Inventory} 5 {View Inventory} 6 {Manage Services} 7 {View Services} 8 {Manage Orders} 9 {View Orders} 10 {Manage Finance} 11 {View Finance} 12 {Manage Operations} 13 {View Operations} 14 {Manage POS} 15 {View POS} other {Privilege {code}}}'**
  String privilegeByCode(String code);

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @owned.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get owned;

  /// No description provided for @managed.
  ///
  /// In en, this message translates to:
  /// **'Managed'**
  String get managed;

  /// No description provided for @cookingChefText.
  ///
  /// In en, this message translates to:
  /// **'Cooking Chef'**
  String get cookingChefText;

  /// No description provided for @serviceNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Service name is required'**
  String get serviceNameRequired;

  /// No description provided for @noResourcesAdded.
  ///
  /// In en, this message translates to:
  /// **'No resources added yet'**
  String get noResourcesAdded;

  /// No description provided for @noStaffAdded.
  ///
  /// In en, this message translates to:
  /// **'No staff added yet'**
  String get noStaffAdded;

  /// No description provided for @appPurposeContent.
  ///
  /// In en, this message translates to:
  /// **'Verdelia\'s mission is to make gluten-free living simple and safe by connecting people with certified products, trusted local businesses, and clear health information.'**
  String get appPurposeContent;

  /// No description provided for @feature3.
  ///
  /// In en, this message translates to:
  /// **'📚 **Educational Content** - Learn about celiac disease, safe ingredients, and gluten-free living.'**
  String get feature3;

  /// No description provided for @recipedeletionConfirmationMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this recipe?'**
  String get recipedeletionConfirmationMessage;

  /// No description provided for @invoiceStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get invoiceStatusPaid;

  /// No description provided for @invoiceStatusPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially paid'**
  String get invoiceStatusPartiallyPaid;

  /// No description provided for @invoiceStatusUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get invoiceStatusUnpaid;

  /// No description provided for @invoiceStatusOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get invoiceStatusOverdue;

  /// No description provided for @invoiceStatusCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get invoiceStatusCanceled;

  /// No description provided for @invoiceStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get invoiceStatusRefunded;

  /// No description provided for @invoiceStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get invoiceStatusUnknown;

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} documents'**
  String documentsCount(int count);

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add Document'**
  String get addDocument;

  /// No description provided for @searchDocuments.
  ///
  /// In en, this message translates to:
  /// **'Search Documents'**
  String get searchDocuments;

  /// No description provided for @searchByNumberOrCustomer.
  ///
  /// In en, this message translates to:
  /// **'Search by number or customer'**
  String get searchByNumberOrCustomer;

  /// No description provided for @myDocuments.
  ///
  /// In en, this message translates to:
  /// **'My Documents'**
  String get myDocuments;

  /// No description provided for @loadingFinancialDocuments.
  ///
  /// In en, this message translates to:
  /// **'Loading financial documents...'**
  String get loadingFinancialDocuments;

  /// No description provided for @noMatchingDocuments.
  ///
  /// In en, this message translates to:
  /// **'No matching documents'**
  String get noMatchingDocuments;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @noDocumentsYet.
  ///
  /// In en, this message translates to:
  /// **'No documents yet'**
  String get noDocumentsYet;

  /// No description provided for @tryAdjustingFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting filters'**
  String get tryAdjustingFilters;

  /// No description provided for @noDocumentsMatch.
  ///
  /// In en, this message translates to:
  /// **'No documents match \"{query}\"'**
  String noDocumentsMatch(String query);

  /// No description provided for @startCreatingFirstDocument.
  ///
  /// In en, this message translates to:
  /// **'Start by creating your first document'**
  String get startCreatingFirstDocument;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @noMoreDocuments.
  ///
  /// In en, this message translates to:
  /// **'No more documents'**
  String get noMoreDocuments;

  /// No description provided for @customerWithId.
  ///
  /// In en, this message translates to:
  /// **'Customer {id}'**
  String customerWithId(Object id);

  /// No description provided for @guestWithId.
  ///
  /// In en, this message translates to:
  /// **'Guest #{id}'**
  String guestWithId(String id);

  /// No description provided for @guestLabel.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestLabel;

  /// No description provided for @canceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get canceled;

  /// No description provided for @dueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get dueSoon;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get onTrack;

  /// No description provided for @partialOverdue.
  ///
  /// In en, this message translates to:
  /// **'Partial / overdue'**
  String get partialOverdue;

  /// No description provided for @overdueDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d overdue'**
  String overdueDays(Object days);

  /// No description provided for @payRemaining.
  ///
  /// In en, this message translates to:
  /// **'Pay remaining'**
  String get payRemaining;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get payNow;

  /// No description provided for @recipe_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found.'**
  String get recipe_not_exists;

  /// No description provided for @recipe_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update recipe.'**
  String get recipe_update_failed;

  /// No description provided for @recipe_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete recipe.'**
  String get recipe_delete_failed;

  /// No description provided for @recipe_fetch_not_found.
  ///
  /// In en, this message translates to:
  /// **'Recipe not found.'**
  String get recipe_fetch_not_found;

  /// No description provided for @recipe_category_not_exists.
  ///
  /// In en, this message translates to:
  /// **'Recipe category not found.'**
  String get recipe_category_not_exists;

  /// No description provided for @recipe_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Recipe already exists.'**
  String get recipe_already_exists;

  /// No description provided for @recipe_insert_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create recipe.'**
  String get recipe_insert_failed;

  /// No description provided for @recipe_image_not_found.
  ///
  /// In en, this message translates to:
  /// **'Recipe image not found.'**
  String get recipe_image_not_found;

  /// No description provided for @recipe_search_not_found.
  ///
  /// In en, this message translates to:
  /// **'No recipes found.'**
  String get recipe_search_not_found;

  /// No description provided for @delivery_update_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update delivery.'**
  String get delivery_update_failed;

  /// No description provided for @food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get retail;

  /// No description provided for @trade.
  ///
  /// In en, this message translates to:
  /// **'Trade'**
  String get trade;

  /// No description provided for @beauty.
  ///
  /// In en, this message translates to:
  /// **'Beauty'**
  String get beauty;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @professional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @technology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technology;

  /// No description provided for @logistics.
  ///
  /// In en, this message translates to:
  /// **'Logistics'**
  String get logistics;

  /// No description provided for @automotive.
  ///
  /// In en, this message translates to:
  /// **'Automotive'**
  String get automotive;

  /// No description provided for @agriculture.
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get agriculture;

  /// No description provided for @hospitality.
  ///
  /// In en, this message translates to:
  /// **'Hospitality'**
  String get hospitality;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @alimentary.
  ///
  /// In en, this message translates to:
  /// **'Alimentary'**
  String get alimentary;

  /// No description provided for @beverages.
  ///
  /// In en, this message translates to:
  /// **'Beverages'**
  String get beverages;

  /// No description provided for @prepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get prepared;

  /// No description provided for @dining.
  ///
  /// In en, this message translates to:
  /// **'Dining'**
  String get dining;

  /// No description provided for @production.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get production;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @pharma.
  ///
  /// In en, this message translates to:
  /// **'Pharma'**
  String get pharma;

  /// No description provided for @wellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get wellness;

  /// No description provided for @medical_devices.
  ///
  /// In en, this message translates to:
  /// **'Medical Devices'**
  String get medical_devices;

  /// No description provided for @personal_care.
  ///
  /// In en, this message translates to:
  /// **'Personal Care'**
  String get personal_care;

  /// No description provided for @facilities.
  ///
  /// In en, this message translates to:
  /// **'Facilities'**
  String get facilities;

  /// No description provided for @diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get diagnostics;

  /// No description provided for @primary_care.
  ///
  /// In en, this message translates to:
  /// **'Primary Care'**
  String get primary_care;

  /// No description provided for @specialized_care.
  ///
  /// In en, this message translates to:
  /// **'Specialized Care'**
  String get specialized_care;

  /// No description provided for @dental.
  ///
  /// In en, this message translates to:
  /// **'Dental'**
  String get dental;

  /// No description provided for @therapy.
  ///
  /// In en, this message translates to:
  /// **'Therapy'**
  String get therapy;

  /// No description provided for @clinical_procedures.
  ///
  /// In en, this message translates to:
  /// **'Clinical Procedures'**
  String get clinical_procedures;

  /// No description provided for @household.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get household;

  /// No description provided for @electronics.
  ///
  /// In en, this message translates to:
  /// **'Electronics'**
  String get electronics;

  /// No description provided for @apparel.
  ///
  /// In en, this message translates to:
  /// **'Apparel'**
  String get apparel;

  /// No description provided for @pet_supplies.
  ///
  /// In en, this message translates to:
  /// **'Pet Supplies'**
  String get pet_supplies;

  /// No description provided for @food_retail.
  ///
  /// In en, this message translates to:
  /// **'Food Retail'**
  String get food_retail;

  /// No description provided for @fashion.
  ///
  /// In en, this message translates to:
  /// **'Fashion'**
  String get fashion;

  /// No description provided for @home_living.
  ///
  /// In en, this message translates to:
  /// **'Home & Living'**
  String get home_living;

  /// No description provided for @lifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get lifestyle;

  /// No description provided for @health_retail.
  ///
  /// In en, this message translates to:
  /// **'Health Retail'**
  String get health_retail;

  /// No description provided for @distribution.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distribution;

  /// No description provided for @international.
  ///
  /// In en, this message translates to:
  /// **'International'**
  String get international;

  /// No description provided for @intermediary.
  ///
  /// In en, this message translates to:
  /// **'Intermediary'**
  String get intermediary;

  /// No description provided for @home_services.
  ///
  /// In en, this message translates to:
  /// **'Home Services'**
  String get home_services;

  /// No description provided for @health_services.
  ///
  /// In en, this message translates to:
  /// **'Health Services'**
  String get health_services;

  /// No description provided for @construction.
  ///
  /// In en, this message translates to:
  /// **'Construction'**
  String get construction;

  /// No description provided for @hair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get hair;

  /// No description provided for @aesthetics.
  ///
  /// In en, this message translates to:
  /// **'Aesthetics'**
  String get aesthetics;

  /// No description provided for @nails.
  ///
  /// In en, this message translates to:
  /// **'Nails'**
  String get nails;

  /// No description provided for @skincare.
  ///
  /// In en, this message translates to:
  /// **'Skincare'**
  String get skincare;

  /// No description provided for @repair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get repair;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @moving.
  ///
  /// In en, this message translates to:
  /// **'Moving'**
  String get moving;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @accounting.
  ///
  /// In en, this message translates to:
  /// **'Accounting'**
  String get accounting;

  /// No description provided for @consulting.
  ///
  /// In en, this message translates to:
  /// **'Consulting'**
  String get consulting;

  /// No description provided for @institutions.
  ///
  /// In en, this message translates to:
  /// **'Institutions'**
  String get institutions;

  /// No description provided for @tutoring.
  ///
  /// In en, this message translates to:
  /// **'Tutoring'**
  String get tutoring;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @it_support.
  ///
  /// In en, this message translates to:
  /// **'IT Support'**
  String get it_support;

  /// No description provided for @development.
  ///
  /// In en, this message translates to:
  /// **'Development'**
  String get development;

  /// No description provided for @digital_marketing.
  ///
  /// In en, this message translates to:
  /// **'Digital Marketing'**
  String get digital_marketing;

  /// No description provided for @warehousing.
  ///
  /// In en, this message translates to:
  /// **'Warehousing'**
  String get warehousing;

  /// No description provided for @transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transport;

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @customs.
  ///
  /// In en, this message translates to:
  /// **'Customs'**
  String get customs;

  /// No description provided for @parts.
  ///
  /// In en, this message translates to:
  /// **'Parts'**
  String get parts;

  /// No description provided for @fluids.
  ///
  /// In en, this message translates to:
  /// **'Fluids'**
  String get fluids;

  /// No description provided for @sales.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get sales;

  /// No description provided for @seeds.
  ///
  /// In en, this message translates to:
  /// **'Seeds'**
  String get seeds;

  /// No description provided for @fertilizers.
  ///
  /// In en, this message translates to:
  /// **'Fertilizers'**
  String get fertilizers;

  /// No description provided for @equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get equipment;

  /// No description provided for @supply.
  ///
  /// In en, this message translates to:
  /// **'Supply'**
  String get supply;

  /// No description provided for @accommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get accommodation;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @banking.
  ///
  /// In en, this message translates to:
  /// **'Banking'**
  String get banking;

  /// No description provided for @pricingModeByProfit.
  ///
  /// In en, this message translates to:
  /// **'By Profit'**
  String get pricingModeByProfit;

  /// No description provided for @pricingModeByFinalPrice.
  ///
  /// In en, this message translates to:
  /// **'By Final Price'**
  String get pricingModeByFinalPrice;

  /// No description provided for @pricingAiPriceApplied.
  ///
  /// In en, this message translates to:
  /// **'AI price applied'**
  String get pricingAiPriceApplied;

  /// No description provided for @pricingAiSuggestedPrice.
  ///
  /// In en, this message translates to:
  /// **'AI Suggested Price'**
  String get pricingAiSuggestedPrice;

  /// No description provided for @pricingAiHigherDiff.
  ///
  /// In en, this message translates to:
  /// **'Your price is DZD {amount} higher'**
  String pricingAiHigherDiff(String amount);

  /// No description provided for @pricingAiLowerDiff.
  ///
  /// In en, this message translates to:
  /// **'Your price is DZD {amount} lower'**
  String pricingAiLowerDiff(String amount);

  /// No description provided for @pricingAiAcceptTooltip.
  ///
  /// In en, this message translates to:
  /// **'Use AI price'**
  String get pricingAiAcceptTooltip;

  /// No description provided for @pricingAiResetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset to AI price'**
  String get pricingAiResetTooltip;

  /// No description provided for @pricingBasePriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Base price'**
  String get pricingBasePriceLabel;

  /// No description provided for @pricingBasePriceHelper.
  ///
  /// In en, this message translates to:
  /// **'Cost before tax'**
  String get pricingBasePriceHelper;

  /// No description provided for @pricingTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get pricingTaxLabel;

  /// No description provided for @pricingTaxHelper.
  ///
  /// In en, this message translates to:
  /// **'Applied on base price'**
  String get pricingTaxHelper;

  /// No description provided for @pricingProfitLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit margin'**
  String get pricingProfitLabel;

  /// No description provided for @pricingProfitHelper.
  ///
  /// In en, this message translates to:
  /// **'Markup on price after tax'**
  String get pricingProfitHelper;

  /// No description provided for @pricingFinalPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Final price'**
  String get pricingFinalPriceLabel;

  /// No description provided for @pricingFinalPriceHelper.
  ///
  /// In en, this message translates to:
  /// **'What the customer pays'**
  String get pricingFinalPriceHelper;

  /// No description provided for @pricingBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'BREAKDOWN'**
  String get pricingBreakdownLabel;

  /// No description provided for @pricingPriceAfterTaxLabel.
  ///
  /// In en, this message translates to:
  /// **'Price after tax'**
  String get pricingPriceAfterTaxLabel;

  /// No description provided for @pricingProfitRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Profit ({percent}%)'**
  String pricingProfitRowLabel(String percent);

  /// No description provided for @selectProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Product'**
  String get selectProductTitle;

  /// No description provided for @searchProductsHint.
  ///
  /// In en, this message translates to:
  /// **'Search products…'**
  String get searchProductsHint;

  /// No description provided for @supplierProductsBadge.
  ///
  /// In en, this message translates to:
  /// **'Supplier Products'**
  String get supplierProductsBadge;

  /// No description provided for @noProductsFoundForQuery.
  ///
  /// In en, this message translates to:
  /// **'No products found for \"{query}\"'**
  String noProductsFoundForQuery(String query);

  /// No description provided for @stockLabel.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count}'**
  String stockLabel(String count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
