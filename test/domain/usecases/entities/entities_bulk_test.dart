import 'package:flutter_test/flutter_test.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';

void main() {
  group('Book entity bulk tests', () {
    final googleCases = [
      {
        'name': 'google full payload',
        'json': {
          'id': 'g1',
          'volumeInfo': {
            'title': 'Titolo Google',
            'authors': ['Autore 1', 'Autore 2'],
            'description': 'Descrizione',
            'imageLinks': {'thumbnail': 'https://img'},
            'pageCount': 350,
            'averageRating': 4.7,
            'ratingsCount': 100,
          },
        },
        'expectedTitle': 'Titolo Google',
        'expectedAuthor': 'Autore 1',
        'expectedRating': 4.7,
        'expectedRatingsCount': 100,
      },
      {
        'name': 'google fallback values',
        'json': {
          'id': 'g2',
          'volumeInfo': {'title': 'Solo Titolo'},
        },
        'expectedTitle': 'Solo Titolo',
        'expectedAuthor': 'Sconosciuto',
        'expectedRating': 0.0,
        'expectedRatingsCount': 0,
      },
      {
        'name': 'google description custom',
        'json': {
          'id': 'g3',
          'volumeInfo': {
            'title': 'T3',
            'authors': ['A3'],
            'description': 'd3',
          },
        },
        'expectedTitle': 'T3',
        'expectedAuthor': 'A3',
        'expectedRating': 0.0,
        'expectedRatingsCount': 0,
      },
    ];

    for (final tc in googleCases) {
      test('Book.fromApi: ${tc['name']}', () {
        final book = Book.fromApi(tc['json']! as Map<String, dynamic>);
        expect(book.title, tc['expectedTitle']);
        expect(book.author, tc['expectedAuthor']);
        expect(book.rating, tc['expectedRating']);
        expect(book.ratingsCount, tc['expectedRatingsCount']);
      });
    }

    final openLibraryCases = [
      {
        'json': {
          'key': '/works/OL1W',
          'title': 'OL Title 1',
          'author_name': ['OL Author'],
          'cover_i': 99,
          'ratings_average': 3.4,
          'ratings_count': 12,
          'number_of_pages_median': 120,
          'first_sentence': ['Init sentence'],
        },
        'id': '_works_OL1W',
      },
      {
        'json': {
          'key': '/works/OL2W',
          'title': 'OL Title 2',
          'author': 'Author 2',
          'ratings_average': 0,
          'ratings_count': 0,
        },
        'id': '_works_OL2W',
      },
    ];

    for (final tc in openLibraryCases) {
      test('Book.fromApi OpenLibrary id sanitization ${tc['id']}', () {
        final book = Book.fromApi(tc['json']! as Map<String, dynamic>);
        expect(book.id, tc['id']);
      });
    }

    for (var i = 0; i < 60; i++) {
      test('Book.fromFirestore default mapping stress #$i', () {
        final book = Book.fromFirestore({}, 'id_$i');
        expect(book.id, 'id_$i');
        expect(book.title, 'Senza Titolo');
        expect(book.author, 'Sconosciuto');
        expect(book.status, 'toread');
        expect(book.rating, 0.0);
      });
    }

    for (var i = 0; i < 30; i++) {
      test('Book.toMap preserves aiAnalysis when present #$i', () {
        final book = Book(
          id: 'id_$i',
          title: 't$i',
          author: 'a$i',
          aiAnalysis: 'analysis_$i',
          rating: i / 10,
        );
        final map = book.toMap();
        expect(map['title'], 't$i');
        expect(map['aiAnalysis'], 'analysis_$i');
      });
    }
  });

  group('Movie + TvSeries entity bulk tests', () {
    test('Movie.fromTmdb full mapping', () {
      final movie = Movie.fromTmdb({
        'id': 10,
        'title': 'Inception',
        'overview': 'Dream',
        'poster_path': '/p.jpg',
        'backdrop_path': '/b.jpg',
        'vote_average': 8.8,
        'vote_count': 1000,
        'release_date': '2010-07-16',
      });

      expect(movie.id, 10);
      expect(movie.fullPosterUrl, 'https://image.tmdb.org/t/p/w500/p.jpg');
      expect(movie.fullBackdropUrl, 'https://image.tmdb.org/t/p/w780/b.jpg');
    });

    test('Movie.copyWith overrides fields', () {
      final movie = Movie(
        id: 1,
        title: 't',
        overview: 'o',
        posterPath: '',
        backdropPath: '',
        voteAverage: 1,
        voteCount: 2,
        releaseDate: 'r',
      );
      final updated = movie.copyWith(title: 't2', status: 'watched');
      expect(updated.title, 't2');
      expect(updated.status, 'watched');
      expect(updated.id, 1);
    });

    for (var i = 0; i < 40; i++) {
      test('Movie.fromFirestore stress #$i', () {
        final movie = Movie.fromFirestore({
          'title': 'M$i',
          'overview': 'O$i',
          'voteAverage': i / 10,
          'voteCount': i,
          'status': i.isEven ? 'watched' : 'towatch',
        }, i);

        expect(movie.id, i);
        expect(movie.title, 'M$i');
        expect(movie.voteCount, i);
      });
    }

    test('TvSeries.fromTmdb full mapping', () {
      final tv = TvSeries.fromTmdb({
        'id': 20,
        'name': 'Dark',
        'overview': 'Time travel',
        'poster_path': '/pt.jpg',
        'backdrop_path': '/bt.jpg',
        'vote_average': 8.5,
        'vote_count': 500,
        'first_air_date': '2017-12-01',
      });

      expect(tv.name, 'Dark');
      expect(tv.fullPosterUrl, 'https://image.tmdb.org/t/p/w500/pt.jpg');
    });

    for (var i = 0; i < 40; i++) {
      test('TvSeries.toMap keeps type tv #$i', () {
        final tv = TvSeries(
          id: i,
          name: 'Series$i',
          overview: 'Overview$i',
          posterPath: '/p$i.jpg',
          backdropPath: '/b$i.jpg',
          voteAverage: 7.0,
          voteCount: i,
          firstAirDate: '2020-01-01',
        );
        final map = tv.toMap();
        expect(map['title'], 'Series$i');
        expect(map['type'], 'tv');
      });
    }
  });
}
