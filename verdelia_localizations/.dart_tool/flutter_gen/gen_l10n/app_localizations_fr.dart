import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Verdelia';

  @override
  String get welcomeMessage => 'Bienvenue sur Verdelia !';

  @override
  String get errorOccurred => 'Une erreur s\'est produite. Veuillez réessayer plus tard.';

  @override
  String get noProductsFound => 'Aucun produit à afficher.';

  @override
  String get addToCart => 'Ajouter';

  @override
  String get aboutProvider => 'À propos';

  @override
  String get productQuantity => 'Quantité';

  @override
  String get productReference => 'Référence';

  @override
  String get priceText => 'Prix';

  @override
  String get noAppUsersFound => 'Aucun utilisateur trouvé';

  @override
  String get successfullLoginMsg => 'Inscription réussie.';

  @override
  String get welcomeBackMsg => 'Bon retour !';

  @override
  String get loginText => 'Connexion';

  @override
  String get pleaseLoginMsg => 'Veuillez vous connecter à votre compte';

  @override
  String get pleaseInputUsernameMsg => 'Veuillez saisir votre nom d\'utilisateur';

  @override
  String get pleaseInputPasswordMsg => 'Veuillez saisir votre mot de passe';

  @override
  String get passwordLengthConstraintMsg => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get suggestRegistrationMsg => 'Vous n\'avez pas de compte ? Inscrivez-vous';

  @override
  String get suggest3rdPartyLogintMsg => 'Ou connectez-vous avec';

  @override
  String get pleaseInputusernameMsg => 'Veuillez saisir un nom d\'utilisateur';

  @override
  String get pleaseInputpasswordMsg => 'Veuillez saisir un mot de passe';

  @override
  String get pleaseInputUserTypeMsg => 'Veuillez sélectionner un type d\'utilisateur';

  @override
  String get pleaseInputFirstNameMsg => 'Veuillez saisir un prénom';

  @override
  String get pleaseInputLastNameMsg => 'Veuillez saisir un nom de famille';

  @override
  String get pleaseInputBirthdateMsg => 'Veuillez sélectionner votre date de naissance';

  @override
  String get pleaseInputLocationNameMsg => 'Veuillez saisir le nom du lieu';

  @override
  String get pleaseInputgenderMsg => 'Veuillez sélectionner un genre';

  @override
  String get pleaseInputnationalityMsg => 'Veuillez sélectionner une nationalité';

  @override
  String get pleaseInputBloodTypeMsg => 'Veuillez sélectionner un groupe sanguin';

  @override
  String get pleaseInputCountryMsg => 'Veuillez sélectionner un pays';

  @override
  String get birthdayText => 'Date de naissance';

  @override
  String get loginSuccessfullMsg => 'Inscription réussie.';

  @override
  String get registerText => 'S\'inscrire';

  @override
  String get registerationFormText => 'Formulaire d\'inscription';

  @override
  String get usernameText => 'Nom d\'utilisateur';

  @override
  String get passwordText => 'Mot de passe';

  @override
  String get userTypeText => 'Type d\'utilisateur';

  @override
  String get firstNameText => 'Prénom';

  @override
  String get lastNameText => 'Nom de famille';

  @override
  String get genderText => 'Genre';

  @override
  String get nationalityText => 'Nationalité';

  @override
  String get bloodTypeText => 'Groupe sanguin';

  @override
  String get latitudeText => 'Latitude';

  @override
  String get longitudeText => 'Longitude';

  @override
  String get locationNameText => 'Nom du lieu';

  @override
  String get locationText => 'Emplacement';

  @override
  String get myLocationText => 'Ma position';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String get mapNotAvailableText => 'Carte non disponible sur cet appareil';

  @override
  String get pdfNotSupportedOnWeb => 'Les fichiers PDF ne sont pas pris en charge sur le web. Veuillez utiliser un appareil mobile.';

  @override
  String get registrationConditionsText => 'Conditions d\'inscription';

  @override
  String get streetText => 'Rue';

  @override
  String get cityText => 'Ville';

  @override
  String get postalCodeText => 'Code postal';

  @override
  String get countryText => 'Pays';

  @override
  String get clientText => 'Client';

  @override
  String get genderTextList => 'Homme,Femme,Autre';

  @override
  String get nationalityTextList => 'Algérienne,Autre';

  @override
  String get missingText => 'Manquant';

  @override
  String get productdeletionConfirmationMessage => 'Êtes-vous sûr de vouloir supprimer ce produit ?';

  @override
  String get cartAddConfirmationMessage => 'Confirmer l\'ajout au panier';

  @override
  String get updateProductText => 'Mettre à jour le produit';

  @override
  String get pleaseInputProductNameMsg => 'Veuillez saisir un nom de produit';

  @override
  String get pleaseInputProductPriceMsg => 'Veuillez saisir un prix de produit';

  @override
  String get pleaseInputProductBrandMsg => 'Veuillez saisir une marque de produit';

  @override
  String get pleaseInputProductBarcodeMsg => 'Veuillez saisir un code-barres de produit';

  @override
  String get pleaseInputvalidnumberMsg => 'Veuillez saisir un nombre valide';

  @override
  String get pleaseInputProductDescriptionMsg => 'Veuillez saisir une description de produit';

  @override
  String get pleaseInputProductQuantityMsg => 'Veuillez saisir une quantité de produit';

  @override
  String get instructionsText => 'Instructions';

  @override
  String get numberConstraintMsg => 'Veuillez saisir un nombre entre 0 et 999999';

  @override
  String get productQuantityText => 'Quantité du produit';

  @override
  String get productDescriptionText => 'Description du produit';

  @override
  String get descriptionCharacterConstraintMsg => 'Limite de caractères : 300.';

  @override
  String get pickImageMsg => 'Choisir une image';

  @override
  String get submitText => 'Soumettre';

  @override
  String get productNameTxt => 'Nom du produit';

  @override
  String get productBrandTxt => 'Marque du produit';

  @override
  String get productBarcodeTxt => 'Code-barres du produit';

  @override
  String get productPriceTxt => 'Prix du produit';

  @override
  String get categoriesNotFoundTxt => 'Catégories introuvables';

  @override
  String get noImageSelectedTxt => 'Aucune image sélectionnée';

  @override
  String get addProductTxt => 'Ajouter';

  @override
  String get orderNowTxt => 'Commander maintenant';

  @override
  String get subtotalTxt => 'Sous-total';

  @override
  String get totalTxt => 'Total';

  @override
  String get confirmOrderTxt => 'Confirmer la commande';

  @override
  String get searchTxt => 'Rechercher';

  @override
  String get emptyCartTxt => 'Votre panier est vide !';

  @override
  String get taxTxt => 'Taxe';

  @override
  String get discountText => 'Remise';

  @override
  String get cancelTxt => 'Annuler';

  @override
  String get confirmTxt => 'Confirmer';

  @override
  String get confirmationTxt => 'confirmation';

  @override
  String get addSupplierTxt => 'Ajouter un fournisseur';

  @override
  String get addBusinessNameMsg => 'Veuillez saisir un nom d\'entreprise';

  @override
  String get supplierNameMsg => 'Nom du fournisseur';

  @override
  String get insertCoordinatesMsg => 'Insérer les coordonnées';

  @override
  String get addContactInfoMsg => 'Ajouter des informations de contact';

  @override
  String get contactInfoMsg => 'Informations de contact';

  @override
  String get pleaseInputContactInfoMsg => 'Veuillez saisir les informations de contact';

  @override
  String get latitudeMsg => 'Latitude';

  @override
  String get longitudeMsg => 'Longitude';

  @override
  String get setLocationMsg => 'Définir l\'emplacement';

  @override
  String get addIngredientMsg => 'Ajouter un ingrédient';

  @override
  String get deleteSuccess => 'Élément supprimé avec succès';

  @override
  String get putSuccess => 'Élément ajouté avec succès';

  @override
  String get updateSuccess => 'Élément mis à jour avec succès';

  @override
  String get serverError => 'Échec de la connexion au serveur';

  @override
  String get notFoundError => 'Objet introuvable';

  @override
  String get deleteFailure => 'Échec de la suppression de l\'élément de stockage';

  @override
  String get getFailure => 'Échec du chargement de l\'élément';

  @override
  String get putFailure => 'Échec de l\'ajout de l\'élément';

  @override
  String get updateFailure => 'Échec de la mise à jour de l\'élément';

  @override
  String price(String price) {
    return '$price DA';
  }

  @override
  String get ingredientSelect => 'Sélectionner un ingrédient';

  @override
  String get ingredientSearch => 'Rechercher un ingrédient';

  @override
  String get ingredientQuantity => 'Saisir la quantité';

  @override
  String get addText => 'Ajouter';

  @override
  String hoursTextValue(int hours) {
    return '$hours heures';
  }

  @override
  String minutesTextValue(int minutes) {
    return '$minutes minutes.';
  }

  @override
  String preparationTimeText(int hours, int minutes) {
    return 'Temps de préparation : $hours heures, $minutes minutes';
  }

  @override
  String get noDescriptionAvailableText => 'Aucune description disponible.';

  @override
  String get noInstructionsAvailableText => 'Aucune instruction disponible.';

  @override
  String get noPreparationTimeText => 'Aucun temps de préparation disponible.';

  @override
  String get productsText => 'Produits';

  @override
  String get providersText => 'Fournisseurs';

  @override
  String get gamesText => 'Jeux';

  @override
  String get selectLanguageText => 'Choisir la langue';

  @override
  String get profileText => 'Profil';

  @override
  String get userInfoText => 'Informations utilisateur';

  @override
  String get personalInfoText => 'Informations personnelles';

  @override
  String get locationInfoText => 'Informations de localisation';

  @override
  String orderAmountText(String amount) {
    return 'Montant : $amount';
  }

  @override
  String get productCategoryTextList => 'Produits de boulangerie,Pâtes à tartiner,Céréales,Pâtes,Snacks,Boissons,Desserts,Aliments surgelés,Ingrédients de boulangerie,Produits emballés';

  @override
  String get allText => 'Tout';

  @override
  String get providerCategoryTextList => 'Restaurant,Boulangerie,Usine,Supermarché,Épicerie,Distributeur';

  @override
  String get ingredientTextList => 'Blé,Orge,Seigle,Avoine,Maïs,Riz,Soja,Lait,Œuf,Arachides,Fruits à coque,Poisson,Crustacés,Lentilles,Pois chiches,Sarrasin,Amande,Noix de coco,Graines de tournesol,Graines de courge,Graines de sésame,Pomme de terre,Patate douce,Gélatine,Lupin,Moutarde,Fenouil,Cumin,Gingembre,Ail,Oignon,Poireau,Échalote,Ciboule,Ciboulette,Persil,Coriandre,Basilic,Origan,Thym,Romarin,Sauge,Menthe,Citronnelle,Lavande,Paprika,Piment fort,Poivre noir,Poivre blanc,Poivre vert,Poivre rouge,Cannelle,Quatre-épices,Beurre,Margarine,Huile végétale,Levure chimique,Bicarbonate de soude,Fécule de maïs,Farine tout usage,Farine à pâtisserie,Farine auto-levante';

  @override
  String get cartText => 'Panier';

  @override
  String get ordersText => 'Commandes';

  @override
  String get noOrdersTxt => 'Aucune commande pour le moment.';

  @override
  String orderIdentifierTxt(String orderId) {
    return 'Identifiant : $orderId';
  }

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get languageText => 'Langue';

  @override
  String currentLanguage(String currentLang) {
    return 'Langue actuelle : $currentLang';
  }

  @override
  String get darkModeText => 'Activer le mode sombre';

  @override
  String get profileUpdateText => 'Mettre à jour les informations du profil';

  @override
  String get passwordUpdateText => 'Mettre à jour le mot de passe';

  @override
  String get showMoreText => 'Afficher plus';

  @override
  String get copiedToClipboardText => 'Copié dans le presse-papiers';

  @override
  String get tapForDetailsText => 'Appuyez pour les détails';

  @override
  String get orText => 'ou';

  @override
  String get noAccountText => 'Vous n\'avez pas de compte ?';

  @override
  String get forgotPasswordText => 'Mot de passe oublié ?';

  @override
  String get heightText => 'Hauteur';

  @override
  String get widthText => 'Largeur';

  @override
  String get imageProcessingErrorText => 'Erreur de traitement de l\'image';

  @override
  String get accountText => 'Compte';

  @override
  String get appearanceText => 'Apparence';

  @override
  String get aboutAppTab => 'À propos de l\'application';

  @override
  String get featuresTitle => 'Fonctionnalités clés';

  @override
  String get feature1 => '🛒 **Boutique en ligne sans gluten** - Achetez en toute confiance des produits certifiés sans gluten avec livraison directe.';

  @override
  String get feature2 => '🎮 **Mini-jeux éducatifs** - Apprenez à identifier les aliments sûrs de manière ludique avec nos jeux interactifs.';

  @override
  String get feature4 => '📍 **Annuaire des commerces locaux** - Trouvez des épiceries et restaurants certifiés sans gluten près de chez vous.';

  @override
  String get contactUsTitle => 'Contactez-nous';

  @override
  String get contactEmail => 'verdelia.team@gmail.com';

  @override
  String get contactPhone => '+213-XXX-XXX-XXX';

  @override
  String get illnessOverviewContent => 'La maladie cœliaque est un trouble auto-immun où l\'ingestion de gluten endommage l\'intestin grêle. Elle peut causer des problèmes digestifs, des carences nutritionnelles et d\'autres complications. L\'éviction stricte et à vie du gluten est le seul traitement efficace.';

  @override
  String get symptom1 => '💨 **Troubles digestifs** - Ballonnements, diarrhée, constipation, nausées et vomissements.';

  @override
  String get symptom2 => '⚡ **Fatigue chronique** - Causée par la malabsorption des nutriments essentiels.';

  @override
  String get symptom3 => '🦴 **Complications osseuses** - Risque accru d\'ostéoporose dû à une mauvaise absorption du calcium et de la vitamine D.';

  @override
  String get treatmentContent => 'Le traitement nécessite un régime strict sans gluten à vie. Les patients doivent éviter le blé, l\'orge, le seigle et leurs dérivés. Le soutien nutritionnel et des outils comme Verdelia aident à prévenir l\'exposition accidentelle.';

  @override
  String get resource1 => '📖 **Fondation pour la maladie cœliaque** - [www.celiac.org](https://www.celiac.org)';

  @override
  String get resource2 => '📱 **Guide d\'achat interactif** - Fonctionnalité intégrée à l\'application pour scanner les listes d\'ingrédients suspectes.';

  @override
  String get resource3 => '👩‍⚕️ **Annuaire des spécialistes** - Trouvez des gastro-entérologues et nutritionnistes spécialisés dans la maladie cœliaque près de chez vous.';

  @override
  String get resourcesTitle => 'Ressources utiles';

  @override
  String get userCredentialsText => 'Vos identifiants de connexion comprennent votre nom d\'utilisateur et votre mot de passe. Assurez-vous de les garder en sécurité et de ne les partager avec personne.';

  @override
  String get processingRequest => 'Traitement de votre demande...';

  @override
  String get save => 'Enregistrer';

  @override
  String get basicInformation => 'Informations de base';

  @override
  String get locationInformation => 'Informations de localisation';

  @override
  String get contactInformation => 'Informations de contact';

  @override
  String get saveSupplier => 'Enregistrer le fournisseur';

  @override
  String get healthText => 'Santé';

  @override
  String get illnessOverviewTitle => 'Qu\'est-ce que la maladie cœliaque ?';

  @override
  String get symptomsTitle => 'Symptômes courants';

  @override
  String get illnessInfoTab => 'Informations';

  @override
  String get appPurposeTitle => 'Mission';

  @override
  String get treatmentTitle => 'Traitement et gestion';

  @override
  String get internal_server_error => 'Erreur interne du serveur. Veuillez réessayer plus tard.';

  @override
  String get http_exception => 'Échec de la requête HTTP. Vérifiez votre connexion.';

  @override
  String get integrity_error => 'Violation de l\'intégrité des données. L\'opération ne peut pas être effectuée.';

  @override
  String get data_error => 'Format de données invalide. Veuillez vérifier votre saisie.';

  @override
  String get operational_error => 'Une erreur opérationnelle s\'est produite. Contactez le support si le problème persiste.';

  @override
  String get programming_error => 'Une erreur de programmation s\'est produite. Les développeurs ont été notifiés.';

  @override
  String get database_error => 'Échec de l\'opération de base de données. Réessayez ou contactez le support.';

  @override
  String get internal_error => 'Une erreur système interne s\'est produite.';

  @override
  String get interface_error => 'Échec de la communication avec l\'interface. Vérifiez les configurations.';

  @override
  String get statement_error => 'Instruction SQL invalide. Erreur de syntaxe ou de logique détectée.';

  @override
  String get incorrect_credentials => 'Nom d\'utilisateur ou mot de passe incorrect';

  @override
  String get sqlalchemy_error => 'Erreur de base de données SQLAlchemy. Vérifiez la requête ou la connexion.';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get passwordChangeTitle => 'Créer un nouveau mot de passe';

  @override
  String get passwordChangeSubtitle => 'Votre nouveau mot de passe doit être différent des mots de passe précédents';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get currentPasswordHint => 'Saisissez votre mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get newPasswordHint => 'Saisissez votre nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get confirmPasswordHint => 'Saisissez à nouveau votre nouveau mot de passe';

  @override
  String get changePasswordButton => 'Changer le mot de passe';

  @override
  String get passwordRequirements => 'Le mot de passe doit contenir :';

  @override
  String get passwordLengthRequirement => 'Au moins 8 caractères';

  @override
  String get passwordUppercaseRequirement => 'Au moins 1 lettre majuscule';

  @override
  String get passwordNumberRequirement => 'Au moins 1 chiffre';

  @override
  String get passwordChangeSuccess => 'Mot de passe changé avec succès !';

  @override
  String get weakPassword => 'Mot de passe faible';

  @override
  String get mediumPassword => 'Force moyenne';

  @override
  String get strongPassword => 'Mot de passe fort';

  @override
  String get categoryText => 'Catégorie';

  @override
  String get currentPasswordRequired => 'Le mot de passe actuel est requis';

  @override
  String get passwordTooShort => 'Le mot de passe doit contenir au moins 8 caractères';

  @override
  String get newPasswordRequired => 'Le nouveau mot de passe est requis';

  @override
  String get passwordUppercaseError => 'Doit contenir au moins une lettre majuscule';

  @override
  String get passwordNumberError => 'Doit contenir au moins un chiffre';

  @override
  String get passwordSameAsCurrent => 'Le nouveau mot de passe doit être différent du mot de passe actuel';

  @override
  String get confirmPasswordRequired => 'Veuillez confirmer votre nouveau mot de passe';

  @override
  String get passwordsDontMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get changePhotoText => 'Changer la photo de profil';

  @override
  String get fieldRequired => 'Champ obligatoire';

  @override
  String get profileUpdateSuccess => 'Profil mis à jour avec succès';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get personalInformation => 'Informations personnelles';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get accountInformation => 'Informations du compte';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get logoutText => 'Déconnexion';

  @override
  String get continueAsGuestText => 'Continuer en tant qu\'invité';

  @override
  String get ingredientText => 'Ingrédients';

  @override
  String get termsTitle => 'Conditions générales';

  @override
  String get termsContent => 'En utilisant cette application, vous acceptez de :';

  @override
  String get termsPoint1 => 'Utiliser l\'application uniquement à des fins personnelles';

  @override
  String get guideTitle => 'Guide d\'utilisation';

  @override
  String get guideStep1 => 'Créez votre profil pour enregistrer vos préférences';

  @override
  String get guideStep3 => 'Ajoutez des favoris pour un accès rapide';

  @override
  String get disclaimerTitle => 'Avertissement important';

  @override
  String get versionText => 'Version de l\'application';

  @override
  String get providedBy => 'Fourni par';

  @override
  String get unknownProvider => 'Fournisseur inconnu';

  @override
  String get callProvider => 'Appeler le fournisseur';

  @override
  String get emailProvider => 'Envoyer un e-mail au fournisseur';

  @override
  String get viewOnMap => 'Voir sur la carte';

  @override
  String get providerContactOptions => 'Options de contact';

  @override
  String get supplierText => 'Fournisseur';

  @override
  String get legalDocumentsTitle => 'Documents juridiques';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfUse => 'Conditions d\'utilisation';

  @override
  String get close => 'Fermer';

  @override
  String get termsAgreementText => 'J\'accepte les conditions d\'utilisation régissant mon utilisation de Verdelia';

  @override
  String get privacyAgreementText => 'J\'accepte la manière dont Verdelia collecte et traite mes données';

  @override
  String get readFullDocument => 'Lire le document complet';

  @override
  String get acceptAllTermsError => 'Vous devez accepter les deux documents pour continuer';

  @override
  String get outOfStock => 'En rupture de stock';

  @override
  String availableText(String amount) {
    return '$amount disponible(s)';
  }

  @override
  String get ingredientUnits => 'Gramme,Kilogramme,Milligramme,Livre,Once,Millilitre,Litre,Tasse,Cuillère à soupe,Cuillère à café,Pincée';

  @override
  String get unitText => 'Unité';

  @override
  String get amountText => 'Quantité';

  @override
  String otherProductsFromSupplier(String supplier_name) {
    return 'Également de : $supplier_name';
  }

  @override
  String productsFromSupplier(String supplier_name) {
    return 'Fourni par : $supplier_name';
  }

  @override
  String similarProductsFromCategory(String category_name) {
    return 'Produits de : $category_name';
  }

  @override
  String get noOtherProductsAvailable => 'Aucun produit disponible de ce fournisseur.';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Appareil photo';

  @override
  String get imagePickFailed => 'Échec de la sélection de l\'image';

  @override
  String get changeImage => 'Changer l\'image';

  @override
  String get selectImage => 'Sélectionner une image';

  @override
  String get uploadImage => 'Télécharger une image';

  @override
  String get removeImage => 'Supprimer l\'image';

  @override
  String get noImageSelected => 'Aucune image sélectionnée';

  @override
  String get searchSuppliersText => 'Rechercher des fournisseurs...';

  @override
  String get confirm => 'Confirmer';

  @override
  String get selectOrganisationHintText => 'Veuillez sélectionner une organisation';

  @override
  String get providerImage => 'Image du fournisseur';

  @override
  String get selectOrganisation => 'Sélectionner une organisation';

  @override
  String get searchOrganisations => 'Rechercher des organisations';

  @override
  String get noOrganisationsFound => 'Aucune organisation trouvée';

  @override
  String get createNew => 'Créer';

  @override
  String get organisationText => 'Organisation';

  @override
  String by_organisation(String org_name) {
    return 'Par $org_name';
  }

  @override
  String get no_location_information_available => 'Aucune information disponible sur la localisation';

  @override
  String get orderFor => 'Commander pour';

  @override
  String get missingProductName => 'Nom du produit manquant';

  @override
  String amountTxtDisplay(String amount, String quantifier) {
    return '$amount $quantifier';
  }

  @override
  String get quantifier_g => 'g';

  @override
  String get quantifier_kg => 'kg';

  @override
  String get quantifier_mg => 'mg';

  @override
  String get quantifier_L => 'L';

  @override
  String get quantifier_mL => 'mL';

  @override
  String get quantifier_pc => 'pièce';

  @override
  String get quantifier_pkg => 'paquet';

  @override
  String get quantifier_box => 'boîte';

  @override
  String get quantifier_bag => 'sac';

  @override
  String get quantifier_slice => 'tranche';

  @override
  String get quantifier_cup => 'tasse';

  @override
  String order_number(String n) {
    return 'Numéro de commande : $n';
  }

  @override
  String get orderItemsTxt => 'Articles de la commande';

  @override
  String get dateTimeNotAvailable => 'Date non disponible';

  @override
  String dateTimeFormat(int day, int month, int year, String hour, String min) {
    return '$day/$month/$year $hour:$min';
  }

  @override
  String dateFormat(int day, int month, int year) {
    return '$day/$month/$year';
  }

  @override
  String get completedTxt => 'Terminée';

  @override
  String get deliveredTxt => 'Livrée';

  @override
  String get pendingTxt => 'En attente';

  @override
  String get cancelledTxt => 'Annulée';

  @override
  String get processingTxt => 'En cours de traitement';

  @override
  String get unknownTxt => 'Inconnu';

  @override
  String get spentTxt => 'Dépensé';

  @override
  String qtyTxt(int quantity, String price) {
    return 'Qté : $quantity × $price';
  }

  @override
  String get loadingOrders => 'Chargement...';

  @override
  String get loadingOrderDetails => 'Chargement des détails de la commande...';

  @override
  String get failedToLoadDetails => 'Échec du chargement des détails';

  @override
  String get yourOrdersWillAppearHere => 'Vos commandes apparaîtront ici';

  @override
  String get refreshTxt => 'Actualiser';

  @override
  String get yourOrderStats => 'Vos statistiques de commandes';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get uploadingImage => 'Téléchargement...';

  @override
  String get laterText => 'Plus tard';

  @override
  String get failedAuthAfterSignIn => 'Échec de l\'authentification après la connexion.';

  @override
  String get loginTimeoutMsg => 'Délai de connexion expiré. Veuillez réessayer.';

  @override
  String get failedLogin => 'Échec de la connexion. Vérifiez vos identifiants.';

  @override
  String get signInWithText => 'Se connecter avec';

  @override
  String get google => 'Google';

  @override
  String get loggingOutText => 'Déconnexion...';

  @override
  String get logoutConsentText => 'Êtes-vous sûr de vouloir vous déconnecter ?';

  @override
  String get scanBarcode => 'Scanner le code-barres';

  @override
  String get alignBarcode => 'Alignez le code-barres dans le cadre';

  @override
  String get positionBarcode => 'Positionnez le code-barres dans la zone de scan pour une détection automatique';

  @override
  String get barcodeScanSuccess => 'Code-barres scanné avec succès !';

  @override
  String get initCam => 'Initialisation de la caméra...';

  @override
  String get captureProduct => 'Capturer le produit';

  @override
  String get positionProductInFrame => 'Positionnez le produit dans le cadre';

  @override
  String get scanHint => 'Assurez un bon éclairage et une mise au point nette';

  @override
  String get tapHint => 'Appuyez pour capturer';

  @override
  String get reviewPhoto => 'Vérifier la photo';

  @override
  String get croppedToFrame => 'Recadré au cadre';

  @override
  String get usePhoto => 'Utiliser cette photo';

  @override
  String get takeAgain => 'Reprendre';

  @override
  String get processingImage => 'Traitement de l\'image...';

  @override
  String get waitText => 'Cela peut prendre quelques secondes';

  @override
  String get aiAnalysing => 'L\'IA analyse votre produit...';

  @override
  String get aiAssistantSubtitle => 'Remplir automatiquement les détails du produit';

  @override
  String get aiAssistantTitle => 'Assistant produit IA';

  @override
  String get productDetailsFilled => 'Détails du produit remplis automatiquement !';

  @override
  String get scanQR => 'Scanner le code QR';

  @override
  String get scannerHint => 'Positionnez le code QR dans le cadre';

  @override
  String get alignQR => 'Alignez le code QR dans la zone de scan pour une détection automatique';

  @override
  String get manualInput => 'Saisie manuelle';

  @override
  String get qrSuccess => 'Code QR scanné avec succès !';

  @override
  String get manualQR => 'Saisir le code QR manuellement';

  @override
  String get manualQRHint => 'Collez ou saisissez le contenu du code QR...';

  @override
  String get scannerTxt => 'Scanner';

  @override
  String get takeProductPhoto => 'Prendre une photo du produit';

  @override
  String get aiWillAnalyseImage => 'L\'IA analysera l\'image du produit';

  @override
  String get automaticallyFillDetailsFromBarcode => 'Remplir automatiquement les détails à partir du code-barres';

  @override
  String get aiGenerated => 'Généré par IA';

  @override
  String get databaseFetched => 'Récupéré de la base de données';

  @override
  String get userInput => 'Fourni par l\'utilisateur';

  @override
  String get notificationOrderReceivedTitle => 'Commande reçue ! 🎉';

  @override
  String get notificationRoleInvitationTitle => 'Invitation d\'équipe';

  @override
  String get notificationProductUpdatedTitle => 'Produit mis à jour';

  @override
  String get notificationDefaultTitle => 'Notification';

  @override
  String get notificationOrderReceivedSubtitle => 'Prête à être traitée';

  @override
  String get notificationProductUpdatedSubtitle => 'Nouvelles modifications disponibles';

  @override
  String get notificationOrderReceivedMessage => 'Votre commande a été reçue avec succès et est en cours de traitement. Vous pouvez suivre son statut dans vos commandes.';

  @override
  String notificationRoleInvitationMessage(String ruleName, String ruleType) {
    return 'Vous avez été invité à rejoindre « $ruleName » en tant que $ruleType. Acceptez pour commencer !';
  }

  @override
  String get notificationRoleInvitationDefaultMessage => 'Vous avez été invité à rejoindre une équipe.';

  @override
  String get notificationProductUpdatedMessage => 'Un produit que vous suivez a été mis à jour avec de nouvelles fonctionnalités et améliorations. Découvrez-le !';

  @override
  String get notificationDefaultMessage => 'Vous avez une nouvelle notification';

  @override
  String get timeJustNow => 'À l\'instant';

  @override
  String timeMinutesAgo(int minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String timeMinutesAgoPlural(int minutes) {
    return 'Il y a $minutes mins';
  }

  @override
  String timeHoursAgo(int hours) {
    return 'Il y a $hours h';
  }

  @override
  String timeHoursAgoPlural(int hours) {
    return 'Il y a $hours hrs';
  }

  @override
  String timeDaysAgo(int days) {
    return 'Il y a $days jour';
  }

  @override
  String timeDaysAgoPlural(int days) {
    return 'Il y a $days jours';
  }

  @override
  String timeWeeksAgo(int weeks) {
    return 'Il y a $weeks semaine';
  }

  @override
  String timeWeeksAgoPlural(int weeks) {
    return 'Il y a $weeks semaines';
  }

  @override
  String timeDate(int day, int month, int year) {
    return '$day/$month/$year';
  }

  @override
  String get actionTrackOrder => 'Suivre la commande';

  @override
  String get actionDownloadInvoice => 'Télécharger la facture';

  @override
  String get actionAccept => 'Accepter';

  @override
  String get actionDecline => 'Refuser';

  @override
  String get actionViewTeam => 'Voir l\'équipe';

  @override
  String get actionSeeChanges => 'Voir les modifications';

  @override
  String get actionUpdateNow => 'Mettre à jour maintenant';

  @override
  String get actionViewDetails => 'Voir les détails';

  @override
  String get status_pending => 'En attente';

  @override
  String get status_rejected => 'Refusé';

  @override
  String get status_suspended => 'Suspendu';

  @override
  String get status_obsolete => 'Obsolète';

  @override
  String get status_active => 'Actif';

  @override
  String get status_inactive => 'Inactif';

  @override
  String get inventory_view_title => 'Voir l\'inventaire';

  @override
  String get inventory_view_description => 'Peut consulter les niveaux de stock actuels';

  @override
  String get inventory_manage_title => 'Gérer l\'inventaire';

  @override
  String get inventory_manage_description => 'Peut mettre à jour les niveaux de stock et gérer les produits';

  @override
  String get orders_view_title => 'Voir les commandes';

  @override
  String get orders_view_description => 'Peut consulter les commandes clients et fournisseurs';

  @override
  String get orders_manage_title => 'Gérer les commandes';

  @override
  String get orders_manage_description => 'Peut créer, modifier et traiter les commandes';

  @override
  String get personnel_view_title => 'Voir l\'équipe';

  @override
  String get personnel_view_description => 'Peut consulter les autres membres de l\'équipe';

  @override
  String get personnel_manage_title => 'Gérer l\'équipe';

  @override
  String get personnel_manage_description => 'Peut ajouter/supprimer des membres et définir les permissions';

  @override
  String get manage_permissions => 'Gérer les permissions';

  @override
  String get save_permissions => 'Enregistrer les permissions';

  @override
  String get no_username => 'Aucun nom d\'utilisateur';

  @override
  String get category_inventory => 'Gestion de l\'inventaire';

  @override
  String get category_orders => 'Gestion des commandes';

  @override
  String get category_personnel => 'Gestion du personnel';

  @override
  String get roleStaff => 'Employé';

  @override
  String get roleAdmin => 'Administrateur';

  @override
  String get roleManager => 'Gestionnaire';

  @override
  String get roleSupervisor => 'Superviseur';

  @override
  String get roleViewer => 'Observateur';

  @override
  String get roleNoPrivileges => 'Aucun privilège';

  @override
  String get actionManagePermissions => 'Permissions';

  @override
  String get actionNotify => 'Notifier';

  @override
  String get pendingInvitationMessage => 'Cet utilisateur a une invitation en attente.';

  @override
  String get actionResendInvite => 'Renvoyer l\'invitation';

  @override
  String get actionCancelInvite => 'Annuler l\'invitation';

  @override
  String suppliersCountCategoryCount(int totalSuppliers, int categoryCount) {
    String _temp0 = intl.Intl.pluralLogic(
      totalSuppliers,
      locale: localeName,
      other: '$totalSuppliers emplacements',
      one: '1 emplacement',
      zero: 'Aucun emplacement',
    );
    String _temp1 = intl.Intl.pluralLogic(
      categoryCount,
      locale: localeName,
      other: '$categoryCount dans la catégorie',
      one: '1 dans la catégorie',
      zero: 'aucune catégorie',
    );
    return '$_temp0 • $_temp1';
  }

  @override
  String get myBusinessesTitle => 'Mes entreprises';

  @override
  String get categories => 'Catégories';

  @override
  String get filteredTxt => 'Filtré';

  @override
  String get noBusinessesFound => 'Aucune entreprise trouvée';

  @override
  String get adjustFilterBusinessHint => 'Essayez d\'ajuster votre recherche ou vos filtres';

  @override
  String get addFirstBusinessHint => 'Ajoutez votre première entreprise pour commencer';

  @override
  String get addMemberText => 'Ajouter un membre';

  @override
  String get addTeamMemberText => 'Ajouter un membre d\'équipe';

  @override
  String addUsersToManageText(String supplierName) {
    return 'Ajouter des utilisateurs pour gérer $supplierName';
  }

  @override
  String get scanQrCodeText => 'Scanner le code QR';

  @override
  String get scanUserProfileQrText => 'Scanner le code QR du profil utilisateur';

  @override
  String get searchAndInviteText => 'Rechercher et inviter';

  @override
  String get searchAndInviteExistingUsersText => 'Rechercher et inviter des utilisateurs existants';

  @override
  String get cancelText => 'Annuler';

  @override
  String get cancelInvitationTitle => 'Annuler l\'invitation';

  @override
  String get cancelInvitationMessage => 'Annuler l\'invitation ? Cette action est irréversible.';

  @override
  String get cancelInvitationAction => 'Annuler l\'invitation';

  @override
  String get removeTeamMemberTitle => 'Supprimer un membre d\'équipe';

  @override
  String removeTeamMemberMessage(String userName, String supplierName) {
    return 'Supprimer $userName de $supplierName ?';
  }

  @override
  String get removeAction => 'Supprimer';

  @override
  String get personnelManagement => 'Gestion du personnel';

  @override
  String privilegesUpdatedMessage(String userName) {
    return 'Privilèges mis à jour pour $userName';
  }

  @override
  String get privilegesUpdateFailedMessage => 'Échec de la mise à jour des privilèges';

  @override
  String get privilegesUpdateError => 'Une erreur s\'est produite lors de la mise à jour des privilèges';

  @override
  String get barcodeText => 'Code-barres';

  @override
  String get barcodeCopiedText => 'Code-barres copié dans le presse-papiers';

  @override
  String get sourceText => 'Source';

  @override
  String get modelText => 'Modèle';

  @override
  String get recentText => 'Récent';

  @override
  String get productDetailsText => 'Détails du produit';

  @override
  String get createdText => 'Créé';

  @override
  String get lastUpdatedText => 'Dernière mise à jour';

  @override
  String get priceUpdatedText => 'Prix mis à jour';

  @override
  String get noProductDataTitle => 'Produit introuvable';

  @override
  String get noProductDataDescription => 'Aucune information produit trouvée pour ce code-barres. Le produit est peut-être nouveau ou pas encore dans notre base de données.';

  @override
  String get noProductDataHelp => 'Vous pouvez réessayer le scan ou ajouter manuellement les détails du produit.';

  @override
  String get scanAgainText => 'Scanner à nouveau';

  @override
  String get addManuallyText => 'Ajouter le produit manuellement';

  @override
  String get ownedText => 'Possédé';

  @override
  String get managedText => 'Géré';

  @override
  String get noOwnedBusinessesTitle => 'Aucune entreprise possédée';

  @override
  String get noOwnedBusinessesDescription => 'Vous ne possédez encore aucune entreprise';

  @override
  String get noManagedBusinessesTitle => 'Aucune entreprise gérée';

  @override
  String get noManagedBusinessesDescription => 'Vous ne gérez aucune entreprise';

  @override
  String get noBusinessesTitle => 'Aucune entreprise';

  @override
  String get noBusinessesDescription => 'Vous ne possédez ni ne gérez encore d\'entreprise';

  @override
  String get noResultsTitle => 'Aucun résultat';

  @override
  String get adjustSearchFiltersText => 'Essayez d\'ajuster votre recherche ou vos filtres';

  @override
  String get orderManagement => 'Gestion des commandes';

  @override
  String get processing => 'En cours';

  @override
  String get completed => 'Terminée';

  @override
  String get selectSupplier => 'Sélectionner un fournisseur';

  @override
  String get noOrderManagementPrivileges => 'Aucun privilège de gestion des commandes';

  @override
  String get orderDetails => 'Détails de la commande';

  @override
  String get noPendingOrders => 'Aucune commande en attente';

  @override
  String get noProcessingOrders => 'Aucune commande en cours';

  @override
  String get noCompletedOrders => 'Aucune commande terminée';

  @override
  String get noOrdersFound => 'Aucune commande trouvée';

  @override
  String get noOrdersFoundForStatus => 'Aucune commande trouvée pour ce statut';

  @override
  String get financeAndPricing => 'Finance et tarification';

  @override
  String get manageInvoicesAndConfigurePricing => 'Gérer les factures et configurer la tarification';

  @override
  String get exportData => 'Exporter les données';

  @override
  String get exportingData => 'Exportation des données...';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get thisQuarter => 'Ce trimestre';

  @override
  String get thisYear => 'Cette année';

  @override
  String get allTime => 'Tout le temps';

  @override
  String get invoices => 'Factures';

  @override
  String get analytics => 'Analytique';

  @override
  String get pricing => 'Tarification';

  @override
  String get newInvoice => 'Nouvelle facture';

  @override
  String get selectSupplierFirstText => 'Sélectionnez d\'abord un fournisseur';

  @override
  String get selectSupplierToViewText => 'Veuillez sélectionner un fournisseur pour voir son inventaire de produits';

  @override
  String get noProductsText => 'Aucun produit disponible';

  @override
  String get noProductsFoundText => 'Aucun produit trouvé';

  @override
  String get tryDifferentSearchText => 'Essayez un autre terme de recherche ou parcourez d\'autres fournisseurs';

  @override
  String get addFirstProductText => 'Ajoutez votre premier produit pour commencer à vendre';

  @override
  String get quickTransactions => 'Transactions rapides';

  @override
  String get barcodeScanningComingSoon => 'Scan de code-barres bientôt disponible';

  @override
  String get chooseStoreToViewProducts => 'Choisissez un magasin pour voir les produits';

  @override
  String get added => 'Ajouté';

  @override
  String get noInventoryPrivilegesText => 'Accès à l\'inventaire restreint';

  @override
  String get toCart => 'au panier';

  @override
  String get businesses => 'Entreprises';

  @override
  String get inventory => 'Inventaire';

  @override
  String get orders => 'Commandes';

  @override
  String get pointOfSale => 'Vendeur';

  @override
  String get loading => 'Chargement...';

  @override
  String get addProduct => 'Ajouter un produit';

  @override
  String get createNewOrder => 'Créer une commande';

  @override
  String get openCart => 'Ouvrir le panier';

  @override
  String get createNewInvoice => 'Créer une facture';

  @override
  String get add => 'Ajouter';

  @override
  String get accessRequired => 'Accès requis';

  @override
  String get pleaseLoginToAccessDashboard => 'Veuillez vous connecter pour accéder au tableau de bord.';

  @override
  String get needBusinessAssignment => 'Vous devez être affecté à une entreprise pour accéder aux fonctionnalités de gestion.';

  @override
  String get contactAdminOrJoinTeam => 'Contactez votre administrateur ou rejoignez une équipe d\'entreprise.';

  @override
  String get checkAccessStatus => 'Vérifier le statut d\'accès';

  @override
  String get viewPendingInvitations => 'Voir les invitations en attente';

  @override
  String get pendingInvitations => 'Invitations en attente';

  @override
  String get noPendingInvitations => 'Aucune invitation en attente';

  @override
  String get unknownBusiness => 'Entreprise inconnue';

  @override
  String get role => 'Rôle';

  @override
  String get accept => 'Accepter';

  @override
  String get decline => 'Refuser';

  @override
  String get invitationAccepted => 'Invitation acceptée !';

  @override
  String get invitationDeclined => 'Invitation refusée.';

  @override
  String get noRoleAssigned => 'Aucun rôle attribué';

  @override
  String get noAnalyticsData => 'Aucune donnée analytique';

  @override
  String get generateInvoicesToSeeAnalytics => 'Générez des factures pour voir les données analytiques';

  @override
  String get financialOverview => 'Aperçu financier';

  @override
  String get totalRevenue => 'Revenu total';

  @override
  String get netProfit => 'Bénéfice net';

  @override
  String get growthRate => 'Taux de croissance';

  @override
  String get totalOrders => 'Total des commandes';

  @override
  String get averageOrder => 'Commande moyenne';

  @override
  String get taxCollected => 'Taxe collectée';

  @override
  String get recentTransactions => 'Transactions récentes';

  @override
  String get last5Transactions => '5 dernières transactions';

  @override
  String get viewAllTransactions => 'Voir toutes les transactions';

  @override
  String get revenue => 'Revenu';

  @override
  String get profit => 'Bénéfice';

  @override
  String get expenses => 'Dépenses';

  @override
  String get tax => 'Taxe';

  @override
  String get discount => 'Remise';

  @override
  String get refund => 'Remboursement';

  @override
  String get paid => 'Payé';

  @override
  String get pending => 'En attente';

  @override
  String get cancelled => 'Annulé';

  @override
  String get refunded => 'Remboursé';

  @override
  String get invoice => 'Facture';

  @override
  String get share => 'Partager';

  @override
  String get download => 'Télécharger';

  @override
  String get noInvoicesYet => 'Aucune facture pour le moment';

  @override
  String get noInvoicesDescription => 'Vos factures apparaîtront ici une fois vos ventes complétées';

  @override
  String get createFirstInvoice => 'Créer la première facture';

  @override
  String get loadingInvoices => 'Chargement des factures...';

  @override
  String get card => 'Carte';

  @override
  String get cash => 'Espèces';

  @override
  String get bankTransfer => 'Virement bancaire';

  @override
  String get mobilePayment => 'Paiement mobile';

  @override
  String get sharingInvoice => 'Partage de la facture';

  @override
  String get downloadingInvoice => 'Téléchargement de la facture';

  @override
  String get invoiceDetails => 'Détails de la facture';

  @override
  String get currencySymbol => 'DZD';

  @override
  String get currencyCode => 'USD';

  @override
  String get accessRefreshed => 'Accès actualisé';

  @override
  String get manageSuppliers => 'Gérer les fournisseurs';

  @override
  String get addFirstProduct => 'Ajouter le premier produit';

  @override
  String get services => 'Services';

  @override
  String get addService => 'Ajouter un service';

  @override
  String serviceDiscount(String percent, String label) {
    return '$percent% $label';
  }

  @override
  String get serviceDiscountOff => 'de réduction';

  @override
  String get servicesAvailable => 'disponible(s)';

  @override
  String get loadingServices => 'Chargement des services';

  @override
  String get pleaseWait => 'Veuillez patienter';

  @override
  String get noServicesFound => 'Aucun service trouvé';

  @override
  String get noServicesDescription => 'Ajoutez votre premier service pour commencer à proposer des services de santé aux patients.';

  @override
  String get proTip => 'Astuce';

  @override
  String get addServicesToManage => 'Ajoutez des services pour gérer les rendez-vous, la tarification et l\'allocation des ressources efficacement.';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get searchServices => 'Rechercher des services...';

  @override
  String get profitMargin => 'marge';

  @override
  String get serviceDetails => 'Détails du service';

  @override
  String get serviceDescription => 'Description';

  @override
  String get duration => 'Durée';

  @override
  String get category => 'Catégorie';

  @override
  String get createdAt => 'Créé';

  @override
  String get deletedAt => 'Supprimé';

  @override
  String get basePrice => 'Prix de base';

  @override
  String get finalPrice => 'Prix final';

  @override
  String get totalCost => 'Coût total';

  @override
  String get discountApplied => 'Remise appliquée sur le prix de base';

  @override
  String get resourceRequirements => 'Besoins en ressources';

  @override
  String get staffRequirements => 'Besoins en personnel';

  @override
  String get totalResourceCost => 'Coût total des ressources';

  @override
  String get totalStaffCost => 'Coût total du personnel';

  @override
  String get costSummary => 'Résumé des coûts';

  @override
  String get resourceCost => 'Coût des ressources';

  @override
  String get staffCost => 'Coût du personnel';

  @override
  String get totalServiceCost => 'Coût total du service';

  @override
  String get servicePrice => 'Prix du service';

  @override
  String get businessOperations => 'Opérations commerciales';

  @override
  String get overdue => 'En retard';

  @override
  String get unpaid => 'Impayé';

  @override
  String get partial => 'Partiel';

  @override
  String get noBusinessOperations => 'Aucune opération commerciale';

  @override
  String get generateOperationsToSeeData => 'Générez des opérations commerciales pour voir les analyses détaillées et les données de transaction';

  @override
  String get exportOperations => 'Exporter les opérations';

  @override
  String get viewAllBusinessTransactions => 'Voir toutes les transactions et opérations commerciales';

  @override
  String get topSuppliers => 'Meilleurs fournisseurs';

  @override
  String get status => 'Statut';

  @override
  String get source => 'Source';

  @override
  String get all => 'Tout';

  @override
  String get carts => 'Paniers';

  @override
  String get clearFilters => 'Effacer les filtres';

  @override
  String get totalAmount => 'Montant total';

  @override
  String get totalPaid => 'Total payé';

  @override
  String get outstanding => 'En suspens';

  @override
  String get balance => 'Solde';

  @override
  String get byStatus => 'Par statut';

  @override
  String get bySource => 'Par source';

  @override
  String get operationDetails => 'Détails de l\'opération';

  @override
  String get transactionDetails => 'Détails de la transaction';

  @override
  String get cartBasedTransaction => 'Transaction basée sur le panier';

  @override
  String get orderBasedTransaction => 'Transaction basée sur la commande';

  @override
  String get operationSummary => 'Résumé de l\'opération';

  @override
  String get operationId => 'ID de l\'opération';

  @override
  String get client => 'Client';

  @override
  String get supplier => 'Fournisseur';

  @override
  String get seller => 'Vendeur';

  @override
  String get cartBased => 'Basé sur le panier';

  @override
  String get orderBased => 'Basé sur la commande';

  @override
  String get paymentDetails => 'Détails du paiement';

  @override
  String get totalDeposited => 'Total déposé';

  @override
  String get balanceDue => 'Solde dû';

  @override
  String get processPayment => 'Traiter le paiement';

  @override
  String get sendReminder => 'Envoyer un rappel';

  @override
  String get print => 'Imprimer';

  @override
  String get sharingOperation => 'Partage de l\'opération...';

  @override
  String get printingOperation => 'Impression de l\'opération...';

  @override
  String get processingPayment => 'Traitement du paiement...';

  @override
  String get sendingReminder => 'Envoi du rappel...';

  @override
  String get noItemsFound => 'Aucun article trouvé';

  @override
  String get itemsWillBeLoadedFromServer => 'Les articles seront chargés depuis le serveur';

  @override
  String get loadItems => 'Charger les articles';

  @override
  String get loadingItems => 'Chargement des articles...';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get total => 'Total';

  @override
  String get quantity => 'Quantité';

  @override
  String get fullyPaid => 'Entièrement payé';

  @override
  String get partiallyPaid => 'Partiellement payé';

  @override
  String get cart => 'Panier';

  @override
  String get order => 'Commande';

  @override
  String get noSuppliersAvailable => 'Aucun fournisseur disponible';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get products => 'Produits';

  @override
  String get browseAndSelectServices => 'Parcourir et sélectionner des services';

  @override
  String get noServicesAvailable => 'Aucun service disponible';

  @override
  String get servicesWillAppearHere => 'Les services apparaîtront ici lorsqu\'ils seront disponibles';

  @override
  String get loadingProducts => 'Chargement des produits...';

  @override
  String get noProductsAvailable => 'Aucun produit disponible';

  @override
  String get preparingServiceCatalog => 'Préparation de votre catalogue de services';

  @override
  String get refreshServices => 'Actualiser les services';

  @override
  String get transaction => 'Transaction';

  @override
  String get documentType => 'Type de document';

  @override
  String get operationType => 'Type d\'opération';

  @override
  String get invoiceStatus => 'Statut de la facture';

  @override
  String get deposited => 'Déposé';

  @override
  String get productsAndServices => 'Produits et services';

  @override
  String get eShopping => 'Achat en ligne';

  @override
  String get inStorePurchase => 'Achat en magasin';

  @override
  String get serviceRepair => 'Réparation';

  @override
  String get serviceMaintenance => 'Maintenance';

  @override
  String get serviceFix => 'Réparation';

  @override
  String get serviceConsultation => 'Consultation';

  @override
  String get serviceAdvice => 'Conseil';

  @override
  String get serviceInstallation => 'Installation';

  @override
  String get serviceSetup => 'Configuration';

  @override
  String get serviceDelivery => 'Livraison';

  @override
  String get serviceShipping => 'Expédition';

  @override
  String get serviceCleaning => 'Nettoyage';

  @override
  String get serviceHousekeeping => 'Entretien ménager';

  @override
  String get serviceDesign => 'Design';

  @override
  String get serviceCreative => 'Créatif';

  @override
  String get serviceTraining => 'Formation';

  @override
  String get serviceEducation => 'Éducation';

  @override
  String get serviceMedical => 'Médical';

  @override
  String get serviceHealth => 'Santé';

  @override
  String get serviceTech => 'Technologie';

  @override
  String get serviceIT => 'Informatique';

  @override
  String get serviceGeneral => 'Services généraux';

  @override
  String get serviceBloodTesting => 'Analyse sanguine';

  @override
  String get serviceDiagnosticImaging => 'Imagerie diagnostique';

  @override
  String get servicePathologyTests => 'Tests pathologiques';

  @override
  String get serviceUrineAnalysis => 'Analyse d\'urine';

  @override
  String get serviceAllergyTesting => 'Tests d\'allergie';

  @override
  String get serviceGeneticTesting => 'Tests génétiques';

  @override
  String get serviceVaccination => 'Vaccination';

  @override
  String get serviceHealthCheckup => 'Bilan de santé';

  @override
  String get serviceDentalCare => 'Soins dentaires';

  @override
  String get serviceMinorSurgery => 'Chirurgie mineure';

  @override
  String get serviceWoundCare => 'Soins des plaies';

  @override
  String get serviceIVTherapy => 'Thérapie intraveineuse';

  @override
  String get servicePhysiotherapy => 'Physiothérapie';

  @override
  String get serviceAcupuncture => 'Acupuncture';

  @override
  String get serviceNutritionCounseling => 'Conseil nutritionnel';

  @override
  String get serviceMentalHealthCounseling => 'Conseil en santé mentale';

  @override
  String get serviceFirstAidTraining => 'Formation aux premiers secours';

  @override
  String get servicePrenatalCare => 'Soins prénatals';

  @override
  String get servicePediatricCare => 'Soins pédiatriques';

  @override
  String get serviceGeriatricCare => 'Soins gériatriques';

  @override
  String get serviceSportsMedicine => 'Médecine du sport';

  @override
  String get serviceGeneralMedical => 'Service médical général';

  @override
  String get supplierCategoryRestaurant => 'Restaurant';

  @override
  String get supplierCategoryBakery => 'Boulangerie';

  @override
  String get supplierCategoryFactory => 'Usine';

  @override
  String get supplierCategorySupermarket => 'Supermarché';

  @override
  String get supplierCategoryGroceryStore => 'Épicerie';

  @override
  String get supplierCategoryDistributor => 'Distributeur';

  @override
  String get supplierCategoryCafe => 'Café';

  @override
  String get supplierCategoryButcher => 'Boucherie';

  @override
  String get supplierCategoryDairy => 'Crémerie';

  @override
  String get supplierCategoryBeverage => 'Boissons';

  @override
  String get suppliers => 'Fournisseurs';

  @override
  String get noSuppliersFound => 'Aucun fournisseur trouvé';

  @override
  String get filterByCategory => 'Filtrer par catégorie';

  @override
  String get supplierType => 'Type';

  @override
  String get supplierContact => 'Contact';

  @override
  String get supplierAddress => 'Adresse';

  @override
  String get supplierRating => 'Évaluation';

  @override
  String get supplierProducts => 'Produits';

  @override
  String get viewSupplierDetails => 'Voir les détails';

  @override
  String get noInvoicesFound => 'Aucune facture trouvée';

  @override
  String get noResultsForFilter => 'Aucun résultat pour le filtre actuel';

  @override
  String get createYourFirstInvoice => 'Créez votre première facture pour commencer';

  @override
  String get tryDifferentFilter => 'Essayez un autre filtre ou terme de recherche';

  @override
  String get createInvoice => 'Créer une facture';

  @override
  String get searchInvoices => 'Rechercher des factures...';

  @override
  String get advancedFilter => 'Filtre avancé';

  @override
  String get dateRange => 'Plage de dates';

  @override
  String get fromDate => 'Du';

  @override
  String get toDate => 'Au';

  @override
  String get amountRange => 'Plage de montants';

  @override
  String get minAmount => 'Montant min';

  @override
  String get maxAmount => 'Montant max';

  @override
  String get clearAll => 'Tout effacer';

  @override
  String get apply => 'Appliquer';

  @override
  String get receipt => 'Reçu';

  @override
  String get quote => 'Devis';

  @override
  String get allDocuments => 'Tous les documents';

  @override
  String get editDocument => 'Modifier le document';

  @override
  String get downloadPdf => 'Télécharger le PDF';

  @override
  String get shareDocument => 'Partager le document';

  @override
  String get markAsPaid => 'Marquer comme payé';

  @override
  String get deleteDocument => 'Supprimer le document';

  @override
  String get createNewDocument => 'Créer un nouveau document';

  @override
  String get createInvoiceDescription => 'Créer une nouvelle facture';

  @override
  String get createReceiptDescription => 'Créer un reçu de paiement';

  @override
  String get createQuoteDescription => 'Créer un devis';

  @override
  String get documentMarkedAsPaid => 'Document marqué comme payé';

  @override
  String get failedToUpdate => 'Échec de la mise à jour du document';

  @override
  String get confirmDelete => 'Confirmer la suppression';

  @override
  String get deleteDocumentConfirmation => 'Êtes-vous sûr de vouloir supprimer ce document ?';

  @override
  String get documentDeleted => 'Document supprimé';

  @override
  String get failedToDelete => 'Échec de la suppression du document';

  @override
  String get totalInvoices => 'Total des factures';

  @override
  String get averageInvoice => 'Facture moyenne';

  @override
  String get pendingInvoices => 'Factures en attente';

  @override
  String get paidInvoices => 'Factures payées';

  @override
  String get overdueInvoices => 'Factures en retard';

  @override
  String get revenueThisMonth => 'Revenu ce mois-ci';

  @override
  String get revenueLastMonth => 'Revenu le mois dernier';

  @override
  String get topClients => 'Meilleurs clients';

  @override
  String get recentActivity => 'Activité récente';

  @override
  String get draft => 'Brouillon';

  @override
  String get yesterday => 'Hier';

  @override
  String get lastMonth => 'Le mois dernier';

  @override
  String get customRange => 'Plage personnalisée';

  @override
  String get exportAsCsv => 'Exporter en CSV';

  @override
  String get exportAsExcel => 'Exporter en Excel';

  @override
  String get exportAsPdf => 'Exporter en PDF';

  @override
  String get exportAll => 'Tout exporter';

  @override
  String get exportSelected => 'Exporter la sélection';

  @override
  String get exportSuccessful => 'Exportation réussie';

  @override
  String get filterApplied => 'Filtre appliqué';

  @override
  String get filterCleared => 'Filtre effacé';

  @override
  String get documentSaved => 'Document enregistré avec succès';

  @override
  String get paymentRecorded => 'Paiement enregistré avec succès';

  @override
  String get noDocumentsToExport => 'Aucun document à exporter';

  @override
  String get exportFailed => 'Échec de l\'exportation. Veuillez réessayer.';

  @override
  String get loadFailed => 'Échec du chargement des documents';

  @override
  String get connectionError => 'Erreur de connexion. Vérifiez votre internet.';

  @override
  String get serverErrorGeneric => 'Erreur serveur. Veuillez réessayer plus tard.';

  @override
  String get loadingMore => 'Chargement...';

  @override
  String get refreshing => 'Actualisation...';

  @override
  String get processingEllipsis => 'Traitement...';

  @override
  String get documentNumber => 'Document n°';

  @override
  String get date => 'Date';

  @override
  String get amount => 'Montant';

  @override
  String get dueDate => 'Date d\'échéance';

  @override
  String get issueDate => 'Date d\'émission';

  @override
  String get paymentDate => 'Date de paiement';

  @override
  String get notes => 'Notes';

  @override
  String get terms => 'Conditions';

  @override
  String get addItem => 'Ajouter un article';

  @override
  String get removeItem => 'Supprimer l\'article';

  @override
  String get calculateTotal => 'Calculer le total';

  @override
  String get sendEmail => 'Envoyer un e-mail';

  @override
  String get saveDraft => 'Enregistrer le brouillon';

  @override
  String get approve => 'Approuver';

  @override
  String get reject => 'Rejeter';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get archive => 'Archiver';

  @override
  String get filterByDate => 'Filtrer par date';

  @override
  String get filterByAmount => 'Filtrer par montant';

  @override
  String get filterByStatus => 'Filtrer par statut';

  @override
  String get filterByType => 'Filtrer par type';

  @override
  String get filterByClient => 'Filtrer par client';

  @override
  String get filterBySupplier => 'Filtrer par fournisseur';

  @override
  String get january => 'Janvier';

  @override
  String get february => 'Février';

  @override
  String get march => 'Mars';

  @override
  String get april => 'Avril';

  @override
  String get may => 'Mai';

  @override
  String get june => 'Juin';

  @override
  String get july => 'Juillet';

  @override
  String get august => 'Août';

  @override
  String get september => 'Septembre';

  @override
  String get october => 'Octobre';

  @override
  String get november => 'Novembre';

  @override
  String get december => 'Décembre';

  @override
  String get monday => 'Lundi';

  @override
  String get tuesday => 'Mardi';

  @override
  String get wednesday => 'Mercredi';

  @override
  String get thursday => 'Jeudi';

  @override
  String get friday => 'Vendredi';

  @override
  String get saturday => 'Samedi';

  @override
  String get sunday => 'Dimanche';

  @override
  String daysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String daysFromNow(int count) {
    return 'Dans $count jours';
  }

  @override
  String get deposit => 'Acompte';

  @override
  String get pendingCart => 'Panier en attente';

  @override
  String get depositReceived => 'Acompte reçu';

  @override
  String get depositCoversFull => 'L\'acompte couvre le total';

  @override
  String get depositPartial => 'Acompte partiel';

  @override
  String get depositFullyCovered => 'Acompte entièrement couvert';

  @override
  String get user => 'Utilisateur';

  @override
  String get person => 'Personne';

  @override
  String get guest => 'Invité';

  @override
  String get directInvoice => 'Facture directe';

  @override
  String get serviceBased => 'Basé sur le service';

  @override
  String get directDeposit => 'Dépôt direct';

  @override
  String get financialDocuments => 'Documents financiers';

  @override
  String get financialSummary => 'Résumé financier';

  @override
  String get due => 'Dû';

  @override
  String get count => 'Nombre';

  @override
  String get paymentProgress => 'Progression du paiement';

  @override
  String get noDocumentsFound => 'Aucun document trouvé';

  @override
  String get retry => 'Réessayer';

  @override
  String get loadingDocuments => 'Chargement des documents...';

  @override
  String get errorLoadingDocuments => 'Erreur de chargement des documents';

  @override
  String get again => 'Encore';

  @override
  String nServicesSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count services sélectionnés',
      one: '1 service sélectionné',
      zero: 'Aucun service sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get configureService => 'Configurer le service';

  @override
  String get scheduleService => 'Planifier le service';

  @override
  String get serviceWillBeScheduled => 'Le service sera planifié';

  @override
  String get addSchedulingInfo => 'Ajouter des informations de planification';

  @override
  String get scheduledDate => 'Date planifiée';

  @override
  String get scheduledTime => 'Heure planifiée';

  @override
  String get specialInstructions => 'Instructions spéciales';

  @override
  String get addNotesHere => 'Ajouter des notes ici...';

  @override
  String get serviceParameters => 'Paramètres du service';

  @override
  String get customizeServiceParameters => 'Personnaliser les paramètres du service';

  @override
  String get saveConfiguration => 'Enregistrer la configuration';

  @override
  String get services_view_title => 'Voir les services';

  @override
  String get services_view_description => 'Voir les services disponibles et la tarification';

  @override
  String get services_manage_title => 'Gérer les services';

  @override
  String get services_manage_description => 'Ajouter, modifier et supprimer des services';

  @override
  String get pos_view_title => 'Voir le point de vente';

  @override
  String get pos_view_description => 'Voir les transactions du point de vente';

  @override
  String get pos_manage_title => 'Gérer le point de vente';

  @override
  String get pos_manage_description => 'Traiter les ventes et gérer les opérations du point de vente';

  @override
  String get operations_view_title => 'Voir les opérations';

  @override
  String get operations_view_description => 'Voir les rapports et métriques opérationnels';

  @override
  String get operations_manage_title => 'Gérer les opérations';

  @override
  String get operations_manage_description => 'Configurer les opérations et paramètres du système';

  @override
  String get finance_view_title => 'Voir la finance';

  @override
  String get finance_view_description => 'Voir les rapports financiers et les transactions';

  @override
  String get finance_manage_title => 'Gérer la finance';

  @override
  String get finance_manage_description => 'Gérer les opérations financières et la comptabilité';

  @override
  String get category_services => 'Gestion des services';

  @override
  String get category_pos => 'Gestion du point de vente';

  @override
  String get category_operations => 'Gestion des opérations';

  @override
  String get category_finance => 'Gestion financière';

  @override
  String get permissionScore => 'Score de permission';

  @override
  String get privileges => 'Privilèges';

  @override
  String get savePrivileges => 'Enregistrer les privilèges';

  @override
  String get privilegesUpdated => 'Privilèges mis à jour avec succès';

  @override
  String get confirmPrivilegeChange => 'Êtes-vous sûr de vouloir modifier les privilèges ?';

  @override
  String get noPrivilegesSelected => 'Aucun privilège sélectionné';

  @override
  String get fullAccess => 'Accès complet';

  @override
  String get limitedAccess => 'Accès limité';

  @override
  String get viewOnly => 'Lecture seule';

  @override
  String get manageAccess => 'Gérer l\'accès';

  @override
  String get togglePrivilegeTooltip => 'Basculer le privilège';

  @override
  String get categoryToggleTooltip => 'Basculer tous les privilèges de la catégorie';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String get last => 'Dernier';

  @override
  String get transactions => 'Transactions';

  @override
  String get activeSuppliers => 'Fournisseurs actifs';

  @override
  String get payment => 'Paiement';

  @override
  String get expense => 'Dépense';

  @override
  String get income => 'Revenu';

  @override
  String get lastWeek => 'La semaine dernière';

  @override
  String get lastYear => 'L\'année dernière';

  @override
  String get accountsReceivable => 'Comptes débiteurs';

  @override
  String get accountsPayable => 'Comptes créditeurs';

  @override
  String get cashFlow => 'Flux de trésorerie';

  @override
  String get roi => 'ROI';

  @override
  String get breakEven => 'Seuil de rentabilité';

  @override
  String get revenueGrowth => 'Croissance des revenus';

  @override
  String get customerLifetimeValue => 'Valeur à vie du client';

  @override
  String get dailyRevenue => 'Revenu quotidien';

  @override
  String get weeklyRevenue => 'Revenu hebdomadaire';

  @override
  String get monthlyRevenue => 'Revenu mensuel';

  @override
  String get yearlyRevenue => 'Revenu annuel';

  @override
  String get revenueTrend => 'Tendance des revenus';

  @override
  String get profitTrend => 'Tendance des bénéfices';

  @override
  String get expenseBreakdown => 'Répartition des dépenses';

  @override
  String get categoryBreakdown => 'Répartition par catégorie';

  @override
  String get filterByCustomer => 'Filtrer par client';

  @override
  String get applyFilters => 'Appliquer les filtres';

  @override
  String get exportAsCSV => 'Exporter en CSV';

  @override
  String get generateReport => 'Générer un rapport';

  @override
  String get downloadReport => 'Télécharger le rapport';

  @override
  String get printReport => 'Imprimer le rapport';

  @override
  String get shareReport => 'Partager le rapport';

  @override
  String get saveReport => 'Enregistrer le rapport';

  @override
  String get refreshData => 'Actualiser les données';

  @override
  String get dataExportedSuccessfully => 'Données exportées avec succès';

  @override
  String get reportGeneratedSuccessfully => 'Rapport généré avec succès';

  @override
  String get noDataToExport => 'Aucune donnée à exporter';

  @override
  String get loadingFinancialData => 'Chargement des données financières...';

  @override
  String get calculatingStatistics => 'Calcul des statistiques...';

  @override
  String get hoverForDetails => 'Survolez pour les détails';

  @override
  String get clickToViewDetails => 'Cliquez pour voir les détails';

  @override
  String get doubleClickToEdit => 'Double-cliquez pour modifier';

  @override
  String get dragToResize => 'Faites glisser pour redimensionner';

  @override
  String get noTransactionsFound => 'Aucune transaction trouvée';

  @override
  String get noRevenueData => 'Aucune donnée de revenu disponible';

  @override
  String get noExpenseData => 'Aucune donnée de dépense disponible';

  @override
  String get noProfitData => 'Aucune donnée de bénéfice disponible';

  @override
  String get summary => 'Résumé';

  @override
  String get overview => 'Aperçu';

  @override
  String get detailedView => 'Vue détaillée';

  @override
  String get quickView => 'Vue rapide';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get reports => 'Rapports';

  @override
  String get insights => 'Informations';

  @override
  String get trends => 'Tendances';

  @override
  String get comparison => 'Comparaison';

  @override
  String get performance => 'Performance';

  @override
  String get target => 'Objectif';

  @override
  String get actual => 'Réel';

  @override
  String get variance => 'Écart';

  @override
  String get achievement => 'Réalisation';

  @override
  String get forecast => 'Prévision';

  @override
  String get projection => 'Projection';

  @override
  String get estimate => 'Estimation';

  @override
  String get vsLastPeriod => 'vs période précédente';

  @override
  String get vsLastYear => 'vs année précédente';

  @override
  String get vsTarget => 'vs objectif';

  @override
  String get vsBudget => 'vs budget';

  @override
  String get vsAverage => 'vs moyenne';

  @override
  String get quickStats => 'Statistiques rapides';

  @override
  String get todayRevenue => 'Revenu d\'aujourd\'hui';

  @override
  String get weekRevenue => 'Revenu de la semaine';

  @override
  String get monthRevenue => 'Revenu du mois';

  @override
  String get yearRevenue => 'Revenu de l\'année';

  @override
  String get revenuePerCustomer => 'Revenu par client';

  @override
  String get averageTransaction => 'Transaction moyenne';

  @override
  String get justNow => 'À l\'instant';

  @override
  String get minutesAgo => 'il y a quelques minutes';

  @override
  String get hoursAgo => 'il y a quelques heures';

  @override
  String get daysAgoLower => 'il y a quelques jours';

  @override
  String get weeksAgo => 'il y a quelques semaines';

  @override
  String get monthsAgo => 'il y a quelques mois';

  @override
  String get yearsAgo => 'il y a quelques années';

  @override
  String get documentsCountLabel => 'Nombre de documents';

  @override
  String get totalDocuments => 'Total des documents';

  @override
  String get averageDocument => 'Moyenne par document';

  @override
  String stock(String stock) {
    return 'Stock : $stock';
  }

  @override
  String itemsCount(int count) {
    return 'Articles : $count';
  }

  @override
  String items(int cartItemCount, int itemCount, int serviceCount) {
    String _temp0 = intl.Intl.pluralLogic(
      cartItemCount,
      locale: localeName,
      other: '# articles',
      one: '# article',
      zero: 'Aucun article',
    );
    String _temp1 = intl.Intl.pluralLogic(
      itemCount,
      locale: localeName,
      other: '$itemCount produits',
      one: 'un produit',
      zero: 'aucun produit',
    );
    String _temp2 = intl.Intl.pluralLogic(
      serviceCount,
      locale: localeName,
      other: '$serviceCount services',
      one: 'un service',
      zero: 'aucun service',
    );
    return '$_temp0 ($_temp1, $_temp2)';
  }

  @override
  String get itemsText => 'Articles';

  @override
  String get checkout => 'Paiement';

  @override
  String get orderConfirmed => 'Commande confirmée';

  @override
  String get orderPlacedSuccessfully => 'Votre commande a été passée avec succès';

  @override
  String get backToHome => 'Retour à l\'accueil';

  @override
  String get guestCustomer => 'Client invité';

  @override
  String get orderItems => 'Articles de la commande';

  @override
  String get paymentMethod => 'Mode de paiement';

  @override
  String get deliveryType => 'Type de livraison';

  @override
  String get pickup => 'Retrait';

  @override
  String get pickupDesc => 'Retirer au magasin';

  @override
  String get delivery => 'Livraison';

  @override
  String get deliveryDesc => 'Livraison le jour même disponible';

  @override
  String get shipping => 'Expédition';

  @override
  String get shippingDesc => 'Expédition standard (3-5 jours ouvrables)';

  @override
  String get orderNotes => 'Notes de commande';

  @override
  String get notesHint => 'Instructions spéciales, notes de livraison, etc.';

  @override
  String get orderSummary => 'Résumé de la commande';

  @override
  String get placeOrder => 'Passer la commande';

  @override
  String get customer => 'Client';

  @override
  String get searchCustomers => 'Rechercher des clients...';

  @override
  String get invoiceReceipt => 'Facture + Reçu';

  @override
  String get receiptOnly => 'Reçu uniquement';

  @override
  String get none => 'Aucun';

  @override
  String get paymentType => 'Type de paiement';

  @override
  String get fullPayment => 'Paiement complet';

  @override
  String get depositOnly => 'Acompte uniquement';

  @override
  String get check => 'Chèque';

  @override
  String get cardDetails => 'Détails de la carte';

  @override
  String get cardType => 'Type de carte';

  @override
  String get cardNumber => 'Numéro de carte';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get bankTransferDetails => 'Détails du virement bancaire';

  @override
  String get bankName => 'Nom de la banque';

  @override
  String get accountNumber => 'Numéro de compte';

  @override
  String get reference => 'Référence';

  @override
  String get mobilePaymentDetails => 'Détails du paiement mobile';

  @override
  String get serviceProvider => 'Fournisseur de services';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get checkDetails => 'Détails du chèque';

  @override
  String get checkPaymentNote => 'Le paiement par chèque sera traité dès réception et compensation.';

  @override
  String get printDocument => 'Imprimer';

  @override
  String get done => 'Terminé';

  @override
  String get selectCustomer => 'Sélectionner un client';

  @override
  String get searchForCustomer => 'Rechercher un client';

  @override
  String get searchCustomersHint => 'Rechercher par nom, e-mail ou téléphone...';

  @override
  String get searchCustomerInstructions => 'Saisissez le nom, l\'e-mail ou le numéro de téléphone du client pour rechercher';

  @override
  String get addNewCustomer => 'Ajouter un nouveau client';

  @override
  String get searching => 'Recherche...';

  @override
  String get noCustomersFound => 'Aucun client trouvé';

  @override
  String get adjustSearchTerms => 'Essayez d\'ajuster vos termes de recherche';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get searchResults => 'Résultats de recherche';

  @override
  String get addNewCustomerInstruction => 'Créez un nouveau profil client pour l\'ajouter au système';

  @override
  String get create => 'Créer';

  @override
  String get customerDetails => 'Détails du client';

  @override
  String get fullName => 'Nom complet';

  @override
  String get email => 'E-mail';

  @override
  String get phone => 'Téléphone';

  @override
  String get phoneNumberLabel => 'Numéro de téléphone';

  @override
  String get address => 'Adresse';

  @override
  String get city => 'Ville';

  @override
  String get country => 'Pays';

  @override
  String get editCustomer => 'Modifier le client';

  @override
  String get removeCustomer => 'Supprimer le client';

  @override
  String get checkoutHelp => 'Aide au paiement';

  @override
  String get customerHelpDescription => 'Sélectionnez ou recherchez un client à associer à cette commande';

  @override
  String get documentTypeHelpDescription => 'Choisissez le type de document à générer';

  @override
  String get paymentMethodHelpDescription => 'Sélectionnez votre mode de paiement préféré';

  @override
  String get notesParametersHelpDescription => 'Ajoutez des notes et des paramètres personnalisés à cette commande';

  @override
  String get gotIt => 'Compris !';

  @override
  String get notesParameters => 'Notes et paramètres';

  @override
  String get parameters => 'Paramètres';

  @override
  String get addParameter => 'Ajouter un paramètre';

  @override
  String get editParameter => 'Modifier le paramètre';

  @override
  String get noParametersAdded => 'Aucun paramètre ajouté';

  @override
  String get addParametersToCustomizeOrder => 'Ajoutez des paramètres pour personnaliser cette commande';

  @override
  String get changeCustomer => 'Changer de client';

  @override
  String get installment => 'Versement';

  @override
  String get help => 'Aide';

  @override
  String get addParameterDescription => 'Ajouter un paramètre personnalisé à cette commande';

  @override
  String get parameterKey => 'Clé du paramètre';

  @override
  String get parameterKeyHint => 'ex. : Priorité, Instructions spéciales';

  @override
  String get parameterKeyRequired => 'Veuillez saisir une clé';

  @override
  String get parameterKeyTooLong => 'La clé est trop longue (max 50 caractères)';

  @override
  String get parameterValue => 'Valeur du paramètre';

  @override
  String get parameterValueHint => 'ex. : Élevée, Manipuler avec précaution';

  @override
  String get parameterValueRequired => 'Veuillez saisir une valeur';

  @override
  String get parameterValueTooLong => 'La valeur est trop longue (max 200 caractères)';

  @override
  String get suggestedParameters => 'Paramètres suggérés';

  @override
  String get saveLabel => 'Enregistrer';

  @override
  String get pleaseSelectCustomer => 'Veuillez sélectionner un client';

  @override
  String get cartEmpty => 'Votre panier est vide';

  @override
  String get pleaseEnterCardDetails => 'Veuillez saisir les détails de la carte';

  @override
  String get pleaseEnterBankDetails => 'Veuillez saisir les détails bancaires';

  @override
  String get pleaseEnterMobilePaymentDetails => 'Veuillez sélectionner un fournisseur de paiement mobile';

  @override
  String get visa => 'VISA';

  @override
  String get mastercard => 'MasterCard';

  @override
  String get amex => 'American Express';

  @override
  String get orangeMoney => 'Orange Money';

  @override
  String get ooredooMoney => 'Ooredoo Money';

  @override
  String get nedjmaPay => 'Nedjma Pay';

  @override
  String get paypal => 'PayPal';

  @override
  String get stcPay => 'STC Pay';

  @override
  String get saveToPreferences => 'Enregistrer dans les préférences pour une utilisation future';

  @override
  String get savedParameters => 'Paramètres enregistrés';

  @override
  String get currentParameters => 'Paramètres actuels';

  @override
  String get noSavedParameters => 'Aucun paramètre enregistré';

  @override
  String get manageSavedParameters => 'Gérer les paramètres enregistrés';

  @override
  String get selectCustomerForOrder => 'Sélectionner un client pour cette commande';

  @override
  String get searchForCustomers => 'Rechercher des clients';

  @override
  String get enterNameOrEmailToFindCustomers => 'Saisissez un nom, un nom d\'utilisateur ou un e-mail pour trouver des clients';

  @override
  String get allCustomers => 'Tous les clients';

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String get newCustomerComingSoon => 'Création de nouveau client bientôt disponible';

  @override
  String get selectPaymentType => 'Sélectionnez comment vous souhaitez payer';

  @override
  String get fullPaymentDesc => 'Payer le montant total maintenant';

  @override
  String get fullPaymentApplied => 'Paiement complet appliqué';

  @override
  String get fullPaymentDescDetail => 'Le montant total vous sera débité immédiatement';

  @override
  String get depositOnlyDesc => 'Payer un acompte maintenant, le solde plus tard';

  @override
  String get enterDepositAmount => 'Saisir le montant de l\'acompte';

  @override
  String get enterAmount => 'Saisir le montant';

  @override
  String get remainingAmount => 'Montant restant';

  @override
  String get installmentDesc => 'Planifier le paiement pour plus tard';

  @override
  String get selectInstallmentDate => 'Sélectionner la date du versement';

  @override
  String get installmentDate => 'Date du versement';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get installmentNote => 'Le montant total sera débité à la date sélectionnée';

  @override
  String get persons => 'Personnes';

  @override
  String get users => 'Utilisateurs';

  @override
  String get searchForPersons => 'Rechercher des personnes';

  @override
  String get enterNameToFindPersons => 'Saisissez un nom pour trouver des personnes';

  @override
  String get noPersonsFound => 'Aucune personne trouvée';

  @override
  String get tryDifferentName => 'Essayez un autre nom';

  @override
  String get recentCustomers => 'Clients récents';

  @override
  String get noCustomersYet => 'Aucun client pour le moment';

  @override
  String get startByAddingCustomers => 'Commencez par ajouter des clients ci-dessous';

  @override
  String get personAccounts => 'Comptes de personnes';

  @override
  String get userAccounts => 'Comptes utilisateurs';

  @override
  String get confirmCheckout => 'Confirmer le paiement';

  @override
  String get checkoutSummary => 'Résumé du paiement';

  @override
  String get mobileMoney => 'Argent mobile';

  @override
  String get orderId => 'ID de commande';

  @override
  String get orderSuccessful => 'Commande réussie';

  @override
  String get continueShopping => 'Continuer les achats';

  @override
  String get viewOrders => 'Voir les commandes';

  @override
  String get confirmAndPay => 'Confirmer et payer';

  @override
  String get ok => 'OK';

  @override
  String get processingOrder => 'Traitement de votre commande...';

  @override
  String get cartEmptyError => 'Votre panier est vide';

  @override
  String get customerRequiredError => 'Veuillez sélectionner un client';

  @override
  String get loginRequiredError => 'Veuillez vous connecter pour passer à la caisse';

  @override
  String get checkoutError => 'Erreur de paiement';

  @override
  String get itemsHelpDescription => 'Vérifiez les articles de votre panier avant le paiement. Vous pouvez modifier les quantités si nécessaire.';

  @override
  String get deliveryHelpDescription => 'Choisissez si le client récupérera la commande ou si elle doit être livrée.';

  @override
  String get deliveryDetails => 'Détails de la livraison';

  @override
  String get packageDetails => 'Détails du colis';

  @override
  String get packageCount => 'Nombre de colis';

  @override
  String get totalWeight => 'Poids total (kg)';

  @override
  String get dimensions => 'Dimensions (L×l×H)';

  @override
  String get goodsDescription => 'Description des marchandises';

  @override
  String get deliveryAddress => 'Adresse de livraison';

  @override
  String get shippingMethod => 'Mode d\'expédition';

  @override
  String get estimatedDeliveryFee => 'Frais de livraison estimés';

  @override
  String get priceMayChange => 'Le prix peut changer selon les détails finaux';

  @override
  String get useCustomerAddress => 'Utiliser l\'adresse du client';

  @override
  String get changeAddress => 'Changer d\'adresse';

  @override
  String get selectAddress => 'Sélectionner l\'adresse de livraison';

  @override
  String get addressSelected => 'Adresse sélectionnée';

  @override
  String get addressFilled => 'Adresse remplie à partir des informations client';

  @override
  String get calculatePrice => 'Calculer le prix';

  @override
  String get standard => 'Standard';

  @override
  String get express => 'Express';

  @override
  String get overnight => 'Nuit';

  @override
  String get freight => 'Fret';

  @override
  String get enterAddress => 'Saisir l\'adresse de livraison';

  @override
  String get deliveryFee => 'Frais de livraison';

  @override
  String get estimatedPrice => 'Prix estimé';

  @override
  String get weightRequired => 'Le poids est requis';

  @override
  String get addressRequired => 'L\'adresse de livraison est requise';

  @override
  String get invalidWeight => 'Valeur de poids invalide';

  @override
  String get loadingPrice => 'Calcul du prix...';

  @override
  String get deliveryOptions => 'Options de livraison';

  @override
  String get freeDelivery => 'Livraison gratuite';

  @override
  String get paidDelivery => 'Livraison payante';

  @override
  String get scheduleDelivery => 'Planifier la livraison';

  @override
  String get deliveryDate => 'Date de livraison';

  @override
  String get deliveryTime => 'Heure de livraison';

  @override
  String get trackingNumber => 'Numéro de suivi';

  @override
  String get carrier => 'Transporteur';

  @override
  String get insurance => 'Assurance';

  @override
  String get signatureRequired => 'Signature requise';

  @override
  String get fragile => 'Fragile';

  @override
  String get perishable => 'Périssable';

  @override
  String get hazardous => 'Dangereux';

  @override
  String get bulk => 'En vrac';

  @override
  String get confirmDelivery => 'Confirmer la livraison';

  @override
  String get deliveryConfirmed => 'Livraison confirmée';

  @override
  String get deliveryPending => 'Livraison en attente';

  @override
  String get deliveryInTransit => 'En transit';

  @override
  String get deliveryOutForDelivery => 'En cours de livraison';

  @override
  String get deliveryDelivered => 'Livrée';

  @override
  String get deliveryFailed => 'Échec de la livraison';

  @override
  String get deliveryCancelled => 'Livraison annulée';

  @override
  String get deliveryReturned => 'Retournée';

  @override
  String get trackDelivery => 'Suivre la livraison';

  @override
  String get viewDeliveryDetails => 'Voir les détails de la livraison';

  @override
  String get editDelivery => 'Modifier la livraison';

  @override
  String get cancelDelivery => 'Annuler la livraison';

  @override
  String get rescheduleDelivery => 'Reprogrammer la livraison';

  @override
  String get deliveryHistory => 'Historique des livraisons';

  @override
  String get upcomingDeliveries => 'Livraisons à venir';

  @override
  String get pastDeliveries => 'Livraisons passées';

  @override
  String get deliveryStatus => 'Statut de la livraison';

  @override
  String get recipient => 'Destinataire';

  @override
  String get sender => 'Expéditeur';

  @override
  String get pickupLocation => 'Lieu de retrait';

  @override
  String get deliveryLocation => 'Lieu de livraison';

  @override
  String get expectedDelivery => 'Livraison prévue';

  @override
  String get actualDelivery => 'Livraison réelle';

  @override
  String get deliveryNotes => 'Notes de livraison';

  @override
  String get proofOfDelivery => 'Preuve de livraison';

  @override
  String get signature => 'Signature';

  @override
  String get photos => 'Photos';

  @override
  String get damageReport => 'Rapport de dommage';

  @override
  String get feedback => 'Commentaires';

  @override
  String get rateDelivery => 'Évaluer la livraison';

  @override
  String get deliveryRating => 'Évaluation de la livraison';

  @override
  String get driverName => 'Nom du chauffeur';

  @override
  String get vehicleNumber => 'Numéro du véhicule';

  @override
  String get contactDriver => 'Contacter le chauffeur';

  @override
  String get shareLocation => 'Partager la position';

  @override
  String get liveTracking => 'Suivi en direct';

  @override
  String get eTA => 'Heure d\'arrivée estimée';

  @override
  String get distance => 'Distance';

  @override
  String get route => 'Itinéraire';

  @override
  String get deliveryProof => 'Preuve de livraison';

  @override
  String get confirmReceipt => 'Confirmer la réception';

  @override
  String get reportIssue => 'Signaler un problème';

  @override
  String get needHelp => 'Besoin d\'aide ?';

  @override
  String get streetAddress => 'Adresse';

  @override
  String get enterStreetAddress => 'Saisir l\'adresse';

  @override
  String get streetAddressRequired => 'L\'adresse est requise';

  @override
  String get enterCity => 'Saisir la ville';

  @override
  String get cityRequired => 'La ville est requise';

  @override
  String get postalCode => 'Code postal';

  @override
  String get enterPostalCode => 'Saisir le code postal';

  @override
  String get stateProvince => 'État/Province';

  @override
  String get enterState => 'Saisir l\'état/province';

  @override
  String get enterCountry => 'Saisir le pays';

  @override
  String get countryRequired => 'Le pays est requis';

  @override
  String get addressType => 'Type d\'adresse';

  @override
  String get additionalDetails => 'Détails supplémentaires';

  @override
  String get building => 'Bâtiment';

  @override
  String get enterBuilding => 'Nom/numéro du bâtiment';

  @override
  String get apartment => 'Appartement';

  @override
  String get enterApartment => 'Numéro d\'appartement/unité';

  @override
  String get floor => 'Étage';

  @override
  String get enterFloor => 'Numéro d\'étage';

  @override
  String get landmark => 'Point de repère';

  @override
  String get enterLandmark => 'Point de repère à proximité';

  @override
  String get quickFill => 'Remplissage rapide';

  @override
  String get addressComplete => 'Adresse complète';

  @override
  String get addressIncomplete => 'Veuillez remplir tous les champs obligatoires';

  @override
  String get selectCountry => 'Sélectionner un pays';

  @override
  String get homeAddress => 'Domicile';

  @override
  String get workAddress => 'Travail';

  @override
  String get businessAddress => 'Entreprise';

  @override
  String get shippingAddress => 'Adresse de livraison';

  @override
  String get billingAddress => 'Adresse de facturation';

  @override
  String get otherAddress => 'Autre';

  @override
  String get requiredField => 'Ce champ est obligatoire';

  @override
  String get invalidFormat => 'Format invalide';

  @override
  String get addressSaved => 'Adresse enregistrée avec succès';

  @override
  String get addressUpdated => 'Adresse mise à jour avec succès';

  @override
  String get addressDeleted => 'Adresse supprimée';

  @override
  String get saveAddress => 'Enregistrer l\'adresse';

  @override
  String get updateAddress => 'Mettre à jour l\'adresse';

  @override
  String get deleteAddress => 'Supprimer l\'adresse';

  @override
  String get clear => 'Effacer';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get myAddresses => 'Mes adresses';

  @override
  String get addNewAddress => 'Ajouter une nouvelle adresse';

  @override
  String get editAddress => 'Modifier l\'adresse';

  @override
  String get defaultAddress => 'Adresse par défaut';

  @override
  String get setAsDefault => 'Définir par défaut';

  @override
  String get removeDefault => 'Supprimer par défaut';

  @override
  String get noAddresses => 'Aucune adresse enregistrée';

  @override
  String get addYourFirstAddress => 'Ajoutez votre première adresse';

  @override
  String get addressBook => 'Carnet d\'adresses';

  @override
  String get useCurrentLocation => 'Utiliser la position actuelle';

  @override
  String get locating => 'Localisation...';

  @override
  String get locationPermission => 'Autorisation de localisation';

  @override
  String get locationPermissionMessage => 'Veuillez activer les services de localisation pour utiliser votre position actuelle';

  @override
  String get enableLocation => 'Activer la localisation';

  @override
  String get locationServicesDisabled => 'Les services de localisation sont désactivés';

  @override
  String get locationNotFound => 'Position introuvable';

  @override
  String get searchLocation => 'Rechercher un lieu';

  @override
  String get selectOnMap => 'Sélectionner sur la carte';

  @override
  String get verifyAddress => 'Vérifier l\'adresse';

  @override
  String get addressVerified => 'Adresse vérifiée';

  @override
  String get addressNotVerified => 'L\'adresse n\'a pas pu être vérifiée';

  @override
  String get suggestedAddress => 'Adresse suggérée';

  @override
  String get useSuggested => 'Utiliser l\'adresse suggérée';

  @override
  String get keepOriginal => 'Conserver l\'originale';

  @override
  String get streetNumber => 'Numéro de rue';

  @override
  String get neighborhood => 'Quartier';

  @override
  String get sublocality => 'Sous-localité';

  @override
  String get administrativeArea => 'Zone administrative';

  @override
  String get subAdministrativeArea => 'Sous-zone administrative';

  @override
  String get postalTown => 'Ville postale';

  @override
  String get premise => 'Locaux';

  @override
  String get subpremise => 'Sous-locaux';

  @override
  String get plusCode => 'Code Plus';

  @override
  String get showOnMap => 'Afficher sur la carte';

  @override
  String get getDirections => 'Obtenir l\'itinéraire';

  @override
  String get copyAddress => 'Copier l\'adresse';

  @override
  String get shareAddress => 'Partager l\'adresse';

  @override
  String get qrCode => 'Code QR';

  @override
  String get labelHome => '🏠 Domicile';

  @override
  String get labelWork => '💼 Travail';

  @override
  String get labelFamily => '👪 Famille';

  @override
  String get labelFriend => '👤 Ami';

  @override
  String get labelOther => '📍 Autre';

  @override
  String get customLabel => 'Libellé personnalisé';

  @override
  String get enterLabel => 'Saisir le libellé';

  @override
  String get deliveryInstructions => 'Instructions de livraison';

  @override
  String get enterInstructions => 'Saisir les instructions de livraison';

  @override
  String get gateCode => 'Code de portail';

  @override
  String get enterGateCode => 'Saisir le code du portail/bâtiment';

  @override
  String get preferredDeliveryTime => 'Heure de livraison préférée';

  @override
  String get leaveAtDoor => 'Laisser à la porte';

  @override
  String get requireSignature => 'Exiger une signature';

  @override
  String get callOnArrival => 'Appeler à l\'arrivée';

  @override
  String get formatAsSingleLine => 'Format sur une ligne';

  @override
  String get formatAsMultiLine => 'Format multiligne';

  @override
  String get copyFormatted => 'Copier le format';

  @override
  String get standardFormat => 'Format standard';

  @override
  String get localFormat => 'Format local';

  @override
  String get internationalFormat => 'Format international';

  @override
  String get lengthHint => 'Longueur';

  @override
  String get widthHint => 'Largeur';

  @override
  String get heightHint => 'Hauteur';

  @override
  String get goodsDescriptionHint => 'Décrivez ce qui est livré';

  @override
  String get hsCode => 'Code SH';

  @override
  String get hsCodeHint => 'Code du Système Harmonisé';

  @override
  String get standardShipping => 'Expédition standard';

  @override
  String get expressShipping => 'Expédition express';

  @override
  String get overnightShipping => 'Expédition de nuit';

  @override
  String get freightShipping => 'Expédition par fret';

  @override
  String get selectDeliveryType => 'Choisissez comment vous souhaitez recevoir votre commande';

  @override
  String get totalDeliveryCost => 'Coût total de livraison';

  @override
  String get fillAddressAutomatically => 'Remplir l\'adresse automatiquement à partir du profil client';

  @override
  String get weightUnit => 'kg';

  @override
  String get dimensionUnitCm => 'cm';

  @override
  String get enterPackageDimensions => 'Saisissez les dimensions du colis pour une expédition précise';

  @override
  String get dimensionUnitM => 'm';

  @override
  String get paidCart => 'Panier payé';

  @override
  String get remaining => 'Restant';

  @override
  String get deposits => 'Acomptes';

  @override
  String get customerType => 'Type de client';

  @override
  String get customerId => 'ID client';

  @override
  String get personId => 'ID personne';

  @override
  String get notAssigned => 'Non attribué';

  @override
  String get documentDetails => 'Détails du document';

  @override
  String get daysIssued => 'Jours émis';

  @override
  String get days => 'jours';

  @override
  String get sourceType => 'Type de source';

  @override
  String makePayment(String amount) {
    return 'Payer $amount';
  }

  @override
  String get copyLink => 'Copier le lien';

  @override
  String get shareViaEmail => 'Partager par e-mail';

  @override
  String get shareViaMessage => 'Partager par message';

  @override
  String get downloadingDocument => 'Téléchargement du document...';

  @override
  String get downloadComplete => 'Téléchargement terminé !';

  @override
  String get cart_with_payments => 'Panier avec paiements';

  @override
  String get pending_cart => 'Panier en attente';

  @override
  String get pending_cart_lower => 'panier en attente';

  @override
  String get deposited_status => 'Déposé';

  @override
  String get partially_paid => 'Partiellement payé';

  @override
  String get cart_based => 'Basé sur le panier';

  @override
  String get invoice_based => 'Basé sur la facture';

  @override
  String get order_based => 'Basé sur la commande';

  @override
  String get direct_deposit => 'Dépôt direct';

  @override
  String get direct_receipt => 'Reçu direct';

  @override
  String get mixed_payments => 'Paiements mixtes';

  @override
  String get payment_only => 'Paiement uniquement';

  @override
  String get no_payments => 'Aucun paiement';

  @override
  String get addDeposit => 'Ajouter un acompte';

  @override
  String get submitDeposit => 'Soumettre l\'acompte';

  @override
  String get submitPayment => 'Soumettre le paiement';

  @override
  String get depositDetails => 'Détails de l\'acompte';

  @override
  String get installmentDetails => 'Détails du versement';

  @override
  String get installmentScheduled => 'Versement planifié pour la date sélectionnée';

  @override
  String get depositAmount => 'Montant de l\'acompte';

  @override
  String get notesOptional => 'Notes facultatives...';

  @override
  String get enterValidAmount => 'Veuillez saisir un montant valide';

  @override
  String get selectDateForInstallment => 'Veuillez sélectionner une date pour le versement';

  @override
  String get success => 'Succès';

  @override
  String get additionalDepositSubmitted => 'Acompte supplémentaire soumis avec succès';

  @override
  String get depositSubmitted => 'Acompte soumis avec succès';

  @override
  String get paymentSubmitted => 'Paiement soumis avec succès';

  @override
  String get customerName => 'Nom du client';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get hasAccount => 'A un compte';

  @override
  String get noDocumentsMatchQuery => 'Aucun document ne correspond';

  @override
  String get documentsWillAppearHere => 'Les documents apparaîtront ici une fois créés';

  @override
  String get tip => '💡 Astuce';

  @override
  String youHaveTotalDocuments(int count) {
    return 'Vous avez $count documents au total.';
  }

  @override
  String get tryDifferentFilters => 'Essayez d\'autres filtres ou termes de recherche.';

  @override
  String get editService => 'Modifier le service';

  @override
  String get createService => 'Créer un service';

  @override
  String get serviceName => 'Nom du service';

  @override
  String get enterServiceName => 'Saisir le nom du service';

  @override
  String get serviceNameRequiredLabel => 'Le nom du service est requis';

  @override
  String get description => 'Description';

  @override
  String get enterDescription => 'Saisir la description du service';

  @override
  String get categoryId => 'ID de catégorie';

  @override
  String get enterCategoryId => 'Saisir l\'ID de catégorie';

  @override
  String get providerId => 'ID du fournisseur';

  @override
  String get enterProviderId => 'Saisir l\'ID du fournisseur';

  @override
  String get durationMinutes => 'Durée (minutes)';

  @override
  String get enterDuration => 'Saisir la durée en minutes';

  @override
  String get durationRequired => 'La durée est requise';

  @override
  String get durationPositive => 'La durée doit être positive';

  @override
  String get enterBasePrice => 'Saisir le prix de base';

  @override
  String get basePriceRequired => 'Le prix de base est requis';

  @override
  String get pricePositive => 'Le prix doit être positif';

  @override
  String get enterFinalPrice => 'Saisir le prix final';

  @override
  String get finalPriceRequired => 'Le prix final est requis';

  @override
  String get pricingConfiguration => 'Configuration tarifaire';

  @override
  String get ageGroup => 'Groupe d\'âge';

  @override
  String get enterAgeGroup => 'ex. : Adulte, Enfant';

  @override
  String get sampleType => 'Type d\'échantillon';

  @override
  String get enterSampleType => 'ex. : Sang, Urine';

  @override
  String get specialistConsultation => 'Consultation spécialisée';

  @override
  String get governmentFunded => 'Financé par le gouvernement';

  @override
  String get consultationIncluded => 'Consultation incluse';

  @override
  String get digitalImaging => 'Imagerie numérique';

  @override
  String get materialOptions => 'Options de matériaux';

  @override
  String get addMaterial => 'Ajouter un matériau';

  @override
  String get enterMaterial => 'ex. : Or, Argent';

  @override
  String get includes => 'Inclut';

  @override
  String get addInclude => 'Ajouter une inclusion';

  @override
  String get enterInclude => 'ex. : Consultation gratuite';

  @override
  String get addResource => 'Ajouter une ressource';

  @override
  String get noResourcesAddedLabel => 'Aucune ressource ajoutée';

  @override
  String get addStaff => 'Ajouter du personnel';

  @override
  String get noStaffAddedLabel => 'Aucun personnel ajouté';

  @override
  String get serviceUpdated => 'Service mis à jour avec succès';

  @override
  String get serviceCreated => 'Service créé avec succès';

  @override
  String get updateService => 'Mettre à jour le service';

  @override
  String get noDiscount => 'Aucune remise';

  @override
  String get minutes => 'min';

  @override
  String get scrollToTop => 'Défiler vers le haut';

  @override
  String get enterPrice => 'Saisir le prix';

  @override
  String get priceRequired => 'Le prix est requis';

  @override
  String get invalidPrice => 'Veuillez saisir un prix valide';

  @override
  String get typeAndPressEnter => 'Saisissez et appuyez sur Entrée...';

  @override
  String get finalPriceLabel => 'Prix final';

  @override
  String get walkInCustomer => 'Client sans rendez-vous';

  @override
  String get emptyCustomer => 'Sélectionner un client';

  @override
  String get guestEmail => 'invite@exemple.com';

  @override
  String get guestLocation => 'Emplacement du magasin';

  @override
  String get something_went_wrong => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get auth_required => 'Authentification requise. Veuillez vous connecter.';

  @override
  String get auth_decode_failed => 'Session expirée. Veuillez vous reconnecter.';

  @override
  String get auth_unauthorized => 'Vous n\'avez pas la permission d\'effectuer cette action.';

  @override
  String get user_auth_creation_failed => 'Échec de la création du compte. Veuillez réessayer.';

  @override
  String get user_net_failed => 'Erreur réseau. Vérifiez votre connexion.';

  @override
  String get appuser_not_exists => 'Utilisateur introuvable.';

  @override
  String get appuser_already_exists => 'L\'utilisateur existe déjà.';

  @override
  String get appusertype_not_exists => 'Type d\'utilisateur introuvable.';

  @override
  String get user_fetch_not_found => 'Utilisateur introuvable.';

  @override
  String get user_insert_failed => 'Échec de la création de l\'utilisateur.';

  @override
  String get user_update_failed => 'Échec de la mise à jour des informations utilisateur.';

  @override
  String get user_delete_failed => 'Échec de la suppression de l\'utilisateur.';

  @override
  String get person_not_exists => 'Personne introuvable.';

  @override
  String get person_insert_failed => 'Échec de la création de l\'enregistrement de la personne.';

  @override
  String get person_update_failed => 'Échec de la mise à jour des informations de la personne.';

  @override
  String get person_delete_failed => 'Échec de la suppression de l\'enregistrement de la personne.';

  @override
  String get person_detail_insert_failed => 'Échec de la création des détails de la personne.';

  @override
  String get person_details_not_found => 'Détails de la personne introuvables.';

  @override
  String get person_fetch_not_found => 'Personne introuvable.';

  @override
  String get product_not_exists => 'Produit introuvable.';

  @override
  String get product_already_exists => 'Le produit existe déjà.';

  @override
  String get product_category_not_exists => 'Catégorie de produit introuvable.';

  @override
  String get product_quantity_not_enough => 'Quantité de produit insuffisante.';

  @override
  String get product_quantity_restore_failed => 'Échec de la restauration de la quantité du produit.';

  @override
  String get product_supplier_not_exists => 'Fournisseur du produit introuvable.';

  @override
  String get product_supplier_already_exists => 'Le fournisseur du produit existe déjà.';

  @override
  String get product_fetch_not_found => 'Produit introuvable.';

  @override
  String get product_insert_failed => 'Échec de la création du produit.';

  @override
  String get product_update_failed => 'Échec de la mise à jour du produit.';

  @override
  String get product_delete_failed => 'Échec de la suppression du produit.';

  @override
  String get product_search_not_found => 'Aucun produit trouvé.';

  @override
  String get product_image_not_found => 'Image du produit introuvable.';

  @override
  String get supplier_not_exists => 'Fournisseur introuvable.';

  @override
  String get supplier_type_not_exists => 'Type de fournisseur introuvable.';

  @override
  String get supplier_fetch_not_found => 'Fournisseur introuvable.';

  @override
  String get supplier_insert_failed => 'Échec de la création du fournisseur.';

  @override
  String get supplier_update_failed => 'Échec de la mise à jour du fournisseur.';

  @override
  String get supplier_delete_failed => 'Échec de la suppression du fournisseur.';

  @override
  String get organisation_not_found => 'Organisation introuvable.';

  @override
  String get organisation_name_used => 'Le nom de l\'organisation est déjà utilisé.';

  @override
  String get org_already_exists => 'L\'organisation existe déjà.';

  @override
  String get org_insert_failed => 'Échec de la création de l\'organisation.';

  @override
  String get org_update_failed => 'Échec de la mise à jour de l\'organisation.';

  @override
  String get org_delete_failed => 'Échec de la suppression de l\'organisation.';

  @override
  String get ingredient_not_exists => 'Ingrédient introuvable.';

  @override
  String get ingredient_already_exists => 'L\'ingrédient existe déjà.';

  @override
  String get ingredient_insert_failed => 'Échec de la création de l\'ingrédient.';

  @override
  String get ingredient_update_failed => 'Échec de la mise à jour de l\'ingrédient.';

  @override
  String get ingredient_delete_failed => 'Échec de la suppression de l\'ingrédient.';

  @override
  String get order_not_exists => 'Commande introuvable.';

  @override
  String get order_fetch_not_found => 'Commande introuvable.';

  @override
  String get order_insert_failed => 'Échec de la création de la commande.';

  @override
  String get order_insert_conflict => 'Impossible de créer la commande en raison d\'un conflit.';

  @override
  String get order_update_failed => 'Échec de la mise à jour de la commande.';

  @override
  String get order_delete_failed => 'Échec de la suppression de la commande.';

  @override
  String get invalid_order_status => 'Changement de statut de commande invalide.';

  @override
  String get order_items_delete_failed => 'Échec de la suppression des articles de la commande.';

  @override
  String get order_item_insert_failed => 'Échec de l\'ajout d\'un article à la commande.';

  @override
  String get cart_not_exists => 'Panier introuvable.';

  @override
  String get cart_insert_failed => 'Échec de la création du panier.';

  @override
  String get delivery_not_exists => 'Livraison introuvable.';

  @override
  String get delivery_update_failed_label => 'Échec de la mise à jour de la livraison.';

  @override
  String get delivery_cannot_be_updated => 'La livraison ne peut pas être mise à jour dans son statut actuel.';

  @override
  String get delivery_bulk_update_failed => 'Échec de la mise à jour des livraisons.';

  @override
  String get delivery_delete_failed => 'Échec de la suppression de la livraison.';

  @override
  String get delivery_bulk_delete_failed => 'Échec de la suppression des livraisons.';

  @override
  String get delivery_insert_failed => 'Échec de la création de la livraison.';

  @override
  String get delivery_validation_failed => 'Informations de livraison invalides.';

  @override
  String get service_not_found => 'Service introuvable.';

  @override
  String get service_insert_conflict => 'Le service existe déjà.';

  @override
  String get service_category_not_found => 'Catégorie de service introuvable.';

  @override
  String get rule_already_exists => 'L\'affectation du personnel existe déjà.';

  @override
  String get rule_not_exists => 'Affectation du personnel introuvable.';

  @override
  String get rule_insert_failed => 'Échec de la création de l\'affectation du personnel.';

  @override
  String get rule_update_failed => 'Échec de la mise à jour de l\'affectation du personnel.';

  @override
  String get rule_delete_failed => 'Échec de la suppression de l\'affectation du personnel.';

  @override
  String get rule_invalid_status => 'Statut d\'affectation du personnel invalide.';

  @override
  String get notification_not_exists => 'Notification introuvable.';

  @override
  String get notification_already_exists => 'La notification existe déjà.';

  @override
  String get notification_insert_failed => 'Échec de la création de la notification.';

  @override
  String get notification_update_failed => 'Échec de la mise à jour de la notification.';

  @override
  String get notification_delete_failed => 'Échec de la suppression de la notification.';

  @override
  String get notification_bulk_insert_failed => 'Échec de la création des notifications.';

  @override
  String get location_not_exists => 'Emplacement introuvable.';

  @override
  String get location_update_failed => 'Échec de la mise à jour de l\'emplacement.';

  @override
  String get location_fetch_not_found => 'Emplacement introuvable.';

  @override
  String get location_insert_failed => 'Échec de la création de l\'emplacement.';

  @override
  String get location_delete_failed => 'Échec de la suppression de l\'emplacement.';

  @override
  String get address_not_found => 'Adresse introuvable.';

  @override
  String get payment_failed => 'Échec du traitement du paiement.';

  @override
  String get deposit_creation_failed => 'Échec de la création de l\'acompte.';

  @override
  String get image_insert_failed => 'Échec du téléchargement de l\'image.';

  @override
  String get image_update_failed => 'Échec de la mise à jour de l\'image.';

  @override
  String get failed => 'Échec de l\'opération.';

  @override
  String get not_found => 'Introuvable.';

  @override
  String get network_timeout => 'Délai réseau expiré. Vérifiez votre connexion.';

  @override
  String get validation_error => 'Veuillez vérifier votre saisie et réessayer.';

  @override
  String get rate_limited => 'Trop de requêtes. Veuillez patienter un instant.';

  @override
  String get permission_denied => 'Permission refusée.';

  @override
  String get client_not_exists => 'Client introuvable.';

  @override
  String get created_successfully => 'Créé avec succès !';

  @override
  String get bad_request => 'Requête invalide. Veuillez vérifier votre saisie.';

  @override
  String get unauthorized => 'Veuillez vous connecter pour continuer.';

  @override
  String get forbidden => 'Vous n\'avez pas la permission d\'accéder à cette ressource.';

  @override
  String get conflict => 'Conflit de ressources. Veuillez réessayer.';

  @override
  String get gone => 'Cette ressource n\'est plus disponible.';

  @override
  String get bad_gateway => 'Service temporairement indisponible. Veuillez réessayer plus tard.';

  @override
  String get service_unavailable => 'Le service est temporairement indisponible.';

  @override
  String get gateway_timeout => 'Délai de la requête expiré. Veuillez réessayer.';

  @override
  String get network_authentication_required => 'Authentification réseau requise.';

  @override
  String get no_response_data => 'Aucune donnée de réponse disponible.';

  @override
  String get noIngredientsFound => 'Aucun ingrédient trouvé';

  @override
  String get manageIngredients => 'Gérer les ingrédients';

  @override
  String get pleaseEnterAmount => 'Veuillez saisir la quantité';

  @override
  String get amountMustBeGreaterThanZero => 'La quantité doit être positive';

  @override
  String get returnBack => 'Retourner à l\'écran précédent';

  @override
  String get viewPendingInvitationsLabel => 'Voir les invitations en attente';

  @override
  String get invitations => 'Invitations';

  @override
  String get activeAssignments => 'Affectations actives';

  @override
  String get noActiveAssignments => 'Aucune affectation active';

  @override
  String get noActiveDescription => 'Vous n\'avez aucune affectation active.';

  @override
  String get noInvitationsOrAssignments => 'Aucune invitation ni affectation';

  @override
  String get noInvitationsDescription => 'Vous n\'avez aucune invitation en attente ni affectation active.';

  @override
  String get noPendingDescription => 'Vous n\'avez aucune invitation en attente.';

  @override
  String get loadingData => 'Chargement...';

  @override
  String get loadingInvitations => 'Chargement des invitations...';

  @override
  String get errorOccurredLabel => 'Erreur';

  @override
  String get pendingStatus => 'En attente';

  @override
  String get activeStatus => 'Actif';

  @override
  String get rejected => 'Refusé';

  @override
  String get expired => 'Expiré';

  @override
  String get roleCode => 'Code du rôle';

  @override
  String get expiry => 'Expiration';

  @override
  String get noExpiry => 'Sans expiration';

  @override
  String get expiredDate => 'Expiré';

  @override
  String get tomorrow => 'Demain';

  @override
  String inDays(int days) {
    return 'Dans $days jours';
  }

  @override
  String get invitationAcceptedSuccessfully => 'Invitation acceptée avec succès';

  @override
  String get invitationDeclinedSuccessfully => 'Invitation refusée avec succès';

  @override
  String get actionFailed => 'Échec de l\'action';

  @override
  String get noInvitationsFound => 'Aucune invitation trouvée';

  @override
  String get userNotAuthenticated => 'Utilisateur non authentifié';

  @override
  String get failedToLoadInvitations => 'Échec du chargement des invitations';

  @override
  String get markAllAsRead => 'Tout marquer comme lu';

  @override
  String get viewAll => 'Voir tout';

  @override
  String inStock(int stock) {
    return 'En stock : $stock';
  }

  @override
  String get addProductsToGetStarted => 'Ajoutez des produits pour commencer';

  @override
  String get addServicesToGetStarted => 'Ajoutez des services pour commencer';

  @override
  String selected(int count) {
    return 'Sélectionné : $count';
  }

  @override
  String available(int count) {
    return 'Disponible : $count';
  }

  @override
  String get accessible => 'accessible';

  @override
  String get searchBusinesses => 'Rechercher des entreprises...';

  @override
  String get noResults => 'Aucun résultat trouvé';

  @override
  String get noBusinesses => 'Aucune entreprise';

  @override
  String get owner => 'Propriétaire';

  @override
  String get manageAccessLabel => 'Gérer l\'accès';

  @override
  String privilegesFor(String userName) {
    return 'Privilèges pour $userName';
  }

  @override
  String get noPrivileges => 'Aucun privilège attribué.';

  @override
  String get addBusiness => 'Ajouter une entreprise';

  @override
  String get refreshSuccess => 'Données actualisées avec succès';

  @override
  String get searchAndInvite => 'Rechercher et inviter';

  @override
  String findUsersToAddTo(String supplierName) {
    return 'Trouver des utilisateurs à ajouter à $supplierName';
  }

  @override
  String get searchByNameUsernameOrRole => 'Rechercher par nom, nom d\'utilisateur ou rôle...';

  @override
  String get searchForUsers => 'Rechercher des utilisateurs';

  @override
  String get enterNameUsernameOrRole => 'Saisissez un nom, nom d\'utilisateur ou rôle pour trouver des personnes';

  @override
  String get currentTeam => 'Équipe actuelle';

  @override
  String get noUsersFound => 'Aucun utilisateur trouvé';

  @override
  String get tryAdjustingSearchTerms => 'Essayez d\'ajuster vos termes de recherche';

  @override
  String get results => 'Résultats';

  @override
  String get team => 'Équipe';

  @override
  String get userAlreadyInTeam => 'Utilisateur déjà dans l\'équipe';

  @override
  String isAlreadyActiveMemberOf(String supplierName) {
    return 'est déjà un membre actif de $supplierName';
  }

  @override
  String get pendingInvitation => 'Invitation en attente';

  @override
  String hasPendingInvitationFor(String supplierName) {
    return 'a une invitation en attente pour $supplierName';
  }

  @override
  String get admin => 'Administrateur';

  @override
  String get provider => 'Fournisseur';

  @override
  String get manager => 'Gestionnaire';

  @override
  String get staff => 'Personnel';

  @override
  String get loadingDashboard => 'Chargement du tableau de bord...';

  @override
  String get noOrganisationsAvailable => 'Aucune organisation disponible.';

  @override
  String get noSuppliersInOrganisation => 'Aucun fournisseur dans cette organisation';

  @override
  String get pendingInvitationsTooltip => 'Invitations en attente';

  @override
  String get createNewOrderLabel => 'Créer une nouvelle commande';

  @override
  String get createNewInvoiceLabel => 'Créer une nouvelle facture';

  @override
  String get back => 'Retour';

  @override
  String get cancelInvitationLabel => 'Annuler l\'invitation';

  @override
  String get noPendingInvitation => 'Aucune invitation en attente trouvée';

  @override
  String areYouSureYouWantToCancelTheInvitationFor(String userName) {
    return 'Êtes-vous sûr de vouloir annuler l\'invitation pour $userName ?';
  }

  @override
  String get invitationCancelledSuccessfully => 'Invitation annulée avec succès';

  @override
  String get failedToCancelInvitation => 'Échec de l\'annulation de l\'invitation';

  @override
  String get activePrivileges => 'Privilèges actifs';

  @override
  String get pendingPrivileges => 'Privilèges en attente';

  @override
  String expiresOn(String date) {
    return 'Expire le $date';
  }

  @override
  String get manage => 'Gérer';

  @override
  String get canManage => 'Peut gérer';

  @override
  String get canView => 'Peut voir';

  @override
  String get failedToProcessInvitation => 'Échec du traitement de l\'invitation';

  @override
  String get documents => 'documents';

  @override
  String get search => 'Rechercher';

  @override
  String get addDocumentLabel => 'Ajouter un document';

  @override
  String get searchDocumentsLabel => 'Rechercher des documents';

  @override
  String get searchByNumberOrCustomerLabel => 'Rechercher par numéro ou client';

  @override
  String get payRemainingLabel => 'Payer le restant';

  @override
  String get paymentOutstandingLabel => 'En suspens';

  @override
  String paymentRemainingAfter(String amount) {
    return '$amount restant après ce paiement';
  }

  @override
  String get paymentSettlesFull => 'Cela solde le montant total';

  @override
  String get paymentAmountLabel => 'Montant';

  @override
  String get paymentMethodLabel => 'Méthode';

  @override
  String get paymentNotesLabel => 'Notes';

  @override
  String get paymentNotesHint => 'Facultatif';

  @override
  String get productsLabel => 'produits';

  @override
  String paymentSubmitButton(String amount) {
    return 'Payer $amount';
  }

  @override
  String get paymentMethodCash => 'Espèces';

  @override
  String get paymentMethodCard => 'Carte';

  @override
  String get paymentMethodBankTransfer => 'Virement bancaire';

  @override
  String get paymentMethodMobileMoney => 'Argent mobile';

  @override
  String get paymentErrorEnterAmount => 'Saisissez un montant';

  @override
  String get paymentErrorInvalidNumber => 'Saisissez un nombre valide';

  @override
  String get paymentErrorMustBePositive => 'Le montant doit être supérieur à zéro';

  @override
  String paymentErrorExceedsDue(String amount) {
    return 'Le montant ne peut pas dépasser $amount';
  }

  @override
  String get paymentSuccessTitle => 'Paiement enregistré';

  @override
  String paymentSuccessBody(String amount, String method) {
    return '$amount payé via $method.';
  }

  @override
  String get paymentQuickAmounts => 'Montants rapides';

  @override
  String get paymentFullAmount => 'Montant total';

  @override
  String get loadAnalyticsData => 'Charger les données analytiques';

  @override
  String get collectionRate => 'Taux de recouvrement';

  @override
  String get totalTransactions => 'Total des transactions';

  @override
  String get totalCollected => 'Total encaissé';

  @override
  String get chooseSupplierHint => 'Choisissez l\'entreprise que vous souhaitez gérer';

  @override
  String get noOrganisation => 'Aucune organisation';

  @override
  String get totalOutstanding => 'Total en suspens';

  @override
  String get unnamedProduct => 'Produit sans nom';

  @override
  String get quantityLabel => 'Quantité';

  @override
  String get itemsLabel => 'articles';

  @override
  String get increaseQuantity => 'Augmenter la quantité';

  @override
  String get decreaseQuantity => 'Diminuer la quantité';

  @override
  String maxAvailable(int count) {
    return 'Max disponible : $count';
  }

  @override
  String get priceLabel => 'Prix';

  @override
  String get defaultPrice => 'Prix par défaut';

  @override
  String get customPrice => 'Prix personnalisé';

  @override
  String get resetToDefault => 'Réinitialiser au prix par défaut';

  @override
  String get customPriceApplied => 'Prix personnalisé appliqué';

  @override
  String get customPriceAboveCatalog => 'Le prix personnalisé est supérieur au prix par défaut — aucune remise appliquée';

  @override
  String discountPreview(String amount, String percent) {
    return '$amount de réduction ($percent%)';
  }

  @override
  String get notesLabel => 'Notes';

  @override
  String get addNotesHint => 'Ajouter des notes...';

  @override
  String get totalLabel => 'Total';

  @override
  String qtyTimesPrice(int qty, String price) {
    return '$qty × $price';
  }

  @override
  String get removeLabel => 'Supprimer';

  @override
  String get updateLabel => 'Mettre à jour';

  @override
  String get addToCartLabel => 'Ajouter au panier';

  @override
  String deliveryDetailTitleWithId(int id) {
    return 'Livraison n°$id';
  }

  @override
  String get deliveryDetailRefreshTooltip => 'Actualiser';

  @override
  String get deliveryDetailEditTooltip => 'Modifier';

  @override
  String get deliveryDetailRefreshing => 'Actualisation…';

  @override
  String get deliveryDetailCopiedToClipboard => 'Copié';

  @override
  String get deliveryDetailSectionItems => 'Articles';

  @override
  String deliveryDetailSectionItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get deliveryDetailSectionDestination => 'Destination';

  @override
  String get deliveryDetailSectionProvider => 'Fournisseur';

  @override
  String get deliveryDetailSectionShipping => 'Expédition';

  @override
  String get deliveryDetailSectionInvoice => 'Facture';

  @override
  String get deliveryDetailSectionMetadata => 'Métadonnées';

  @override
  String get deliveryDetailUpdatedJustNow => 'Mis à jour à l\'instant';

  @override
  String deliveryDetailUpdatedMinutesAgo(int count) {
    return 'Mis à jour il y a $count min';
  }

  @override
  String deliveryDetailUpdatedHoursAgo(int count) {
    return 'Mis à jour il y a $count h';
  }

  @override
  String deliveryDetailUpdatedDaysAgo(int count) {
    return 'Mis à jour il y a $count j';
  }

  @override
  String deliveryDetailUpdatedOnDate(int day, int month, int year) {
    return 'Mis à jour le $day/$month/$year';
  }

  @override
  String get deliveryDetailEmptyItems => 'Aucun article pour ce fournisseur';

  @override
  String get deliveryDetailEmptyDestination => 'Aucun détail de destination';

  @override
  String get deliveryDetailEmptyProvider => 'Aucun détail du fournisseur';

  @override
  String get deliveryDetailEmptyShipping => 'Aucun détail d\'expédition';

  @override
  String get deliveryDetailEmptyInvoice => 'Aucun détail de facture';

  @override
  String get deliveryDetailEmptyMetadata => 'Aucune métadonnée disponible';

  @override
  String deliveryDetailItemQuantityLabel(int count) {
    return '$count×';
  }

  @override
  String deliveryDetailProductFallback(int id) {
    return 'Produit n°$id';
  }

  @override
  String deliveryDetailItemSubline(String brand, String barcode, int productId) {
    return '$brand · $barcode · n°$productId';
  }

  @override
  String deliveryDetailItemUnitLine(String price, String unit, String vat) {
    return '$price DA l\'unité · par $unit · TVA $vat%';
  }

  @override
  String get deliveryDetailItemDelivered => 'Livré';

  @override
  String get deliveryDetailTotalsSubtotal => 'Sous-total';

  @override
  String get deliveryDetailTotalsDiscount => 'Remise';

  @override
  String get deliveryDetailTotalsTotal => 'Total';

  @override
  String deliveryDetailDiscountValue(String amount) {
    return '− $amount DA';
  }

  @override
  String deliveryDetailPriceWithCurrency(String price) {
    return '$price DA';
  }

  @override
  String get deliveryDetailFieldAddress => 'Adresse';

  @override
  String get deliveryDetailFieldStreet => 'Rue';

  @override
  String get deliveryDetailFieldCity => 'Ville';

  @override
  String get deliveryDetailFieldPostalCode => 'Code postal';

  @override
  String get deliveryDetailFieldCountry => 'Pays';

  @override
  String get deliveryDetailFieldRecipient => 'Destinataire';

  @override
  String get deliveryDetailFieldName => 'Nom';

  @override
  String get deliveryDetailFieldOrganisation => 'Organisation';

  @override
  String get deliveryDetailFieldProviderId => 'ID fournisseur';

  @override
  String get deliveryDetailFieldMethod => 'Méthode';

  @override
  String get deliveryDetailFieldPackages => 'Colis';

  @override
  String get deliveryDetailFieldTotalWeight => 'Poids total';

  @override
  String get deliveryDetailFieldDimensions => 'Dimensions';

  @override
  String get deliveryDetailFieldGoods => 'Marchandises';

  @override
  String get deliveryDetailFieldHsCode => 'Code SH';

  @override
  String get deliveryDetailFieldMerchant => 'Marchand';

  @override
  String get deliveryDetailFieldInstructions => 'Instructions';

  @override
  String get deliveryDetailFieldFee => 'Frais';

  @override
  String get deliveryDetailFieldInvoiceNumber => 'Numéro';

  @override
  String get deliveryDetailFieldInvoiceType => 'Type';

  @override
  String get deliveryDetailFieldInvoiceStatus => 'Statut';

  @override
  String get deliveryDetailFieldStatus => 'Statut';

  @override
  String get deliveryDetailFieldInvoiceTotal => 'Total';

  @override
  String get deliveryDetailFieldInvoiceIssueDate => 'Date d\'émission';

  @override
  String get deliveryDetailFieldInvoiceDueDate => 'Date d\'échéance';

  @override
  String get deliveryDetailFieldInvoiceTaxApplied => 'Taxe appliquée';

  @override
  String get deliveryDetailFieldInvoiceNotes => 'Notes';

  @override
  String get deliveryDetailFieldCreated => 'Créé';

  @override
  String get deliveryDetailFieldUpdated => 'Mis à jour';

  @override
  String get deliveryDetailFieldDeliveryId => 'ID livraison';

  @override
  String get deliveryDetailFieldBrokerId => 'ID courtier';

  @override
  String get deliveryDetailFieldInvoiceRef => 'Réf. facture';

  @override
  String get deliveryDetailFieldSourceType => 'Type de source';

  @override
  String get deliveryDetailFieldSourceId => 'ID source';

  @override
  String get deliveryDetailFieldAddressId => 'ID adresse';

  @override
  String get deliveryDetailFieldCurrentAddressId => 'ID adresse actuelle';

  @override
  String get deliveryDetailFieldItemCount => 'Articles';

  @override
  String deliveryDetailFieldBrokerEntry(String key) {
    return 'Courtier $key';
  }

  @override
  String deliveryDetailPersonWithId(int id) {
    return 'Personne n°$id';
  }

  @override
  String deliveryDetailProviderWithId(int id) {
    return 'Fournisseur n°$id';
  }

  @override
  String deliveryDetailIdValue(int id) {
    return 'n°$id';
  }

  @override
  String deliveryDetailPackageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colis',
      one: '1 colis',
    );
    return '$_temp0';
  }

  @override
  String deliveryDetailWeightKg(String weight) {
    return '$weight kg';
  }

  @override
  String deliveryDetailPercentValue(int value) {
    return '$value%';
  }

  @override
  String get deliveryDetailActionCancel => 'Annuler';

  @override
  String get deliveryDetailActionValidate => 'Valider la commande';

  @override
  String get deliveryDetailCancelDialogTitle => 'Annuler cette livraison ?';

  @override
  String deliveryDetailCancelDialogBody(int id) {
    return 'La livraison n°$id sera marquée comme annulée. Cette action est irréversible.';
  }

  @override
  String get deliveryDetailCancelDialogKeep => 'Conserver';

  @override
  String get deliveryDetailCancelDialogConfirm => 'Annuler la livraison';

  @override
  String get deliveryDetailCancelSuccess => 'Livraison annulée';

  @override
  String get deliveryDetailCancelFailure => 'Échec de l\'annulation';

  @override
  String get deliveryDetailValidateTitle => 'Confirmer la livraison';

  @override
  String get deliveryDetailValidateSubtitle => 'Vérifiez les détails ci-dessous avant de marquer comme terminée.';

  @override
  String get deliveryDetailValidateBack => 'Retour';

  @override
  String get deliveryDetailValidateConfirm => 'Valider';

  @override
  String deliveryDetailValidateSuccess(int id) {
    return 'Livraison n°$id validée';
  }

  @override
  String get deliveryDetailValidateFailure => 'Échec de la mise à jour de la livraison';

  @override
  String get deliveryStatusPending => 'En attente';

  @override
  String get deliveryStatusProcessing => 'En cours de traitement';

  @override
  String get deliveryStatusConfirmed => 'Confirmée';

  @override
  String get deliveryStatusReadyForPickup => 'Prête pour le retrait';

  @override
  String get deliveryStatusInTransit => 'En transit';

  @override
  String get deliveryStatusOutForDelivery => 'En cours de livraison';

  @override
  String get deliveryStatusDelivered => 'Livrée';

  @override
  String get deliveryStatusFailed => 'Échouée';

  @override
  String get deliveryStatusCancelled => 'Annulée';

  @override
  String get deliveryStatusReturned => 'Retournée';

  @override
  String get deliveryStatusRefunded => 'Remboursée';

  @override
  String get deliveryStatusUnknown => 'Inconnu';

  @override
  String get deliveryStatusShipped => 'Expédiée';

  @override
  String get shippingMethodStandard => 'Livraison standard';

  @override
  String get shippingMethodExpress => 'Livraison express';

  @override
  String get shippingMethodOvernight => 'Livraison de nuit';

  @override
  String get shippingMethodFreight => 'Expédition par fret';

  @override
  String get shippingMethodPickup => 'Retrait';

  @override
  String get shippingMethodCourier => 'Coursier';

  @override
  String get shippingMethodSameDay => 'Le jour même';

  @override
  String get shippingMethodInternational => 'International';

  @override
  String get invoiceTypeInvoice => 'Facture';

  @override
  String get invoiceTypeReceipt => 'Reçu';

  @override
  String get invoiceTypeProforma => 'Proforma';

  @override
  String get invoiceStatusUnpaidLabel => 'Impayée';

  @override
  String get invoiceStatusPaidLabel => 'Payée';

  @override
  String get invoiceStatusCanceledLabel => 'Annulée';

  @override
  String get invoiceStatusPartiallyPaidLabel => 'Partiellement payée';

  @override
  String get invoiceStatusOverdueLabel => 'En retard';

  @override
  String get invoiceStatusRefundedLabel => 'Remboursée';

  @override
  String get deliveryCardNoDestination => 'Aucune destination';

  @override
  String get deliveryCardLoadFailed => 'Impossible de charger les détails de la livraison';

  @override
  String get deliveryDetailSectionCustomer => 'Client';

  @override
  String get deliveryDetailFieldUsername => 'Nom d\'utilisateur';

  @override
  String get deliveryDetailFieldEmail => 'E-mail';

  @override
  String get deliveryDetailFieldUserType => 'Type d\'utilisateur';

  @override
  String get deliveryDetailFieldPhone => 'Téléphone';

  @override
  String get deliveryDetailFieldUserId => 'ID utilisateur';

  @override
  String get deliveryDetailActionAccept => 'Accepter';

  @override
  String get deliveryDetailActionConfirm => 'Confirmer';

  @override
  String get deliveryDetailActionShip => 'Expédier';

  @override
  String get deliveryDetailActionInTransit => 'Marquer en transit';

  @override
  String get deliveryDetailActionOutForDelivery => 'En cours de livraison';

  @override
  String get deliveryDetailActionDeliver => 'Livrer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonClear => 'Effacer';

  @override
  String get deliveryDetailsTitle => 'Détails de la livraison';

  @override
  String get deliveryDetailsSectionProducts => 'Produits';

  @override
  String get deliveryDetailsSectionPackages => 'Détails du colis';

  @override
  String get deliveryDetailsSectionShipping => 'Informations d\'expédition';

  @override
  String get deliveryDetailsSectionAdditional => 'Informations supplémentaires';

  @override
  String get deliveryDetailsProductSearchHint => 'Rechercher par nom, marque ou code-barres';

  @override
  String deliveryDetailsProductFallback(int id) {
    return 'Produit n°$id';
  }

  @override
  String deliveryDetailsProductsSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count produits sélectionnés',
      one: '1 produit sélectionné',
    );
    return '$_temp0';
  }

  @override
  String deliveryDetailsStockIn(int count) {
    return '$count en stock';
  }

  @override
  String get deliveryDetailsStockOut => 'En rupture de stock';

  @override
  String get deliveryDetailsNoProducts => 'Cette livraison n\'a aucun produit associé.';

  @override
  String deliveryDetailsNoMatches(String query) {
    return 'Aucun produit ne correspond à « $query ».';
  }

  @override
  String get deliveryDetailsDimensionLength => 'Longueur';

  @override
  String get deliveryDetailsDimensionWidth => 'Largeur';

  @override
  String get deliveryDetailsDimensionHeight => 'Hauteur';

  @override
  String deliveryDetailsPackageWeightLabel(int index) {
    return 'Poids du colis $index (kg)';
  }

  @override
  String get deliveryDetailsRemovePackage => 'Supprimer le colis';

  @override
  String get deliveryDetailsAddPackage => 'Ajouter un colis';

  @override
  String deliveryDetailsPackageSummary(int count, String weight) {
    return 'Nombre de colis : $count   Poids total : $weight kg';
  }

  @override
  String get deliveryDetailsFeeLabel => 'Frais de livraison (DA)';

  @override
  String get deliveryDetailsFeeHelper => 'Montant que le client paie au transporteur';

  @override
  String get deliveryDetailsShippingMethodLabel => 'Mode d\'expédition';

  @override
  String get deliveryDetailsHsCodeLabel => 'Code SH';

  @override
  String get deliveryDetailsMerchantLabel => 'Nom du marchand';

  @override
  String get deliveryDetailsGoodsLabel => 'Description des marchandises';

  @override
  String get deliveryDetailsInstructionsLabel => 'Instructions spéciales';

  @override
  String get deliveryDetailsSaveButton => 'Enregistrer les modifications';

  @override
  String get deliveryDetailsSaveFailed => 'Échec de l\'enregistrement des détails';

  @override
  String deliveryDetailsSaveError(String message) {
    return 'Erreur : $message';
  }

  @override
  String get deliveryDetailsValidationEnterWeight => 'Saisir le poids';

  @override
  String get deliveryDetailsValidationRequired => 'Requis';

  @override
  String get deliveryDetailsValidationEnterAmount => 'Saisir un montant valide';

  @override
  String get deliveryDetailsValidationFeeNegative => 'Les frais ne peuvent pas être négatifs';

  @override
  String get deliveryActionAccept => 'Accepter';

  @override
  String get deliveryActionConfirm => 'Confirmer';

  @override
  String get deliveryActionShip => 'Expédier';

  @override
  String get deliveryActionInTransit => 'Marquer en transit';

  @override
  String get deliveryActionOutForDelivery => 'En cours de livraison';

  @override
  String get deliveryActionDeliver => 'Livrer';

  @override
  String get deliveryActionFail => 'Signaler un échec';

  @override
  String get deliveryActionCancel => 'Annuler la livraison';

  @override
  String get deliveryActionReturn => 'Marquer comme retournée';

  @override
  String get deliveryActionRefund => 'Rembourser';

  @override
  String deliveryTransitionDeliveryId(int id) {
    return 'Livraison n°$id';
  }

  @override
  String get deliveryTransitionReady => 'Prêt à continuer';

  @override
  String get deliveryTransitionMissing => 'Exigences manquantes';

  @override
  String deliveryTransitionMissingHint(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Complétez les $count éléments manquants pour continuer.',
      one: 'Complétez l\'élément manquant pour continuer.',
    );
    return '$_temp0';
  }

  @override
  String get deliveryTransitionWorking => 'En cours…';

  @override
  String deliveryTransitionCommit(String verb) {
    return '$verb la livraison';
  }

  @override
  String deliveryTransitionSuccess(String verb) {
    return '$verb réussi';
  }

  @override
  String deliveryTransitionFailure(String verb) {
    return '$verb échoué';
  }

  @override
  String get deliveryTransitionFix => 'Corriger';

  @override
  String get deliveryTransitionReqRecipient => 'Destinataire spécifié';

  @override
  String get deliveryTransitionReqRecipientDesc => 'La livraison a besoin d\'un destinataire ou d\'une adresse de destination.';

  @override
  String get deliveryTransitionReqPackages => 'Au moins un colis';

  @override
  String get deliveryTransitionReqPackagesDesc => 'Déclarez les colis et le poids avant de confirmer.';

  @override
  String get deliveryTransitionReqProvider => 'Fournisseur assigné';

  @override
  String get deliveryTransitionReqCarrierAccepted => 'Transporteur a accepté la remise';

  @override
  String get deliveryTransitionReqCarrierAcceptedDesc => 'Cela enregistre que le transporteur a pris la garde physique.';

  @override
  String get deliveryTransitionReqTracking => 'Le suivi du transporteur montre un mouvement';

  @override
  String get deliveryTransitionReqTrackingDesc => 'Cela enregistre que le transporteur signale que les marchandises sont en mouvement.';

  @override
  String get deliveryTransitionReqDestination => 'Adresse de destination au dossier';

  @override
  String get deliveryTransitionReqProof => 'Preuve de livraison capturée';

  @override
  String get deliveryTransitionReqProofDesc => 'Signature, photo ou scan reçu du destinataire.';

  @override
  String get sourceDistribution => 'Répartition des sources';

  @override
  String get noDataAvailable => 'Aucune donnée disponible';

  @override
  String get productQuantifierTxt => 'Quantificateur';

  @override
  String get productOriginTxt => 'Origine';

  @override
  String get productHiddenLabel => 'Masqué';

  @override
  String get deleteProductTitle => 'Supprimer le produit ?';

  @override
  String deleteProductConfirmation(String productName) {
    return 'La suppression de « $productName » le retire du catalogue. Les commandes qui y font référence conservent leur enregistrement historique.';
  }

  @override
  String get thisProductFallback => 'ce produit';

  @override
  String get cancelButton => 'Annuler';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get productDeletedMessage => 'Produit supprimé';

  @override
  String get productDeleteFailedMessage => 'Échec de la suppression du produit';

  @override
  String get productNowVisibleMessage => 'Le produit est maintenant visible';

  @override
  String get productNowHiddenMessage => 'Le produit est maintenant masqué';

  @override
  String get productVisibilityUpdateFailedMessage => 'Échec de la mise à jour de la visibilité';

  @override
  String get editorModeBadge => 'Mode éditeur';

  @override
  String get pricingSectionTitle => 'Tarification';

  @override
  String get basePriceLabel => 'Prix de base';

  @override
  String get basePriceCaption => 'Coût fournisseur';

  @override
  String get finalPriceCaption => 'Le client paie';

  @override
  String get marginLabel => 'Marge';

  @override
  String get marginPercentLabel => 'Marge %';

  @override
  String get setBasePriceHint => 'Définissez un prix de base pour voir la marge et le ROI';

  @override
  String get hideAction => 'Masquer';

  @override
  String get showAction => 'Afficher';

  @override
  String get stockSectionTitle => 'Stock';

  @override
  String get inStockLabel => 'En stock';

  @override
  String get outOfStockLabel => 'En rupture de stock';

  @override
  String get stockTotalLabel => 'Total';

  @override
  String get stockReservedLabel => 'Réservé';

  @override
  String get stockAvailableLabel => 'Disponible';

  @override
  String get metadataSectionTitle => 'Métadonnées du produit';

  @override
  String get metaIdLabel => 'ID';

  @override
  String get metaCategoryLabel => 'Catégorie';

  @override
  String get metaBarcodeLabel => 'Code-barres';

  @override
  String get metaUnitLabel => 'Unité';

  @override
  String get metaProviderLabel => 'Fournisseur';

  @override
  String get metaOwnerLabel => 'Propriétaire';

  @override
  String get metaOriginLabel => 'Origine';

  @override
  String get visibilityVisibleLabel => 'Visible';

  @override
  String get visibilityHiddenLabel => 'Masqué';

  @override
  String get dangerZoneTitle => 'Zone de danger';

  @override
  String get dangerZoneBody => 'La suppression d\'un produit le retire du catalogue. Les commandes qui y font référence conservent leur enregistrement historique.';

  @override
  String get productVisibilityTitle => 'Visibilité';

  @override
  String get editServiceTitle => 'Modifier le service';

  @override
  String get createServiceTitle => 'Créer un service';

  @override
  String get basicInformationSection => 'Informations de base';

  @override
  String get pricingSection => 'Tarification';

  @override
  String get pricingConfigurationSection => 'Configuration tarifaire';

  @override
  String get resourceRequirementsSection => 'Besoins en ressources';

  @override
  String get staffRequirementsSection => 'Besoins en personnel';

  @override
  String get costSummarySection => 'Résumé des coûts';

  @override
  String get serviceNameLabel => 'Nom du service';

  @override
  String get serviceNameHint => 'Saisir le nom du service';

  @override
  String get serviceNameRequiredField => 'Le nom du service est requis';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get descriptionHint => 'Saisir la description';

  @override
  String get durationLabel => 'Durée (minutes)';

  @override
  String get durationHint => 'Saisir la durée';

  @override
  String get durationInvalid => 'Saisir une durée valide';

  @override
  String get minutesSuffix => 'min';

  @override
  String get ageGroupLabel => 'Groupe d\'âge';

  @override
  String get ageGroupHint => 'Saisir le groupe d\'âge';

  @override
  String get sampleTypeLabel => 'Type d\'échantillon';

  @override
  String get sampleTypeHint => 'Saisir le type d\'échantillon';

  @override
  String get specialistConsultationLabel => 'Consultation spécialisée';

  @override
  String get governmentFundedLabel => 'Financé par le gouvernement';

  @override
  String get consultationIncludedLabel => 'Consultation incluse';

  @override
  String get digitalImagingLabel => 'Imagerie numérique';

  @override
  String get materialOptionsLabel => 'Options de matériaux';

  @override
  String get includesLabel => 'Inclut';

  @override
  String roleFallback(int roleId) {
    return 'Rôle n°$roleId';
  }

  @override
  String get validationProviderRequired => 'Un fournisseur valide est requis';

  @override
  String get validationCategoryRequired => 'Une catégorie valide est requise';

  @override
  String get validationDurationPositive => 'La durée doit être supérieure à zéro';

  @override
  String get validationBasePricePositive => 'Le prix de base doit être supérieur à zéro';

  @override
  String get validationFinalPricePositive => 'Le prix final doit être supérieur à zéro';

  @override
  String get validationFinalPriceExceedsBase => 'Le prix final ne peut pas être supérieur au prix de base';

  @override
  String unexpectedErrorWithDetail(String detail) {
    return 'Une erreur inattendue s\'est produite : $detail';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '1 heure',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String durationHoursOnly(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours heures',
      one: '1 heure',
    );
    return '$_temp0';
  }

  @override
  String durationMinutesOnly(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get durationPlaceholder => '—';

  @override
  String get glutenFreeLabel => 'Sans gluten';

  @override
  String get containsGlutenLabel => 'Contient du gluten';

  @override
  String get mayContainGlutenLabel => 'Peut contenir du gluten';

  @override
  String get importedFromAi => 'Importé par IA';

  @override
  String importedFromSource(String source) {
    return 'Importé de $source';
  }

  @override
  String get metaImportedBrandLabel => 'Marque importée';

  @override
  String get metaImportSourceLabel => 'Source d\'importation';

  @override
  String get metaImportConfidenceLabel => 'Confiance de l\'importation';

  @override
  String get expiresLabel => 'Expire';

  @override
  String get failedToLoadProducts => 'Échec du chargement des produits';

  @override
  String get retryButton => 'Réessayer';

  @override
  String get deleteTooltip => 'Supprimer le fournisseur';

  @override
  String get editTooltip => 'Modifier le fournisseur';

  @override
  String get modulePersonnel => 'Personnel';

  @override
  String get moduleInventory => 'Inventaire';

  @override
  String get moduleServices => 'Services';

  @override
  String get moduleSeller => 'Vendeur';

  @override
  String get moduleOrders => 'Commandes';

  @override
  String get moduleOperations => 'Opérations';

  @override
  String get moduleFinance => 'Finance';

  @override
  String get failedToLoadSuppliers => 'Échec du chargement des fournisseurs';

  @override
  String get grandTotalLabel => 'Total général';

  @override
  String get paidLabel => 'Payé';

  @override
  String get dueLabel => 'Dû';

  @override
  String get roiLabel => 'ROI';

  @override
  String get discountLabel => 'Remise';

  @override
  String get taxLabel => 'Taxe';

  @override
  String get deliveryLabel => 'Livraison';

  @override
  String get productSubtotalLabel => 'Sous-total produits';

  @override
  String get serviceSubtotalLabel => 'Sous-total services';

  @override
  String get grossSubtotalLabel => 'Sous-total brut';

  @override
  String get totalCostLabel => 'Coût total';

  @override
  String get commercialBreakdownTitle => 'Répartition commerciale';

  @override
  String get profitabilityTitle => 'Rentabilité';

  @override
  String get itemsTitle => 'Articles';

  @override
  String get servicesTitle => 'Services';

  @override
  String get cartDetailsTitle => 'Détails du panier';

  @override
  String get cartIdLabel => 'ID panier';

  @override
  String get deliveryIdLabel => 'ID livraison';

  @override
  String get deliveryMethodLabel => 'Méthode';

  @override
  String get deliveryFeeLabel => 'Frais';

  @override
  String get metaOperationLabel => 'Opération';

  @override
  String get metaCreatedLabel => 'Créé';

  @override
  String get metaStatusLabel => 'Statut';

  @override
  String get vatLabel => 'TVA';

  @override
  String get invoiceStatusPartiallyPaidValue => 'Partiellement payée';

  @override
  String get invoiceStatusCanceledValue => 'Annulée';

  @override
  String get itemStatusDelivered => 'Livré';

  @override
  String get itemStatusProcessing => 'En cours de traitement';

  @override
  String get itemStatusPending => 'En attente';

  @override
  String get itemStatusCancelled => 'Annulé';

  @override
  String get itemStatusReturned => 'Retourné';

  @override
  String get itemStatusPartial => 'Partiel';

  @override
  String get serviceStatusCompleted => 'Terminé';

  @override
  String get serviceStatusScheduled => 'Planifié';

  @override
  String get serviceStatusInProgress => 'En cours';

  @override
  String get serviceStatusProcessing => 'En cours de traitement';

  @override
  String get serviceStatusPending => 'En attente';

  @override
  String get serviceStatusCancelled => 'Annulé';

  @override
  String get serviceStatusNoShow => 'Non présenté';

  @override
  String get costSegmentProducts => 'Produits';

  @override
  String get costSegmentConsumables => 'Consommables';

  @override
  String get costSegmentAmortized => 'Amorti';

  @override
  String get costSegmentLabor => 'Main-d\'œuvre';

  @override
  String get costSegmentDelivery => 'Livraison';

  @override
  String get resourceKindConsumable => 'consommable';

  @override
  String get resourceKindAmortized => 'amorti';

  @override
  String get resourceFallbackName => 'Ressource';

  @override
  String productFallbackName(String id) {
    return 'Produit n°$id';
  }

  @override
  String serviceFallbackName(String id) {
    return 'Service n°$id';
  }

  @override
  String documentsCountLabel2(int count) {
    return '$count documents';
  }

  @override
  String get addDocumentTooltip => 'Ajouter un document';

  @override
  String customerLabelWithId(int id) {
    return 'Client $id';
  }

  @override
  String guestLabelWithId(int id) {
    return 'Invité n°$id';
  }

  @override
  String overdueDaysLabel(int days) {
    return '${days}j de retard';
  }

  @override
  String get filterByLocationTooltip => 'Filtrer par emplacement';

  @override
  String get expiresLabelSuffix => 'Expire';

  @override
  String get activeStatusLabel => 'Actif';

  @override
  String get pendingStatusLabel => 'En attente';

  @override
  String privilegeByCode(String code) {
    String _temp0 = intl.Intl.selectLogic(
      code,
      {
        '1': 'Administrateur',
        '2': 'Gérer le personnel',
        '3': 'Voir le personnel',
        '4': 'Gérer l\'inventaire',
        '5': 'Voir l\'inventaire',
        '6': 'Gérer les services',
        '7': 'Voir les services',
        '8': 'Gérer les commandes',
        '9': 'Voir les commandes',
        '10': 'Gérer la finance',
        '11': 'Voir la finance',
        '12': 'Gérer les opérations',
        '13': 'Voir les opérations',
        '14': 'Gérer le point de vente',
        '15': 'Voir le point de vente',
        'other': 'Privilège $code',
      },
    );
    return '$_temp0';
  }

  @override
  String get error => 'Erreur';

  @override
  String get refresh => 'Actualiser';

  @override
  String get cancel => 'Annuler';

  @override
  String get unknown => 'Inconnu';

  @override
  String get comingSoon => 'Bientôt disponible';

  @override
  String get owned => 'Possédé';

  @override
  String get managed => 'Géré';

  @override
  String get cookingChefText => 'Chef Cuisinier';

  @override
  String get serviceNameRequired => 'Le nom du service est requis';

  @override
  String get noResourcesAdded => 'Aucune ressource ajoutée';

  @override
  String get noStaffAdded => 'Aucun personnel ajouté';

  @override
  String get appPurposeContent => 'La mission de Verdelia est de rendre la vie sans gluten simple et sûre en connectant les personnes à des produits certifiés, des commerces locaux de confiance et des informations de santé claires.';

  @override
  String get feature3 => '📚 **Contenu éducatif** - Apprenez sur la maladie cœliaque, les ingrédients sûrs et la vie sans gluten.';

  @override
  String get recipedeletionConfirmationMessage => 'Êtes-vous sûr de vouloir supprimer cette recette ?';

  @override
  String get invoiceStatusPaid => 'Payée';

  @override
  String get invoiceStatusPartiallyPaid => 'Partiellement payée';

  @override
  String get invoiceStatusUnpaid => 'Impayée';

  @override
  String get invoiceStatusOverdue => 'En retard';

  @override
  String get invoiceStatusCanceled => 'Annulée';

  @override
  String get invoiceStatusRefunded => 'Remboursée';

  @override
  String get invoiceStatusUnknown => 'Inconnu';

  @override
  String documentsCount(int count) {
    return '$count documents';
  }

  @override
  String get addDocument => 'Ajouter un document';

  @override
  String get searchDocuments => 'Rechercher des documents';

  @override
  String get searchByNumberOrCustomer => 'Rechercher par numéro ou client';

  @override
  String get myDocuments => 'Mes documents';

  @override
  String get loadingFinancialDocuments => 'Chargement des documents financiers...';

  @override
  String get noMatchingDocuments => 'Aucun document correspondant';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get noDocumentsYet => 'Aucun document pour le moment';

  @override
  String get tryAdjustingFilters => 'Essayez d\'ajuster les filtres';

  @override
  String noDocumentsMatch(String query) {
    return 'Aucun document ne correspond à « $query »';
  }

  @override
  String get startCreatingFirstDocument => 'Commencez par créer votre premier document';

  @override
  String get loadMore => 'Charger plus';

  @override
  String get noMoreDocuments => 'Plus de documents';

  @override
  String customerWithId(String id) {
    return 'Client $id';
  }

  @override
  String guestWithId(String id) {
    return 'Invité n°$id';
  }

  @override
  String get guestLabel => 'Invité';

  @override
  String get canceled => 'Annulé';

  @override
  String get dueSoon => 'Bientôt dû';

  @override
  String get onTrack => 'Dans les temps';

  @override
  String get partialOverdue => 'Partiel / en retard';

  @override
  String overdueDays(String days) {
    return '${days}j de retard';
  }

  @override
  String get payRemaining => 'Payer le restant';

  @override
  String get payNow => 'Payer maintenant';

  @override
  String get recipe_not_exists => 'Recette introuvable.';

  @override
  String get recipe_update_failed => 'Échec de la mise à jour de la recette.';

  @override
  String get recipe_delete_failed => 'Échec de la suppression de la recette.';

  @override
  String get recipe_fetch_not_found => 'Recette introuvable.';

  @override
  String get recipe_category_not_exists => 'Catégorie de recette introuvable.';

  @override
  String get recipe_already_exists => 'La recette existe déjà.';

  @override
  String get recipe_insert_failed => 'Échec de la création de la recette.';

  @override
  String get recipe_image_not_found => 'Image de la recette introuvable.';

  @override
  String get recipe_search_not_found => 'Aucune recette trouvée.';

  @override
  String get delivery_update_failed => 'Échec de la mise à jour de la livraison.';
}
