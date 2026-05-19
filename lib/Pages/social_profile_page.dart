import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/entities/social_stats.dart';
import 'package:library_ai/domain/entities/pinned_item.dart';
import 'package:library_ai/domain/entities/vault_entry.dart';
import 'package:library_ai/domain/use_cases/social_use_cases.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/pages/settings_page.dart';
import 'social_profile_widgets/profile_header.dart';
import 'social_profile_widgets/pinned_vault_showcase.dart';
import 'social_profile_widgets/recent_diary.dart';

class SocialProfilePage extends StatefulWidget {
  const SocialProfilePage({super.key});

  @override
  State<SocialProfilePage> createState() => _SocialProfilePageState();
}

class _SocialProfilePageState extends State<SocialProfilePage>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  AppUser? _user;
  SocialStats _stats = const SocialStats();
  List<VaultEntry> _recentEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authUser = sl<AuthRepository>().currentUser;
    if (authUser == null) {
      setState(() => _loading = false);
      return;
    }

    final results = await Future.wait([
      sl<GetUserDataUseCase>().call(authUser.id),
      sl<GetSocialStatsUseCase>().call(authUser.id),
    ]);

    if (mounted) {
      setState(() {
        _user = results[0] as AppUser?;
        _stats = results[1] as SocialStats;
        _recentEntries = _loadDiaryFromCache(authUser.id);
        _loading = false;
      });
      _fadeCtrl.forward();
    }
  }

  /// Legge le ultime 5 opere dalla cache Hive locale.
  /// Zero chiamate di rete: usa i dati già scaricati dagli altri repository.
  List<VaultEntry> _loadDiaryFromCache(String userId) {
    if (!Hive.isBoxOpen('cinelib_cache')) return [];
    final box = Hive.box('cinelib_cache');
    final all = <VaultEntry>[];

    // ── Film e Serie TV ──────────────────────────────────────────────────────
    for (final status in ['watched', 'watching', 'towatch']) {
      final cached = box.get('watchlist_${userId}_$status');
      if (cached is! List) continue;
      for (final raw in cached) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw as Map);
        // Il row di user_watchlist ha: user_id, media_id, type, raw_data, timestamp
        final rawData = row['raw_data'] is Map
            ? Map<String, dynamic>.from(row['raw_data'] as Map)
            : <String, dynamic>{};
        // Movie.toMap() usa 'posterPath' (camelCase), non 'poster_path'
        final posterPath = rawData['posterPath']?.toString() ?? '';
        all.add(VaultEntry(
          id: row['id']?.toString() ?? UniqueKey().toString(),
          userId: userId,
          mediaId: (row['media_id'] as num?)?.toInt() ?? 0,
          mediaType: row['type']?.toString() ?? 'movie',
          title: rawData['title']?.toString() ??
              rawData['name']?.toString() ?? '',
          posterUrl: posterPath.isNotEmpty
              ? 'https://image.tmdb.org/t/p/w342$posterPath'
              : null,
          rating: (rawData['voteAverage'] as num?)?.toDouble(),
          reviewSnippet: null,
          status: status,
          addedAt: row['timestamp'] != null
              ? DateTime.tryParse(row['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now(),
        ));
      }
    }

    // ── Libri ────────────────────────────────────────────────────────────────
    for (final status in ['reading', 'completed', 'want_to_read', 'dropped']) {
      final cached = box.get('books_${userId}_$status');
      if (cached is! List) continue;
      for (final raw in cached) {
        if (raw is! Map) continue;
        final row = Map<String, dynamic>.from(raw as Map);
        all.add(VaultEntry(
          id: row['id']?.toString() ?? UniqueKey().toString(),
          userId: userId,
          mediaId: row['book_id']?.hashCode.abs() ?? 0,
          mediaType: 'book',
          title: row['title']?.toString() ?? '',
          posterUrl: row['thumbnail_url']?.toString(),
          rating: (row['rating'] as num?)?.toDouble(),
          reviewSnippet: null,
          status: status,
          addedAt: row['timestamp'] != null
              ? DateTime.tryParse(row['timestamp'].toString()) ?? DateTime.now()
              : DateTime.now(),
        ));
      }
    }

    // Ordina per data e taglia a 5
    all.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return all.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();

    final user = _user;
    if (user == null) return _buildUnauthenticated();

    final authUser = sl<AuthRepository>().currentUser!;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // ── Spazio per l'header trasparente
            const SliverToBoxAdapter(child: SizedBox(height: 56)),

            // ── Header del profilo
            SliverToBoxAdapter(
              child: ProfileHeader(user: user, stats: _stats),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // ── Vetrina – Pinned Big 4
            SliverToBoxAdapter(child: _buildSectionTitle('Vetrina')),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: StreamBuilder<List<PinnedItem>>(
                stream: sl<GetPinnedItemsUseCase>().call(authUser.id),
                builder: (context, snap) {
                  final items = snap.data ?? [];
                  return PinnedVaultShowcase(items: items, userId: authUser.id);
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 36)),

            // ── Diario Recente
            SliverToBoxAdapter(child: _buildSectionTitle('Diario Recente')),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: _recentEntries.isEmpty
                  ? _buildEmptyDiary()
                  : Column(
                      children: _recentEntries
                          .map((e) => RecentDiaryEntry(entry: e))
                          .toList(),
                    ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: const Color(0xFF0A0A0A).withOpacity(0.7),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profilo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      ),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Colors.orangeAccent.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(height: 1, color: Colors.white.withOpacity(0.06)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDiary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 40),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 48,
            color: Colors.white.withOpacity(0.15),
          ),
          const SizedBox(height: 16),
          Text(
            'Il tuo vault è ancora vuoto.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Aggiungi film, serie o libri dalla Home.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnauthenticated() {
    return const Center(
      child: Text(
        'Accedi per vedere il tuo profilo.',
        style: TextStyle(color: Colors.white54),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: ListView(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 70),
        children: [
          // Avatar skeleton
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 140,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 90,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer entry ────────────────────────────────────────────────────────────

class _DiaryEntryShimmer extends StatelessWidget {
  const _DiaryEntryShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 66,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
