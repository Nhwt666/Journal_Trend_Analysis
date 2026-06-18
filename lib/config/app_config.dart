class AppConfig {
  static const String openAlexBaseUrl = 'https://api.openalex.org';
  // Replace with your real email so OpenAlex uses the polite pool (higher rate limits)
  static const String userAgentEmail = 'nhuthase180710@fpt.edu.vn';
  /// Page size for the search results list. 30 is a good middle ground:
  /// large enough to keep the list scrollable for a while, small enough
  /// to keep the initial JSON payload and parse time low.
  static const int defaultPerPage = 30;
  /// Hard cap on the number of results loaded in a single search session
  /// (across all pages). Prevents unbounded memory growth and endless
  /// scroll when the user leaves the screen on auto-pagination.
  static const int maxLoadedResults = 200;
  static const Duration httpTimeout = Duration(seconds: 35);
}
