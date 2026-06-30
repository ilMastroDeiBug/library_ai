import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/repositories/ai_repository.dart';
import 'package:library_ai/domain/use_cases/ai_use_cases.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/Pages/ai_features/time_box_tetris_dialog.dart';
import 'package:library_ai/Pages/ai_features/what_to_watch_next_dialog.dart';

// ─── Brand colors ─────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF000000);
const Color _kBrand = Colors.white;
const Color _kTextDim = Color(0xFFA1A1AA); // Zinc 400
const Color _kBorderColor = Color(0x14FFFFFF); // ~8% white

// ─── Feature model ────────────────────────────────────────────────────────────
class _AiFeature {
  final String id;
  final String title;
  final String description;
  final String badge;
  final IconData icon;
  final int tokenCost;

  const _AiFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.badge,
    required this.icon,
    required this.tokenCost,
  });
}

List<_AiFeature> _buildFeatures(AppLocalizations l) => [
  _AiFeature(
    id: 'vault_sync',
    title: l.aiFeatureVaultSyncTitle,
    description: l.aiFeatureVaultSyncDesc,
    badge: l.aiFeatureVaultSyncBadge,
    icon: Icons.sync_alt_rounded,
    tokenCost: 1,
  ),
  _AiFeature(
    id: 'what_to_watch',
    title: l.aiFeatureWatchNowTitle,
    description: l.aiFeatureWatchNowDesc,
    badge: l.aiFeatureWatchNowBadge,
    icon: Icons.play_circle_outline_rounded,
    tokenCost: 1,
  ),
  _AiFeature(
    id: 'mood_mapper',
    title: l.aiFeatureMoodTitle,
    description: l.aiFeatureMoodDesc,
    badge: l.aiFeatureMoodBadge,
    icon: Icons.waves_rounded,
    tokenCost: 1,
  ),
  _AiFeature(
    id: 'scudo_spoiler',
    title: l.aiFeatureShieldTitle,
    description: l.aiFeatureShieldDesc,
    badge: l.aiFeatureShieldBadge,
    icon: Icons.security_rounded,
    tokenCost: 1,
  ),
  _AiFeature(
    id: 'scene_correlation',
    title: l.aiFeatureSceneTitle,
    description: l.aiFeatureSceneDesc,
    badge: l.aiFeatureSceneBadge,
    icon: Icons.image_search_rounded,
    tokenCost: 3,
  ),
  _AiFeature(
    id: 'time_box_tetris',
    title: "Time-Box Tetris",
    description:
        "L'Ottimizzatore di Sonno: trova l'incastro perfetto prima di andare a letto.",
    badge: "NUOVO",
    icon: Icons.access_time_filled_rounded,
    tokenCost: 2,
  ),
  _AiFeature(
    id: 'what_to_watch_next',
    title: "Cosa Guardare Dopo?",
    description:
        "Cerca un titolo appena finito e ricevi 3 raccomandazioni perfette.",
    badge: "NUOVO",
    icon: Icons.auto_awesome_rounded,
    tokenCost: 2,
  ),
];

// ─── Page ────────────────────────────────────────────────────────────────────
class StudioAIPage extends StatefulWidget {
  const StudioAIPage({super.key});

  @override
  State<StudioAIPage> createState() => _StudioAIPageState();
}

class _StudioAIPageState extends State<StudioAIPage>
    with SingleTickerProviderStateMixin {
  String _userId = '';
  int _tokens = 15;
  DateTime? _nextResetDate;

  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    final user = sl<AuthRepository>().currentUser;
    if (user != null) {
      _userId = user.id;

      _initTokensAndSync();
    }
  }

  Future<void> _initTokensAndSync() async {
    final aiRepo = sl<AiRepository>();
    // Sync tokens securely via DB RPC
    await aiRepo.syncTokens();

    // Fetch stream for real-time updates
    sl<GetAiTokensUseCase>().call(_userId).listen((t) {
      if (mounted) setState(() => _tokens = t);
    });

    // Fetch next reset date for the countdown
    final resetDate = await aiRepo.getNextResetDate(_userId);
    if (mounted) {
      setState(() {
        _nextResetDate = resetDate;
      });
    }
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _onFeatureTap(_AiFeature feature, AppLocalizations l) {
    if (_tokens < feature.tokenCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.aiStudioInsufficientTokens(feature.tokenCost)),
          backgroundColor: Colors.white,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.black,
            onPressed: () {},
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    if (feature.id == 'time_box_tetris') {
      showTimeBoxTetrisModal(context);
      return;
    }

    if (feature.id == 'what_to_watch_next') {
      showWhatToWatchNextModal(context, null);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l.aiStudioOpening(feature.title),
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final features = _buildFeatures(l);
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // LAYER 0: Collage Covers Background
          Positioned.fill(child: _CoversBackground()),

          // LAYER 1: Subtle Gradient overlay to ensure text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),

          // LAYER 2: Scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, topPadding + 40, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TokenPill(
                        tokens: _tokens,
                        nextResetDate: _nextResetDate,
                        l: l,
                      ),
                      const SizedBox(height: 32),
                      AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (context, child) {
                          return ShaderMask(
                            shaderCallback: (bounds) {
                              return LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(
                                    0.6 + (_glowCtrl.value * 0.4),
                                  ),
                                  Colors.white,
                                ],
                                stops: [0.0, _glowCtrl.value, 1.0],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds);
                            },
                            child: child,
                          );
                        },
                        child: Text(
                          l.aiStudioTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -2.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.aiStudioSubtitle,
                        style: const TextStyle(
                          color: _kTextDim,
                          fontSize: 16,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _FeatureCard(
                        feature: features[i],
                        onTap: () => _onFeatureTap(features[i], l),
                      ),
                    ),
                    childCount: features.length,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Covers Background ────────────────────────────────────────────────────────
class _CoversBackground extends StatefulWidget {
  @override
  State<_CoversBackground> createState() => _CoversBackgroundState();
}

class _CoversBackgroundState extends State<_CoversBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<String> _images = List.generate(
    30,
    (i) => 'assets/images/covers/cover_${i + 1}.jpg',
  )..shuffle();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Stack(
          children: [
            Row(
              children: List.generate(4, (colIndex) {
                final int itemsPerCol = (_images.length / 4).ceil();
                final colImages = _images
                    .skip(colIndex * itemsPerCol)
                    .take(itemsPerCol)
                    .toList();

                final double offset =
                    (colIndex % 2 == 0 ? -_ctrl.value : (_ctrl.value - 1)) *
                    1000;

                return Expanded(
                  child: OverflowBox(
                    maxHeight: double.infinity,
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: Offset(0, offset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...colImages.map(_buildImage),
                          ...colImages.map(_buildImage),
                          ...colImages.map(_buildImage),
                          ...colImages.map(
                            _buildImage,
                          ), // Ripetizioni per scroll infinito
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage(String path) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
          height: 180,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              Container(height: 180, color: Colors.white.withOpacity(0.05)),
        ),
      ),
    );
  }
}

// ─── Token pill with Countdown ────────────────────────────────────────────────
class _TokenPill extends StatelessWidget {
  final int tokens;
  final DateTime? nextResetDate;
  final AppLocalizations l;

  const _TokenPill({required this.tokens, this.nextResetDate, required this.l});

  String _getResetText() {
    if (nextResetDate == null) return "Calcolo...";
    final now = DateTime.now().toUtc();
    final diff = nextResetDate!.difference(now);
    if (diff.isNegative) return "Ricarica imminente";

    if (diff.inDays > 0) return "Ricarica tra ${diff.inDays} giorni";
    if (diff.inHours > 0) return "Ricarica tra ${diff.inHours} ore";
    if (diff.inMinutes > 0) return "Ricarica tra ${diff.inMinutes} min";
    return "Ricarica tra poco";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // Zinc 900
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            l.aiStudioTokensRemaining(tokens),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 12, color: Colors.white.withOpacity(0.2)),
          const SizedBox(width: 12),
          Text(
            _getResetText(),
            style: const TextStyle(
              color: _kTextDim,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature card (Bento 2.0 with Spring Physics) ──────────────────────────────
class _FeatureCard extends StatefulWidget {
  final _AiFeature feature;
  final VoidCallback onTap;
  const _FeatureCard({required this.feature, required this.onTap});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final SpringSimulation _springSim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _springSim = SpringSimulation(
      const SpringDescription(mass: 1, stiffness: 400, damping: 25),
      _ctrl.value,
      1.0,
      0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _ctrl.animateTo(
      0.96,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails details) {
    _ctrl.animateWith(_springSim);
    widget.onTap();
  }

  void _onTapCancel() {
    _ctrl.animateWith(_springSim);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF09090B), // Zinc 950
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _kBorderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimal Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kBorderColor),
                ),
                child: Icon(widget.feature.icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 20),

              // Text block
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            widget.feature.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _TokenBadge(cost: widget.feature.tokenCost),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.feature.description,
                      style: const TextStyle(
                        color: _kTextDim,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _kBorderColor),
                      ),
                      child: Text(
                        widget.feature.badge,
                        style: const TextStyle(
                          color: _kTextDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Token badge ──────────────────────────────────────────────────────────────
class _TokenBadge extends StatelessWidget {
  final int cost;
  const _TokenBadge({required this.cost});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.bolt_rounded,
          color: Colors.white.withOpacity(0.5),
          size: 14,
        ),
        const SizedBox(width: 2),
        Text(
          cost.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
