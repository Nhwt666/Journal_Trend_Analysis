import 'package:flutter/foundation.dart';
import '../models/dashboard_stats.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';
import '../services/analytics_service.dart';

class DashboardProvider extends ChangeNotifier {
  DashboardProvider({AnalyticsService? service})
      : _service = service ?? AnalyticsService();

  final AnalyticsService _service;

  DashboardStats _stats = DashboardStats.empty;
  DashboardStats get stats => _stats;

  List<TrendPoint> _trend = [];
  List<TrendPoint> get trend => List.unmodifiable(_trend);

  List<Publication> _topCited = [];
  List<Publication> get topCited => List.unmodifiable(_topCited);

  List<MapEntry<String, int>> _topJournals = [];
  List<MapEntry<String, int>> get topJournals =>
      List.unmodifiable(_topJournals);

  List<MapEntry<String, int>> _topAuthors = [];
  List<MapEntry<String, int>> get topAuthors =>
      List.unmodifiable(_topAuthors);

  bool get isReady => _stats.totalPublications > 0;

  void recompute(List<Publication> pubs) {
    _stats = _service.computeStats(pubs);
    _trend = _service.publicationsByYear(pubs);
    _topCited = _service.topCited(pubs, n: 10);
    _topJournals = _service.topJournals(pubs, n: 5);
    _topAuthors = _service.topAuthors(pubs, n: 5);
    notifyListeners();
  }

  void reset() {
    _stats = DashboardStats.empty;
    _trend = [];
    _topCited = [];
    _topJournals = [];
    _topAuthors = [];
    notifyListeners();
  }
}
