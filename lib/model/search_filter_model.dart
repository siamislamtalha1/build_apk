class SearchFilter {
  final bool includeJioSaavn;
  final bool includeYTMusic;
  final bool includeYTVideo;
  final SearchSortBy sortBy;

  const SearchFilter({
    this.includeJioSaavn = true,
    this.includeYTMusic = true,
    this.includeYTVideo = true,
    this.sortBy = SearchSortBy.relevance,
  });

  SearchFilter copyWith({
    bool? includeJioSaavn,
    bool? includeYTMusic,
    bool? includeYTVideo,
    SearchSortBy? sortBy,
  }) {
    return SearchFilter(
      includeJioSaavn: includeJioSaavn ?? this.includeJioSaavn,
      includeYTMusic: includeYTMusic ?? this.includeYTMusic,
      includeYTVideo: includeYTVideo ?? this.includeYTVideo,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasAnySourceEnabled =>
      includeJioSaavn || includeYTMusic || includeYTVideo;
}

enum SearchSortBy {
  relevance,
  uploadDate,
  popularity,
}

extension SearchSortByExtension on SearchSortBy {
  String get displayName {
    switch (this) {
      case SearchSortBy.relevance:
        return 'Relevance';
      case SearchSortBy.uploadDate:
        return 'Upload Date';
      case SearchSortBy.popularity:
        return 'Popularity';
    }
  }
}
