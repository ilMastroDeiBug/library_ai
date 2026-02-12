import 'package:flutter/material.dart';
import '../../models/app_mode.dart';
import '../../models/category_model.dart';

class ExploreService {
  List<CategoryModel> getCategories(AppMode mode) {
    return mode == AppMode.books ? _bookCategories : _movieCategories;
  }

  // --- CONFIGURAZIONE COLORI UNIFICATA (GOLD/ORANGE) ---
  static const Color _unifiedColor = Colors.orangeAccent;

  // --- DATI STATICI (Catalogo Espanso) ---

  // LIBRI (Open Library Subjects)
  static const List<CategoryModel> _bookCategories = [
    CategoryModel(
      id: 'fiction',
      name: 'Bestsellers',
      icon: Icons.star,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'thriller',
      name: 'Thriller',
      icon: Icons.fingerprint,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'fantasy',
      name: 'Fantasy',
      icon: Icons.auto_awesome,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'science_fiction',
      name: 'Sci-Fi',
      icon: Icons.rocket_launch,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'mystery',
      name: 'Gialli',
      icon: Icons.search,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'romance',
      name: 'Romance',
      icon: Icons.favorite,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'horror',
      name: 'Horror',
      icon: Icons.sentiment_very_dissatisfied,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'historical_fiction',
      name: 'Storici',
      icon: Icons.account_balance,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'biography',
      name: 'Biografie',
      icon: Icons.person,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'business',
      name: 'Business',
      icon: Icons.trending_up,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'self_help',
      name: 'Crescita',
      icon: Icons.fitness_center,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'psychology',
      name: 'Psicologia',
      icon: Icons.psychology,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'philosophy',
      name: 'Filosofia',
      icon: Icons.lightbulb,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'science',
      name: 'Scienza',
      icon: Icons.science,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'computers',
      name: 'Tech',
      icon: Icons.terminal,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'art',
      name: 'Arte',
      icon: Icons.palette,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'cooking',
      name: 'Cucina',
      icon: Icons.restaurant,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'travel',
      name: 'Viaggi',
      icon: Icons.flight,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'graphic_novels',
      name: 'Fumetti',
      icon: Icons.layers,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: 'poetry',
      name: 'Poesia',
      icon: Icons.edit_note,
      color: _unifiedColor,
    ),
  ];

  // FILM (TMDB Genre IDs)
  static const List<CategoryModel> _movieCategories = [
    CategoryModel(
      id: '28',
      name: 'Azione',
      icon: Icons.local_fire_department,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '12',
      name: 'Avventura',
      icon: Icons.explore,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '878',
      name: 'Sci-Fi',
      icon: Icons.rocket,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '53',
      name: 'Thriller',
      icon: Icons.fingerprint,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '35',
      name: 'Commedia',
      icon: Icons.sentiment_very_satisfied,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '18',
      name: 'Drammatici',
      icon: Icons.theater_comedy,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '80',
      name: 'Crime',
      icon: Icons.local_police,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '27',
      name: 'Horror',
      icon: Icons.bug_report,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '9648',
      name: 'Mistero',
      icon: Icons.help_outline,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '10752',
      name: 'Guerra',
      icon: Icons.military_tech,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '37',
      name: 'Western',
      icon: Icons.badge,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '14',
      name: 'Fantasy',
      icon: Icons.auto_awesome,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '10749',
      name: 'Romance',
      icon: Icons.favorite,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '16',
      name: 'Animazione',
      icon: Icons.animation,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '10751',
      name: 'Per Famiglie',
      icon: Icons.family_restroom,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '36',
      name: 'Storici',
      icon: Icons.history_edu,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '10402',
      name: 'Musica',
      icon: Icons.music_note,
      color: _unifiedColor,
    ),
    CategoryModel(
      id: '99',
      name: 'Documentari',
      icon: Icons.videocam,
      color: _unifiedColor,
    ),
  ];
}
