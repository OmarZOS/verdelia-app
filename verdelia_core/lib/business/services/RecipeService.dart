import 'dart:typed_data';

import 'package:verdelia_core/app/TraceableService.dart';

import '../Recipe.dart';

// RecipeService.dart
abstract class RecipeService extends TraceableService {
  Future<List<RecipeIngredient>?> getAllIngredients(int offset, int limit,
      {String? callerKey}) async {
    return null;
  }

  Future<List<RecipeCategory>?>? getCategories({String? callerKey}) async {
    return null;
  }

  Future<List<Recipe>?>? getAllRecipes(int category, int page, int limit,
      {int user_id = 0, String query = "", String? callerKey}) async {
    return null;
  }

  Future<Recipe?> getRecipe(String idRecipe, {String? callerKey}) async {
    return null;
  }

  Future<Recipe?> addRecipe(Recipe recipe, {String? callerKey}) async {
    return null;
  }

  Future<Recipe?> updateRecipe(Recipe updatedRecipe,
      {String? callerKey}) async {
    return null;
  }

  Future<int?> deleteRecipe(String recipeId, {String? callerKey}) async {
    return null;
  }

  Future<RecipeIngredient?> getIngredient(String idRecipeIngredient,
      {String? callerKey}) async {
    return null;
  }

  Future<RecipeIngredient?> addIngredient(RecipeIngredient ingredient,
      {String? callerKey}) async {
    return null;
  }

  Future<RecipeIngredient?> updateIngredient(
      RecipeIngredient updatedRecipeIngredient,
      {String? callerKey}) async {
    return null;
  }

  Future<int?> deleteIngredient(String ingredientId,
      {String? callerKey}) async {
    return null;
  }
}
