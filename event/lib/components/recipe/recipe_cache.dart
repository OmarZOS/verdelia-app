import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/business/Recipe.dart';

class RecipeCache {
  final Map<int, Recipe> recipes = {};
  final Map<int, RecipeIngredient> ingredients = {};
  final Map<int, AppUser> users = {};

  // ============ CLEAR ============

  void clearAll() {
    recipes.clear();
    ingredients.clear();
    users.clear();
  }

  // ============ RECIPE CACHE ============

  void cacheRecipe(Recipe recipe) {
    if (recipe.id_recipe != null && recipe.id_recipe != 0) {
      recipes[recipe.id_recipe!] = recipe;
    }
  }

  Recipe? getRecipe(int id) => recipes[id];

  void invalidateRecipe(int id) {
    recipes.remove(id);
  }

  bool hasRecipe(int id) => recipes.containsKey(id);

  // ============ INGREDIENT CACHE ============

  void cacheIngredient(RecipeIngredient ingredient) {
    ingredients[ingredient.id_ingredient] = ingredient;
  }

  RecipeIngredient? getIngredient(int id) => ingredients[id];

  void invalidateIngredient(int id) {
    ingredients.remove(id);
  }

  bool hasIngredient(int id) => ingredients.containsKey(id);

  // ============ USER CACHE ============

  void cacheUser(AppUser user) {
    if (user.idAppUser != null && user.idAppUser != 0) {
      users[user.idAppUser!] = user;
    }
  }

  AppUser? getUser(int id) => users[id];

  void invalidateUser(int id) {
    users.remove(id);
  }

  bool hasUser(int id) => users.containsKey(id);

  void clearUsers() {
    users.clear();
  }

  // ============ STATS ============

  Map<String, int> getStats() {
    return {
      'recipes': recipes.length,
      'ingredients': ingredients.length,
      'users': users.length,
    };
  }
}
