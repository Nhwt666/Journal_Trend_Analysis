class AppConfig {
  static const String openAlexBaseUrl = 'https://api.openalex.org';
  // Replace with your real email so OpenAlex uses the polite pool (higher rate limits)
  static const String userAgentEmail = 'nhuthase180710@fpt.edu.vn';
  static const int defaultPerPage = 50;
  static const Duration httpTimeout = Duration(seconds: 35);
}
