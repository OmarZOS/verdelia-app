import 'package:verdelia_core/business/Recipe.dart';
import 'package:verdelia_core/business/services/RecipeService.dart';
import 'package:verdelia_core/app/VerdeliaException.dart';
import 'recipe_state.dart';
import 'recipe_cache.dart';

class RecipeFetch {
  final RecipeService _service;
  final RecipeState _state;
  final RecipeCache _cache;

  RecipeFetch({
    required RecipeService service,
    required RecipeState state,
    required RecipeCache cache,
  })  : _service = service,
        _state = state,
        _cache = cache;

  Future<void> fetchRecipes({
    int categoryId = 0,
    String searchQuery = "",
    bool reset = false,
    String? callerKey,
  }) async {
    if (_state.isLoading) return;

    if (reset ||
        _state.currentCategory != categoryId ||
        _state.currentSearch != searchQuery) {
      _state.currentCategory = categoryId;
      _state.currentSearch = searchQuery;
      _state.currentPage = 0;
      _state.hasMoreRecipes = true;
      if (reset) _state.recipes.clear();
    }

    if (!_state.hasMoreRecipes) return;

    _state.setLoading(true);

    try {
      final fetched = await _service.getAllRecipes(
        _state.currentCategory,
        _state.currentPage * RecipeState.itemsPerPage,
        RecipeState.itemsPerPage,
        user_id: 0,
        query: _state.currentSearch,
        callerKey: callerKey,
      );

      if (fetched != null && fetched.isNotEmpty) {
        for (final recipe in fetched) {
          if (recipe.id_recipe != null && recipe.id_recipe != 0) {
            _state.recipes[recipe.id_recipe!] = recipe;
            _cache.cacheRecipe(recipe);
          }
        }
        _state.currentPage++;
        _state.hasMoreRecipes = fetched.length >= RecipeState.itemsPerPage;
      } else {
        _state.hasMoreRecipes = false;
      }
    } catch (e) {
      throw VerdeliaException('Failed to fetch recipes: $e');
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> loadMore({String? callerKey}) async {
    if (!_state.isLoading && _state.hasMoreRecipes) {
      await fetchRecipes(callerKey: callerKey);
    }
  }

  Future<Recipe?> fetchRecipeById(int id, {String? callerKey}) async {
    final cached = _cache.getRecipe(id);
    if (cached != null) return cached;

    try {
      final recipe =
          await _service.getRecipe(id.toString(), callerKey: callerKey);
      if (recipe != null) {
        _cache.cacheRecipe(recipe);
        _state.addRecipe(recipe);
      }
      return recipe;
    } catch (e) {
      throw VerdeliaException('Failed to fetch recipe: $e');
    }
  }

  Future<void> fetchAllIngredients({String? callerKey}) async {
    if (_state.isLoading) return;

    _state.setLoading(true);

    try {
      final fetched = await _service.getAllIngredients(
        0,
        1000,
        callerKey: callerKey,
      );

      if (fetched != null && fetched.isNotEmpty) {
        _state.ingredients.clear();
        for (final ingredient in fetched) {
          _state.ingredients[ingredient.id_ingredient] = ingredient;
          _cache.cacheIngredient(ingredient);
        }
      }
    } catch (e) {
      throw VerdeliaException('Failed to fetch all ingredients: $e');
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> fetchIngredients({
    bool reset = false,
    String? callerKey,
  }) async {
    if (_state.isLoading) return;

    if (reset) {
      _state.ingredients.clear();
      _state.currentIngredientPage = 0;
      _state.hasMoreIngredients = true;
    }

    if (!_state.hasMoreIngredients) return;

    _state.setLoading(true);

    try {
      final fetched = await _service.getAllIngredients(
        _state.currentIngredientPage * RecipeState.ingredientsPerPage,
        RecipeState.ingredientsPerPage,
        callerKey: callerKey,
      );

      if (fetched != null && fetched.isNotEmpty) {
        for (final ingredient in fetched) {
          _state.ingredients[ingredient.id_ingredient] = ingredient;
          _cache.cacheIngredient(ingredient);
        }
        _state.currentIngredientPage++;
        _state.hasMoreIngredients =
            fetched.length >= RecipeState.ingredientsPerPage;
      } else {
        _state.hasMoreIngredients = false;
      }
    } catch (e) {
      throw VerdeliaException('Failed to fetch ingredients: $e');
    } finally {
      _state.setLoading(false);
    }
  }

  Future<void> loadMoreIngredients({String? callerKey}) async {
    if (!_state.isLoading && _state.hasMoreIngredients) {
      await fetchIngredients(callerKey: callerKey);
    }
  }
}
