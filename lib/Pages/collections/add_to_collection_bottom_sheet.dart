import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/media_collection.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/collection_use_cases.dart';

class AddToCollectionBottomSheet extends StatefulWidget {
  final String itemId;
  final String itemType;
  final String title;

  const AddToCollectionBottomSheet({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.title,
  });

  @override
  State<AddToCollectionBottomSheet> createState() => _AddToCollectionBottomSheetState();
}

class _AddToCollectionBottomSheetState extends State<AddToCollectionBottomSheet> {
  late Stream<List<MediaCollection>> _collectionsStream;
  List<int> _itemCollectionIds = [];
  bool _isLoadingIds = true;
  final String _userId = sl<AuthRepository>().currentUser!.id;

  @override
  void initState() {
    super.initState();
    _collectionsStream = sl<GetCollectionsStreamUseCase>().call(_userId);
    _loadItemCollections();
  }

  Future<void> _loadItemCollections() async {
    try {
      final ids = await sl<GetItemCollectionIdsUseCase>().call(
        _userId,
        widget.itemId,
        widget.itemType,
      );
      if (mounted) {
        setState(() {
          _itemCollectionIds = ids;
          _isLoadingIds = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingIds = false);
      }
    }
  }

  Future<void> _toggleCollection(int collectionId, bool isCurrentlyIn) async {
    // Aggiornamento ottimistico
    setState(() {
      if (isCurrentlyIn) {
        _itemCollectionIds.remove(collectionId);
      } else {
        _itemCollectionIds.add(collectionId);
      }
    });

    try {
      if (isCurrentlyIn) {
        await sl<RemoveMediaFromCollectionUseCase>().call(collectionId, widget.itemId, widget.itemType);
      } else {
        await sl<AddMediaToCollectionUseCase>().call(collectionId, widget.itemId, widget.itemType);
      }
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          if (isCurrentlyIn) {
            _itemCollectionIds.add(collectionId);
          } else {
            _itemCollectionIds.remove(collectionId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante l\'aggiornamento della raccolta')),
        );
      }
    }
  }

  Future<void> _showCreateCollectionDialog() async {
    final TextEditingController nameController = TextEditingController();
    bool isCreating = false;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121212).withOpacity(0.9),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Nuova Raccolta",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: "Nome della raccolta...",
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: isCreating ? null : () => Navigator.pop(context),
                                child: Text(
                                  "Annulla",
                                  style: TextStyle(color: Colors.white.withOpacity(0.5)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isCreating
                                    ? null
                                    : () async {
                                        final name = nameController.text.trim();
                                        if (name.isEmpty) return;
                                        setStateDialog(() => isCreating = true);
                                        try {
                                          final newCol = await sl<CreateCollectionUseCase>().call(_userId, name);
                                          // Aggiungiamo subito il media alla nuova raccolta
                                          await sl<AddMediaToCollectionUseCase>().call(newCol.id, widget.itemId, widget.itemType);
                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                          _loadItemCollections(); // Ricarica ids
                                        } catch (e) {
                                          if (mounted) {
                                            setStateDialog(() => isCreating = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: isCreating
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                      )
                                    : const Text("Crea", style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF09090B).withOpacity(0.8),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Aggiungi a Raccolta",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Flexible(
                  child: StreamBuilder<List<MediaCollection>>(
                    stream: _collectionsStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }

                      final collections = snapshot.data ?? [];
                      if (collections.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.collections_bookmark_outlined, color: Colors.white.withOpacity(0.2), size: 48),
                              const SizedBox(height: 16),
                              Text(
                                "Non hai ancora nessuna raccolta.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: collections.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          final isCurrentlyIn = _itemCollectionIds.contains(collection.id);

                          return ListTile(
                            onTap: _isLoadingIds ? null : () => _toggleCollection(collection.id, isCurrentlyIn),
                            leading: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.folder_outlined, color: Colors.white70),
                            ),
                            title: Text(
                              collection.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "${collection.itemCount} elementi",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 13,
                              ),
                            ),
                            trailing: _isLoadingIds
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Icon(
                                    isCurrentlyIn ? Icons.check_circle_rounded : Icons.circle_outlined,
                                    color: isCurrentlyIn ? Colors.white : Colors.white24,
                                    size: 28,
                                  ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _showCreateCollectionDialog,
                            icon: const Icon(Icons.add_rounded, size: 24),
                            label: const Text(
                              "Nuova Raccolta",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "Fatto",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }
}
