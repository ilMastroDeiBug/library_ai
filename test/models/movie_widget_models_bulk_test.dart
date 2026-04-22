import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/models/movie_widget/cast_model.dart';
import 'package:library_ai/models/movie_widget/review_model.dart';
import 'package:library_ai/models/movie_widget/watch_provider_model.dart';

void main() {
  group('Review model bulk tests', () {
    test('fromJson maps standard avatar path', () {
      final review = Review.fromJson({
        'author': 'Alice',
        'content': 'Great movie',
        'created_at': '2021-01-01',
        'author_details': {'avatar_path': '/avatar.jpg', 'rating': 8},
      });

      expect(review.author, 'Alice');
      expect(review.avatarPath, 'https://image.tmdb.org/t/p/w185/avatar.jpg');
      expect(review.rating, 8.0);
    });

    test('fromJson strips /http malformed avatar', () {
      final review = Review.fromJson({
        'author_details': {'avatar_path': '/http://cdn/avatar.jpg'},
      });

      expect(review.avatarPath, 'http://cdn/avatar.jpg');
    });

    test('fromJson fallback defaults', () {
      final review = Review.fromJson({});
      expect(review.author, 'Anonimo');
      expect(review.content, '');
      expect(review.createdAt, isNotEmpty);
    });

    for (var i = 0; i < 400; i++) {
      test('rating conversion stress #$i', () {
        final json = {
          'author': 'Author$i',
          'content': 'Content$i',
          'created_at': '2022-01-01',
          'author_details': {
            'avatar_path': '/a$i.jpg',
            'rating': (i % 10) + 0.5,
          },
        };

        final review = Review.fromJson(json);
        expect(review.author, 'Author$i');
        expect(review.rating, ((i % 10) + 0.5).toDouble());
        expect(review.avatarPath, contains('/a$i.jpg'));
      });
    }
  });

  group('CastMember model bulk tests', () {
    test('fromJson standard mapping', () {
      final cast = CastMember.fromJson({
        'name': 'Leonardo DiCaprio',
        'character': 'Cobb',
        'profile_path': '/leo.jpg',
      });

      expect(cast.name, 'Leonardo DiCaprio');
      expect(cast.character, 'Cobb');
      expect(cast.fullProfileUrl, 'https://image.tmdb.org/t/p/w185/leo.jpg');
    });

    test('fromJson fallback values', () {
      final cast = CastMember.fromJson({});
      expect(cast.name, 'Sconosciuto');
      expect(cast.character, 'Ruolo non specificato');
      expect(cast.fullProfileUrl, '');
    });

    for (var i = 0; i < 400; i++) {
      test('profile url stress #$i', () {
        final cast = CastMember.fromJson({
          'name': 'Name$i',
          'character': 'Character$i',
          'profile_path': '/profile_$i.jpg',
        });

        expect(cast.name, 'Name$i');
        expect(cast.character, 'Character$i');
        expect(cast.fullProfileUrl, contains('/profile_$i.jpg'));
      });
    }
  });

  group('Watch providers model bulk tests', () {
    test('WatchProviderModel.fromJson maps fields', () {
      final provider = WatchProviderModel.fromJson({
        'provider_name': 'Prime Video',
        'logo_path': '/prime.png',
        'provider_id': 119,
      });

      expect(provider.providerName, 'Prime Video');
      expect(provider.providerId, 119);
      expect(
        provider.fullLogoUrl,
        'https://image.tmdb.org/t/p/original/prime.png',
      );
    });

    test('WatchProvidersResult.empty returns empty lists', () {
      final result = WatchProvidersResult.empty();
      expect(result.flatrate, isEmpty);
      expect(result.rent, isEmpty);
      expect(result.buy, isEmpty);
    });

    test('WatchProvidersResult.fromJson parses all lists', () {
      final result = WatchProvidersResult.fromJson({
        'link': 'https://tmdb/providers',
        'flatrate': [
          {'provider_name': 'Netflix', 'logo_path': '/n.png', 'provider_id': 8},
        ],
        'rent': [
          {
            'provider_name': 'Apple TV',
            'logo_path': '/a.png',
            'provider_id': 2,
          },
        ],
        'buy': [
          {'provider_name': 'Google', 'logo_path': '/g.png', 'provider_id': 3},
        ],
      });

      expect(result.link, 'https://tmdb/providers');
      expect(result.flatrate.length, 1);
      expect(result.rent.length, 1);
      expect(result.buy.length, 1);
    });

    for (var i = 0; i < 300; i++) {
      test('fromJson partial structures stress #$i', () {
        final result = WatchProvidersResult.fromJson({
          'flatrate': [
            {
              'provider_name': 'Provider$i',
              'logo_path': '/logo_$i.png',
              'provider_id': i,
            },
          ],
        });

        expect(result.flatrate.first.providerName, 'Provider$i');
        expect(result.rent, isEmpty);
        expect(result.buy, isEmpty);
      });
    }
  });
}
