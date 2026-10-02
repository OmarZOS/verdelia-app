import 'package:verdelia_core/business/Recipe.dart';
import 'package:verdelia_core/business/services/RecipeService.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'recipe_state.dart';
import 'recipe_cache.dart';

class RecipeCrud {
  final RecipeService _service;
  final RecipeState _state;
  final RecipeCache _cache;

  RecipeCrud({
    required RecipeService service,
    required RecipeState state,
    required RecipeCache cache,
  })  : _service = service,
        _state = state,
        _cache = cache;

  Future<bool> createOrUpdate(Recipe recipe, {String? callerKey}) async {
    final isNew = recipe.id_recipe == null || recipe.id_recipe == 0;

    try {
      if (recipe.recipeImage != null) {
        final imageUrl = await recipe.recipeImage?.uploadImage();
        recipe.recipe_image_url = imageUrl;
        recipe.id_recipe_image = 0;
      }

      final result = isNew
          ? await _service.addRecipe(recipe, callerKey: callerKey)
          : await _service.updateRecipe(recipe, callerKey: callerKey);

      if (result != null && result.id_recipe != null && result.id_recipe != 0) {
        _state.addRecipe(result);
        _cache.cacheRecipe(result);
        return true;
      }
      return false;
    } catch (e) {
      throw VerdeliaException(
          'Failed to ${isNew ? 'add' : 'update'} recipe: $e');
    }
  }

  Future<bool> delete(int id, {String? callerKey}) async {
    try {
      final status =
          await _service.deleteRecipe(id.toString(), callerKey: callerKey);

      if (status == 200 || status == 204) {
        _state.removeRecipe(id);
        _cache.invalidateRecipe(id);
        return true;
      }
      return false;
    } catch (e) {
      throw VerdeliaException('Failed to delete recipe: $e');
    }
  }

  void addLocally(Recipe recipe) {
    if (recipe.id_recipe != null && recipe.id_recipe != 0) {
      _state.addRecipe(recipe);
      _cache.cacheRecipe(recipe);
    }
  }

  void updateLocally(Recipe recipe) {
    if (recipe.id_recipe != null && _state.hasRecipe(recipe.id_recipe!)) {
      _state.updateRecipe(recipe);
      _cache.cacheRecipe(recipe);
    }
  }

  Recipe? getCached(int id) => _cache.getRecipe(id);

  bool isCached(int id) => _cache.hasRecipe(id);
}
