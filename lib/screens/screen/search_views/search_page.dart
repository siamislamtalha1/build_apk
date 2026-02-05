import 'package:Bloomee/model/search_filter_model.dart';
import 'package:Bloomee/blocs/search_suggestions/search_suggestion_bloc.dart';
import 'package:Bloomee/screens/widgets/sign_board_widget.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:Bloomee/blocs/search/fetch_search_results.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:Bloomee/screens/widgets/glass_widgets.dart';

class SearchPageDelegate extends SearchDelegate {
  List<String> searchList = [];
  ResultTypes resultType = ResultTypes.songs;
  SearchFilter? filter;
  String _lastSuggestionQuery = '';
  SearchPageDelegate(
    this.resultType, {
    this.filter,
  });
  @override
  String? get searchFieldLabel => "Explore the world of music...";

  @override
  ThemeData appBarTheme(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20))),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: scheme.onSurface),
      ),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: scheme.onSurface,
        ).merge(Default_Theme.secondoryTextStyleMedium),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: scheme.onSurface.withValues(alpha: 0.45),
        ).merge(Default_Theme.secondoryTextStyle),
        fillColor: scheme.surface.withValues(alpha: 0.10),
        filled: true,
      ),
    );
  }

  @override
  void showResults(BuildContext context) {
    if (query.replaceAll(' ', '').isNotEmpty) {
      // Use unified search across all sources with filter
      context.read<FetchSearchResultsCubit>().searchAllSources(
            query,
            resultType: resultType,
            filter: filter,
          );
      BloomeeDBService.putSearchHistory(query);
    }
    close(context, query);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(MingCute.close_fill))
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(MingCute.arrow_left_fill),
      onPressed: () => Navigator.of(context).pop(),
      // Exit from the search screen.
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final List<String> searchResults = searchList
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Container(
      color: scheme.surface,
      child: ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(searchResults[index]),
            onTap: () {
              close(context, searchResults[index]);
            },
          );
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // final List<String> suggestionList = [];
    if (query != _lastSuggestionQuery) {
      _lastSuggestionQuery = query;
      context.read<SearchSuggestionBloc>().add(SearchSuggestionFetch(query));
    }

    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<SearchSuggestionBloc, SearchSuggestionState>(
      builder: (context, state) {
        return Container(
          color: scheme.surface,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: switch (state) {
              SearchSuggestionLoading() => Center(
                  child: CircularProgressIndicator(
                    color: Default_Theme.accentColor2,
                  ),
                ),
              SearchSuggestionLoaded() => state.suggestionList.isEmpty &&
                      state.dbSuggestionList.isEmpty
                  ? const Center(
                      child: SignBoardWidget(
                        message: "No Suggestions found!",
                        icon: MingCute.look_up_line,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListView(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable inner scrolling
                          children: state.dbSuggestionList
                              .map(
                                (e) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: GlassSurface(
                                    borderRadius: BorderRadius.circular(18),
                                    sigmaX: 24,
                                    sigmaY: 24,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4, vertical: 2),
                                    child: ListTile(
                                      title: Text(
                                        e.values.first,
                                        style: TextStyle(
                                          color: scheme.onSurface,
                                        ).merge(
                                            Default_Theme.secondoryTextStyle),
                                      ),
                                      contentPadding: const EdgeInsets.only(
                                          left: 16, right: 8),
                                      leading: Icon(
                                        MingCute.history_line,
                                        size: 22,
                                        color: scheme.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                      trailing: IconButton(
                                        onPressed: () {
                                          context
                                              .read<SearchSuggestionBloc>()
                                              .add(SearchSuggestionClear(
                                                  e.values.first));
                                        },
                                        icon: Icon(
                                          MingCute.close_fill,
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.5),
                                          size: 22,
                                        ),
                                      ),
                                      onTap: () {
                                        query = e.values.first;
                                        showResults(context);
                                      },
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable inner scrolling
                          itemBuilder: (BuildContext context, int index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: GlassSurface(
                                borderRadius: BorderRadius.circular(18),
                                sigmaX: 24,
                                sigmaY: 24,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                child: ListTile(
                                  title: Text(
                                    state.suggestionList[index],
                                    style: TextStyle(
                                      color: scheme.onSurface,
                                    ).merge(Default_Theme.secondoryTextStyle),
                                  ),
                                  contentPadding:
                                      const EdgeInsets.only(left: 16, right: 8),
                                  leading: Icon(
                                    MingCute.search_line,
                                    size: 22,
                                    color:
                                        scheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {
                                      query = state.suggestionList[index];
                                    },
                                    icon: Icon(
                                      MingCute.arrow_left_up_line,
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.5),
                                      size: 22,
                                    ),
                                  ),
                                  onTap: () {
                                    query = state.suggestionList[index];
                                    showResults(context);
                                  },
                                ),
                              ),
                            );
                          },
                          itemCount: state.suggestionList.length,
                        ),
                      ],
                    ),
              _ => const Center(
                  child: SignBoardWidget(
                    message: "No Suggestions found!",
                    icon: MingCute.look_up_line,
                  ),
                ),
            },
            ),
          ),
        );
      },
    );
  }
}
