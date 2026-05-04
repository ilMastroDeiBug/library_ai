import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../domain/entities/actor.dart';
import '../domain/use_cases/actor_use_cases.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/use_cases/favorite_use_cases.dart';
import '../injection_container.dart';

class ActorDetailPage extends StatefulWidget {
  final int actorId;
  const ActorDetailPage({Key? key, required this.actorId}) : super(key: key);

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

  static const Color _brandColor = Colors.orangeAccent;
  static const Color _backgroundColor = Colors.black;
  static const Color _cardColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    _loadActorDetails();
  }

  Future<void> _loadActorDetails() async {
    try {
      final useCase = sl<GetActorDetailsUseCase>();
      final result = await useCase.call(widget.actorId);
      if (mounted) {
        setState(() {
          actor = result;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  Future<void> _handleFavoriteToggle(bool currentStreamValue) async {
    if (actor == null) return;
    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) _showMinimalSnackBar("Accedi per aggiungere ai preferiti.");
      return;
    }

    final targetValue = !(_optimisticIsFavorite ?? currentStreamValue);
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
          isAdded ? "Aggiunto ai Preferiti ❤️" : "Rimosso dai Preferiti 💔",
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _optimisticIsFavorite = !targetValue);
        _showMinimalSnackBar("Errore nell'aggiornamento dei preferiti.");
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
        body: Center(child: CircularProgressIndicator(color: _brandColor)),
      );
    }

    if (errorMessage != null || actor == null) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'Errore: $errorMessage',
            style: const TextStyle(color: Colors.white70),
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
                      if (user != null)
                        StreamBuilder<bool>(
                          stream: sl<CheckFavoriteStatusUseCase>().call(
                            user.id,
                            actor!.id,
                            'person',
                          ),
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
                                      ? Colors.redAccent.withOpacity(0.1)
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
                                        ? Colors.redAccent
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
                  _buildSectionTitle('BIOGRAFIA'),
                  const SizedBox(height: 16),
                  _buildExpandableBiography(actor!),
                  const SizedBox(height: 40),
                  _buildSectionTitle('FILMOGRAFIA'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: _buildFilmography(actor!.credits),
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

  Widget _buildExpandableBiography(Actor actor) {
    final bio = actor.biography.isNotEmpty
        ? actor.biography
        : 'Nessuna biografia disponibile per questo attore.';
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
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "Leggi di più",
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
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                "Mostra meno",
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

  Widget _buildFilmography(List<ActorCredit> credits) {
    if (credits.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          'Nessuna informazione sulla filmografia.',
          style: TextStyle(color: Colors.white30),
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
