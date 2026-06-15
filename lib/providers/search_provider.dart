import 'package:flutter/foundation.dart';
import '../models/api_error.dart';
import '../models/publication.dart';
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

  String _query = '';
  String get query => _query;

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
    } on ApiError catch (e) {
      _errorMessage = e.message;
      _status = SearchStatus.error;
    } catch (e) {
      _errorMessage = 'Unexpected error: $e';
      _status = SearchStatus.error;
    }

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || _query.isEmpty) return;

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
      _hasMore = result.hasMore;
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
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
