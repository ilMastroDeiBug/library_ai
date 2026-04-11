import 'package:flutter/material.dart';
import '../domain/entities/category.dart';
import '../models/app_mode.dart';
import '../injection_container.dart';
import '../domain/use_cases/movie_use_cases.dart';
import '../domain/use_cases/tv_series_use_cases.dart';
import '../domain/use_cases/book_use_cases.dart';
import '../models/movie_widget/movie_card.dart';
import '../domain/entities/book.dart';
import 'movie_detail_page.dart';
import 'book_detail_page.dart';

class GenreResultPage extends StatefulWidget {
  final CategoryEntity category;
  final AppMode mode;
  final bool isTvSeries;

  const GenreResultPage({
    super.key,
    required this.category,
    required this.mode,
    this.isTvSeries = false,
  });

  @override
  State<GenreResultPage> createState() => _GenreResultPageState();
}

class _GenreResultPageState extends State<GenreResultPage> {
  // 1. IL CONTROLLER DELLO SCROLL
  final ScrollController _scrollController = ScrollController();

  // 2. LO STATO DELLA PAGINAZIONE
  List<dynamic> _items = [];
  int _currentPage = 1;
  bool _isLoadingFirstTime = true;
  bool _isFetchingMore = false;
  bool _hasReachedMax =
      false; // Se TMDB ci ridà una lista vuota, siamo alla fine

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    // 3. ASCOLTIAMO LO SCROLL IN TEMPO REALE
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- LA LOGICA DEL RADAR ---
  void _onScroll() {
    // Se siamo arrivati a 200 pixel dal fondo (prima ancora di toccarlo visivamente)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // E se non stiamo già caricando, e se c'è ancora roba da caricare...
      if (!_isFetchingMore && !_hasReachedMax && !_isLoadingFirstTime) {
        _fetchMoreData();
      }
    }
  }

  Future<void> _fetchInitialData() async {
    final newItems = await _fetchItemsFromApi(1);
    if (mounted) {
      setState(() {
        _items = newItems;
        _isLoadingFirstTime = false;
        // Se TMDB ci dà meno di 20 risultati, significa che non c'è una pagina 2
        if (newItems.length < 20) _hasReachedMax = true;
      });
    }
  }

  Future<void> _fetchMoreData() async {
    setState(() {
      _isFetchingMore = true; // Mostriamo la rotellina in basso
    });

    _currentPage++; // Andiamo alla pagina successiva
    final newItems = await _fetchItemsFromApi(_currentPage);

    if (mounted) {
      setState(() {
        _isFetchingMore = false;
        if (newItems.isEmpty) {
          _hasReachedMax = true; // Fine dei contenuti
        } else {
          _items.addAll(newItems); // ACCODIAMO i nuovi film a quelli vecchi!
        }
      });
    }
  }

  Future<List<dynamic>> _fetchItemsFromApi(int page) async {
    try {
      if (widget.mode == AppMode.books) {
        // Se i tuoi libri non hanno il parametro page, fermiamo il caricamento alla pagina 1
        if (page > 1) return [];
        return await sl<GetBooksByCategoryUseCase>().call(widget.category.name);
      } else {
        // CINEMA MAGICO
        final path = 'with_genres=${widget.category.id}';
        if (widget.isTvSeries) {
          return await sl<GetTvSeriesByCategoryUseCase>().call(
            path,
            page: page,
          );
        } else {
          return await sl<GetMoviesByCategoryUseCase>().call(path, page: page);
        }
      }
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // APP BAR
          SliverAppBar(
            backgroundColor: const Color(0xFF0A0A0C),
            floating: true,
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.category.name.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),

          // STATO 1: Primo Caricamento
          if (_isLoadingFirstTime)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              ),
            )
          // STATO 2: Dati Caricati (Griglia Infinita)
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      3, // 3 locandine per riga (stile Netflix/Letterboxd)
                  childAspectRatio:
                      0.65, // Proporzione classica delle locandine
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 15,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = _items[index];

                  // Riutilizziamo la tua bellissima MovieCard!
                  return MovieCard(
                    media: item,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => item is Book
                              ? BookDetailPage(book: item)
                              : MovieDetailPage(media: item),
                        ),
                      );
                    },
                  );
                }, childCount: _items.length),
              ),
            ),

          // STATO 3: Caricamento nuova pagina in fondo alla lista
          if (_isFetchingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 20, bottom: 40),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.orangeAccent),
                ),
              ),
            ),

          // Buffer di spazio per evitare che l'ultimo film finisca sotto la navigation bar
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
