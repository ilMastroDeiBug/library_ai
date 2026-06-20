import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/ai_use_cases.dart';
import 'package:library_ai/l10n/app_localizations.dart';

// ─── Brand colors ─────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF09090B);
const Color _kBrand = Colors.orangeAccent;
const Color _kTextDim = Color(0xFF9CA3AF);

// ─── Cover paths ──────────────────────────────────────────────────────────────
const List<String> _coverPaths = [
  'assets/images/covers/cover_1.jpg',
  'assets/images/covers/cover_2.jpg',
  'assets/images/covers/cover_3.jpg',
  'assets/images/covers/cover_4.jpg',
  'assets/images/covers/cover_5.jpg',
  'assets/images/covers/cover_6.jpg',
  'assets/images/covers/cover_7.jpg',
  'assets/images/covers/cover_8.jpg',
  'assets/images/covers/cover_9.jpg',
  'assets/images/covers/cover_10.jpg',
  'assets/images/covers/cover_11.jpg',
  'assets/images/covers/cover_12.jpg',
  'assets/images/covers/cover_13.jpg',
  'assets/images/covers/cover_14.jpg',
  'assets/images/covers/cover_15.jpg',
  'assets/images/covers/cover_16.jpg',
  'assets/images/covers/cover_17.jpg',
  'assets/images/covers/cover_18.jpg',
  'assets/images/covers/cover_19.jpg',
  'assets/images/covers/cover_20.jpg',
  'assets/images/covers/cover_21.jpg',
  'assets/images/covers/cover_22.jpg',
  'assets/images/covers/cover_23.jpg',
  'assets/images/covers/cover_24.jpg',
  'assets/images/covers/cover_25.jpg',
  'assets/images/covers/cover_26.jpg',
  'assets/images/covers/cover_27.jpg',
  'assets/images/covers/cover_28.jpg',
  'assets/images/covers/cover_29.jpg',
  'assets/images/covers/cover_30.jpg',
];

// ─── Feature model (non-const: needs runtime l10n strings) ───────────────────
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
    id: 'memory_forge',
    title: l.aiFeatureMemoryTitle,
    description: l.aiFeatureMemoryDesc,
    badge: l.aiFeatureMemoryBadge,
    icon: Icons.auto_stories_rounded,
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

  late final AnimationController _driftCtrl;
  late final Animation<double> _driftAnim;

  @override
  void initState() {
    super.initState();
    _driftCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat(reverse: true);
    _driftAnim = Tween<double>(begin: 0, end: 1).animate(_driftCtrl);

    final user = sl<AuthRepository>().currentUser;
    if (user != null) {
      _userId = user.id;
      sl<GetAiTokensUseCase>().call(_userId).listen((t) {
        if (mounted) setState(() => _tokens = t);
      });
    }
  }

  @override
  void dispose() {
    _driftCtrl.dispose();
    super.dispose();
  }

  void _onFeatureTap(_AiFeature feature, AppLocalizations l) {
    if (_tokens < feature.tokenCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.aiStudioInsufficientTokens(feature.tokenCost)),
          backgroundColor: Colors.redAccent.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.aiStudioOpening(feature.title)),
        backgroundColor: _kBrand.withOpacity(0.9),
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
          // ── LAYER 0: Cover collage background ──────────────────────────────
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _driftAnim,
              builder: (context, _) =>
                  _CoverCollage(driftValue: _driftAnim.value),
            ),
          ),

          // ── LAYER 1: Dark gradient overlay ─────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _kBg.withOpacity(0.65),
                    _kBg.withOpacity(0.42),
                    _kBg.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ),

          // ── LAYER 2: Scrollable content ───────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, topPadding + 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TokenPill(tokens: _tokens, l: l),
                      const SizedBox(height: 24),
                      Text(
                        l.aiStudioTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l.aiStudioSubtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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

// ─── Cover collage ────────────────────────────────────────────────────────────
class _CoverCollage extends StatelessWidget {
  final double driftValue;
  const _CoverCollage({required this.driftValue});

  @override
  Widget build(BuildContext context) {
    const columns = 4;
    const tileWidth = 100.0;
    const tileHeight = 150.0;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rows = (constraints.maxHeight / tileHeight).ceil() + 3;
          final totalWidth = columns * tileWidth;
          final totalHeight = rows * tileHeight;
          // Extra buffer accounts for the odd-column vertical offset (tileHeight/2)
          final maxH = totalHeight + tileHeight;
          final driftOffset = driftValue * 60.0;

          return OverflowBox(
            maxWidth: totalWidth.toDouble(),
            maxHeight: maxH.toDouble(),
            alignment: Alignment.topLeft,
            child: Transform.translate(
              offset: Offset(0, -driftOffset),
              child: SizedBox(
                width: totalWidth.toDouble(),
                height: totalHeight.toDouble(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(columns, (col) {
                    final vertOffset = col.isOdd ? tileHeight / 2 : 0.0;
                    final extraRow = col.isOdd ? 1 : 0;
                    final colRows = rows + extraRow;

                    return SizedBox(
                      width: tileWidth,
                      child: Transform.translate(
                        offset: Offset(0, vertOffset),
                        child: SizedBox(
                          height: colRows * tileHeight,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: List.generate(colRows, (row) {
                              final idx =
                                  (col * rows + row) % _coverPaths.length;
                              return SizedBox(
                                width: tileWidth,
                                height: tileHeight,
                                child: Image.asset(
                                  _coverPaths[idx],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFF1C1C1E),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Token pill ───────────────────────────────────────────────────────────────
class _TokenPill extends StatelessWidget {
  final int tokens;
  final AppLocalizations l;
  const _TokenPill({required this.tokens, required this.l});

  Color get _color {
    if (tokens >= 10) return _kBrand;
    if (tokens >= 5) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _color.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: _color, size: 16),
              const SizedBox(width: 6),
              Text(
                l.aiStudioTokensRemaining(tokens),
                style: TextStyle(
                  color: _color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Feature card ─────────────────────────────────────────────────────────────
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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(
      begin: 1.0,
      end: 0.975,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpensive = widget.feature.tokenCost >= 3;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF09090B).withOpacity(0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.09)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.04),
                    blurRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                  if (isExpensive)
                    BoxShadow(
                      color: _kBrand.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: -4,
                    ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _kBrand.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _kBrand.withOpacity(0.18)),
                    ),
                    child: Icon(widget.feature.icon, color: _kBrand, size: 22),
                  ),
                  const SizedBox(width: 16),

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
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _TokenBadge(cost: widget.feature.tokenCost),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.feature.description,
                          style: const TextStyle(
                            color: _kTextDim,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.09),
                            ),
                          ),
                          child: Text(
                            widget.feature.badge,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.22),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
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
    final color = cost >= 3 ? _kBrand : Colors.white38;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt_rounded, color: color, size: 13),
        const SizedBox(width: 2),
        Text(
          cost.toString(),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
