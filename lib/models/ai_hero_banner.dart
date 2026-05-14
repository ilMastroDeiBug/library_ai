import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/l10n/app_localizations.dart';

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
  double _currentPageValue = _infiniteStart.toDouble();

  List<dynamic> _dailyItems = [];
  static const int _infiniteStart = 10000;

  @override
  void initState() {
    super.initState();
    _generateDailyRotation();
    _pageController = PageController(
      initialPage: _infiniteStart,
      viewportFraction: 0.78, // Leggermente ridotto per vedere più copertine laterali
    );
    _currentPageValue = _pageController.initialPage.toDouble();

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
    // Solo se la lunghezza è diversa consideriamo il feed "cambiato".
    // Previene il reset del carosello e i salti improvvisi ai re-render dello stream.
    if (widget.items.length != oldWidget.items.length) {
      _stopAutoScroll();
      _generateDailyRotation();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_infiniteStart);
      }
      _currentPageValue = _infiniteStart.toDouble();
      _realIndex = 0;
      _startAutoScroll();
    }
  }

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

    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_pageController.hasClients &&
          _pageController.position.haveDimensions) {
        try {
          _pageController.nextPage(
            duration: const Duration(
              milliseconds: 1200,
            ), // Più lungo per godersi la transizione
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

  Map<String, String> _extractData(dynamic item, BuildContext context) {
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
        'subtitle': AppLocalizations.of(context)!.heroBannerMovieOfDay,
      };
    } else if (item is TvSeries) {
      return {
        'title': item.name,
        'image': item.fullBackdropUrl.isNotEmpty
            ? item.fullBackdropUrl
            : item.fullPosterUrl,
        'subtitle': AppLocalizations.of(context)!.heroBannerTvTrending,
      };
    }
    return {'title': '', 'image': '', 'subtitle': ''};
  }

  @override
  Widget build(BuildContext context) {
    if (_dailyItems.isEmpty) return const SizedBox();

    final double bannerHeight = MediaQuery.of(context).size.height * 0.65;

    return SizedBox(
      height: bannerHeight,
      child: GestureDetector(
        onPanDown: (_) => _stopAutoScroll(),
        onPanCancel: () => _startAutoScroll(),
        onPanEnd: (_) => _startAutoScroll(),
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
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
                final data = _extractData(item, context);

                // MATEMATICA TRANSIZIONE
                double delta = index - _currentPageValue;
                double clampedDelta = delta.clamp(-1.0, 1.0);
                double absDelta = clampedDelta.abs();

                // 1. Scala ridotta ai lati
                double scale = 1.0 - (absDelta * 0.15);

                // 2. Raggio per far sembrare vere carte come su Disney+
                double cornerRadius = 14.0;

                // 3. Calcolo dello shift orizzontale per farle adiacenti
                // ViewportFraction è 0.82. Scalando si creerebbe uno spazio.
                // Lo azzeriamo traslando le carte verso il centro.
                double cardWidth = MediaQuery.of(context).size.width * 0.78;
                double emptySpace = cardWidth * (1.0 - scale) / 2.0;
                double horizontalShift = -clampedDelta * emptySpace; 

                // 4. Oscuramento carte laterali (effetto profondità)
                double overlayOpacity = (absDelta * 0.5).clamp(0.0, 1.0);

                // 5. Fade ultra-rapido per il testo (sparisce prima dell'immagine)
                double textOpacity = (1.0 - (absDelta * 2.5)).clamp(0.0, 1.0);

                return _TactileCard(
                  onTap: () => widget.onItemTap(item),
                  child: Transform.translate(
                    offset: Offset(horizontalShift, 0),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.center,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Sfondo protettivo (evita flash neri/bianchi durante il render)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(cornerRadius),
                            ),
                          ),

                          // L'Immagine con Parallasse Interno
                          ClipRRect(
                            borderRadius: BorderRadius.circular(cornerRadius),
                            child: CachedNetworkImage(
                              imageUrl: data['image']!,
                              fit: BoxFit.cover,
                              // Il parallasse fa slittare l'immagine al contrario rispetto allo scroll
                              alignment: Alignment(clampedDelta * 0.7, 0),
                              errorWidget: (ctx, url, error) =>
                                  Container(color: const Color(0xFF1A1A1A)),
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orangeAccent,
                                ),
                              ),
                            ),
                          ),

                          // Scuriamo le carte che non sono al centro
                          if (overlayOpacity > 0)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(cornerRadius),
                              child: Container(
                                color: Colors.black.withOpacity(overlayOpacity),
                              ),
                            ),

                          // Il Gradiente (deve avere lo stesso raggio per non sbordare)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(cornerRadius),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.5),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                    Colors.black,
                                  ],
                                  stops: const [0.0, 0.2, 0.6, 0.85, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Testi e Badge
                          Positioned(
                            bottom: 40,
                            left: 20,
                            right: 20,
                            child: Opacity(
                              opacity: textOpacity,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Badge Liquid Glass
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                      ),
                                      boxShadow: [
                                        const BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 10,
                                          spreadRadius: -2,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.local_fire_department_rounded,
                                          color: Colors.orangeAccent,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          data['subtitle']!.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
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
                                      fontSize: 38,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                      letterSpacing: -1.0,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black54,
                                          offset: Offset(0, 4),
                                          blurRadius: 15,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Tasto "Maggiori Info" (Pillola Premium)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.black,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.heroBannerMoreInfo,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            letterSpacing: -0.2,
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
                    ),
                  ),
                );
              },
            ),

            // Indicatori (Dots) in basso
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

// ─── _TactileCard ────────────────────────────────────────────────────────────
// Aggiunge un feedback tattile (scala al tocco) per rendere la UI più fisica e premium.
class _TactileCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TactileCard({required this.child, required this.onTap});

  @override
  State<_TactileCard> createState() => _TactileCardState();
}

class _TactileCardState extends State<_TactileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}

