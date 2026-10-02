// In personnel_state.dart

import 'package:verdelia_core/app/AppUser.dart';
import 'package:verdelia_core/app/ManagementRule.dart';
import 'package:verdelia_core/app/Person.dart';

class PersonnelState {
  // Main data
  final List<AppUser> personnel = [];
  List<AppUser> searchResults = [];
  List<Person> personSearchResults = [];

  // State
  bool isLoading = false;
  String searchQuery = '';
  String? error;
  int currentPage = 0;
  bool hasMore = true;
  bool isRebuildingState = false;
  bool hasSearched = false; // Track if a search has been performed

  // Statistics
  int get totalCount {
    return personnel.length;
  }

  int get searchResultCount {
    return searchResults.length + personSearchResults.length;
  }

  void reset() {
    personnel.clear();
    searchResults.clear();
    personSearchResults.clear();
    isLoading = false;
    searchQuery = '';
    error = null;
    currentPage = 0;
    hasMore = true;
    hasSearched = false;
  }

  void resetPagination() {
    currentPage = 0;
    hasMore = true;
    personnel.clear();
  }

  void setLoading(bool loading) {
    isLoading = loading;
  }

  void setError(String? errorMessage) {
    error = errorMessage;
  }

  void setSearchQuery(String query) {
    searchQuery = query;
  }
}
