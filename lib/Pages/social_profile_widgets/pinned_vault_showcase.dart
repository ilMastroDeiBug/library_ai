import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/pinned_item.dart';
import 'package:library_ai/domain/use_cases/social_use_cases.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';

/// La "Vetrina" del profilo: griglia asimmetrica 2x2 con le 4 opere pinnate.
/// Slot vuoti mostrano un bottone per aggiungere un'opera.
class PinnedVaultShowcase extends StatelessWidget {
  final List<PinnedItem> items;
  final String userId;

  const PinnedVaultShowcase({
    super.key,
    required this.items,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    // Costruiamo una lista di 4 slot, riempita con i dati esistenti
    final slots = List<PinnedItem?>.generate(4, (i) {
      try {
        return items.firstWhere((it) => it.position == i);
      } catch (_) {
        return null;
      }
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          childAspectRatio: 0.58,
        ),
        itemCount: 4,
        itemBuilder: (context, i) {
          final item = slots[i];
          return item != null
              ? _FilledSlot(item: item, userId: userId)
              : _EmptySlot(position: i, userId: userId);
        },
      ),
    );
  }
}

// ── Slot pieno ────────────────────────────────────────────────────────────────

class _FilledSlot extends StatefulWidget {
  final PinnedItem item;
  final String userId;

  const _FilledSlot({required this.item, required this.userId});

  @override
  State<_FilledSlot> createState() => _FilledSlotState();
}

class _FilledSlotState extends State<_FilledSlot> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: () => _showUnpinDialog(context),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Poster
              widget.item.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.item.posterUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _PosterPlaceholder(
                        mediaType: widget.item.mediaType,
                      ),
                      errorWidget: (_, __, ___) => _PosterPlaceholder(
                        mediaType: widget.item.mediaType,
                      ),
                    )
                  : _PosterPlaceholder(mediaType: widget.item.mediaType),

              // Gradiente bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Titolo
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  widget.item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    shadows: [
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),

              // Badge tipo
              Positioned(
                top: 8,
                right: 8,
                child: _TypeBadge(mediaType: widget.item.mediaType),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnpinDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnpinSheet(
        item: widget.item,
        userId: widget.userId,
      ),
    );
  }
}

// ── Slot vuoto ────────────────────────────────────────────────────────────────

class _EmptySlot extends StatelessWidget {
  final int position;
  final String userId;

  const _EmptySlot({required this.position, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Per pinnare un\'opera, aprila e usa il menu Azioni.',
            ),
            backgroundColor: Color(0xFF2A2A2A),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: Colors.white.withOpacity(0.2),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Aggiungi',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Poster placeholder ────────────────────────────────────────────────────────

class _PosterPlaceholder extends StatelessWidget {
  final String mediaType;
  const _PosterPlaceholder({required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final icon = switch (mediaType) {
      'tv' => Icons.tv_rounded,
      'book' => Icons.menu_book_rounded,
      _ => Icons.movie_rounded,
    };
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Icon(icon, color: Colors.white12, size: 40),
    );
  }
}

// ── Type Badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String mediaType;
  const _TypeBadge({required this.mediaType});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (mediaType) {
      'tv' => ('Serie', Colors.white),
      'book' => ('Libro', Colors.white),
      _ => ('Film', Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ── Unpin sheet ───────────────────────────────────────────────────────────────

class _UnpinSheet extends StatelessWidget {
  final PinnedItem item;
  final String userId;

  const _UnpinSheet({required this.item, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Rimuovi dalla vetrina?',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text(
                        'Annulla',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    // Guard offline
                    if (!OfflineActionGuard.checkAndShow(context)) return;
                    Navigator.pop(context);
                    await sl<UnpinItemUseCase>().call(item.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        'Rimuovi',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
