import 'package:Bloomee/blocs/statistics/statistics_state.dart';
import 'package:Bloomee/model/time_period.dart';
import 'package:Bloomee/services/db/statistics_db_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit() : super(StatisticsInitial());

  TimePeriod _currentPeriod = TimePeriod.allTime;
  TimePeriod get currentPeriod => _currentPeriod;

  Future<void> loadStatistics({TimePeriod? period}) async {
    if (period != null) {
      _currentPeriod = period;
    }

    emit(StatisticsLoading());

    try {
      final topSongs = await StatisticsDBService.getTopSongs(
          period: _currentPeriod, limit: 50);
      final topArtists = await StatisticsDBService.getTopArtists(
          period: _currentPeriod, limit: 20);
      // Albums not fully implemented in service yet, using mock or empty for now
      // final topAlbums = await StatisticsDBService.getTopAlbums(period: _currentPeriod);

      emit(StatisticsLoaded(
        topSongs: topSongs,
        topArtists: topArtists,
        topAlbums: const [],
        lastUpdated: DateTime.now(),
      ));
    } catch (e) {
      emit(StatisticsError("Failed to load statistics: $e"));
    }
  }

  void updatePeriod(TimePeriod period) {
    loadStatistics(period: period);
  }
}
