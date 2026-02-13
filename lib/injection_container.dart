import 'package:get_it/get_it.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/repositories/user_repository.dart';
import 'package:library_ai/domain/repositories/book_repository.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';

import 'package:library_ai/data/firebase_auth_repository.dart';
import 'package:library_ai/data/firebase_user_repository.dart';
import 'package:library_ai/data/book_repository_impl.dart';
import 'package:library_ai/data/movie_repository_impl.dart';

import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';

final sl = GetIt.instance;

Future<void> init() async {
  if (sl.isRegistered<AuthRepository>()) return;

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository());
  sl.registerLazySingleton<UserRepository>(() => FirebaseUserRepository());
  sl.registerLazySingleton<BookRepository>(() => BookRepositoryImpl());
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

  // Use Cases (Books)
  sl.registerLazySingleton(() => GetUserBooksUseCase(sl()));
  sl.registerLazySingleton(() => AddBookUseCase(sl()));
  sl.registerLazySingleton(() => DeleteBookUseCase(sl()));
  sl.registerLazySingleton(() => ToggleBookStatusUseCase(sl()));
  sl.registerLazySingleton(() => SaveBookAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => SearchBooksUseCase(sl()));
  sl.registerLazySingleton(() => GetBooksByCategoryUseCase(sl()));

  // Use Cases (Movies)
  sl.registerLazySingleton(() => GetWatchlistUseCase(sl()));
  sl.registerLazySingleton(() => ToggleMovieStatusUseCase(sl()));
  sl.registerLazySingleton(() => SaveMovieUseCase(sl()));
  sl.registerLazySingleton(() => SaveMovieAnalysisUseCase(sl()));
  sl.registerLazySingleton(() => DeleteMovieUseCase(sl()));
  sl.registerLazySingleton(() => GetMoviesByCategoryUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieReviewsUseCase(sl()));
  sl.registerLazySingleton(() => GetMovieCastUseCase(sl()));
}
