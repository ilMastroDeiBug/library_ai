import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart'; // Fondamentale

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
      setState(() {
        _currentPageValue = _pageController.page ?? _infiniteStart.toDouble();
      });
    });

    _startAutoScroll();
  }

  void _generateDailyRotation() {
    if (widget.items.isEmpty) {
      _dailyItems = [];
      return;
    }
    final now = DateTime.now();
    final int dailySeed = now.year * 10000 + now.month * 100 + now.day;
    final random = Random(dailySeed);
    final List<dynamic> shuffledItems = List.from(widget.items)
      ..shuffle(random);
    final int countToTake = shuffledItems.length > 5 ? 5 : shuffledItems.length;
    _dailyItems = shuffledItems.take(countToTake).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (_dailyItems.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  void _stopAutoScroll() {
    _timer?.cancel();
  }

  // ESTRAZIONE DATI POLIMORFICA
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
        'title': item.name, // Serie usano 'name'
        'image': item.fullBackdropUrl.isNotEmpty
            ? item.fullBackdropUrl
            : item.fullPosterUrl,
        'subtitle': "SERIE TV DEL GIORNO",
      };
    }
    return {'title': '', 'image': '', 'subtitle': ''};
  }

  @override
  Widget build(BuildContext context) {
    if (_dailyItems.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: GestureDetector(
            onPanDown: (_) => _stopAutoScroll(),
            onPanCancel: () => _startAutoScroll(),
            onPanEnd: (_) => _startAutoScroll(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _realIndex = index % _dailyItems.length;
                });
              },
              itemBuilder: (context, index) {
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
                      // Immagine Parallax
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
                                Container(color: const Color(0xFF1E1E1E)),
                          ),
                        ),
                      ),
                      // Gradiente
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.2),
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                              const Color(0xFF121212),
                            ],
                            stops: const [0.0, 0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                      // Testi
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Opacity(
                          opacity: (1 - delta.abs()).clamp(0.0, 1.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.cyanAccent.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  data['subtitle']!.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                data['title']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
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
          ),
        ),
        // Indicatori
        Transform.translate(
          offset: const Offset(0, -25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _dailyItems.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 4,
                width: _realIndex == index ? 24 : 4,
                decoration: BoxDecoration(
                  color: _realIndex == index
                      ? Colors.cyanAccent
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
