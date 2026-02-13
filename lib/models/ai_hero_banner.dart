import 'dart:async';
import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
// Opzionale se usi cached, altrimenti Image.network

class AiHeroBanner extends StatefulWidget {
  final List<dynamic> items; // Accetta sia List<Book> che List<Movie>
  final Function(dynamic) onItemTap;

  const AiHeroBanner({super.key, required this.items, required this.onItemTap});

  @override
  State<AiHeroBanner> createState() => _AiHeroBannerState();
}

class _AiHeroBannerState extends State<AiHeroBanner> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // Logica Auto-Scroll
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentIndex < widget.items.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  // Ferma il timer quando l'utente tocca
  void _stopAutoScroll() {
    _timer?.cancel();
  }

  // Helper per estrarre dati da Book o Movie
  Map<String, String> _extractData(dynamic item) {
    if (item is Book) {
      return {
        'title': item.title,
        'image': item
            .thumbnailUrl, // Assicurati che sia ad alta risoluzione se possibile
        'subtitle': item.author,
      };
    } else if (item is Movie) {
      return {
        'title': item.title,
        'image': item.fullBackdropUrl.isNotEmpty
            ? item.fullBackdropUrl
            : item.fullPosterUrl,
        'subtitle': "Voto: ${item.voteAverage.toStringAsFixed(1)}",
      };
    }
    return {'title': 'Sconosciuto', 'image': '', 'subtitle': ''};
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox();

    return Column(
      children: [
        SizedBox(
          height: 280, // Altezza del banner
          child: GestureDetector(
            // Ferma lo scroll quando tocchi, riprendi quando lasci
            onPanDown: (_) => _stopAutoScroll(),
            onPanCancel: () => _startAutoScroll(),
            onPanEnd: (_) => _startAutoScroll(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final data = _extractData(item);

                return GestureDetector(
                  onTap: () => widget.onItemTap(item),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Immagine di Sfondo
                      Image.network(
                        data['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            Container(color: Colors.grey[900]),
                      ),

                      // 2. Gradiente per leggibilità testo
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.0),
                              Colors.black.withOpacity(
                                0.8,
                              ), // Più scuro in basso
                              const Color(
                                0xFF121212,
                              ), // Si fonde con lo sfondo dell'app
                            ],
                            stops: const [0.0, 0.5, 0.8, 1.0],
                          ),
                        ),
                      ),

                      // 3. Testi
                      Positioned(
                        bottom: 40,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['subtitle']!.toUpperCase(),
                              style: const TextStyle(
                                color:
                                    Colors.cyanAccent, // O il tuo brand color
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              data['title']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // 4. Indicatori (Puntini)
        Transform.translate(
          offset: const Offset(0, -20), // Li sposta sopra il gradiente
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.items.length > 5
                  ? 5
                  : widget.items.length, // Max 5 puntini
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: _currentIndex == index
                    ? 20
                    : 6, // Il corrente è più largo
                decoration: BoxDecoration(
                  color: _currentIndex == index
                      ? Colors.cyanAccent
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
