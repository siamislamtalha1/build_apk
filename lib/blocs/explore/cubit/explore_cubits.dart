// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';
import 'package:Bloomee/repository/Youtube/yt_music_home.dart';
import 'package:Bloomee/services/db/GlobalDB.dart';
import 'package:Bloomee/utils/country_info.dart';
import 'package:Bloomee/model/MediaPlaylistModel.dart';
import 'package:Bloomee/model/chart_model.dart';
import 'package:Bloomee/plugins/ext_charts/chart_defines.dart';
import 'package:Bloomee/repository/Youtube/yt_charts_home.dart';
import 'package:Bloomee/screens/screen/chart/show_charts.dart';
import 'package:Bloomee/services/db/bloomee_db_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
part 'explore_states.dart';

class TrendingCubit extends Cubit<TrendingCubitState> {
  bool isLatest = false;
  TrendingCubit() : super(TrendingCubitInitial()) {
    getTrendingVideosFromDB();
    getTrendingVideos();
  }

  void getTrendingVideos() async {
    try {
      List<ChartModel> ytCharts = await fetchTrendingVideos();
      if (ytCharts.isEmpty) return;
      ChartModel chart = ytCharts[0]
        ..chartItems = getFirstElements(ytCharts[0].chartItems!, 16);
      if (isClosed) return;
      emit(state.copyWith(ytCharts: [chart]));
      isLatest = true;
    } catch (e, st) {
      log("Trending fetch failed: $e", name: "Trending", stackTrace: st);
    }
  }

  List<ChartItemModel> getFirstElements(List<ChartItemModel> list, int count) {
    return list.length > count ? list.sublist(0, count) : list;
  }

  void getTrendingVideosFromDB() async {
    try {
      ChartModel? ytChart = await BloomeeDBService.getChart("Trending Videos");
      if ((!isLatest) &&
          ytChart != null &&
          (ytChart.chartItems?.isNotEmpty ?? false)) {
        ChartModel chart = ytChart
          ..chartItems = getFirstElements(ytChart.chartItems!, 16);
        if (isClosed) return;
        emit(state.copyWith(ytCharts: [chart]));
      }
    } catch (e, st) {
      log("Trending DB load failed: $e", name: "Trending", stackTrace: st);
    }
  }
}

class RecentlyCubit extends Cubit<RecentlyCubitState> {
  StreamSubscription<void>? watcher;
  RecentlyCubit() : super(RecentlyCubitInitial()) {
    getRecentlyPlayed();
    watchRecentlyPlayed();
  }

  Future<void> watchRecentlyPlayed() async {
    watcher = (await BloomeeDBService.watchRecentlyPlayed()).listen((event) {
      getRecentlyPlayed();
      log("Recently Played Updated");
    });
  }

  @override
  Future<void> close() {
    watcher?.cancel();
    return super.close();
  }

  void getRecentlyPlayed() async {
    try {
      final mediaPlaylist =
          await BloomeeDBService.getRecentlyPlayed(limit: 15);
      if (isClosed) return;
      emit(state.copyWith(mediaPlaylist: mediaPlaylist));
    } catch (e, st) {
      log("Recently played load failed: $e", name: "Recently", stackTrace: st);
    }
  }
}

class ChartCubit extends Cubit<ChartState> {
  ChartInfo chartInfo;
  StreamSubscription? strm;
  FetchChartCubit fetchChartCubit;
  ChartCubit(
    this.chartInfo,
    this.fetchChartCubit,
  ) : super(ChartInitial()) {
    getChartFromDB();
    initListener();
  }
  void initListener() {
    strm = fetchChartCubit.stream.listen(
      (state) {
        if (state.isFetched) {
          log("Chart Fetched from Isolate - ${chartInfo.title}",
              name: "Isolate Fetched");
          getChartFromDB();
        }
      },
      onError: (Object e, StackTrace st) {
        log("ChartCubit stream error: $e", name: "Isolate", stackTrace: st);
      },
    );
  }

  Future<void> getChartFromDB() async {
    try {
      final chart = await BloomeeDBService.getChart(chartInfo.title);
      if (chart != null) {
        if (isClosed) return;
        emit(state.copyWith(
            chart: chart, coverImg: chart.chartItems?.first.imageUrl));
      }
    } catch (e, st) {
      log("Chart DB load failed: $e", name: "ChartCubit", stackTrace: st);
    }
  }

  @override
  Future<void> close() {
    fetchChartCubit.close();
    strm?.cancel();
    return super.close();
  }
}

Map<String, List<dynamic>> parseYTMusicData(String source) {
  final dynamicMap = jsonDecode(source);

  Map<String, List<dynamic>> listDynamicMap;
  if (dynamicMap is Map) {
    listDynamicMap = dynamicMap.map((key, value) {
      List<dynamic> list = [];
      if (value is List) {
        list = value;
      }
      return MapEntry(key, list);
    });
  } else {
    listDynamicMap = {};
  }
  return listDynamicMap;
}

class FetchChartCubit extends Cubit<FetchChartState> {
  FetchChartCubit() : super(FetchChartInitial()) {
    fetchCharts();
  }

  Future<void> fetchCharts() async {
    try {
      String path = (await getApplicationSupportDirectory()).path;
      BackgroundIsolateBinaryMessenger.ensureInitialized(
        ServicesBinding.rootIsolateToken!,
      );
      await BloomeeDBService.db;
      List<ChartModel> chartList = <ChartModel>[];
      try {
        chartList = await Isolate.run<List<ChartModel>>(() async {
          log(path, name: "Isolate Path");
          final chartList0 = <ChartModel>[];
          final db = await Isar.open(
            [
              ChartsCacheDBSchema,
            ],
            directory: path,
          );
          try {
            for (var i in chartInfoList) {
              final chartCacheDB = db.chartsCacheDBs
                  .where()
                  .filter()
                  .chartNameEqualTo(i.title)
                  .findFirstSync();
              final shouldFetch = (chartCacheDB?.lastUpdated
                          .difference(DateTime.now())
                          .inHours
                          .abs() ??
                      80) >
                  16;
              log(
                "Last Updated - ${(chartCacheDB?.lastUpdated.difference(DateTime.now()).inHours)?.abs()} Hours before ",
                name: "Isolate",
              );

              if (!shouldFetch) continue;

              ChartModel chart;
              try {
                chart = await i.chartFunction(i.url);
              } catch (e, st) {
                log(
                  "Chart fetch failed - ${i.title}: $e",
                  name: "Isolate",
                  stackTrace: st,
                );
                continue;
              }

              if ((chart.chartItems?.isNotEmpty) ?? false) {
                db.writeTxnSync(() => db.chartsCacheDBs
                    .putSync(chartModelToChartCacheDB(chart)));
              }
              log("Chart Fetched - ${chart.chartName}", name: "Isolate");
              chartList0.add(chart);
            }
          } finally {
            db.close();
          }
          return chartList0;
        });
      } catch (e, st) {
        log("Charts isolate failed: $e", name: "Isolate", stackTrace: st);
        return;
      }

      if (isClosed) return;
      if (chartList.isNotEmpty) {
        if (isClosed) return;
        emit(state.copyWith(isFetched: true));
      }
    } catch (e, st) {
      log("FetchChartCubit failed: $e", name: "Isolate", stackTrace: st);
    }
  }
}

class YTMusicCubit extends Cubit<YTMusicCubitState> {
  YTMusicCubit() : super(YTMusicCubitInitial()) {
    fetchYTMusicDB();
    fetchYTMusic();
  }

  void fetchYTMusicDB() async {
    try {
      final data = await BloomeeDBService.getAPICache("YTMusic");
      if (data != null) {
        final ytmData = await compute(parseYTMusicData, data);
        if (ytmData.isNotEmpty) {
          if (isClosed) return;
          if (isClosed) return;
          emit(state.copyWith(ytmData: ytmData));
        }
      }
    } catch (e, st) {
      log("YTMusic DB load failed: $e", name: "YTMusic", stackTrace: st);
    }
  }

  Future<void> fetchYTMusic() async {
    try {
      final countryCode = await getCountry();
      if (isClosed) return;
      final ytCharts =
          await Isolate.run(() => getMusicHome(countryCode: countryCode));
      if (isClosed) return;
      if (ytCharts.isNotEmpty) {
        if (isClosed) return;
        emit(state.copyWith(ytmData: Map<String, List<dynamic>>.from(ytCharts)));
        final ytChartsJson = await compute(jsonEncode, ytCharts);
        BloomeeDBService.putAPICache("YTMusic", ytChartsJson);
        log("YTMusic Fetched", name: "YTMusic");
      }
    } catch (e) {
      log("YTMusic fetch failed: $e", name: "YTMusic");
    }
  }
}
