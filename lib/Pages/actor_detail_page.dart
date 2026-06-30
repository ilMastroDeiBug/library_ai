import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../domain/entities/actor.dart';
import '../domain/use_cases/actor_use_cases.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/use_cases/favorite_use_cases.dart';
import '../injection_container.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';

class ActorDetailPage extends StatefulWidget {
  final int actorId;
  const ActorDetailPage({super.key, required this.actorId});

  @override
  State<ActorDetailPage> createState() => _ActorDetailPageState();
}

class _ActorDetailPageState extends State<ActorDetailPage> {
  Actor? actor;
  bool isLoading = true;
  String? errorMessage;
  bool _isBioExpanded = false;

  // UI OTTIMISTICA
  bool? _optimisticIsFavorite;
  bool _isTogglingHeart = false;
  Stream<bool>? _favoriteStream;

  static const Color _brandColor = Colors.white;
  static const Color _backgroundColor = Colors.black;
  static const Color _cardColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadActorDetails();
  }

  Future<void> _loadActorDetails() async {
    if (mounted) setState(() { isLoading = true; errorMessage = null; });
    try {
      final result = await sl<GetActorDetailsUseCase>().call(widget.actorId);
      final user = sl<AuthRepository>().currentUser;
      if (mounted) {
        setState(() { 
          actor = result; 
          if (user != null) {
            _favoriteStream = sl<CheckFavoriteStatusUseCase>().call(
              user.id,
              result.id,
              'person',
            );
          }
          isLoading = false; 
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        // Pulisce il messaggio togliendo il prefisso 'Exception: '
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> _handleFavoriteToggle(bool currentStreamValue) async {
    if (actor == null) return;
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) _showMinimalSnackBar(AppLocalizations.of(context)!.actorLoginToFavorite);
      return;
    }

    final targetValue = !(_optimisticIsFavorite ?? currentStreamValue);

    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return;

    setState(() {
      _isTogglingHeart = true;
      _optimisticIsFavorite = targetValue;
    });

    try {
      final String? fullProfileUrl = actor!.profilePath != null
          ? 'https://image.tmdb.org/t/p/w500${actor!.profilePath}'
          : null;

      final isAdded = await sl<ToggleFavoriteUseCase>().call(
        user.id,
        actor!.id,
        'person',
        actor!.name,
        fullProfileUrl,
      );

      if (mounted) {
        setState(() => _optimisticIsFavorite = isAdded);
        _showMinimalSnackBar(
          isAdded ? AppLocalizations.of(context)!.actorAddedToFavorites : AppLocalizations.of(context)!.actorRemovedFromFavorites,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticIsFavorite = !targetValue);
        _showMinimalSnackBar(AppLocalizations.of(context)!.actorFavoriteError);
      }
    } finally {
      if (mounted) setState(() => _isTogglingHeart = false);
    }
  }

  void _showMinimalSnackBar(String message) {
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: _brandColor,
                strokeWidth: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Caricamento...',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage != null || actor == null) {
      final isOffline = errorMessage?.contains('Internet') == true ||
          errorMessage?.contains('TMDB') == true;
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Back button
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
              // Errore centrato
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icona animata
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: (isOffline ? Colors.white : Colors.white)
                                .withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: (isOffline ? Colors.white : Colors.white)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Icon(
                            isOffline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                            color: isOffline ? Colors.white : Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isOffline ? 'Sei offline' : 'Qualcosa è andato storto',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          errorMessage ?? 'Impossibile caricare i dati.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Bottone Riprova
                        GestureDetector(
                          onTap: _loadActorDetails,
                          child: Container(
                            height: 48,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _brandColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _brandColor.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.refresh_rounded, color: Colors.black, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Riprova',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Torna indietro
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            height: 48,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: const Text(
                              'Torna indietro',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final user = sl<AuthRepository>().currentUser;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeroHeader(actor!),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          actor!.name.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (user != null && _favoriteStream != null)
                        StreamBuilder<bool>(
                          stream: _favoriteStream,
                          builder: (context, favSnapshot) {
                            final streamValue = favSnapshot.data ?? false;
                            final isFavorite = _isTogglingHeart
                                ? _optimisticIsFavorite!
                                : (_optimisticIsFavorite ?? streamValue);

                            return GestureDetector(
                              onTap: () => _handleFavoriteToggle(streamValue),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isFavorite
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.white.withOpacity(0.05),
                                  shape: BoxShape.circle,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, anim) =>
                                      ScaleTransition(
                                        scale: anim,
                                        child: child,
                                      ),
                                  child: Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    key: ValueKey(isFavorite),
                                    color: isFavorite
                                        ? Colors.white
                                        : Colors.white,
                                    size: 26,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    actor!.knownForDepartment.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _brandColor,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 28),
                  _buildStatsRow(actor!),
                  const SizedBox(height: 40),
                  _buildSectionTitle(AppLocalizations.of(context)!.actorBiographyTitle),
                  const SizedBox(height: 16),
                  _buildExpandableBiography(actor!, context),
                  const SizedBox(height: 40),
                  _buildSectionTitle(AppLocalizations.of(context)!.actorFilmographyTitle),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: _buildFilmography(actor!.credits, context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(Actor actor) {
    return SliverAppBar(
      expandedHeight: 450.0,
      pinned: true,
      stretch: true,
      backgroundColor: _backgroundColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.white,
          ),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            actor.profilePath != null
                ? CachedNetworkImage(
                    imageUrl:
                        'https://image.tmdb.org/t/p/original${actor.profilePath}',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  )
                : Container(color: _cardColor),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    _backgroundColor.withOpacity(0.8),
                    _backgroundColor,
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Actor actor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          if (actor.birthday != null)
            _buildStatCapsule(Icons.cake_outlined, actor.birthday!),
          if (actor.placeOfBirth != null)
            _buildStatCapsule(Icons.location_on_outlined, actor.placeOfBirth!),
          _buildStatCapsule(
            Icons.local_fire_department_outlined,
            actor.popularity.toStringAsFixed(0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCapsule(IconData icon, String value) {
    final displayValue = value.length > 20
        ? '${value.substring(0, 20)}...'
        : value;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _brandColor, size: 16),
          const SizedBox(width: 8),
          Text(
            displayValue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white.withOpacity(0.3),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildExpandableBiography(Actor actor, BuildContext context) {
    final bio = actor.biography.isNotEmpty
        ? actor.biography
        : AppLocalizations.of(context)!.actorNoBio;
    return GestureDetector(
      onTap: () => setState(() => _isBioExpanded = !_isBioExpanded),
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: _isBioExpanded
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bio,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            if (bio.length > 150)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  AppLocalizations.of(context)!.actorReadMore,
                  style: TextStyle(
                    color: _brandColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        secondChild: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bio,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                AppLocalizations.of(context)!.actorShowLess,
                style: TextStyle(
                  color: _brandColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilmography(List<ActorCredit> credits, BuildContext context) {
    if (credits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          AppLocalizations.of(context)!.actorNoFilmography,
          style: const TextStyle(color: Colors.white30),
        ),
      );
    }
    return SizedBox(
      height: 250,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: credits.length,
        itemBuilder: (context, index) {
          final credit = credits[index];
          return GestureDetector(
            onTap: () {},
            child: Container(
              width: 120,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl:
                            'https://image.tmdb.org/t/p/w300${credit.posterPath}',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: _cardColor,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _brandColor,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: _cardColor,
                          child: const Icon(
                            Icons.movie_creation_outlined,
                            color: Colors.white24,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    credit.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (credit.character != null && credit.character!.isNotEmpty)
                    Text(
                      credit.character!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
