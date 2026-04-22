import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';

class AiHeroBanner extends StatefulWidget {
  final List<dynamic> items;
  final Function(dynamic) onItemTap;

  const AiHeroBanner({super.key, required this.items, required this.onItemTap});

  @override
  State<AiHeroBanner> createState() => _AiHeroBannerState();
}

class _AiHeroBannerState extends State<AiHeroBanner> {
  late PageController _pageController;
  int _realIndex = 0;
  Timer? _timer;
  double _currentPageValue = 0.0;

  List<dynamic> _dailyItems = [];
  static const int _infiniteStart = 10000;

  @override
  void initState() {
    super.initState();
    _generateDailyRotation();
    _pageController = PageController(initialPage: _infiniteStart);

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPageValue = _pageController.page ?? _infiniteStart.toDouble();
        });
      }
    });

    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant AiHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _stopAutoScroll();
      _generateDailyRotation();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_infiniteStart);
      }
      _startAutoScroll();
    }
  }

  // --- LOGICA INTATTA ---
  void _generateDailyRotation() {
    if (widget.items.isEmpty) {
      setState(() => _dailyItems = []);
      return;
    }

    final now = DateTime.now();
    final int typeModifier = widget.items.first is TvSeries ? 500 : 0;
    final int dailySeed =
        now.year * 10000 + now.month * 100 + now.day + typeModifier;

    final random = Random(dailySeed);
    final List<dynamic> shuffledItems = List.from(widget.items)
      ..shuffle(random);
    final int countToTake = shuffledItems.length > 5 ? 5 : shuffledItems.length;

    setState(() {
      _dailyItems = shuffledItems.take(countToTake).toList();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_dailyItems.isEmpty) return;

    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients &&
          _pageController.position.haveDimensions) {
        try {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.fastOutSlowIn,
          );
        } catch (e) {
          debugPrint("Scorrimento banner saltato: ricalcolo layout.");
        }
      }
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
  }

  Map<String, String> _extractData(dynamic item) {
    if (item is Book) {
      return {
        'title': item.title,
        'image': item.thumbnailUrl,
        'subtitle': item.author,
      };
    } else if (item is Movie) {
      return {
        'title': item.title,
        'image': item.fullBackdropUrl.isNotEmpty
            ? item.fullBackdropUrl
            : item.fullPosterUrl,
        'subtitle': "FILM DEL GIORNO",
      };
    } else if (item is TvSeries) {
      return {
        'title': item.name,
        'image': item.fullBackdropUrl.isNotEmpty
            ? item.fullBackdropUrl
            : item.fullPosterUrl,
        'subtitle': "SERIE TV IN TENDENZA",
      };
    }
    return {'title': '', 'image': '', 'subtitle': ''};
  }

  @override
  Widget build(BuildContext context) {
    if (_dailyItems.isEmpty) return const SizedBox();

    // L'altezza ora è dinamica: 65% dello schermo per un vero effetto "Hero"
    final double bannerHeight = MediaQuery.of(context).size.height * 0.65;

    return SizedBox(
      height: bannerHeight,
      child: GestureDetector(
        onPanDown: (_) => _stopAutoScroll(),
        onPanCancel: () => _startAutoScroll(),
        onPanEnd: (_) => _startAutoScroll(),
        child: Stack(
          children: [
            // 1. IL CAROSELLO
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() {
                    _realIndex = index % _dailyItems.length;
                  });
                }
              },
              itemBuilder: (context, index) {
                if (_dailyItems.isEmpty) return const SizedBox();

                final int actualIndex = index % _dailyItems.length;
                final item = _dailyItems[actualIndex];
                final data = _extractData(item);

                double delta = index - _currentPageValue;
                delta = delta.clamp(-1.0, 1.0);

                return GestureDetector(
                  onTap: () => widget.onItemTap(item),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Immagine con Parallasse
                      ClipRRect(
                        child: Transform(
                          transform: Matrix4.identity()
                            ..translate(delta * 50.0, 0.0, 0.0)
                            ..scale(1.0 + (delta.abs() * 0.1)),
                          alignment: Alignment.center,
                          child: Image.network(
                            data['image']!,
                            fit: BoxFit.cover,
                            alignment: Alignment(delta * 0.5, 0),
                            errorBuilder: (ctx, err, stack) =>
                                Container(color: Colors.black),
                          ),
                        ),
                      ),

                      // Gradiente Cinematico Netflix-Style
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(
                                0.5,
                              ), // Scurisce l'header sopra
                              Colors.transparent,
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                              Colors.black, // Si fonde col vuoto sotto!
                            ],
                            stops: const [0.0, 0.2, 0.6, 0.85, 1.0],
                          ),
                        ),
                      ),

                      // Testi e Badge
                      Positioned(
                        bottom: 40, // Lascia spazio per i dot
                        left: 20,
                        right: 20,
                        child: Opacity(
                          opacity: (1 - delta.abs()).clamp(0.0, 1.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Badge Glassmorphism
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.local_fire_department_rounded,
                                      color: Colors.orangeAccent,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      data['subtitle']!.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Titolo
                              Text(
                                data['title']!,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset: Offset(0, 4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 15),

                              // Tasto Finto Netflix (Scopri di più)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Maggiori Info",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 2. INDICATORI INTEGRATI (Dot pagination)
            Positioned(
              bottom: 15,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _dailyItems.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 5,
                    width: _realIndex == index ? 20 : 5,
                    decoration: BoxDecoration(
                      color: _realIndex == index
                          ? Colors.orangeAccent
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
