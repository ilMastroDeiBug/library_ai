import 'dart:async';
import 'package:flutter/material.dart';
import '../../injection_container.dart';
import '../../domain/use_cases/movie_use_cases.dart';
import '../../domain/use_cases/tv_series_use_cases.dart';
import '../../domain/entities/movie.dart';
import '../../domain/entities/tv_series.dart';
import '../../Pages/movie_detail_page.dart';
import '../movie_widget/movie_card.dart';
import '../../services/utility_services/language_service.dart';

class CinemaHorizontalList extends StatefulWidget {
  final String title;
  final String path;
  final bool isTv;
  final Set<int> seenIds;

  const CinemaHorizontalList({
    required this.title,
    required this.path,
    required this.isTv,
    required this.seenIds,
    super.key,
  });

  @override
  State<CinemaHorizontalList> createState() => _CinemaHorizontalListState();
}

class _CinemaHorizontalListState extends State<CinemaHorizontalList> {
  late Stream<List<dynamic>> _stream;
  final LanguageService _languageService = sl<LanguageService>();

  @override
  void initState() {
    super.initState();
    _stream = _fetchAndFilter();
    _languageService.addListener(_handleLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _stream = _fetchAndFilter();
    });
  }

  Stream<List<dynamic>> _fetchAndFilter() async* {
    int pageToFetch = 1;

    final Stream<List<dynamic>> stream = widget.isTv
        ? sl<GetTvSeriesByCategoryUseCase>()
              .call(widget.path, page: pageToFetch)
              .map((items) => List<dynamic>.from(items))
        : sl<GetMoviesByCategoryUseCase>()
              .call(widget.path, page: pageToFetch)
              .map((items) => List<dynamic>.from(items));

    // FIX SCHERMO NERO: Memoria locale degli ID aggiunti da QUESTA emissione
    final Set<int> localAddedIds = {};

    await for (final rawItems in stream) {
      // Puliamo gli ID che avevamo inserito noi stessi con la precedente emissione (cache)
      widget.seenIds.removeAll(localAddedIds);
      localAddedIds.clear();

      List<dynamic> uniqueItems = [];
      for (var item in rawItems) {
        int currentId = 0;
        if (item is Movie) {
          currentId = item.id;
        } else if (item is TvSeries) {
          currentId = item.id;
        } else {
          continue;
        }

        // Filtra contro i veri doppioni delle ALTRE righe
        if (!widget.seenIds.contains(currentId)) {
          uniqueItems.add(item);
          widget.seenIds.add(currentId);
          localAddedIds.add(currentId); // Ci segniamo di averlo messo noi
        }
      }

      if (widget.path.contains('with_genres=')) {
        uniqueItems.shuffle();
      }

      if (uniqueItems.isNotEmpty) {
        yield uniqueItems;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: StreamBuilder<List<dynamic>>(
            key: ValueKey('list_${widget.title}_${widget.isTv}'),
            stream: _stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orangeAccent,
                  ),
                );
              }
              final items = snapshot.data ?? [];

              if (items.isEmpty) return const SizedBox.shrink();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: MovieCard(
                      media: items[index],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MovieDetailPage(media: items[index]),
                        ),
                      ),
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
