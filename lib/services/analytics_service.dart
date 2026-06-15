import '../models/dashboard_stats.dart';
import '../models/publication.dart';
import '../models/trend_point.dart';

class AnalyticsService {
  List<TrendPoint> publicationsByYear(List<Publication> pubs) {
    final map = <int, int>{};
    for (final p in pubs) {
      if (p.year != null) {
        map[p.year!] = (map[p.year!] ?? 0) + 1;
      }
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) => TrendPoint(year: e.key, count: e.value)).toList();
  }

  List<Publication> topCited(List<Publication> pubs, {int n = 10}) {
    final sorted = [...pubs]
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
    return sorted.take(n).toList();
  }

  List<MapEntry<String, int>> topJournals(
    List<Publication> pubs, {
    int n = 5,
  }) {
    final map = <String, int>{};
    for (final p in pubs) {
      final name = p.journal.name;
      if (name.isEmpty) continue;
      map[name] = (map[name] ?? 0) + 1;
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(n).toList();
  }

  List<MapEntry<String, int>> topAuthors(
    List<Publication> pubs, {
    int n = 5,
  }) {
    final map = <String, int>{};
    for (final p in pubs) {
      for (final a in p.authors) {
        if (a.name.isEmpty) continue;
        map[a.name] = (map[a.name] ?? 0) + 1;
      }
    }
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(n).toList();
  }

  DashboardStats computeStats(List<Publication> pubs) {
    if (pubs.isEmpty) return DashboardStats.empty;

    final totalCitations = pubs.fold<int>(0, (s, p) => s + p.citedByCount);
    final avg = totalCitations / pubs.length;

    final yearMap = <int, int>{};
    final journalMap = <String, int>{};
    final authorMap = <String, int>{};

    for (final p in pubs) {
      if (p.year != null) yearMap[p.year!] = (yearMap[p.year!] ?? 0) + 1;
      if (p.journal.name.isNotEmpty) {
        journalMap[p.journal.name] =
            (journalMap[p.journal.name] ?? 0) + 1;
      }
      for (final a in p.authors) {
        if (a.name.isNotEmpty) {
          authorMap[a.name] = (authorMap[a.name] ?? 0) + 1;
        }
      }
    }

    final topYear = _topEntry(yearMap);
    final topJournal = _topEntry(journalMap);
    final topAuthor = _topEntry(authorMap);
    final mostInfluential = topCited(pubs, n: 1).firstOrNull;

    return DashboardStats(
      totalPublications: pubs.length,
      averageCitations: avg,
      mostActiveYear: topYear?.key,
      mostActiveYearCount: topYear?.value ?? 0,
      topJournal: topJournal?.key,
      topJournalCount: topJournal?.value ?? 0,
      topAuthor: topAuthor?.key,
      topAuthorCount: topAuthor?.value ?? 0,
      mostInfluentialTitle: mostInfluential?.title,
      mostInfluentialId: mostInfluential?.id,
      mostInfluentialCitations: mostInfluential?.citedByCount ?? 0,
      mostInfluentialYear: mostInfluential?.year,
    );
  }

  MapEntry<K, int>? _topEntry<K>(Map<K, int> map) {
    if (map.isEmpty) return null;
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
