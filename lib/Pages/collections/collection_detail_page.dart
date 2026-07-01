import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/media_collection.dart';
import 'package:library_ai/domain/use_cases/collection_use_cases.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/Pages/movie_detail_page.dart';
import 'package:library_ai/domain/entities/movie.dart';
import 'package:library_ai/domain/entities/tv_series.dart';

class CollectionDetailPage extends StatefulWidget {
  final MediaCollection collection;

  const CollectionDetailPage({super.key, required this.collection});

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  late Stream<List<MediaCollectionItem>> _itemsStream;

  @override
  void initState() {
    super.initState();
    _itemsStream = sl<GetCollectionItemsStreamUseCase>().call(widget.collection.id);
  }

  void _deleteCollection() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Elimina Raccolta', style: TextStyle(color: Colors.white)),
        content: const Text('Sei sicuro di voler eliminare questa raccolta?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Elimina', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await sl<DeleteCollectionUseCase>().call(widget.collection.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Raccolta eliminata')));
      }
    }
  }

  void _deleteItem(MediaCollectionItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Rimuovi Elemento', style: TextStyle(color: Colors.white)),
        content: const Text('Sei sicuro di voler rimuovere questo elemento dalla raccolta?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rimuovi', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await sl<RemoveMediaFromCollectionUseCase>().call(item.collectionId, item.itemId, item.itemType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Elemento rimosso')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: const Color(0xFF0A0A0A),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.white),
                onPressed: _deleteCollection,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.collection.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  shadows: [Shadow(offset: Offset(0, 2), blurRadius: 4.0, color: Colors.black)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.collection.coverUrl != null && widget.collection.coverUrl!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: widget.collection.coverUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: const Color(0xFF1E1E1E)),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.3),
                            Colors.transparent,
                            const Color(0xFF0A0A0A),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.collection.description != null && widget.collection.description!.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Text(
                  widget.collection.description!,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          StreamBuilder<List<MediaCollectionItem>>(
            stream: _itemsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }

              final items = snapshot.data ?? [];
              
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "Nessun elemento in questa raccolta.",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(15),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      return GestureDetector(
                        onTap: () {
                          if (item.itemType == 'movie') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailPage(
                                  media: Movie(
                                    id: int.parse(item.itemId),
                                    title: item.title ?? 'Sconosciuto',
                                    overview: '',
                                    posterPath: item.posterUrl ?? '',
                                    backdropPath: '',
                                    voteAverage: 0.0,
                                    voteCount: 0,
                                    releaseDate: '',
                                    popularity: 0.0,
                                  ),
                                ),
                              ),
                            );
                          } else if (item.itemType == 'tv') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MovieDetailPage(
                                  media: TvSeries(
                                    id: int.parse(item.itemId),
                                    name: item.title ?? 'Sconosciuto',
                                    overview: '',
                                    posterPath: item.posterUrl ?? '',
                                    backdropPath: '',
                                    voteAverage: 0.0,
                                    voteCount: 0,
                                    firstAirDate: '',
                                    popularity: 0.0,
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        onLongPress: () => _deleteItem(item),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (item.posterUrl != null && item.posterUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: CachedNetworkImage(
                                    imageUrl: item.posterUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    ),
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Icon(Icons.movie, color: Colors.white24, size: 30),
                                    ),
                                  ),
                                )
                              else
                                const Center(
                                  child: Icon(Icons.movie, color: Colors.white24, size: 30),
                                ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(6),
                                      bottomRight: Radius.circular(6),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.9),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                  child: Text(
                                    item.title ?? '',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _deleteItem(item),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
