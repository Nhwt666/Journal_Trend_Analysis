import 'package:flutter/material.dart';
import '../models/publication.dart';
import '../utils/number_format.dart';

class PublicationCard extends StatelessWidget {
  const PublicationCard({
    super.key,
    required this.publication,
    required this.onTap,
  });

  final Publication publication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 80),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title - max 2 lines
                Text(
                  publication.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 8),

                // Metadata row
                Row(
                  children: [
                    // Year
                    _MetaChip(
                      icon: Icons.calendar_today,
                      text: publication.year?.toString() ?? 'N/A',
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),

                    // Journal name - truncated
                    Expanded(
                      child: _MetaChip(
                        icon: Icons.menu_book,
                        text: publication.journal.name,
                        colorScheme: colorScheme,
                        flexible: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Citation row
                Row(
                  children: [
                    _MetaChip(
                      icon: Icons.format_quote,
                      text: '${formatCompact(publication.citedByCount)} citations',
                      colorScheme: colorScheme,
                    ),
                    if (publication.type != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          publication.type!,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.text,
    required this.colorScheme,
    this.flexible = false,
  });

  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.primary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(200),
            ),
          ),
        ),
      ],
    );

    if (flexible) {
      return content;
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      child: content,
    );
  }
}
