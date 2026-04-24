import 'package:flutter/material.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/movie_use_cases.dart';
import '../../domain/use_cases/tv_series_use_cases.dart';
import '../../pages/movie_detail_page.dart';
import '../movie_widget/movie_card.dart';
import '../../services/utility_services/language_service.dart';

// ... (import precedenti)

class CinemaHorizontalList extends StatelessWidget {
  final String title;
  final String path;
  final bool isTv;

  const CinemaHorizontalList({
    required this.title,
    required this.path,
    required this.isTv,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final languageCode = sl<LanguageService>().currentLanguage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: FutureBuilder<List<dynamic>>(
            key: ValueKey('cinema_horizontal_${title}_${path}_${isTv}_$languageCode'),
            future: isTv
                ? sl<GetTvSeriesByCategoryUseCase>().call(path)
                : sl<GetMoviesByCategoryUseCase>().call(path),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  // item può essere Movie o TvSeries
                  final item = snapshot.data![index];

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: MovieCard(
                      media: item,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            // Passiamo l'oggetto dynamic alla pagina di dettaglio
                            builder: (_) => MovieDetailPage(media: item),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
