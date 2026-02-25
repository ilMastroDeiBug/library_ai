import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/models/app_mode.dart';

// Entities
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';

// Use Cases
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';

// Cards & Pages
import 'package:library_ai/models/book_widgets/book_card.dart';
import 'package:library_ai/models/movie_widget/movie_card.dart';
import 'package:library_ai/pages/movie_detail_page.dart';
import 'package:library_ai/pages/book_detail_page.dart';

class GenreResultPage extends StatefulWidget {
  final String categoryName;
  final String categoryId;
  final AppMode mode;
  final bool isTvSeries;

  const GenreResultPage({
    super.key,
    required this.categoryName,
    required this.categoryId,
    required this.mode,
    this.isTvSeries = false,
  });

  @override
  State<GenreResultPage> createState() => _GenreResultPageState();
}

class _GenreResultPageState extends State<GenreResultPage> {
  final List<dynamic> _items = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  static const Color _brandColor = Colors.orangeAccent;
  static const Color _bgColor = Color(0xFF0A0A0C);

  @override
  void initState() {
    super.initState();
    _loadData();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading &&
          _hasMoreData) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    List<dynamic> newItems = [];

    try {
      if (widget.mode == AppMode.books) {
        newItems = await sl<GetBooksByCategoryUseCase>().call(
          widget.categoryId,
        );
        _hasMoreData = false;
      } else {
        final tmdbPath = 'with_genres=${widget.categoryId}';

        if (widget.isTvSeries) {
          newItems = await sl<GetTvSeriesByCategoryUseCase>().call(
            tmdbPath,
            page: _currentPage,
          );
        } else {
          newItems = await sl<GetMoviesByCategoryUseCase>().call(
            tmdbPath,
            page: _currentPage,
          );
        }
      }

      if (mounted) {
        setState(() {
          _items.addAll(newItems);
          _currentPage++;
          _isLoading = false;

          if (newItems.isEmpty || newItems.length < 20) {
            _hasMoreData = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint("Errore caricamento pagina $_currentPage: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.categoryName.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
      ),
      body: _items.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandColor))
          : _items.isEmpty && !_isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 60,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 15),
                  Text(
                    "Nessun risultato trovato",
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: GridView.builder(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.6,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 20,
                        ),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      if (item is Book) {
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookDetailPage(book: item),
                            ),
                          ),
                          child: BookCard(book: item),
                        );
                      } else {
                        return MovieCard(
                          media: item,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MovieDetailPage(media: item),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                if (_isLoading && _items.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: _brandColor),
                  ),
              ],
            ),
    );
  }
}
