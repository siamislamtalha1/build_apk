import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:equatable/equatable.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final List<PlayStatisticsDB> topSongs;
  final List<Map<String, dynamic>> topArtists;
  final List<Map<String, dynamic>> topAlbums;
  final DateTime lastUpdated;

  const StatisticsLoaded({
    required this.topSongs,
    required this.topArtists,
    required this.topAlbums,
    required this.lastUpdated,
  });

  @override
  List<Object> get props => [topSongs, topArtists, topAlbums, lastUpdated];
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object> get props => [message];
}
