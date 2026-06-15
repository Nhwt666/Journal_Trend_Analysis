class DashboardStats {
  final int totalPublications;
  final double averageCitations;
  final int? mostActiveYear;
  final int mostActiveYearCount;
  final String? topJournal;
  final int topJournalCount;
  final String? topAuthor;
  final int topAuthorCount;
  final String? mostInfluentialTitle;
  final String? mostInfluentialId;
  final int mostInfluentialCitations;
  final int? mostInfluentialYear;

  const DashboardStats({
    required this.totalPublications,
    required this.averageCitations,
    this.mostActiveYear,
    this.mostActiveYearCount = 0,
    this.topJournal,
    this.topJournalCount = 0,
    this.topAuthor,
    this.topAuthorCount = 0,
    this.mostInfluentialTitle,
    this.mostInfluentialId,
    this.mostInfluentialCitations = 0,
    this.mostInfluentialYear,
  });

  static const empty = DashboardStats(
    totalPublications: 0,
    averageCitations: 0,
  );
}
