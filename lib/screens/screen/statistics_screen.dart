import 'package:Bloomee/blocs/statistics/statistics_cubit.dart';
import 'package:Bloomee/blocs/statistics/statistics_state.dart';
import 'package:Bloomee/model/time_period.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatisticsCubit()..loadStatistics(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistics'),
          actions: [
            IconButton(
              icon: const Icon(EvaIcons.refresh),
              onPressed: () => context.read<StatisticsCubit>().loadStatistics(),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildPeriodFilter(context),
            Expanded(
              child: BlocBuilder<StatisticsCubit, StatisticsState>(
                builder: (context, state) {
                  if (state is StatisticsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is StatisticsError) {
                    return Center(child: Text(state.message));
                  } else if (state is StatisticsLoaded) {
                    return ListView(
                      children: [
                        _buildTopSongsSection(context, state),
                        const SizedBox(height: 20),
                        _buildTopArtistsSection(context, state),
                        const SizedBox(height: 50),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodFilter(BuildContext context) {
    return SizedBox(
      height: 60,
      child: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          final cubit = context.read<StatisticsCubit>();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: TimePeriod.values.length,
            itemBuilder: (context, index) {
              final period = TimePeriod.values[index];
              final isSelected = cubit.currentPeriod == period;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(TimePeriodHelper.getDisplayName(period)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      cubit.updatePeriod(period);
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTopSongsSection(BuildContext context, StatisticsLoaded state) {
    if (state.topSongs.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Text('Top Songs', style: Theme.of(context).textTheme.titleLarge),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.topSongs.length,
          itemBuilder: (context, index) {
            final song = state.topSongs[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text("${index + 1}"),
              ),
              title: Text(song.title,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(song.artist,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Text("${song.playCount} plays"),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTopArtistsSection(BuildContext context, StatisticsLoaded state) {
    if (state.topArtists.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Top Artists',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.topArtists.length,
            itemBuilder: (context, index) {
              final artist = state.topArtists[index];
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      child: Icon(
                          EvaIcons.person), // Placeholder for artist image
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist['artist'] ?? "Unknown",
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("${artist['count']} plays",
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
