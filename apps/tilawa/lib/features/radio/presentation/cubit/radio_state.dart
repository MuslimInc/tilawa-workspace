import 'package:equatable/equatable.dart';
import 'package:tilawa_core/errors/failures.dart';

import '../../domain/entities/radio_station.dart';

enum RadioStatus { initial, loading, loaded, empty, error }

class RadioState extends Equatable {
  const RadioState({
    this.status = RadioStatus.initial,
    this.stations = const <RadioStation>[],
    this.filteredStations = const <RadioStation>[],
    this.favorites = const <RadioStation>[],
    this.recent = const <RadioStation>[],
    this.featured,
    this.searchQuery = '',
    this.failure,
    this.isOffline = false,
    this.isRefreshing = false,
  });

  final RadioStatus status;
  final List<RadioStation> stations;
  final List<RadioStation> filteredStations;
  final List<RadioStation> favorites;
  final List<RadioStation> recent;
  final RadioStation? featured;
  final String searchQuery;
  final Failure? failure;
  final bool isOffline;
  final bool isRefreshing;

  bool get hasSearch => searchQuery.trim().isNotEmpty;

  List<RadioStation> get visibleStations =>
      hasSearch ? filteredStations : stations;

  RadioState copyWith({
    RadioStatus? status,
    List<RadioStation>? stations,
    List<RadioStation>? filteredStations,
    List<RadioStation>? favorites,
    List<RadioStation>? recent,
    RadioStation? featured,
    bool clearFeatured = false,
    String? searchQuery,
    Failure? failure,
    bool clearFailure = false,
    bool? isOffline,
    bool? isRefreshing,
  }) {
    return RadioState(
      status: status ?? this.status,
      stations: stations ?? this.stations,
      filteredStations: filteredStations ?? this.filteredStations,
      favorites: favorites ?? this.favorites,
      recent: recent ?? this.recent,
      featured: clearFeatured ? null : (featured ?? this.featured),
      searchQuery: searchQuery ?? this.searchQuery,
      failure: clearFailure ? null : (failure ?? this.failure),
      isOffline: isOffline ?? this.isOffline,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    stations,
    filteredStations,
    favorites,
    recent,
    featured,
    searchQuery,
    failure,
    isOffline,
    isRefreshing,
  ];
}
