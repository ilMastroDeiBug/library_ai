import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/explore_repository.dart';
import '../../models/app_mode.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  @override
  List<CategoryEntity> getCategoriesByMode(
    AppMode mode, {
    bool isTvSeries = false,
  }) {
    if (mode == AppMode.books) {
      return _bookCategories;
    } else {
      // Siamo nel mondo Cinema: discriminiamo tra Film e Serie TV
      return isTvSeries ? _tvCategories : _movieCategories;
    }
  }

  static const List<CategoryEntity> _bookCategories = [
    CategoryEntity(
      id: 'fiction',
      name: 'Bestsellers',
      icon: Icons.star_rounded,
    ),
    CategoryEntity(id: 'thriller', name: 'Thriller', icon: Icons.fingerprint),
    CategoryEntity(id: 'fantasy', name: 'Fantasy', icon: Icons.auto_awesome),
    CategoryEntity(
      id: 'science_fiction',
      name: 'Sci-Fi',
      icon: Icons.rocket_launch_rounded,
    ),
    CategoryEntity(id: 'mystery', name: 'Gialli', icon: Icons.search_rounded),
    CategoryEntity(
      id: 'romance',
      name: 'Romance',
      icon: Icons.favorite_rounded,
    ),
    CategoryEntity(
      id: 'historical_fiction',
      name: 'Storici',
      icon: Icons.account_balance_rounded,
    ),
    CategoryEntity(
      id: 'biography',
      name: 'Biografie',
      icon: Icons.person_rounded,
    ),
    CategoryEntity(
      id: 'business',
      name: 'Business',
      icon: Icons.trending_up_rounded,
    ),
    CategoryEntity(
      id: 'psychology',
      name: 'Psicologia',
      icon: Icons.psychology_rounded,
    ),
    CategoryEntity(id: 'art', name: 'Arte', icon: Icons.palette_rounded),
    CategoryEntity(
      id: 'graphic_novels',
      name: 'Fumetti',
      icon: Icons.layers_rounded,
    ),
  ];

  static const List<CategoryEntity> _movieCategories = [
    CategoryEntity(
      id: '28',
      name: 'Azione',
      icon: Icons.local_fire_department_rounded,
    ),
    CategoryEntity(id: '12', name: 'Avventura', icon: Icons.explore_rounded),
    CategoryEntity(id: '878', name: 'Sci-Fi', icon: Icons.rocket_rounded),
    CategoryEntity(id: '53', name: 'Thriller', icon: Icons.fingerprint),
    CategoryEntity(
      id: '35',
      name: 'Commedia',
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    CategoryEntity(
      id: '18',
      name: 'Drammatici',
      icon: Icons.theater_comedy_rounded,
    ),
    CategoryEntity(id: '80', name: 'Crime', icon: Icons.local_police_rounded),
    CategoryEntity(id: '27', name: 'Horror', icon: Icons.bug_report_rounded),
    CategoryEntity(
      id: '9648',
      name: 'Mistero',
      icon: Icons.help_outline_rounded,
    ),
    CategoryEntity(id: '14', name: 'Fantasy', icon: Icons.auto_awesome),
    CategoryEntity(id: '10749', name: 'Romance', icon: Icons.favorite_rounded),
    CategoryEntity(id: '16', name: 'Animazione', icon: Icons.animation_rounded),
  ];

  static const List<CategoryEntity> _tvCategories = [
    CategoryEntity(
      id: '10759',
      name: 'Action & Adv',
      icon: Icons.local_fire_department_rounded,
    ),
    CategoryEntity(id: '16', name: 'Animazione', icon: Icons.animation_rounded),
    CategoryEntity(
      id: '35',
      name: 'Commedia',
      icon: Icons.sentiment_very_satisfied_rounded,
    ),
    CategoryEntity(id: '80', name: 'Crime', icon: Icons.local_police_rounded),
    CategoryEntity(id: '99', name: 'Documentari', icon: Icons.videocam_rounded),
    CategoryEntity(
      id: '18',
      name: 'Drammatici',
      icon: Icons.theater_comedy_rounded,
    ),
    CategoryEntity(
      id: '10765',
      name: 'Sci-Fi & Fan',
      icon: Icons.rocket_launch_rounded,
    ),
    CategoryEntity(
      id: '9648',
      name: 'Mistero',
      icon: Icons.help_outline_rounded,
    ),
  ];
}
