import 'package:get_it/get_it.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/repositories/user_repository.dart';
import 'package:library_ai/domain/repositories/book_repository.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/repositories/explore_repository.dart';
import 'package:library_ai/data/firebase_user_repository.dart';
import 'package:library_ai/data/book_repository_impl.dart'; // Vecchia implementazione Firebase (puoi tenerla per backup)
import 'package:library_ai/data/supabase_book_repository_impl.dart'; // <-- NUOVO IMPORT SUPABASE
import 'package:library_ai/data/movie_repository_impl.dart';
import 'package:library_ai/data/supabase_auth_repository_impl.dart';
import 'package:library_ai/data/supabase_user_repository_impl.dart';
import 'package:library_ai/data/explore_repository_impl.dart';

import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/explore_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/services/utility_services/language_service.dart';

final sl = GetIt.instance;

Future<void> init() async {
  if (sl.isRegistered<AuthRepository>()) return;

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => SupabaseAuthRepositoryImpl());
  sl.registerLazySingleton<UserRepository>(() => SupabaseUserRepositoryImpl());
  sl.registerLazySingleton<BookRepository>(
    () => SupabaseBookRepositoryImpl(),
  ); // <-- LA MAGIA È QUI
  sl.registerLazySingleton<MovieRepository>(() => MovieRepositoryImpl());

  // Use Cases (Auth)
  sl.registerLazySingleton(() => LoginWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => GoogleLoginUseCase(sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => ResetPasswordUseCase(sl()));

  // Use Cases (User)
  sl.registerLazySingleton(() => GetUserDataUseCase(sl()));
  sl.registerLazySingleton(() => UpdateBioUseCase(sl()));
  sl.registerLazySingleton(() => UpdatePrivacyUseCase(sl()));
  sl.registerLazySingleton(() => LanguageService());

  // Use Cases (Books)
  sl.registerLazySingleton(() => GetUserBooksUseCase(sl()));
  sl.registerLazySingleton(() => AddBookUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBookUseCase(sl()));
  sl.registerLazySingleton(() => ToggleBookStatusUseCase(sl()));
  sl.registerLazySingleton(() => SaveBookAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => SearchBooksUseCase(sl()));
  sl.registerLazySingleton(() => GetBooksByCategoryUseCase(sl()));

  // <-- IL PEZZO MANCANTE CHE CAUSAVA IL CRASH È QUI:
  sl.registerLazySingleton(() => GetSingleBookUseCase(sl()));

  // Use Cases (Movies)
  sl.registerLazySingleton(() => GetWatchlistUseCase(sl()));
  sl.registerLazySingleton(() => ToggleMovieStatusUseCase(sl()));
  sl.registerLazySingleton(() => SaveMovieUseCase(sl()));
  sl.registerLazySingleton(() => SaveMovieAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMovieUseCase(sl()));
  sl.registerLazySingleton(() => GetMoviesByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieReviewsUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieCastUseCase(sl()));
  sl.registerLazySingleton(() => AnalyzeMovieUseCase(sl()));
  sl.registerLazySingleton(() => SearchMoviesUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieTrailerUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieWatchProvidersUseCase(sl()));

  // --- TV SERIES USE CASES ---
  // API
  sl.registerLazySingleton(() => GetTvSeriesByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => SearchTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => GetTvSeriesReviewsUseCase(sl()));
  sl.registerLazySingleton(() => GetTvSeriesCastUseCase(sl()));
  sl.registerLazySingleton(() => AnalyzeTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => GetTvSeriesTrailerUseCase(sl()));
  sl.registerLazySingleton(() => GetTvSeriesWatchProvidersUseCase(sl()));

  // DB
  sl.registerLazySingleton(() => SaveTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => ToggleTvSeriesStatusUseCase(sl()));
  sl.registerLazySingleton(() => DeleteTvSeriesUseCase(sl()));
  sl.registerLazySingleton(() => SaveTvSeriesAnalysisUseCase(sl()));

  // Explore (Domain & Data)
  sl.registerLazySingleton<ExploreRepository>(() => ExploreRepositoryImpl());
  sl.registerLazySingleton(() => GetExploreCategoriesUseCase(sl()));
}
