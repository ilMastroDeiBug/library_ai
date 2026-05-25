import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/l10n/app_localizations.dart';

// ────────────────────────────────────────────────────────────────────────────
// Design Reference: Disney+ peek carousel + Letterboxd editorial bottom text
//
// • viewportFraction: 0.88  → card laterali visibili per ~6% ai bordi
// • scale laterale: 0.93    → profondità senza drammaticità
// • corner radius: 18        → "contenuto", non "scheda"
// • glass edge border: inner border white/13 + top-highlight 2px gradient
// • testo left-aligned DENTRO la card in basso
// • progress dots verticali destra, dentro la card
// ────────────────────────────────────────────────────────────────────────────

const double _kViewportFraction = 0.88;
const double _kCornerRadius = 18.0;
const double _kScaleSide = 0.93;
const double _kDimSide = 0.38;
const int _kInfiniteStart = 10000;

class AiHeroBanner extends StatefulWidget {
  final List<dynamic> items;
  final Function(dynamic) onItemTap;

  const AiHeroBanner({super.key, required this.items, required this.onItemTap});

  @override
  State<AiHeroBanner> createState() => _AiHeroBannerState();
}

class _AiHeroBannerState extends State<AiHeroBanner>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _realIndex = 0;
  Timer? _timer;
  double _currentPageValue = _kInfiniteStart.toDouble();

  List<dynamic> _dailyItems = [];

  late AnimationController _textFadeCtrl;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    _textFadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _textFade =
        CurvedAnimation(parent: _textFadeCtrl, curve: Curves.easeOut);

    _generateDailyRotation();

    _pageController = PageController(
      initialPage: _kInfiniteStart,
      viewportFraction: _kViewportFraction,
    );
    _currentPageValue = _kInfiniteStart.toDouble();

    _pageController.addListener(() {
      if (mounted) {
        setState(() {
          _currentPageValue =
              _pageController.page ?? _kInfiniteStart.toDouble();
        });
      }
    });

    _textFadeCtrl.forward();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant AiHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.length != oldWidget.items.length) {
      _stopAutoScroll();
      _generateDailyRotation();
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_kInfiniteStart);
      }
      _currentPageValue = _kInfiniteStart.toDouble();
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
    final int seed =
        now.year * 10000 + now.month * 100 + now.day + typeModifier;
    final random = Random(seed);
    final shuffled = List.from(widget.items)..shuffle(random);
    setState(() => _dailyItems = shuffled.take(5).toList());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _textFadeCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_dailyItems.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_pageController.hasClients &&
          _pageController.position.haveDimensions) {
        try {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeInOutCubic,
          );
        } catch (_) {}
      }
    });
  }

  void _stopAutoScroll() => _timer?.cancel();

  void _onPageChanged(int index) {
    if (!mounted) return;
    _textFadeCtrl.reset();
    setState(() => _realIndex = index % _dailyItems.length);
    _textFadeCtrl.forward();
  }

  _MediaData _extractData(dynamic item, BuildContext context) {
    if (item is Book) {
      return _MediaData(
        title: item.title,
        imageUrl: item.thumbnailUrl,
        label: 'LIBRO IN EVIDENZA',
        rating: '',
      );
    } else if (item is Movie) {
      return _MediaData(
        title: item.title,
        imageUrl: item.fullBackdropUrl.isNotEmpty
            ? item.fullBackdropUrl
            : item.fullPosterUrl,
        label:
            AppLocalizations.of(context)!.heroBannerMovieOfDay.toUpperCase(),
        rating: item.voteAverage > 0
            ? item.voteAverage.toStringAsFixed(1)
            : '',
      );
    } else if (item is TvSeries) {
      return _MediaData(
        title: item.name,
        imageUrl: item.fullBackdropUrl.isNotEmpty
            ? item.fullBackdropUrl
            : item.fullPosterUrl,
        label:
            AppLocalizations.of(context)!.heroBannerTvTrending.toUpperCase(),
        rating: item.voteAverage > 0
            ? item.voteAverage.toStringAsFixed(1)
            : '',
      );
    }
    return _MediaData(title: '', imageUrl: '', label: '', rating: '');
  }

  @override
  Widget build(BuildContext context) {
    if (_dailyItems.isEmpty) return const SizedBox();

    // Altezza ridotta: 55% — più compatto, meno gap con le sezioni
    final double cardHeight = MediaQuery.of(context).size.height * 0.55;
    final double cardWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: cardHeight,
      child: GestureDetector(
        onPanDown: (_) => _stopAutoScroll(),
        onPanCancel: _startAutoScroll,
        onPanEnd: (_) => _startAutoScroll(),
        child: Stack(
          children: [
            // ── PageView con peek laterale ──────────────────────────────────
            PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                if (_dailyItems.isEmpty) return const SizedBox();

                final int actual = index % _dailyItems.length;
                final item = _dailyItems[actual];
                final data = _extractData(item, context);

                final double delta = index - _currentPageValue;
                final double absDelta = delta.abs().clamp(0.0, 1.0);

                // Scala: 1.0 al centro, _kScaleSide ai bordi
                final double scale = 1.0 - (absDelta * (1.0 - _kScaleSide));

                // Shift compensativo per chiudere il gap creato dallo scaling
                final double emptySpace =
                    cardWidth * _kViewportFraction * (1.0 - scale) / 2.0;
                final double shift = -delta.clamp(-1.0, 1.0) * emptySpace;

                // Oscuramento card laterali
                final double dimOpacity =
                    (absDelta * _kDimSide).clamp(0.0, _kDimSide);

                // Parallasse interno
                final double parallax = delta.clamp(-1.0, 1.0) * 0.08;

                return Transform.translate(
                  offset: Offset(shift, 0),
                  child: Transform.scale(
                    scale: scale,
                    alignment: Alignment.center,
                    child: _TactileCard(
                      onTap: () => widget.onItemTap(item),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(_kCornerRadius),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // ── Sfondo nero (evita flash) ─────────────────
                            const ColoredBox(color: Color(0xFF0C0C0C)),

                            // ── Immagine con parallasse ───────────────────
                            CachedNetworkImage(
                              imageUrl: data.imageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment(parallax, -0.1),
                              errorWidget: (_, __, ___) =>
                                  const ColoredBox(color: Color(0xFF181818)),
                              placeholder: (_, __) => const _ShimmerBox(),
                            ),

                            // ── Gradient cinematico bottom-heavy ──────────
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x00000000),
                                    Color(0x99000000),
                                    Color(0xF0000000),
                                  ],
                                  stops: [0.0, 0.4, 0.72, 1.0],
                                ),
                              ),
                            ),

                            // ── Vignetta sinistra ─────────────────────────
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0x44000000),
                                    Color(0x00000000),
                                  ],
                                ),
                              ),
                            ),

                            // ── Oscuramento card laterali ─────────────────
                            if (dimOpacity > 0)
                              ColoredBox(
                                color: Color.fromRGBO(0, 0, 0, dimOpacity),
                              ),

                            // ── Glass edge border ─────────────────────────
                            // Inner border bianco/13 — simula il perimetro
                            // fisico di una lastra di vetro satinato.
                            // Non è un semplice border: il top-highlight da
                            // un ulteriore 2px di luce sul bordo superiore,
                            // come la rifrazione della luce naturale.
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(_kCornerRadius),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.13),
                                  width: 0.8,
                                ),
                              ),
                            ),
                            // Top-edge highlight: 2px di luce "rifratta"
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 2.5,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.only(
                                    topLeft:
                                        Radius.circular(_kCornerRadius),
                                    topRight:
                                        Radius.circular(_kCornerRadius),
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.white.withValues(alpha: 0.25),
                                      Colors.white.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // ── Testo left-aligned in basso ───────────────
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 44,
                              child: _CardText(
                                data: data,
                                isActive: actual == _realIndex,
                                fadeAnim: _textFade,
                                onTap: () => widget.onItemTap(item),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Progress dots verticali (dentro la card attiva, destra) ────
            Positioned(
              bottom: 20,
              right: 16,
              child: _ProgressDots(
                count: _dailyItems.length,
                active: _realIndex,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dati media ───────────────────────────────────────────────────────────────

class _MediaData {
  final String title;
  final String imageUrl;
  final String label;
  final String rating;
  const _MediaData({
    required this.title,
    required this.imageUrl,
    required this.label,
    required this.rating,
  });
}

// ─── Testo card ───────────────────────────────────────────────────────────────

class _CardText extends StatelessWidget {
  final _MediaData data;
  final bool isActive;
  final Animation<double> fadeAnim;
  final VoidCallback onTap;

  const _CardText({
    required this.data,
    required this.isActive,
    required this.fadeAnim,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: isActive ? fadeAnim : const AlwaysStoppedAnimation(1.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label + rating
          Row(
            children: [
              _GlassChip(label: data.label),
              if (data.rating.isNotEmpty) ...[
                const SizedBox(width: 7),
                _GlassChip(label: '★ ${data.rating}', accent: true),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // Titolo
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),

          // CTA
          _CtaButton(
            label: AppLocalizations.of(context)!.heroBannerMoreInfo,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}

// ─── Glass chip ───────────────────────────────────────────────────────────────

class _GlassChip extends StatelessWidget {
  final String label;
  final bool accent;
  const _GlassChip({required this.label, this.accent = false});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: accent
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
              width: 0.7,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: accent
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.70),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── CTA button ───────────────────────────────────────────────────────────────

class _CtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CtaButton({required this.label, required this.onTap});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF111111), size: 14),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF111111),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Progress dots verticali ──────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int count;
  final int active;
  const _ProgressDots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final bool isActive = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: 2.5),
          width: 2.5,
          height: isActive ? 16 : 5,
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white
                : Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

// ─── Shimmer skeleton ─────────────────────────────────────────────────────────

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _anim = Tween<double>(begin: -1.0, end: 2.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: const [
              Color(0xFF111111),
              Color(0xFF1C1C1C),
              Color(0xFF111111),
            ],
            stops: [
              (_anim.value - 1).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 1).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tactile card (feedback pressione) ───────────────────────────────────────

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
        vsync: this, duration: const Duration(milliseconds: 90));
    _scale = Tween<double>(begin: 1.0, end: 0.985)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
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
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
