import 'package:event/components/recipe/recipe_fetch.dart';
import 'package:verdelia_core/business/Recipe.dart';
import 'package:verdelia_core/business/services/RecipeService.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'recipe_state.dart';
import 'recipe_cache.dart';

class RecipeIngredientManager {
  final RecipeService _service;
  final RecipeState _state;
  final RecipeCache _cache;

  RecipeIngredientManager({
    required RecipeService service,
    required RecipeState state,
    required RecipeCache cache,
  })  : _service = service,
        _state = state,
        _cache = cache;

  Future<bool> add(String name, String iconUrl, {String? callerKey}) async {
    try {
      final ingredient = RecipeIngredient(
        id_ingredient: 0,
        ingredient_name: name,
        ingredient_icon: iconUrl,
      );

      final created =
          await _service.addIngredient(ingredient, callerKey: callerKey);

      if (created != null) {
        _state.addIngredient(created);
        _cache.cacheIngredient(created);
        return true;
      }
      return false;
    } catch (e) {
      throw VerdeliaException('Failed to add ingredient: $e');
    }
  }

  Future<bool> update(int id, String name, String iconUrl,
      {String? callerKey}) async {
    try {
      final ingredient = RecipeIngredient(
        id_ingredient: id,
        ingredient_name: name,
        ingredient_icon: iconUrl,
      );

      final updated =
          await _service.updateIngredient(ingredient, callerKey: callerKey);

      if (updated != null) {
        _state.addIngredient(updated);
        _cache.cacheIngredient(updated);
        return true;
      }
      return false;
    } catch (e) {
      throw VerdeliaException('Failed to update ingredient: $e');
    }
  }

  Future<bool> delete(int id, {String? callerKey}) async {
    try {
      final result =
          await _service.deleteIngredient(id.toString(), callerKey: callerKey);

      if (result == 200 || result == 204) {
        _state.removeIngredient(id);
        _cache.invalidateIngredient(id);
        return true;
      }
      return false;
    } catch (e) {
      throw VerdeliaException('Failed to delete ingredient: $e');
    }
  }

  Future<void> refresh({String? callerKey}) async {
    _state.ingredients.clear();
    _state.currentIngredientPage = 0;
    _state.hasMoreIngredients = true;

    final fetch = RecipeFetch(
      service: _service,
      state: _state,
      cache: _cache,
    );
    await fetch.fetchAllIngredients(callerKey: callerKey);
  }

  RecipeIngredient? getById(int id) => _state.getIngredient(id);
  List<RecipeIngredient> getAll() => _state.ingredientList;
  List<RecipeIngredient> search(String query) =>
      _state.searchIngredientsLocally(query);
}
