import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/entities/media_collection.dart';
import 'package:library_ai/domain/use_cases/collection_use_cases.dart';
import 'package:library_ai/models/app_mode.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/Pages/collections/create_collection_page.dart';
import 'package:library_ai/Pages/collections/collection_detail_page.dart';

class CollectionsGridView extends StatefulWidget {
  final VoidCallback onBackToLibrary;

  const CollectionsGridView({super.key, required this.onBackToLibrary});

  @override
  State<CollectionsGridView> createState() => _CollectionsGridViewState();
}

class _CollectionsGridViewState extends State<CollectionsGridView> {
  String _searchQuery = "";

  late Stream<List<MediaCollection>> _collectionsStream;

  @override
  void initState() {
    super.initState();
    final user = sl<AuthRepository>().currentUser;
    if (user != null) {
      _collectionsStream = sl<GetCollectionsStreamUseCase>().call(user.id);
    } else {
      _collectionsStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: StreamBuilder<List<MediaCollection>>(
            stream: _collectionsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final collections = snapshot.data ?? [];
              final filtered = collections.where((c) {
                if (_searchQuery.isNotEmpty && !c.name.toLowerCase().contains(_searchQuery)) {
                  return false;
                }
                return true;
              }).toList();

              return GridView.builder(
                padding: const EdgeInsets.only(top: 10, left: 15, right: 15, bottom: 150),
                physics: const BouncingScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  return _buildCollectionCard(context, filtered[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 5),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBackToLibrary,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Cerca nelle raccolte...",
                    hintStyle: const TextStyle(color: Colors.white38),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateCollectionPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
                        blurRadius: 10,
                      )
                    ]
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.black, size: 22),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionCard(BuildContext context, MediaCollection collection) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CollectionDetailPage(collection: collection)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (collection.coverUrl != null && collection.coverUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: collection.coverUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.collections_bookmark_rounded, color: Colors.white24, size: 30),
                  ),
                ),
              )
            else
              const Center(
                child: Icon(Icons.collections_bookmark_rounded, color: Colors.white24, size: 30),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 6,
              right: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    collection.name.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      shadows: [Shadow(offset: Offset(0, 1), blurRadius: 3.0, color: Colors.black)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${collection.itemCount} elementi",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
