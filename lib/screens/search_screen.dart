import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/bookmark_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/search_provider.dart';
import '../providers/theme_provider.dart';
import '../services/openalex_service.dart';
import '../utils/debouncer.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/publication_card.dart';
import 'bookmarks_screen.dart';
import 'dashboard_screen.dart';
import 'publication_detail_screen.dart';
import 'trend_analysis_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();
  final _scrollController = ScrollController();

  static const _suggestions = [
    'Artificial Intelligence',
    'Software Engineering',
    'Data Science',
    'Cybersecurity',
    'Internet of Things',
    'Blockchain',
    'Machine Learning',
    'Cloud Computing',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debouncer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchProvider>().loadMore();
    }
  }

  void _runSearch([String? override]) {
    final q = (override ?? _controller.text).trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();

    context.read<SearchProvider>().search(q).then((_) {
      if (!mounted) return;
      final sp = context.read<SearchProvider>();
      if (sp.hasResults) {
        context.read<DashboardProvider>().recompute(sp.publications);
      }
    });
  }

  void _showSortMenu(BuildContext context) {
    final sp = context.read<SearchProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModernBottomSheet(
        title: 'Sort By',
        children: SortOption.values.map((opt) {
          final selected = sp.sortOption == opt;
          return ListTile(
            leading: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? Theme.of(context).colorScheme.primary : Colors.grey,
            ),
            title: Text(opt.label),
            onTap: () {
              Navigator.pop(context);
              if (!selected) sp.setSort(opt);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final sp = context.read<SearchProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(initialFilters: sp.filters),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<SearchProvider>();
    final theme = context.watch<ThemeProvider>();
    final bookmarks = context.watch<BookmarkProvider>();
    final isDark = theme.isDark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
        body: Stack(
          children: [
            // Background gradient blobs
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? Colors.indigo : Colors.indigo)
                          .withAlpha(40),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -100,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? Colors.purple : Colors.purple)
                          .withAlpha(30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Custom app bar
                  _buildAppBar(context, theme, bookmarks, search),

                  // Body
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildBody(search, isDark),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeProvider theme,
    BookmarkProvider bookmarks,
    SearchProvider search,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
      child: Row(
        children: [
          _GlassIconButton(
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onTap: () => SystemNavigator.pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ResearchHub',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Discover academic research',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          _GlassIconButton(
            icon: Icon(
              theme.isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            onTap: () => theme.toggle(),
          ),
          const SizedBox(width: 8),
          _GlassIconButton(
            icon: Badge(
              isLabelVisible: bookmarks.hasBookmarks,
              label: Text(bookmarks.bookmarks.length.toString()),
              child: Icon(
                bookmarks.hasBookmarks
                    ? Icons.bookmark
                    : Icons.bookmark_border,
                size: 20,
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarksScreen()),
            ),
          ),
          if (search.hasResults) ...[
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: Badge(
                isLabelVisible: search.filters.isActive,
                child: const Icon(Icons.tune, size: 20),
              ),
              onTap: () => _showFilterSheet(context),
            ),
            const SizedBox(width: 8),
            _GlassIconButton(
              icon: const Icon(Icons.sort, size: 20),
              onTap: () => _showSortMenu(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(SearchProvider search, bool isDark) {
    switch (search.status) {
      case SearchStatus.idle:
        return _IdleBody(
          key: const ValueKey('idle'),
          controller: _controller,
          suggestions: _suggestions,
          onSearch: _runSearch,
          onSuggestionTap: (s) {
            _controller.text = s;
            _runSearch(s);
          },
          isDark: isDark,
        );
      case SearchStatus.loading:
        return const _ModernShimmer(key: ValueKey('loading'));
      case SearchStatus.error:
        return ErrorView(
          key: const ValueKey('error'),
          message: search.errorMessage ?? 'Something went wrong',
          onRetry: () => _runSearch(),
        );
      case SearchStatus.success:
        if (!search.hasResults) {
          return const EmptyView(
            key: ValueKey('empty'),
            message: 'No publications found.\nTry different keywords.',
            icon: Icons.search_off,
          );
        }
        return _ResultsBody(
          key: ValueKey('results_${search.query}'),
          search: search,
          scrollController: _scrollController,
          onLoadMore: () => search.loadMore(),
        );
    }
  }
}

// ── Idle / Search State ────────────────────────────────────────

class _IdleBody extends StatefulWidget {
  const _IdleBody({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.onSearch,
    required this.onSuggestionTap,
    required this.isDark,
  });

  final TextEditingController controller;
  final List<String> suggestions;
  final void Function([String?]) onSearch;
  final void Function(String) onSuggestionTap;
  final bool isDark;

  @override
  State<_IdleBody> createState() => _IdleBodyState();
}

class _IdleBodyState extends State<_IdleBody>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnim;
  final _focusNode = FocusNode();
  final _idleDebouncer = _IdleDebouncer();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _focusNode.dispose();
    _idleDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final searchProvider = context.watch<SearchProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Search box
          AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, 20 * (1 - _slideAnim.value)),
              child: Opacity(opacity: _slideAnim.value, child: child),
            ),
            child: _ModernSearchBox(
              controller: widget.controller,
              focusNode: _focusNode,
              onSubmitted: widget.onSearch,
              onChanged: (v) {
                if (v.trim().length >= 3) {
                  _idleDebouncer.call(() => widget.onSearch());
                }
              },
              onClear: () {
                widget.controller.clear();
                context.read<SearchProvider>().clear();
                context.read<DashboardProvider>().reset();
              },
              isDark: widget.isDark,
            ),
          ),

          const SizedBox(height: 28),

          // Popular topics
          AnimatedBuilder(
            animation: _slideAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, 30 * (1 - _slideAnim.value)),
              child: Opacity(opacity: _slideAnim.value, child: child),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Topics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.suggestions.map((s) {
                    return _ModernChip(
                      label: s,
                      onTap: () => widget.onSuggestionTap(s),
                      isDark: widget.isDark,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Recent searches
          if (searchProvider.history.isNotEmpty)
            AnimatedBuilder(
              animation: _slideAnim,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, 30 * (1 - _slideAnim.value)),
                child: Opacity(opacity: _slideAnim.value, child: child),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recent Searches',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () =>
                            context.read<SearchProvider>().clearHistory(),
                        child: const Text('Clear all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...searchProvider.history.take(5).map((q) {
                    return _RecentSearchTile(
                      text: q,
                      onTap: () {
                        widget.controller.text = q;
                        widget.onSearch(q);
                      },
                    );
                  }),
                ],
              ),
            ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Modern Search Box ─────────────────────────────────────────

class _ModernSearchBox extends StatelessWidget {
  const _ModernSearchBox({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function([String?]) onSubmitted;
  final void Function(String) onChanged;
  final VoidCallback onClear;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSubmitted(),
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search research topics...',
          hintStyle: TextStyle(
            color: colorScheme.onSurface.withAlpha(100),
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 4),
            padding: const EdgeInsets.all(0),
            child: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close, color: colorScheme.onSurface.withAlpha(150)),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: isDark
              ? const Color(0xFF1E1E2E).withAlpha(200)
              : Colors.white.withAlpha(240),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorScheme.outline.withAlpha(30),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(
              color: colorScheme.primary.withAlpha(100),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// ── Modern Chip ───────────────────────────────────────────────

class _ModernChip extends StatelessWidget {
  const _ModernChip({
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isDark
              ? colorScheme.surfaceContainerHighest.withAlpha(150)
              : Colors.white.withAlpha(230),
          border: Border.all(
            color: colorScheme.outline.withAlpha(40),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Recent Search Tile ────────────────────────────────────────

class _RecentSearchTile extends StatelessWidget {
  const _RecentSearchTile({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.history,
        size: 20,
        color: colorScheme.onSurface.withAlpha(120),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withAlpha(200),
        ),
      ),
      trailing: Icon(
        Icons.north_west,
        size: 16,
        color: colorScheme.onSurface.withAlpha(80),
      ),
    );
  }
}

// ── Glass Icon Button ─────────────────────────────────────────

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});

  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: colorScheme.surfaceContainerHighest.withAlpha(150),
          border: Border.all(
            color: colorScheme.outline.withAlpha(40),
          ),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

// ── Results Body ───────────────────────────────────────────────

class _ResultsBody extends StatelessWidget {
  const _ResultsBody({
    super.key,
    required this.search,
    required this.scrollController,
    required this.onLoadMore,
  });

  final SearchProvider search;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Results header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                '${search.totalCount} results',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withAlpha(30),
                      colorScheme.secondary.withAlpha(30),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  search.sortOption.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Dashboard',
                icon: const Icon(Icons.dashboard_outlined, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                ),
              ),
              IconButton(
                tooltip: 'Trend Analysis',
                icon: const Icon(Icons.insights_outlined, size: 20),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrendAnalysisScreen()),
                ),
              ),
            ],
          ),
        ),

        // Active filters
        if (search.filters.isActive)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (search.filters.fromYear != null ||
                      search.filters.toYear != null)
                    _ActiveFilterChip(
                      label:
                          '${search.filters.fromYear ?? '*'}–${search.filters.toYear ?? '*'}',
                      onRemove: () {
                        search.setFilters(search.filters.copyWith(
                          clearFromYear: true,
                          clearToYear: true,
                        ));
                        search.search(search.query);
                      },
                    ),
                  if (search.filters.minCitations > 0)
                    _ActiveFilterChip(
                      label: '>${search.filters.minCitations} citations',
                      onRemove: () {
                        search.setFilters(search.filters.copyWith(minCitations: 0));
                        search.search(search.query);
                      },
                    ),
                  if (search.filters.type != null)
                    _ActiveFilterChip(
                      label: search.filters.type!.replaceAll('-', ' '),
                      onRemove: () {
                        search.setFilters(search.filters.copyWith(clearType: true));
                        search.search(search.query);
                      },
                    ),
                ],
              ),
            ),
          ),

        // Results list
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await context.read<SearchProvider>().search(search.query);
            },
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: search.publications.length + (search.hasMore ? 1 : 0),
              separatorBuilder: (context, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i >= search.publications.length) {
                  return _buildLoadMore(search);
                }
                final pub = search.publications[i];
                return PublicationCard(
                  publication: pub,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PublicationDetailScreen(publication: pub),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMore(SearchProvider search) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: search.isLoadingMore
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Loading more...'),
                ],
              )
            : TextButton.icon(
                onPressed: onLoadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load More'),
              ),
      ),
    );
  }
}

// ── Active Filter Chip ────────────────────────────────────────

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.tertiaryContainer,
            colorScheme.tertiaryContainer.withAlpha(180),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 14,
              color: colorScheme.onTertiaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Modern Shimmer Loading ─────────────────────────────────────

class _ModernShimmer extends StatelessWidget {
  const _ModernShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: 6,
        separatorBuilder: (context, idx) => const SizedBox(height: 12),
        itemBuilder: (context, idx) => Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ── Modern Bottom Sheet ────────────────────────────────────────

class _ModernBottomSheet extends StatelessWidget {
  const _ModernBottomSheet({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outline.withAlpha(60),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
            child: Row(
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...children,
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ── Filter Sheet ───────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initialFilters});

  final SearchFilters initialFilters;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TextEditingController _fromYearCtrl;
  late TextEditingController _toYearCtrl;
  late TextEditingController _minCitCtrl;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _fromYearCtrl = TextEditingController(
      text: widget.initialFilters.fromYear?.toString() ?? '',
    );
    _toYearCtrl = TextEditingController(
      text: widget.initialFilters.toYear?.toString() ?? '',
    );
    _minCitCtrl = TextEditingController(
      text: widget.initialFilters.minCitations > 0
          ? widget.initialFilters.minCitations.toString()
          : '',
    );
    _selectedType = widget.initialFilters.type;
  }

  @override
  void dispose() {
    _fromYearCtrl.dispose();
    _toYearCtrl.dispose();
    _minCitCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final sp = context.read<SearchProvider>();
    sp.setFilters(SearchFilters(
      fromYear: int.tryParse(_fromYearCtrl.text),
      toYear: int.tryParse(_toYearCtrl.text),
      minCitations: int.tryParse(_minCitCtrl.text) ?? 0,
      type: _selectedType,
    ));
    Navigator.pop(context);
    if (sp.query.isNotEmpty) sp.search(sp.query);
  }

  void _clear() {
    context.read<SearchProvider>().clearFilters();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withAlpha(60),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  TextButton(onPressed: _clear, child: const Text('Clear All')),
                ],
              ),
              const SizedBox(height: 20),

              // Year Range
              Text(
                'Publication Year',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromYearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'From year',
                        hintText: 'e.g. 2020',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _toYearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'To year',
                        hintText: 'e.g. 2025',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Min Citations
              Text(
                'Minimum Citations',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _minCitCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min citations',
                  hintText: 'e.g. 10',
                ),
              ),

              const SizedBox(height: 20),

              // Document Type
              Text(
                'Document Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TypeChip(
                    label: 'Any',
                    selected: _selectedType == null,
                    onTap: () => setState(() => _selectedType = null),
                  ),
                  ...SearchFilters.docTypes.map((t) => _TypeChip(
                        label: t.$2,
                        selected: _selectedType == t.$1,
                        onTap: () => setState(() => _selectedType = t.$1),
                      )),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outline.withAlpha(50),
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _IdleDebouncer {
  _IdleDebouncer();

  final List<VoidCallback> _callbacks = [];
  bool _debouncing = false;

  void call(VoidCallback cb) {
    _callbacks.add(cb);
    if (_debouncing) return;
    _debouncing = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      for (final c in _callbacks) {
        c();
      }
      _callbacks.clear();
      _debouncing = false;
    });
  }

  void dispose() {}
}
