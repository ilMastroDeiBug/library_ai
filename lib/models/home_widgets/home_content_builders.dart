import 'package:flutter/material.dart';
import '../../services/pages_services/home_service.dart';
// Import Widget necessari
import '../../models/book_widgets/book_section.dart';
import '../../models/movie_widget/movie_section.dart';

class HomeContentBuilder {
  // Costruisce la lista di widget per i LIBRI
  static List<Widget> buildBookContent() {
    return HomeService.bookSections.map((data) {
      // Se è un header
      if (data.containsKey('header')) {
        return _SectionHeader(text: data['header']);
      }
      // Se è una sezione libro
      return Column(
        children: [
          BookSection(title: data['title'], categoryQuery: data['query']),
          const SizedBox(height: 10), // Spaziatura standard
        ],
      );
    }).toList();
  }

  // Costruisce la lista di widget per i FILM
  static List<Widget> buildMovieContent() {
    return HomeService.movieSections.map((data) {
      if (data.containsKey('header')) {
        return _SectionHeader(text: data['header']);
      }
      return Column(
        children: [
          MovieSection(title: data['title'], categoryPath: data['path']),
          const SizedBox(height: 10),
        ],
      );
    }).toList();
  }
}

// Widget Header (Privato ma riutilizzato qui)
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        20,
        30,
        20,
        10,
      ), // Spaziatura integrata
      child: Text(
        text,
        style: TextStyle(
          color: Colors.orangeAccent.withOpacity(0.8),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
