import 'package:flutter/material.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/review_use_cases.dart';
import '../../injection_container.dart';
import '../../models/reviews_widgets/write_review_sheet.dart';
import '../../Pages/all_reviews_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MovieReviewsSection extends StatefulWidget {
  final int id;
  final String title;
  final bool isTvSeries;

  const MovieReviewsSection({
    super.key,
    required this.id,
    required this.title,
    this.isTvSeries = false,
  });

  @override
  State<MovieReviewsSection> createState() => _MovieReviewsSectionState();
}

class _MovieReviewsSectionState extends State<MovieReviewsSection> {
  List<Review>? _reviews;
  String _sortBy = 'relevance';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() => _isLoading = true);
    final user = sl<AuthRepository>().currentUser;
    final userId = user?.id ?? '';

    try {
      final reviews = await sl<GetMediaReviewsUseCase>().call(
        widget.id,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Accedi per votare")));
      return;
    }
    if (!review.isCustom) return; // Non si votano le TMDB

    // Optimistic UI
    int newVote = review.userVote == vote ? 0 : vote; // Toggle
    int newLikes = review.likes;
    int newDislikes = review.dislikes;

    if (review.userVote == 1) newLikes--;
    if (review.userVote == -1) newDislikes--;
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
      // Revert if failed
      _fetchReviews();
    }
  }

  Future<void> _handleDelete(Review review) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null || !review.isWrittenBy(user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Puoi eliminare solo le tue recensioni")),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Eliminare recensione?",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Questa azione non puo essere annullata.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Elimina",
              style: TextStyle(color: Colors.redAccent),
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
    } catch (_) {
      if (mounted) {
        setState(() => _reviews = previousReviews);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Impossibile eliminare la recensione")),
        );
      }
    }
  }

  void _openWriteReview() async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accedi per scrivere una recensione")),
      );
      return;
    }
    final bool? success = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          WriteReviewSheet(mediaId: widget.id, isTvSeries: widget.isTvSeries),
    );
    if (success == true) _fetchReviews();
  }

  void _openAllReviews() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AllReviewsPage(
          mediaId: widget.id,
          title: widget.title,
          isTvSeries: widget.isTvSeries,
        ),
      ),
    );
    if (mounted) _fetchReviews();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orangeAccent),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "RECENSIONI",
              style: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            DropdownButton<String>(
              value: _sortBy,
              dropdownColor: const Color(0xFF1E1E1E),
              icon: const Icon(
                Icons.sort_rounded,
                color: Colors.orangeAccent,
                size: 16,
              ),
              underline: const SizedBox(),
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'relevance',
                  child: Text("Più rilevanti"),
                ),
                DropdownMenuItem(value: 'recent', child: Text("Più recenti")),
                DropdownMenuItem(
                  value: 'rating_desc',
                  child: Text("Voti più alti"),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _sortBy = val);
                  _fetchReviews();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (_reviews == null || _reviews!.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Nessuna recensione. Sii il primo!",
                style: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          )
        else
          ..._reviews!.take(3).map((r) => _buildReviewCard(r)),

        const SizedBox(height: 10),

        if (_reviews != null && _reviews!.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            height: 45,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withOpacity(0.16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.forum_outlined, color: Colors.white70),
              label: const Text(
                "Vedi tutte le recensioni",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _openAllReviews,
            ),
          ),
          const SizedBox(height: 10),
        ],

        SizedBox(
          width: double.infinity,
          height: 45,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.orangeAccent.withOpacity(0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.edit_note_rounded,
              color: Colors.orangeAccent,
            ),
            label: const Text(
              "Scrivi una recensione",
              style: TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: _openWriteReview,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Review review) {
    final user = sl<AuthRepository>().currentUser;
    final canDelete = review.isWrittenBy(user?.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white10,
                backgroundImage: review.avatarUrl != null
                    ? CachedNetworkImageProvider(review.avatarUrl!)
                    : null,
                child: review.avatarUrl == null
                    ? const Icon(Icons.person, color: Colors.white54, size: 20)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (!review.isCustom)
                      Text(
                        "Da TMDB",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  tooltip: "Elimina recensione",
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  onPressed: () => _handleDelete(review),
                ),
              if (review.rating > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.orangeAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review.content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),

          if (review.isCustom) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _buildVoteButton(
                  Icons.thumb_up_rounded,
                  Icons.thumb_up_outlined,
                  review.likes,
                  review.userVote == 1,
                  () => _handleVote(review, 1),
                ),
                const SizedBox(width: 15),
                _buildVoteButton(
                  Icons.thumb_down_rounded,
                  Icons.thumb_down_outlined,
                  review.dislikes,
                  review.userVote == -1,
                  () => _handleVote(review, -1),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteButton(
    IconData activeIcon,
    IconData inactiveIcon,
    int count,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            isActive ? activeIcon : inactiveIcon,
            size: 18,
            color: isActive ? Colors.orangeAccent : Colors.white54,
          ),
          const SizedBox(width: 6),
          Text(
            count.toString(),
            style: TextStyle(
              color: isActive ? Colors.orangeAccent : Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
