import 'package:event/components/recipe/recipe_cache.dart';
import 'package:event/components/recipe/recipe_category.dart';
import 'package:event/components/recipe/recipe_crud.dart';
import 'package:event/components/recipe/recipe_fetch.dart';
import 'package:event/components/recipe/recipe_ingredient.dart';
import 'package:event/components/recipe/recipe_state.dart';
import 'package:event/components/recipe/recipe_user.dart';
import 'package:flutter/material.dart';
import 'package:app_constants/app_constants.dart';
import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'package:verdelia_core/business/Recipe.dart';
import 'package:verdelia_core/business/services/RecipeService.dart';
import 'package:verdelia_core/app/Services/UserService.dart';
import 'package:event/TraceableNotifier.dart';
import 'package:locator/locator.dart';

class RecipeNotifier extends TraceableNotifier {
  final RecipeService _recipeService = AppLocator.get<RecipeService>();
  final AppUserService _userService = AppLocator.get<AppUserService>();

  // Components
  late final RecipeState _state;
  late final RecipeCache _cache;
  late final RecipeCrud _crud;
  late final RecipeFetch _fetch;
  late final RecipeCategoryManager _categories;
  late final RecipeIngredientManager _ingredients;
  late final RecipeUserManager _users;

  RecipeNotifier() {
    _initComponents();
    _initialize();
  }

  void _initComponents() {
    _state = RecipeState();
    _cache = RecipeCache();
    _crud = RecipeCrud(
      service: _recipeService,
      state: _state,
      cache: _cache,
    );
    _fetch = RecipeFetch(
      service: _recipeService,
      state: _state,
      cache: _cache,
    );
    _categories = RecipeCategoryManager(
      service: _recipeService,
      state: _state,
    );
    _ingredients = RecipeIngredientManager(
      service: _recipeService,
      state: _state,
      cache: _cache,
    );
    _users = RecipeUserManager(
      userService: _userService,
      cache: _cache,
      state: _state,
    );
  }

  Future<void> _initialize() async {
    await _categories.fetchCategories();
    await _fetch.fetchRecipes(reset: true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _notify() {
    if (!_state.isLoading) {
      notifyListeners();
    }
  }

  // ============ PUBLIC GETTERS ============

  List<Recipe> get recipes => _state.recipeList;
  List<RecipeIngredient> get recipeIngredients => _state.ingredientList;
  List<String> get categories => _state.categories;
  List<AppUser> get users => _cache.users.values.toList();
  bool get isLoading => _state.isLoading;
  bool get hasMoreRecipes => _state.hasMoreRecipes;
  bool get hasMoreIngredients => _state.hasMoreIngredients;
  bool get userIsLoading => _users.isLoading;
  int get totalRecipeCount => _state.totalRecipeCount;
  int get totalIngredientCount => _state.totalIngredientCount;

  // ============ CATEGORY MANAGEMENT ============

  Future<void> fetchCategories({String? callerKey}) async {
    await _categories.fetchCategories(callerKey: callerKey);
    _notify();
  }

  set recipeCategories(List<String> value) {
    _state.categories = value;
    _notify();
  }

  // ============ RECIPE MANAGEMENT ============

  Future<bool> addOrUpdateRecipe(Recipe recipe, {String? callerKey}) async {
    final isNew = recipe.id_recipe == null || recipe.id_recipe == 0;
    final key = getCallerKey(
      isNew ? 'addRecipe' : 'updateRecipe',
      id: recipe.id_recipe?.toString(),
      suffix: recipe.recipe_name,
    );

    try {
      final result = await _crud.createOrUpdate(recipe, callerKey: key);
      if (result) {
        await _fetch.fetchRecipes(
          categoryId: _state.currentCategory,
          reset: true,
          callerKey: key,
        );
        _notify();
        storeSuccess(key, true);
      } else {
        storeFailure(key, null, code: 500, errorCode: 'OPERATION_FAILED');
      }
      return result;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to add/update recipe', error: e);
      return false;
    }
  }

  Future<void> fetchRecipes({
    int categoryId = 0,
    String searchQuery = "",
    bool reset = false,
    String? callerKey,
  }) async {
    final key = callerKey ??
        getCallerKey(
          'fetchRecipes',
          suffix: '${categoryId}_${searchQuery}_${_state.currentPage}',
        );

    try {
      await _fetch.fetchRecipes(
        categoryId: categoryId,
        searchQuery: searchQuery,
        reset: reset,
        callerKey: key,
      );
      _notify();
      storeSuccess(key, _state.recipeList);
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to fetch recipes', error: e);
    }
  }

  Future<void> loadMoreRecipes({String? callerKey}) async {
    await _fetch.loadMore(callerKey: callerKey);
    _notify();
  }

  Future<bool> deleteRecipe(int idRecipe, {String? callerKey}) async {
    final key =
        callerKey ?? getCallerKey('deleteRecipe', id: idRecipe.toString());

    try {
      final result = await _crud.delete(idRecipe, callerKey: key);
      if (result) {
        _notify();
        storeSuccess(key, true);
      } else {
        storeFailure(key, false, code: 500, errorCode: 'DELETE_FAILED');
      }
      return result;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to delete recipe', error: e);
      return false;
    }
  }

  // ============ LOCAL RECIPE OPERATIONS ============

  void addRecipeLocally(Recipe recipe) {
    _crud.addLocally(recipe);
    _notify();
  }

  void updateLocalRecipe(Recipe recipe) {
    _crud.updateLocally(recipe);
    _notify();
  }

  // ============ INGREDIENT MANAGEMENT ============

  Future<void> fetchIngredients({bool reset = false, String? callerKey}) async {
    final key = callerKey ??
        getCallerKey(
          'fetchIngredients',
          suffix: '${_state.currentIngredientPage}_$reset',
        );

    try {
      await _fetch.fetchIngredients(reset: reset, callerKey: key);
      _notify();
      storeSuccess(key, _state.ingredientList);
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to fetch ingredients', error: e);
    }
  }

  Future<void> loadMoreIngredients({String? callerKey}) async {
    await _fetch.loadMoreIngredients(callerKey: callerKey);
    _notify();
  }

  Future<bool> addIngredient(String name, String iconUrl,
      {String? callerKey}) async {
    final key = callerKey ?? getCallerKey('addIngredient', suffix: name);

    try {
      final result = await _ingredients.add(name, iconUrl, callerKey: key);
      if (result) {
        _notify();
        storeSuccess(key, true);
      } else {
        storeFailure(key, null, code: 500, errorCode: 'ADD_FAILED');
      }
      return result;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to add ingredient', error: e);
      return false;
    }
  }

  Future<bool> updateIngredient(int id, String name, String iconUrl,
      {String? callerKey}) async {
    final key =
        callerKey ?? getCallerKey('updateIngredient', id: id.toString());

    try {
      final result =
          await _ingredients.update(id, name, iconUrl, callerKey: key);
      if (result) {
        _notify();
        storeSuccess(key, true);
      } else {
        storeFailure(key, null, code: 500, errorCode: 'UPDATE_FAILED');
      }
      return result;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to update ingredient', error: e);
      return false;
    }
  }

  Future<bool> deleteIngredient(int id, {String? callerKey}) async {
    final key =
        callerKey ?? getCallerKey('deleteIngredient', id: id.toString());

    try {
      final result = await _ingredients.delete(id, callerKey: key);
      if (result) {
        _notify();
        storeSuccess(key, true);
      } else {
        storeFailure(key, false, code: 500, errorCode: 'DELETE_FAILED');
      }
      return result;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to delete ingredient', error: e);
      return false;
    }
  }

  Future<void> refreshIngredients({String? callerKey}) async {
    await _ingredients.refresh(callerKey: callerKey);
    _notify();
  }

  Future<void> fetchAllIngredients({String? callerKey}) async {
    final key = callerKey ?? getCallerKey('fetchAllIngredients');

    try {
      await _fetch.fetchAllIngredients(callerKey: key);
      _notify();
      storeSuccess(key, _state.ingredientList);
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to fetch all ingredients', error: e);
    }
  }

  RecipeIngredient? getIngredientById(int id) => _ingredients.getById(id);
  List<RecipeIngredient> getAllIngredients() => _ingredients.getAll();
  List<RecipeIngredient> searchIngredients(String query) =>
      _ingredients.search(query);

  // ============ USER MANAGEMENT ============

  Future<AppUser?> getUserById(int id, {String? callerKey}) async {
    final key = callerKey ?? getCallerKey('getUserById', id: id.toString());

    try {
      final user = await _users.getById(id, callerKey: key);
      if (user != null) {
        storeSuccess(key, user);
      } else {
        storeFailure(key, null, code: 404, errorCode: 'NOT_FOUND');
      }
      _notify();
      return user;
    } catch (e) {
      storeFailure(key, e.toString(),
          errorCode: e is VerdeliaException ? e.message : 'ERROR');
      logError('Failed to fetch user', error: e);
      return null;
    }
  }

  // ============ FILTERING HELPERS ============

  List<Recipe> filterRecipesByCategory(int categoryId) =>
      _state.filterByCategory(categoryId);

  List<Recipe> searchRecipesLocally(String query) =>
      _state.searchLocally(query);

  // ============ CACHE MANAGEMENT ============

  void clearCache() {
    _cache.clearAll();
    _state.resetPagination();
    logInfo('Cache cleared');
    _notify();
  }

  Future<void> refreshAll({String? callerKey}) async {
    clearCache();
    await _categories.fetchCategories(callerKey: callerKey);
    await _fetch.fetchRecipes(reset: true, callerKey: callerKey);
    await _fetch.fetchIngredients(reset: true, callerKey: callerKey);
    _notify();
  }

  // ============ STATE HELPERS ============

  bool hasRecipe(int id) => _state.hasRecipe(id);
  Recipe? getRecipeById(int id) => _state.getRecipe(id);

  // ============ RESET ============

  void reset() {
    _state.reset();
    _cache.clearAll();
    logInfo('Notifier reset');
    _notify();
  }
}
