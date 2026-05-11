import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/repositories/tv_progress_repository.dart';
import '../domain/entities/tv_series_progress.dart';

class SupabaseTvProgressRepositoryImpl implements TvProgressRepository {
  final SupabaseClient _supabase;
  static const String _tableName = 'user_tv_progress';

  SupabaseTvProgressRepositoryImpl({SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? Supabase.instance.client;

  @override
  Future<TvSeriesProgress?> getProgress(String userId, int seriesId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('series_id', seriesId)
          .maybeSingle();

      if (response == null) return null;
      return TvSeriesProgress.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveProgress(TvSeriesProgress progress) async {
    await _supabase
        .from(_tableName)
        .upsert(progress.toMap(), onConflict: 'user_id, series_id');
  }

  @override
  Stream<TvSeriesProgress?> watchProgress(String userId, int seriesId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((events) {
          final filteredEvents = events
              .where((row) => row['series_id'] == seriesId)
              .toList();

          return filteredEvents.isEmpty
              ? null
              : TvSeriesProgress.fromMap(filteredEvents.first);
        });
  }

  @override
  Stream<List<TvSeriesProgress>> watchAllUserProgress(String userId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((events) {
          // ANTI-DUPLICATO ASSOLUTO: Usiamo una Mappa per schiacciare i doppioni
          final uniqueMap = <int, TvSeriesProgress>{};

          for (var e in events) {
            final progress = TvSeriesProgress.fromMap(e);
            // Se esiste già una serie con questo ID, viene sovrascritta. Ne passa solo una.
            uniqueMap[progress.seriesId] = progress;
          }

          return uniqueMap.values.toList();
        });
  }

  @override
  Future<void> deleteProgress(String userId, int seriesId) async {
    await _supabase
        .from(_tableName)
        .delete()
        .eq('user_id', userId)
        .eq('series_id', seriesId);
  }
}
