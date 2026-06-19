import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../utils/number_format.dart';
import '../widgets/empty_view.dart';
import '../widgets/method_explainer_card.dart';
import '../widgets/modern_app_bar.dart';
import 'publication_detail_screen.dart';

class TrendAnalysisScreen extends StatelessWidget {
  const TrendAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    if (!dash.isReady) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
        appBar: const ModernAppBar(title: 'Trend Analysis'),
        body: const Center(
          child: EmptyView(
            message: 'Run a search first to see trends.',
            icon: Icons.insights,
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
          surfaceTintColor: Colors.transparent,
          title: const Text('Trend Analysis'),
          bottom: TabBar(
            isScrollable: false,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            indicatorSize: TabBarIndicatorSize.label,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.primaryContainer,
            ),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Trend', icon: Icon(Icons.show_chart, size: 18)),
              Tab(text: 'Top Cited', icon: Icon(Icons.format_quote, size: 18)),
              Tab(text: 'Journals', icon: Icon(Icons.menu_book, size: 18)),
              Tab(text: 'Authors', icon: Icon(Icons.people, size: 18)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TrendTab(isDark: isDark),
            _TopCitedTab(isDark: isDark),
            _TopJournalsTab(isDark: isDark),
            _TopAuthorsTab(isDark: isDark),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: Publication trend line chart ──────────────────────────────────────
class _TrendTab extends StatelessWidget {
  const _TrendTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final points = context.watch<DashboardProvider>().trend;
    final colorScheme = Theme.of(context).colorScheme;

    if (points.isEmpty) {
      return const EmptyView(message: 'No year data available.');
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Publications per Year',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${points.length} years tracked',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(130),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: colorScheme.outline.withAlpha(30),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 1,
                        getTitlesWidget: (v, _) => Text(
                          v.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withAlpha(120),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 32,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= points.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              points[i].year.toString(),
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.onSurface.withAlpha(120),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < points.length; i++)
                          FlSpot(i.toDouble(), points[i].count.toDouble()),
                      ],
                      isCurved: true,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: points.length <= 20,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.25),
                            colorScheme.primary.withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                        final i = s.x.toInt();
                        return LineTooltipItem(
                          '${points[i].year}: ${points[i].count} papers',
                          TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 2: Top cited papers ────────────────────────────────────────────────
class _TopCitedTab extends StatelessWidget {
  const _TopCitedTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final list = context.watch<DashboardProvider>().topCited;

    if (list.isEmpty) {
      return const EmptyView(message: 'No citation data.');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      separatorBuilder: (context, idx) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = list[i];
        return _ModernRankedCard(
          rank: i + 1,
          title: p.title,
          subtitle:
              '${p.year ?? 'N/A'} • ${p.journal.displayName} • ${formatCompact(p.citedByCount)} citations',
          onTap: () => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => PublicationDetailScreen(publication: p),
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 3: Top journals ────────────────────────────────────────────────────
class _TopJournalsTab extends StatelessWidget {
  const _TopJournalsTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<DashboardProvider>().topJournals;
    final colorScheme = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return const EmptyView(message: 'No journal data.');
    }

    // fl_chart requires maxY > 0; guard against empty corpus, all-zero
    // values, or single-row data so the chart never crashes.
    final maxValue = entries
        .map((e) => e.value)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = maxValue <= 0 ? 1.0 : maxValue.toDouble();
    // Ensure interval is at least 1 to avoid infinite height issues
    final interval = maxY <= 5 ? 1.0 : (maxY / 5).ceilToDouble().clamp(1.0, maxY);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Journals by Publication Count',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withAlpha(10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY * 1.2,
                  barGroups: [
                  for (var i = 0; i < entries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: entries[i].value.toDouble(),
                          width: 24,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: interval,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurface.withAlpha(120),
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: SizedBox(
                            width: 64,
                            child: Text(
                              _truncate(entries[i].key, 12),
                              style: TextStyle(
                                fontSize: 9,
                                color: colorScheme.onSurface.withAlpha(120),
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outline.withAlpha(20),
                    strokeWidth: 1,
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, rod, rodIndex, category) {
                      final i = group.x.toInt();
                      if (i < 0 || i >= entries.length) return null;
                      return BarTooltipItem(
                        '${entries[i].key}\n${entries[i].value} papers',
                        const TextStyle(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.separated(
                itemCount: entries.length,
                separatorBuilder: (context, idx) => Divider(
                  color: colorScheme.outline.withAlpha(20),
                  height: 1,
                ),
                itemBuilder: (ctx, i) {
                  final e = entries[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.primaryContainer,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            e.key,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Text(
                          '${e.value} papers',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncate(String s, int n) =>
      s.length > n ? '${s.substring(0, n)}…' : s;
}

// ── Tab 4: Top authors ─────────────────────────────────────────────────────
class _TopAuthorsTab extends StatelessWidget {
  const _TopAuthorsTab({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final entries = context.watch<DashboardProvider>().topAuthors;
    final allAuthors = context.watch<DashboardProvider>().allAuthors;

    if (entries.isEmpty) {
      return const EmptyView(message: 'No author data.');
    }

    final totalAuthorships = allAuthors.fold<int>(0, (s, a) => s + a.count);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        AuthorsEvidenceCard(
          authors: allAuthors.length > 5
              ? allAuthors.take(10).toList()
              : allAuthors,
          onSampleTap: (id) {
            final cited = context.read<DashboardProvider>().topCited;
            if (cited.isEmpty) return;
            final pub = cited.firstWhere(
              (p) => p.id == id,
              orElse: () => cited.first,
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PublicationDetailScreen(publication: pub),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        if (allAuthors.length > 5) ...[
          Center(
            child: Text(
              '+ ${allAuthors.length - 5} more authors not shown',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withAlpha(140),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withAlpha(80),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withAlpha(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${allAuthors.length} distinct name${allAuthors.length == 1 ? '' : 's'} contributed $totalAuthorships authorship${totalAuthorships == 1 ? '' : 's'} across the loaded sample.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(180),
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Modern Ranked Card ──────────────────────────────────────────────────────
class _ModernRankedCard extends StatelessWidget {
  const _ModernRankedCard({
    required this.rank,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final int rank;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.outline.withAlpha(20),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(8),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: rank == 1
                      ? [Colors.amber, Colors.orange]
                      : rank == 2
                          ? [Colors.grey.shade400, Colors.grey.shade600]
                          : rank == 3
                              ? [Colors.brown.shade400, Colors.brown.shade600]
                              : [
                                  colorScheme.primary.withValues(alpha: 0.3),
                                  colorScheme.secondary.withValues(alpha: 0.3),
                                ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(140),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withAlpha(80),
              ),
          ],
        ),
      ),
    );
  }
}
