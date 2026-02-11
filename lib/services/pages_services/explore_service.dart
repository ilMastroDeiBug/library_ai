import 'package:flutter/material.dart';
import 'package:library_ai/models/app_mode.dart';
import 'package:library_ai/models/category_model.dart';

class ExploreService {
  List<CategoryModel> getCategories(AppMode mode) {
    return mode == AppMode.books ? _bookCategories : _movieCategories;
  }

  // --- CONFIGURAZIONE COLORI UNIFICATA ---
  static const Color _bookColor = Colors.cyanAccent;
  static const Color _movieColor = Colors.orangeAccent;

  // --- DATI STATICI (Colori Uniformati) ---

  static const List<CategoryModel> _bookCategories = [
    CategoryModel(
      id: 'fiction',
      name: 'Bestsellers',
      icon: Icons.star,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'fantasy',
      name: 'Fantasy',
      icon: Icons.auto_awesome,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'science_fiction',
      name: 'Sci-Fi',
      icon: Icons.rocket_launch,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'horror',
      name: 'Horror',
      icon: Icons.sentiment_very_dissatisfied,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'thriller',
      name: 'Thriller',
      icon: Icons.fingerprint,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'history',
      name: 'Storici',
      icon: Icons.account_balance,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'biography',
      name: 'Biografie',
      icon: Icons.person,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'manga',
      name: 'Manga',
      icon: Icons.import_contacts,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'romance',
      name: 'Romantici',
      icon: Icons.favorite,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'computers',
      name: 'Tech',
      icon: Icons.terminal,
      color: _bookColor,
    ),
    CategoryModel(
      id: 'psychology',
      name: 'Psicologia',
      icon: Icons.psychology,
      color: _bookColor,
    ),
  ];

  static const List<CategoryModel> _movieCategories = [
    CategoryModel(
      id: '28',
      name: 'Azione',
      icon: Icons.local_fire_department,
      color: _movieColor,
    ),
    CategoryModel(
      id: '35',
      name: 'Commedia',
      icon: Icons.sentiment_very_satisfied,
      color: _movieColor,
    ),
    CategoryModel(
      id: '18',
      name: 'Drammatici',
      icon: Icons.theater_comedy,
      color: _movieColor,
    ),
    CategoryModel(
      id: '878',
      name: 'Sci-Fi',
      icon: Icons.rocket,
      color: _movieColor,
    ),
    CategoryModel(
      id: '27',
      name: 'Horror',
      icon: Icons.bug_report,
      color: _movieColor,
    ),
    CategoryModel(
      id: '16',
      name: 'Animazione',
      icon: Icons.animation,
      color: _movieColor,
    ),
    CategoryModel(
      id: '99',
      name: 'Documentari',
      icon: Icons.videocam,
      color: _movieColor,
    ),
    CategoryModel(
      id: '53',
      name: 'Thriller',
      icon: Icons.fingerprint,
      color: _movieColor,
    ),
  ];
}
