import 'package:verdelia_core/business/Recipe.dart';

class RecipeState {
  final Map<int, Recipe> recipes = {};
  final Map<int, RecipeIngredient> ingredients = {};
  List<String> categories = [];

  bool isLoading = false;
  bool hasMoreRecipes = true;
  bool hasMoreIngredients = true;

  String currentSearch = "";
  int currentPage = 0;
  int currentCategory = 0;
  int currentIngredientPage = 0;

  static const int itemsPerPage = 20;
  static const int ingredientsPerPage = 50;

  // ============ GETTERS ============

  List<Recipe> get recipeList => recipes.values.toList();
  List<RecipeIngredient> get ingredientList => ingredients.values.toList();
  int get totalRecipeCount => recipes.length;
  int get totalIngredientCount => ingredients.length;

  // ============ RESET METHODS ============

  void reset() {
    recipes.clear();
    ingredients.clear();
    categories.clear();
    isLoading = false;
    hasMoreRecipes = true;
    hasMoreIngredients = true;
    currentSearch = "";
    currentPage = 0;
    currentCategory = 0;
    currentIngredientPage = 0;
  }

  void resetPagination() {
    currentPage = 0;
    currentIngredientPage = 0;
    hasMoreRecipes = true;
    hasMoreIngredients = true;
  }

  void setLoading(bool loading) {
    isLoading = loading;
  }

  // ============ RECIPE OPERATIONS ============

  void addRecipe(Recipe recipe) {
    if (recipe.id_recipe != null && recipe.id_recipe != 0) {
      recipes[recipe.id_recipe!] = recipe;
    }
  }

  void removeRecipe(int id) {
    recipes.remove(id);
  }

  Recipe? getRecipe(int id) => recipes[id];

  bool hasRecipe(int id) => recipes.containsKey(id);

  void updateRecipe(Recipe recipe) {
    if (recipe.id_recipe != null && recipes.containsKey(recipe.id_recipe!)) {
      recipes[recipe.id_recipe!] = recipe;
    }
  }

  // ============ INGREDIENT OPERATIONS ============

  void addIngredient(RecipeIngredient ingredient) {
    ingredients[ingredient.id_ingredient] = ingredient;
  }

  void removeIngredient(int id) {
    ingredients.remove(id);
  }

  RecipeIngredient? getIngredient(int id) => ingredients[id];

  bool hasIngredient(int id) => ingredients.containsKey(id);

  void updateIngredient(RecipeIngredient ingredient) {
    ingredients[ingredient.id_ingredient] = ingredient;
  }

  // ============ FILTERING ============

  List<Recipe> filterByCategory(int categoryId) {
    if (categoryId == 0) return recipeList;
    return recipeList
        .where((recipe) => recipe.recipe_category_id == categoryId)
        .toList();
  }

  List<Recipe> searchLocally(String query) {
    if (query.isEmpty) return recipeList;
    return recipeList
        .where((recipe) =>
            recipe.recipe_name?.toLowerCase().contains(query.toLowerCase()) ??
            false)
        .toList();
  }

  List<RecipeIngredient> searchIngredientsLocally(String query) {
    if (query.isEmpty) return ingredientList;
    return ingredientList
        .where((ingredient) => ingredient.ingredient_name
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
  }
}
