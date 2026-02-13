# Backup original files
Copy-Item lib/models/home_widgets/home_content_builders.dart lib/models/home_widgets/home_content_builders.dart.bak -Force
Copy-Item lib/Pages/home_page.dart lib/Pages/home_page.dart.bak -Force

# Overwrite HomeContentBuilder with hero banner integration
@"
import 'package:flutter/material.dart';
import '../../services/pages_services/home_service.dart';
// Import Widget necessari
import '../../models/book_widgets/book_section.dart';
import '../../models/movie_widget/movie_section.dart';
import '../../injection_container.dart';
import '../../models/ai_hero_banner.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/movie.dart';
import '../../domain/use_cases/book_use_cases.dart';
import '../../domain/use_cases/movie_use_cases.dart';
import '../../Pages/book_detail_page.dart';
import '../../Pages/movie_detail_page.dart';
import '../../models/app_mode.dart';

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

  // Hero banner dinamico (Book o Movie)
  static Widget buildHeroBanner(AppMode mode) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchHeroItems(mode),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final heroItems = snapshot.data!.take(5).toList();

        return AiHeroBanner(
          items: heroItems,
          onItemTap: (item) {
            if (item is Book) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailPage(book: item)),
              );
            } else if (item is Movie) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MovieDetailPage(movie: item)),
              );
            }
          },
        );
      },
    );
  }

  // Logica per recuperare gli elementi del banner
  static Future<List<dynamic>> _fetchHeroItems(AppMode mode) async {
    try {
      if (mode == AppMode.books) {
        // Esempio: categoria "Fantasy"
        return await sl<GetBooksByCategoryUseCase>().call("Fantasy");
      } else {
        // Esempio: path 'trending' per film
        return await sl<GetMoviesByCategoryUseCase>().call("trending");
      }
    } catch (e) {
      return [];
    }
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
"@ | Set-Content -Path lib/models/home_widgets/home_content_builders.dart -Encoding UTF8

# Replace AI placeholder in home_page.dart to call HomeContentBuilder.buildHeroBanner(mode)
(Get-Content lib/Pages/home_page.dart -Raw) `
 -replace '\s*_buildAIBannerPlaceholder\(\),\s*\n\s*const SizedBox\(height: 30\),' , 'HomeContentBuilder.buildHeroBanner(mode),`n                  const SizedBox(height: 30),' `
 -replace '\s*// 2\. CONTENUTO DINAMICO\s*\n\s*if \(mode == AppMode\.books\) \.\.\.\[', ' // 2. CONTENUTO DINAMICO\n                if (mode == AppMode.books) ...[' |
 Set-Content lib/Pages/home_page.dart -Encoding UTF8

# Remove the old _buildAIBannerPlaceholder implementation if present
(Get-Content lib/Pages/home_page.dart -Raw) -replace '(?s)Widget\s+_buildAIBannerPlaceholder\(\)\s*\{.*?\}\s*', '' | Set-Content lib/Pages/home_page.dart -Encoding UTF8

Write-Host "Hero banner integration applied. Backups created: *.bak"
