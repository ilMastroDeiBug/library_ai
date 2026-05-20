import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/review_use_cases.dart';
import '../../injection_container.dart';
import '../../models/reviews_widgets/write_review_sheet.dart';
import '../../Pages/all_reviews_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reviewsLoginToVote),
        ),
      );
      return;
    }

    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return;

    if (!review.isCustom) return;

    int newVote = review.userVote == vote ? 0 : vote;
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
      _fetchReviews();
    }
  }

  Future<void> _handleDelete(Review review) async {
    final user = sl<AuthRepository>().currentUser;
    if (user == null || !review.isWrittenBy(user.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reviewsDeleteOnlyYours),
        ),
      );
      return;
    }

    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0D0D0F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
        title: Text(
          AppLocalizations.of(context)!.reviewsDeleteTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.reviewsDeleteDesc,
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
            ),
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
    setState(() => _reviews?.removeWhere((item) => item.id == review.id));

    try {
      await sl<DeleteReviewUseCase>().call(review.id, user.id);
    } catch (_) {
      if (mounted) {
        setState(() => _reviews = previousReviews);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.reviewsDeleteError),
          ),
        );
      }
    }
  }

  void _openWriteReview() async {
    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return;

    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.reviewsLoginToWrite),
        ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header sezione
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.reviewsTitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
            // Sort pill
            GestureDetector(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111113),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.07),
                    width: 1,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _sortBy,
                  dropdownColor: const Color(0xFF0D0D0F),
                  isDense: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFFFF8C00),
                    size: 14,
                  ),
                  underline: const SizedBox(),
                  style: const TextStyle(
                    color: Color(0xFFFF8C00),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'relevance',
                      child: Text(
                        AppLocalizations.of(context)!.reviewsSortRelevance,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'recent',
                      child: Text(
                        AppLocalizations.of(context)!.reviewsSortRecent,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'rating_desc',
                      child: Text(
                        AppLocalizations.of(context)!.reviewsSortRating,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _sortBy = val);
                      _fetchReviews();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Skeleton / lista / empty
        if (_isLoading)
          _buildSkeletonLoader()
        else if (_reviews == null || _reviews!.isEmpty)
          _buildEmptyState(context)
        else
          ..._reviews!.take(3).map((r) => _buildReviewCard(r)),

        const SizedBox(height: 10),

        // Bottone "vedi tutte"
        if (_reviews != null && _reviews!.isNotEmpty) ...[
          _buildActionButton(
            label: AppLocalizations.of(context)!.reviewsViewAll,
            icon: Icons.forum_outlined,
            onTap: _openAllReviews,
            isOrange: false,
          ),
          const SizedBox(height: 10),
        ],

        // Bottone "scrivi recensione"
        _buildActionButton(
          label: AppLocalizations.of(context)!.reviewsWrite,
          icon: Icons.edit_note_rounded,
          onTap: _openWriteReview,
          isOrange: true,
        ),
      ],
    );
  }

  Widget _buildSkeletonLoader() {
    return Column(
      children: List.generate(
        2,
        (_) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF111113),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _ShimmerBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          AppLocalizations.of(context)!.reviewsEmpty,
          style: TextStyle(
            color: Colors.white.withOpacity(0.25),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isOrange,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isOrange
                ? const Color(0xFFFF8C00).withOpacity(0.08)
                : const Color(0xFF111113),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: isOrange
                  ? const Color(0xFFFF8C00).withOpacity(0.3)
                  : Colors.white.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isOrange
                    ? const Color(0xFFFF8C00)
                    : Colors.white.withOpacity(0.5),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isOrange
                      ? const Color(0xFFFF8C00)
                      : Colors.white.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final user = sl<AuthRepository>().currentUser;
    final canDelete = review.isWrittenBy(user?.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header autore
                Row(
                  children: [
                    // Avatar squircle
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: review.avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: review.avatarUrl!,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  _defaultAvatar(review.author),
                            )
                          : _defaultAvatar(review.author),
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
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (review.createdAt != null)
                            Text(
                              _formatDate(review.createdAt),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 10,
                              ),
                            )
                          else if (!review.isCustom)
                            Text(
                              AppLocalizations.of(context)!.reviewsFromTMDB,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Badge rating
                    if (review.rating > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFF8C00).withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFF8C00),
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Color(0xFFFF8C00),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (canDelete)
                      IconButton(
                        padding: const EdgeInsets.only(left: 8),
                        constraints: const BoxConstraints(),
                        tooltip: AppLocalizations.of(context)!
                            .reviewsDeleteTooltip,
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.redAccent.withOpacity(0.7),
                          size: 16,
                        ),
                        onPressed: () => _handleDelete(review),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Testo
                Text(
                  review.content,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

                // Bottoni voto
                if (review.isCustom) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildMiniVoteButton(
                        Icons.thumb_up_rounded,
                        Icons.thumb_up_outlined,
                        review.likes,
                        review.userVote == 1,
                        () => _handleVote(review, 1),
                      ),
                      const SizedBox(width: 12),
                      _buildMiniVoteButton(
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
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Color(0xFFFF8C00),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Widget _buildMiniVoteButton(
    IconData activeIcon,
    IconData inactiveIcon,
    int count,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFF8C00).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? const Color(0xFFFF8C00).withOpacity(0.25)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 14,
              color: isActive
                  ? const Color(0xFFFF8C00)
                  : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 5),
            Text(
              count.toString(),
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFFF8C00)
                    : Colors.white.withOpacity(0.3),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Shimmer box per skeleton loader
class _ShimmerBox extends StatefulWidget {
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
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: false);
    _anim = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_anim.value - 1, 0),
              end: Alignment(_anim.value, 0),
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.04),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        );
      },
    );
  }
}
