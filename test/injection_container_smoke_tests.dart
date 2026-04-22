import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/repositories/book_repository.dart';
import 'package:library_ai/domain/repositories/explore_repository.dart';
import 'package:library_ai/domain/repositories/movie_repository.dart';
import 'package:library_ai/domain/repositories/user_repository.dart';
import 'package:library_ai/domain/use_cases/auth_use_cases.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/injection_container.dart' as di;
import 'package:library_ai/services/utility_services/language_service.dart';

void main() {
  tearDown(() async {
    await di.sl.reset();
  });

  test('init registers critical dependencies and is idempotent', () async {
    await di.init();
    await di.init();

    expect(di.sl.isRegistered<AuthRepository>(), isTrue);
    expect(di.sl.isRegistered<UserRepository>(), isTrue);
    expect(di.sl.isRegistered<BookRepository>(), isTrue);
    expect(di.sl.isRegistered<MovieRepository>(), isTrue);
    expect(di.sl.isRegistered<ExploreRepository>(), isTrue);

    expect(di.sl.isRegistered<LoginWithEmailUseCase>(), isTrue);
    expect(di.sl.isRegistered<RegisterUseCase>(), isTrue);
    expect(di.sl.isRegistered<GoogleLoginUseCase>(), isTrue);
    expect(di.sl.isRegistered<UpdateProfileUseCase>(), isTrue);
    expect(di.sl.isRegistered<LogoutUseCase>(), isTrue);
    expect(di.sl.isRegistered<ResetPasswordUseCase>(), isTrue);
    expect(di.sl.isRegistered<DeleteAccountUseCase>(), isTrue);

    expect(di.sl.isRegistered<GetUserBooksUseCase>(), isTrue);
    expect(di.sl.isRegistered<AddBookUseCase>(), isTrue);
    expect(di.sl.isRegistered<DeleteBookUseCase>(), isTrue);
    expect(di.sl.isRegistered<GetWatchlistUseCase>(), isTrue);
    expect(di.sl.isRegistered<SaveMovieUseCase>(), isTrue);
    expect(di.sl.isRegistered<GetTvSeriesByCategoryUseCase>(), isTrue);

    expect(di.sl.isRegistered<LanguageService>(), isTrue);
  });
}
