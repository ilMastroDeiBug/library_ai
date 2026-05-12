import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../domain/entities/review.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/use_cases/review_use_cases.dart';
import '../injection_container.dart';
import '../models/reviews_widgets/write_review_sheet.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class AllReviewsPage extends StatefulWidget {
  final int mediaId;
  final String title;
  final bool isTvSeries;

  const AllReviewsPage({
    super.key,
    required this.mediaId,
    required this.title,
    this.isTvSeries = false,
  });

  @override
  State<AllReviewsPage> createState() => _AllReviewsPageState();
}

class _AllReviewsPageState extends State<AllReviewsPage> {
  List<Review>? _reviews;
  String _sortBy = 'relevance';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final user = sl<AuthRepository>().currentUser;
    final userId = user?.id ?? '';

    try {
      final reviews = await sl<GetMediaReviewsUseCase>().call(
        widget.mediaId,
        widget.isTvSeries ? 'tv' : 'movie',
        userId,
        sortBy: _sortBy,
      );
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleVote(Review review, int vote) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      _showSnackBar(AppLocalizations.of(context)!.allReviewsLoginToVote);
      return;
    }
    if (!review.isCustom) {
      _showSnackBar(AppLocalizations.of(context)!.allReviewsTmdbCannotVote);
      return;
    }

    // Optimistic UI
    int newVote = review.userVote == vote
        ? 0
        : vote; // Toggle se clicca lo stesso
    int newLikes = review.likes;
    int newDislikes = review.dislikes;

    // Rimuovi il vecchio voto se presente
    if (review.userVote == 1) newLikes--;
    if (review.userVote == -1) newDislikes--;
    // Applica il nuovo voto
    if (newVote == 1) newLikes++;
    if (newVote == -1) newDislikes++;

    setState(() {
      final index = _reviews!.indexWhere((r) => r.id == review.id);
      if (index != -1) {
        _reviews![index] = review.copyWith(
          likes: newLikes,
          dislikes: newDislikes,
          userVote: newVote,
        );
      }
    });

    try {
      await sl<VoteReviewUseCase>().call(review.id, user.id, newVote);
    } catch (e) {
      _fetchReviews(); // Revert in caso di errore di rete
    }
  }

  Future<void> _handleDelete(Review review) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null || !review.isWrittenBy(user.id)) {
      _showSnackBar(AppLocalizations.of(context)!.allReviewsDeleteOnlyYours);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(
          AppLocalizations.of(context)!.allReviewsDeleteTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          AppLocalizations.of(context)!.allReviewsDeleteDesc,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final previousReviews = List<Review>.from(_reviews ?? []);
    setState(() {
      _reviews?.removeWhere((item) => item.id == review.id);
    });

    try {
      await sl<DeleteReviewUseCase>().call(review.id, user.id);
      _showSnackBar(AppLocalizations.of(context)!.allReviewsDeleted);
    } catch (_) {
      if (mounted) {
        setState(() => _reviews = previousReviews);
        _showSnackBar(AppLocalizations.of(context)!.allReviewsDeleteError);
      }
    }
  }

  void _openWriteReview() async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      _showSnackBar(AppLocalizations.of(context)!.allReviewsLoginToWrite);
      return;
    }

    final bool? success = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WriteReviewSheet(
        mediaId: widget.mediaId,
        isTvSeries: widget.isTvSeries,
      ),
    );

    if (success == true) _fetchReviews();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    // Formattazione nativa in Dart (es. 05/05/2026) senza pacchetti esterni!
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0C), // Sfondo ultra scuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openWriteReview,
        backgroundColor: Colors.orangeAccent,
        icon: const Icon(Icons.edit_rounded, color: Colors.black),
        label: Text(
          AppLocalizations.of(context)!.allReviewsWrite,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // HEADER CON FILTRI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _reviews != null
                      ? AppLocalizations.of(context)!.allReviewsCount(_reviews!.length)
                      : AppLocalizations.of(context)!.allReviewsLoading,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161618),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: DropdownButton<String>(
                    value: _sortBy,
                    dropdownColor: const Color(0xFF1E1E1E),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.orangeAccent,
                      size: 18,
                    ),
                    underline: const SizedBox(),
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'relevance',
                        child: Text(AppLocalizations.of(context)!.allReviewsSortRelevant),
                      ),
                      DropdownMenuItem(value: 'recent', child: Text(AppLocalizations.of(context)!.allReviewsSortRecent)),
                      DropdownMenuItem(
                        value: 'rating_desc',
                        child: Text(AppLocalizations.of(context)!.allReviewsSortHighRating),
                      ),
                      DropdownMenuItem(
                        value: 'rating_asc',
                        child: Text(AppLocalizations.of(context)!.allReviewsSortLowRating),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null && val != _sortBy) {
                        setState(() => _sortBy = val);
                        _fetchReviews();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // LISTA RECENSIONI
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.orangeAccent,
                    ),
                  )
                : RefreshIndicator(
                    color: Colors.orangeAccent,
                    backgroundColor: const Color(0xFF161618),
                    onRefresh: _fetchReviews,
                    child: _reviews == null || _reviews!.isEmpty
                        ? ListView(
                            // Usiamo ListView per permettere il pull-to-refresh anche se vuoto
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                              ),
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.forum_outlined,
                                      size: 60,
                                      color: Colors.white.withOpacity(0.1),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.allReviewsEmpty,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 100,
                            ), // Spazio per il FAB
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: _reviews!.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _buildFullReviewCard(_reviews![index]);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullReviewCard(Review review) {
    final user = sl<AuthRepository>().currentUser;
    final canDelete = review.isWrittenBy(user?.id);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AUTORE E AVATAR
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.05),
                backgroundImage: review.avatarUrl != null
                    ? CachedNetworkImageProvider(review.avatarUrl!)
                    : null,
                child: review.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white38, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (!review.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "TMDB",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          _formatDate(review.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  tooltip: AppLocalizations.of(context)!.allReviewsDeleteTooltip,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => _handleDelete(review),
                ),
              // STELLINE
              if (review.rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.orangeAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // TESTO RECENSIONE
          Text(
            review.content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.6,
            ),
          ),

          // BOTTONI VOTO (Solo per recensioni Custom)
          if (review.isCustom) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(
              children: [
                _buildVoteButton(
                  activeIcon: Icons.thumb_up_alt_rounded,
                  inactiveIcon: Icons.thumb_up_alt_outlined,
                  count: review.likes,
                  isActive: review.userVote == 1,
                  activeColor: Colors.greenAccent,
                  onTap: () => _handleVote(review, 1),
                ),
                const SizedBox(width: 24),
                _buildVoteButton(
                  activeIcon: Icons.thumb_down_alt_rounded,
                  inactiveIcon: Icons.thumb_down_alt_outlined,
                  count: review.dislikes,
                  isActive: review.userVote == -1,
                  activeColor: Colors.redAccent,
                  onTap: () => _handleVote(review, -1),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData activeIcon,
    required IconData inactiveIcon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 20,
              color: isActive ? activeColor : Colors.white38,
            ),
            const SizedBox(width: 6),
            Text(
              count.toString(),
              style: TextStyle(
                color: isActive ? activeColor : Colors.white38,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
