import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/api_error.dart';
import '../models/publication.dart';
import '../models/topic.dart';
import '../services/openalex_service.dart';
import '../services/search_history_service.dart';

enum SearchStatus { idle, loading, success, error }

class SearchProvider extends ChangeNotifier {
  SearchProvider({
    OpenAlexService? service,
    SearchHistoryService? historyService,
  })  : _service = service ?? OpenAlexService(),
        _historyService = historyService ?? SearchHistoryService();

  final OpenAlexService _service;
  final SearchHistoryService _historyService;

  /// Hook called every time a search successfully finishes. The
  /// `DashboardProvider` registers itself here so the analytics it
  /// exposes (Top Authors / Fields / Trends) always reflect the
  /// latest search, regardless of which screen triggered it.
  void Function(List<Publication> pubs, String query, int total)? _onSuccess;

  void attachDashboardHook(
    void Function(List<Publication>, String, int) hook,
  ) {
    _onSuccess = hook;
  }

  /// Lightweight hook for the Profile screen — fires after every
  /// successful search with just the query string. We use a separate
  /// hook (instead of packing it into `_onSuccess`) so the profile
  /// does not need to listen to the bulky publication list.
  void Function(String query)? _onProfileSearch;

  void attachProfileHook(void Function(String) hook) {
    _onProfileSearch = hook;
  }

  String _query = '';
  String get query => _query;

  Topic? _activeTopic;
  Topic? get activeTopic => _activeTopic;

  List<Publication> _publications = [];
  List<Publication> get publications => List.unmodifiable(_publications);

  SearchStatus _status = SearchStatus.idle;
  SearchStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get hasResults => _publications.isNotEmpty;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  bool _hasMore = false;
  bool get hasMore => _hasMore;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  int _currentPage = 1;

  SortOption _sortOption = SortOption.citedByDesc;
  SortOption get sortOption => _sortOption;

  SearchFilters _filters = const SearchFilters();
  SearchFilters get filters => _filters;

  List<String> _history = [];
  List<String> get history => List.unmodifiable(_history);

  Future<void> loadHistory() async {
    _history = await _historyService.load();
    notifyListeners();
  }

  void setFilters(SearchFilters f) {
    _filters = f;
    notifyListeners();
  }

  void clearFilters() {
    _filters = const SearchFilters();
    notifyListeners();
    if (_query.isNotEmpty) search(_query);
  }

  Future<void> search(String topic) async {
    final trimmed = topic.trim();
    if (trimmed.isEmpty) return;

    _query = trimmed;
    _currentPage = 1;
    _status = SearchStatus.loading;
    _errorMessage = null;
    _publications = [];
    notifyListeners();

    try {
      final result = await _service.searchWorks(
        trimmed,
        page: 1,
        sort: _sortOption,
        filters: _filters,
      );
      _publications = result.publications;
      _totalCount = result.totalCount;
      _hasMore = result.hasMore;
      _status = SearchStatus.success;
      await _addToHistory(trimmed);
      // Fire the dashboard hook so analytics are always in sync
      // with the current search, no matter which screen triggered
      // it (TopicsScreen, SearchScreen, history re-run, etc.).
      _onSuccess?.call(
        result.publications,
        trimmed,
        result.totalCount,
      );
      _onProfileSearch?.call(trimmed);
    } on ApiError catch (e) {
      _errorMessage = e.message;
      _status = SearchStatus.error;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _status = SearchStatus.error;
    }

    notifyListeners();
  }

  /// Run a search that was triggered by selecting a topic from TopicsScreen.
  /// Stores the topic so the results screen can show its category/field.
  Future<void> searchByTopic(Topic topic) async {
    _activeTopic = topic;
    await search(topic.displayName);
  }

  void setActiveTopic(Topic? topic) {
    _activeTopic = topic;
    notifyListeners();
  }

  /// Clears the active topic so subsequent searches are unfiltered. Does
  /// not touch the current query or results.
  void clearActiveTopic() {
    _activeTopic = null;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _query.isEmpty) return;
    // Hard cap: stop auto-paginating once the user has already loaded the
    // configured maximum number of results. The list will still show a
    // "Load more" button so the user can opt-in to more.
    if (_publications.length >= AppConfig.maxLoadedResults) {
      _hasMore = false;
      notifyListeners();
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.searchWorks(
        _query,
        page: _currentPage + 1,
        sort: _sortOption,
        filters: _filters,
      );
      _currentPage++;
      _publications = [..._publications, ...result.publications];
      // Re-check cap after appending: another page may have pushed us over.
      if (_publications.length >= AppConfig.maxLoadedResults) {
        _publications = _publications.sublist(0, AppConfig.maxLoadedResults);
        _hasMore = false;
      } else {
        _hasMore = result.hasMore;
      }
      // Refresh dashboard analytics over the full corpus now that
      // more papers are in scope.
      _onSuccess?.call(_publications, _query, _totalCount);
    } on ApiError catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  void setSort(SortOption option) {
    if (_sortOption == option) return;
    _sortOption = option;
    if (_query.isNotEmpty) search(_query);
  }

  Future<void> _addToHistory(String q) async {
    _history.remove(q);
    _history.insert(0, q);
    if (_history.length > 8) _history.removeLast();
    await _historyService.save(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    await _historyService.clear();
    notifyListeners();
  }

  void clear() {
    _query = '';
    _publications = [];
    _status = SearchStatus.idle;
    _errorMessage = null;
    _totalCount = 0;
    _hasMore = false;
    _isLoadingMore = false;
    _currentPage = 1;
    _activeTopic = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
