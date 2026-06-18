import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/topic.dart';
import '../providers/bookmark_provider.dart';
import '../providers/recent_provider.dart';
import '../providers/search_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/topics_provider.dart';
import '../utils/debouncer.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/recent_sections.dart';
import '../widgets/topic_card.dart';
import '../widgets/topics_overview.dart';
import 'bookmarks_screen.dart';
import 'search_screen.dart';

class TopicsScreen extends StatefulWidget {
  const TopicsScreen({super.key});

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final topics = context.read<TopicsProvider>();
      if (topics.status == TopicsStatus.idle) {
        topics.loadFeatured();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onTopicSelected(Topic topic) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    final search = context.read<SearchProvider>();
    context.read<RecentProvider>().trackTopic(topic);
    search.search(topic.displayName).then((_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SearchScreen(
            topic: topic,
            initialQuery: topic.displayName,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<TopicsProvider>();
    final theme = context.watch<ThemeProvider>();
    final bookmarks = context.watch<BookmarkProvider>();
    final isDark = theme.isDark;
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF0F2F8),
        body: Stack(
          children: [
            // Background gradient blobs
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withAlpha(50),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: -120,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.secondary.withAlpha(35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context, theme, bookmarks),
                  _buildSearchBox(context, topics, isDark),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildBody(context, topics, isDark),
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
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'ResearchHub',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Pick a topic to explore research',
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
            icon: const Icon(
              Icons.person_outline_rounded,
              size: 20,
            ),
            onTap: () => Navigator.pushNamed(context, '/profile'),
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
        ],
      ),
    );
  }

  Widget _buildSearchBox(
    BuildContext context,
    TopicsProvider topics,
    bool isDark,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Container(
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
          controller: _searchController,
          onChanged: (v) {
            _debouncer.call(() {
              topics.searchTopics(v);
            });
          },
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Search topics (e.g. AI, Quantum, Bio...)',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withAlpha(100),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onSurface.withAlpha(150),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      topics.loadFeatured();
                      setState(() {});
                    },
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
      ),
    );
  }

  Widget _buildBody(BuildContext context, TopicsProvider topics, bool isDark) {
    if (topics.status == TopicsStatus.error) {
      return ErrorView(
        key: const ValueKey('topics_error'),
        message: topics.errorMessage ?? 'Failed to load topics',
        onRetry: () => topics.loadFeatured(),
      );
    }

    if (topics.status == TopicsStatus.loading && topics.topics.isEmpty) {
      return _TopicsShimmer(key: const ValueKey('topics_loading'), isDark: isDark);
    }

    if (topics.topics.isEmpty) {
      return EmptyView(
        key: const ValueKey('topics_empty'),
        icon: Icons.search_off,
        message: topics.query.isEmpty
            ? 'No topics available right now.'
            : 'No topics match "${topics.query}".',
      );
    }

    final grouped = topics.grouped();
    final entries = grouped.entries.toList();
    // Header layout: [Overview?] [Recent?] [TopicSection...].
    // Header items are always rendered even when there are zero
    // topic-sections (e.g. user filtered down to nothing but we
    // still want to keep the overview + recents visible).
    final recents = context.watch<RecentProvider>();
    final hasRecents =
        recents.publications.isNotEmpty || recents.topics.isNotEmpty;
    final showOverview = topics.query.isEmpty && topics.topics.isNotEmpty;
    final headerCount = (showOverview ? 1 : 0) + (hasRecents ? 1 : 0);
    final totalItems = entries.length + headerCount;

    return RefreshIndicator(
      key: const ValueKey('topics_success'),
      onRefresh: () => topics.loadFeatured(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        itemCount: totalItems,
        itemBuilder: (context, index) {
          var cursor = index;
          if (showOverview) {
            if (cursor == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: TopicsOverviewPlaceholder(),
              );
            }
            cursor -= 1;
          }
          if (hasRecents) {
            if (cursor == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: RecentSections(),
              );
            }
            cursor -= 1;
          }
          if (entries.isEmpty) {
            // Header only — render a small empty hint below the
            // header so the screen is not completely blank.
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyView(
                icon: Icons.search_off,
                message:
                    'No topics match your filter. Try a different search term.',
              ),
            );
          }
          final entry = entries[cursor];
          return _TopicSection(
            title: entry.key,
            topics: entry.value,
            onTopicTap: _onTopicSelected,
          );
        },
      ),
    );
  }
}

/// Tiny wrapper so we can `const`-construct the [TopicsOverview] in
/// the list and only build it with the actual topics list on demand.
class TopicsOverviewPlaceholder extends StatelessWidget {
  const TopicsOverviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final topics = context.watch<TopicsProvider>().topics;
    return TopicsOverview(topics: topics);
  }
}

class _TopicSection extends StatelessWidget {
  const _TopicSection({
    required this.title,
    required this.topics,
    required this.onTopicTap,
  });

  final String title;
  final List<Topic> topics;
  final void Function(Topic) onTopicTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.secondary,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '· ${topics.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withAlpha(120),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        ...topics.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TopicCard(topic: t, onTap: () => onTopicTap(t)),
          ),
        ),
      ],
    );
  }
}

class _TopicsShimmer extends StatelessWidget {
  const _TopicsShimmer({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          height: 86,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

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
