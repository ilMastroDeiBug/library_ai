import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../domain/entities/review.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/use_cases/review_use_cases.dart';
import '../injection_container.dart';
import '../models/reviews_widgets/write_review_sheet.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';

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

    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return;

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
      _showSnackBar(AppLocalizations.of(context)!.allReviewsDeleteOnlyYours);
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
          AppLocalizations.of(context)!.allReviewsDeleteTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.allReviewsDeleteDesc,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
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
      _showSnackBar(AppLocalizations.of(context)!.allReviewsDeleted);
    } catch (_) {
      if (mounted) {
        setState(() => _reviews = previousReviews);
        _showSnackBar(AppLocalizations.of(context)!.allReviewsDeleteError);
      }
    }
  }

  void _openWriteReview() async {
    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return;

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
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0C),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080809),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080809),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF111113),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 15,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _openWriteReview,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFE06500)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8C00).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.edit_rounded, color: Colors.black, size: 16),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.allReviewsWrite,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Header con count e sort
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _reviews != null
                      ? AppLocalizations.of(context)!
                            .allReviewsCount(_reviews!.length)
                      : AppLocalizations.of(context)!.allReviewsLoading,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                // Sort pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111113),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.07),
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
                          AppLocalizations.of(
                            context,
                          )!.allReviewsSortRelevant,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'recent',
                        child: Text(
                          AppLocalizations.of(context)!.allReviewsSortRecent,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'rating_desc',
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.allReviewsSortHighRating,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'rating_asc',
                        child: Text(
                          AppLocalizations.of(
                            context,
                          )!.allReviewsSortLowRating,
                        ),
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

          // Lista recensioni
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF8C00),
                      strokeWidth: 2,
                    ),
                  )
                : RefreshIndicator(
                    color: const Color(0xFFFF8C00),
                    backgroundColor: const Color(0xFF111113),
                    onRefresh: _fetchReviews,
                    child: _reviews == null || _reviews!.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 120,
                            ),
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            itemCount: _reviews!.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) =>
                                _buildFullReviewCard(_reviews![index]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF111113),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
                child: Icon(
                  Icons.forum_outlined,
                  size: 30,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.allReviewsEmpty,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Scrivi la prima recensione',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.18),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullReviewCard(Review review) {
    final user = sl<AuthRepository>().currentUser;
    final canDelete = review.isWrittenBy(user?.id);

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header autore
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar squircle
                  ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: review.avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: review.avatarUrl!,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _defaultAvatar(review.author, 38),
                          )
                        : _defaultAvatar(review.author, 38),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (!review.isCustom) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.blueAccent.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'TMDB',
                                  style: TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              _formatDate(review.createdAt),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.25),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Badge rating + delete
                  Row(
                    children: [
                      if (review.rating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8C00).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(9),
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
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                review.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Color(0xFFFF8C00),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (canDelete)
                        IconButton(
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(),
                          tooltip: AppLocalizations.of(
                            context,
                          )!.allReviewsDeleteTooltip,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent.withOpacity(0.7),
                            size: 17,
                          ),
                          onPressed: () => _handleDelete(review),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Separatore sottile
              Container(height: 1, color: Colors.white.withOpacity(0.04)),
              const SizedBox(height: 14),

              // Testo recensione
              Text(
                review.content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.72),
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              // Bottoni voto
              if (review.isCustom) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildVoteButton(
                      activeIcon: Icons.thumb_up_alt_rounded,
                      inactiveIcon: Icons.thumb_up_alt_outlined,
                      count: review.likes,
                      isActive: review.userVote == 1,
                      label: 'Utile',
                      onTap: () => _handleVote(review, 1),
                    ),
                    const SizedBox(width: 10),
                    _buildVoteButton(
                      activeIcon: Icons.thumb_down_alt_rounded,
                      inactiveIcon: Icons.thumb_down_alt_outlined,
                      count: review.dislikes,
                      isActive: review.userVote == -1,
                      label: 'Non utile',
                      onTap: () => _handleVote(review, -1),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String name, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1C),
        borderRadius: BorderRadius.circular(size * 0.29),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            color: const Color(0xFFFF8C00),
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
          ),
        ),
      ),
    );
  }

  Widget _buildVoteButton({
    required IconData activeIcon,
    required IconData inactiveIcon,
    required int count,
    required bool isActive,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFFFF8C00).withOpacity(0.1)
              : const Color(0xFF111113),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFFFF8C00).withOpacity(0.3)
                : Colors.white.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              size: 15,
              color: isActive
                  ? const Color(0xFFFF8C00)
                  : Colors.white.withOpacity(0.3),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                color: isActive
                    ? const Color(0xFFFF8C00)
                    : Colors.white.withOpacity(0.3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
