import 'package:get_it/get_it.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/repositories/user_repository.dart';
import 'package:library_ai/domain/repositories/book_repository.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/repositories/explore_repository.dart';
import 'package:library_ai/domain/repositories/favorite_repository.dart';
import 'package:library_ai/domain/repositories/review_repository.dart';
import 'package:library_ai/data/supabase_book_repository_impl.dart';
import 'package:library_ai/data/supabase_auth_repository_impl.dart';
import 'package:library_ai/data/supabase_user_repository_impl.dart';
import 'package:library_ai/data/explore_repository_impl.dart';
import 'package:library_ai/data/supabase_movie_repository_impl.dart';
import 'package:library_ai/data/supabase_favorites_repository_impl.dart';
import 'package:library_ai/data/supabase_review_repository_impl.dart';
import 'package:library_ai/domain/repositories/ai_repository.dart';
import 'package:library_ai/data/supabase_ai_repository_impl.dart';
import 'package:library_ai/domain/use_cases/ai_use_cases.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/explore_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/domain/use_cases/favorite_use_cases.dart';
import 'package:library_ai/domain/use_cases/review_use_cases.dart';
import 'package:library_ai/domain/use_cases/import_letterboxd_use_case.dart';
import 'package:library_ai/domain/use_cases/export_user_data_use_case.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import 'package:library_ai/services/utility_services/network_status_service.dart';
import 'package:library_ai/domain/repositories/actor_repository.dart';
import 'package:library_ai/data/tmdb_actor_repository_impl.dart';
import 'package:library_ai/domain/use_cases/actor_use_cases.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/services/utility_services/cinelib_cache_service.dart';
import 'package:library_ai/services/utility_services/review_author_sync_service.dart';
import 'package:library_ai/domain/repositories/tv_progress_repository.dart';
import 'package:library_ai/data/supabase_tv_progress_repository_impl.dart';
// IMPORTA IL FILE DOVE HAI MESSO GLI USE CASE DEL PROGRESSO!
import 'package:library_ai/domain/use_cases/tv_series_progress_use_cases.dart'; // Sostituisci col nome reale del file se diverso

// Rating
import 'package:library_ai/domain/repositories/rating_repository.dart';
import 'package:library_ai/data/repositories/supabase_rating_repository_impl.dart';
import 'package:library_ai/domain/use_cases/save_rating_use_case.dart';

// Import Services Libri (DORMIENTI)
import 'package:library_ai/services/utility_services/open_library_service.dart';
import 'package:library_ai/services/utility_services/google_books_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart'; // Import necessario per passare il client al repository

final sl = GetIt.instance;

Future<void> init() async {
  if (sl.isRegistered<AuthRepository>()) return;

  // =========================================================================
  // EXTERNAL SERVICES / DATA SOURCES
  // =========================================================================
  sl.registerLazySingleton<TmdbService>(() => TmdbService());
  sl.registerLazySingleton<CinelibCacheService>(() => CinelibCacheService());
  sl.registerLazySingleton<ReviewAuthorSyncService>(
    () => ReviewAuthorSyncService(),
  );

  // 🔒 Libri (Dormienti)
  sl.registerLazySingleton<OpenLibraryService>(() => OpenLibraryService());
  sl.registerLazySingleton<GoogleBooksService>(() => GoogleBooksService());

  // =========================================================================
  // REPOSITORIES
  // =========================================================================
  sl.registerLazySingleton<AuthRepository>(
    () => SupabaseAuthRepositoryImpl(reviewAuthorSyncService: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => SupabaseUserRepositoryImpl(reviewAuthorSyncService: sl()),
  );
  sl.registerLazySingleton<ReviewRepository>(
    () => SupabaseReviewRepositoryImpl(),
  );

  sl.registerLazySingleton<ActorRepository>(
    () => TmdbActorRepositoryImpl(tmdbService: sl()),
  );

  sl.registerLazySingleton<BookRepository>(
    () => SupabaseBookRepositoryImpl(
      openLibraryService: sl(),
      googleBooksService: sl(),
      cacheService: sl(),
    ),
  );

  sl.registerLazySingleton<MovieRepository>(
    () => SupabaseMovieRepositoryImpl(tmdbService: sl(), cacheService: sl()),
  );

  sl.registerLazySingleton<ExploreRepository>(() => ExploreRepositoryImpl());

  sl.registerLazySingleton<FavoritesRepository>(
    () => SupabaseFavoritesRepositoryImpl(),
  );

  // REGISTRAZIONE REPOSITORY PROGRESSO TV
  sl.registerLazySingleton<TvProgressRepository>(
    () => SupabaseTvProgressRepositoryImpl(
      supabaseClient: Supabase.instance.client,
    ),
  );

  // REGISTRAZIONE REPOSITORY RATING
  sl.registerLazySingleton<RatingRepository>(
    () => SupabaseRatingRepositoryImpl(
      supabase: Supabase.instance.client,
    ),
  );

  // =========================================================================
  // USE CASES
  // =========================================================================

  sl.registerLazySingleton<AiRepository>(
    () => SupabaseAiRepositoryImpl(Supabase.instance.client),
  );

  // Auth & User...
  sl.registerLazySingleton(() => LoginWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GoogleLoginUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAccountUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAvatarUseCase(sl()));
  sl.registerLazySingleton(() => GetUserDataUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBioUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePrivacyUseCase(sl()));
  sl.registerLazySingleton(() => LanguageService());
  sl.registerLazySingleton(() => UpdateLanguagePreferenceUseCase(sl()));
  sl.registerLazySingleton(() => NetworkStatusService());
  sl.registerLazySingleton(() => UpdateNameUseCase(sl()));

  // Books...
  sl.registerLazySingleton(() => GetUserBooksUseCase(sl()));
  sl.registerLazySingleton(() => AddBookUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBookUseCase(sl()));
  sl.registerLazySingleton(() => ToggleBookStatusUseCase(sl()));
  sl.registerLazySingleton(() => SaveBookAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => SearchBooksUseCase(sl()));
  sl.registerLazySingleton(() => GetBooksByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetSingleBookUseCase(sl()));
  sl.registerLazySingleton(() => GetFullBookDetailsUseCase(sl()));

  // Movies...
  sl.registerLazySingleton(() => GetWatchlistUseCase(sl()));
  sl.registerLazySingleton(() => ToggleMovieStatusUseCase(sl()));
  sl.registerLazySingleton(() => SaveMovieUseCase(sl()));
  sl.registerLazySingleton(() => SaveMovieAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMovieUseCase(sl()));
  sl.registerLazySingleton(() => GetMoviesByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieCastUseCase(sl()));
  sl.registerLazySingleton(() => AnalyzeMovieUseCase(sl()));
  sl.registerLazySingleton(() => SearchMoviesUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieTrailerUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieWatchProvidersUseCase(sl()));
  sl.registerLazySingleton(() => GetSingleMovieUseCase(sl()));
  sl.registerLazySingleton(() => ImportLetterboxdUseCase(
        tmdbService: sl(),
        saveMovieUseCase: sl(),
        submitReviewUseCase: sl(),
        toggleFavoriteUseCase: sl(),
      ));
  sl.registerLazySingleton(() => ExportUserDataUseCase(Supabase.instance.client));

  // AI Use Cases...
  sl.registerLazySingleton(() => GetAiTokensUseCase(sl()));
  sl.registerLazySingleton(() => CallAiFunctionUseCase(sl()));

  // TV Series...
  sl.registerLazySingleton(() => GetTvSeriesByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => SearchTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => GetTvSeriesCastUseCase(sl()));
  sl.registerLazySingleton(() => AnalyzeTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => GetTvSeriesTrailerUseCase(sl()));
  sl.registerLazySingleton(() => GetTvSeriesWatchProvidersUseCase(sl()));
  sl.registerLazySingleton(() => SaveTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => ToggleTvSeriesStatusUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => SaveTvSeriesAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => GetSingleTvSeriesUseCase(sl()));

  // TV Series Progress (NUOVI!)
  sl.registerLazySingleton(() => GetSeriesProgressUseCase(sl()));
  sl.registerLazySingleton(() => GetAllUserProgressUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSeriesProgressUseCase(sl())); // NUOVO
  sl.registerLazySingleton(() => ToggleEpisodeWatchedUseCase(sl()));

  // Explore...
  sl.registerLazySingleton(() => GetExploreCategoriesUseCase(sl()));

  // Actors...
  sl.registerLazySingleton(() => GetActorDetailsUseCase(sl()));
  sl.registerLazySingleton(() => SearchActorsUseCase(sl()));

  // Favorites...
  sl.registerLazySingleton(() => ToggleFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => GetFavoritesStreamUseCase(sl()));
  sl.registerLazySingleton(() => CheckFavoriteStatusUseCase(sl()));

  // Reviews...
  sl.registerLazySingleton(() => GetMediaReviewsUseCase(sl()));
  sl.registerLazySingleton(() => SubmitReviewUseCase(sl()));
  sl.registerLazySingleton(() => VoteReviewUseCase(sl()));
  sl.registerLazySingleton(() => DeleteReviewUseCase(sl()));

  // Ratings...
  sl.registerLazySingleton(() => SaveRatingUseCase(sl()));
}
