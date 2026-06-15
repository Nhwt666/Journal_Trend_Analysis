import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/api_error.dart';
import '../models/publication.dart';

enum SortOption {
  citedByDesc('cited_by_count:desc', 'Most Cited'),
  citedByAsc('cited_by_count:asc', 'Least Cited'),
  yearDesc('publication_year:desc', 'Newest First'),
  yearAsc('publication_year:asc', 'Oldest First'),
  relevance('relevance_score:desc', 'Most Relevant');

  final String apiValue;
  final String label;
  const SortOption(this.apiValue, this.label);
}

class SearchFilters {
  const SearchFilters({
    this.fromYear,
    this.toYear,
    this.minCitations = 0,
    this.type,
  });

  final int? fromYear;
  final int? toYear;
  final int minCitations;
  final String? type;

  bool get isActive =>
      fromYear != null || toYear != null || minCitations > 0 || type != null;

  SearchFilters copyWith({
    int? fromYear,
    int? toYear,
    int? minCitations,
    String? type,
    bool clearFromYear = false,
    bool clearToYear = false,
    bool clearType = false,
  }) {
    return SearchFilters(
      fromYear: clearFromYear ? null : (fromYear ?? this.fromYear),
      toYear: clearToYear ? null : (toYear ?? this.toYear),
      minCitations: minCitations ?? this.minCitations,
      type: clearType ? null : (type ?? this.type),
    );
  }

  SearchFilters clear() => const SearchFilters();

  static const docTypes = [
    ('journal-article', 'Journal Article'),
    ('proceedings-article', 'Conference Paper'),
    ('book', 'Book'),
    ('book-chapter', 'Book Chapter'),
    ('dissertation', 'Dissertation'),
    ('preprint', 'Preprint'),
  ];
}

class SearchResult {
  const SearchResult({
    required this.publications,
    required this.totalCount,
    required this.hasMore,
  });

  final List<Publication> publications;
  final int totalCount;
  final bool hasMore;
}

class OpenAlexService {
  OpenAlexService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  bool _shouldRetryTimeout = false;
  static const _baseUrl = AppConfig.openAlexBaseUrl;

  Map<String, String> get _headers => {
        'User-Agent':
            'JournalTrendAnalyzer/1.0 (mailto:${AppConfig.userAgentEmail})',
        'Accept': 'application/json',
      };

  Future<SearchResult> searchWorks(
    String query, {
    int page = 1,
    int perPage = 25,
    SortOption sort = SortOption.citedByDesc,
    SearchFilters filters = const SearchFilters(),
  }) async {
    _shouldRetryTimeout = false;

    final params = <String, String>{
      'search': query,
      'page': page.toString(),
      'per_page': perPage.toString(),
      'sort': sort.apiValue,
    };

    // Build filter string for OpenAlex
    final filterParts = <String>[];

    if (filters.fromYear != null || filters.toYear != null) {
      final from = filters.fromYear ?? '*';
      final to = filters.toYear ?? '*';
      filterParts.add('publication_year:$from-$to');
    }
    if (filters.minCitations > 0) {
      filterParts.add('cited_by_count:>${filters.minCitations}');
    }
    if (filters.type != null) {
      filterParts.add('doc_type:${filters.type}');
    }

    if (filterParts.isNotEmpty) {
      params['filter'] = filterParts.join(',');
    }

    final uri = Uri.parse('$_baseUrl/works').replace(queryParameters: params);

    http.Response response;
    try {
      final request = http.Request('GET', uri)..headers.addAll(_headers);
      final streamedResponse =
          await _client.send(request).timeout(AppConfig.httpTimeout);
      response = await http.Response.fromStream(streamedResponse)
          .timeout(AppConfig.httpTimeout);
    } on TimeoutException {
      if (!_shouldRetryTimeout) {
        _shouldRetryTimeout = true;
        return searchWorks(
          query,
          page: page,
          perPage: perPage,
          sort: sort,
          filters: filters,
        );
      }
      throw const ApiError('Request timed out. Check your connection and try again.');
    } catch (e) {
      _shouldRetryTimeout = false;
      throw ApiError('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw ApiError(
        'OpenAlex returned ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List?) ?? const [];
    final total = (body['meta'] as Map<String, dynamic>?)?['count'] as int? ?? 0;
    final hasMore = page * perPage < total;

    return SearchResult(
      publications: results
          .map((e) => Publication.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: total,
      hasMore: hasMore,
    );
  }

  void dispose() {
    _client.close();
  }
}
