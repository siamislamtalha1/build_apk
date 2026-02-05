import 'dart:ui';
import 'package:Bloomee/model/search_filter_model.dart';
import 'package:Bloomee/theme_data/default.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class SearchFilterBottomSheet extends StatefulWidget {
  final SearchFilter currentFilter;
  final Function(SearchFilter) onFilterChanged;

  const SearchFilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  State<SearchFilterBottomSheet> createState() =>
      _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends State<SearchFilterBottomSheet> {
  late SearchFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = scheme.primary;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: (isDark ? scheme.surfaceContainerHighest : scheme.surface)
                .withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.08),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Search Filters',
                    style: Default_Theme.primaryTextStyle.merge(
                      TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Default_Theme.primaryColor1,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      MingCute.close_circle_fill,
                      color: Default_Theme.primaryColor1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sources Section
              Text(
                'Sources',
                style: Default_Theme.secondoryTextStyle.merge(
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _buildFilterTile(
                title: 'JioSaavn',
                icon: MingCute.music_2_fill,
                value: _filter.includeJioSaavn,
                onChanged: (value) {
                  setState(() {
                    _filter = _filter.copyWith(includeJioSaavn: value);
                  });
                },
              ),

              _buildFilterTile(
                title: 'YouTube Music',
                icon: MingCute.youtube_fill,
                value: _filter.includeYTMusic,
                onChanged: (value) {
                  setState(() {
                    _filter = _filter.copyWith(includeYTMusic: value);
                  });
                },
              ),

              _buildFilterTile(
                title: 'YouTube Video',
                icon: MingCute.video_fill,
                value: _filter.includeYTVideo,
                onChanged: (value) {
                  setState(() {
                    _filter = _filter.copyWith(includeYTVideo: value);
                  });
                },
              ),

              const SizedBox(height: 20),

              // Sort By Section
              Text(
                'Sort By',
                style: Default_Theme.secondoryTextStyle.merge(
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                children: SearchSortBy.values.map((sortBy) {
                  final isSelected = _filter.sortBy == sortBy;
                  return ChoiceChip(
                    label: Text(sortBy.displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _filter = _filter.copyWith(sortBy: sortBy);
                        });
                      }
                    },
                    backgroundColor:
                        Default_Theme.primaryColor2.withValues(alpha: 0.1),
                    selectedColor:
                        accent.withValues(alpha: 0.3),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? accent
                          : Default_Theme.primaryColor1,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? accent
                          : scheme.onSurface.withValues(alpha: isDark ? 0.10 : 0.08),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_filter.hasAnySourceEnabled) {
                      widget.onFilterChanged(_filter);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Please select at least one source'),
                          backgroundColor: accent,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Default_Theme.primaryColor1,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Default_Theme.primaryColor2.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(
              icon,
              color: Default_Theme.primaryColor1,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: Default_Theme.secondoryTextStyle.merge(
                TextStyle(
                  color: Default_Theme.primaryColor1,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.primary,
        activeTrackColor:
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
      ),
    );
  }
}
