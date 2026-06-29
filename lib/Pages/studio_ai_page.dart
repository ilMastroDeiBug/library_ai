import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/ai_use_cases.dart';
import 'package:library_ai/l10n/app_localizations.dart';

// ─── Brand colors ─────────────────────────────────────────────────────────────
const Color _kBg = Color(0xFF000000);
const Color _kBrand = Colors.white; // Brand is now pure white for high contrast
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
  // memory_forge removed as per design guidelines (moved to detail page)
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

class _StudioAIPageState extends State<StudioAIPage> {
  String _userId = '';
  int _tokens = 15;

  @override
  void initState() {
    super.initState();
    final user = sl<AuthRepository>().currentUser;
    if (user != null) {
      _userId = user.id;
      sl<GetAiTokensUseCase>().call(_userId).listen((t) {
        if (mounted) setState(() => _tokens = t);
      });
    }
  }

  void _onFeatureTap(_AiFeature feature, AppLocalizations l) {
    if (_tokens < feature.tokenCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.aiStudioInsufficientTokens(feature.tokenCost)),
          backgroundColor: Colors.white,
          action: SnackBarAction(label: 'OK', textColor: Colors.black, onPressed: () {}),
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
        content: Text(
          l.aiStudioOpening(feature.title),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding + 40, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TokenPill(tokens: _tokens, l: l),
                  const SizedBox(height: 32),
                  Text(
                    l.aiStudioTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -2.0,
                      height: 1.0,
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
    );
  }
}

// ─── Token pill ───────────────────────────────────────────────────────────────
class _TokenPill extends StatelessWidget {
  final int tokens;
  final AppLocalizations l;
  const _TokenPill({required this.tokens, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B), // Zinc 900
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _kBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            l.aiStudioTokensRemaining(tokens),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
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

class _FeatureCardState extends State<_FeatureCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final SpringSimulation _springSim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, lowerBound: 0.96, upperBound: 1.0, value: 1.0);
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
    _ctrl.animateTo(0.96, duration: const Duration(milliseconds: 100), curve: Curves.easeOut);
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
        builder: (context, child) => Transform.scale(
          scale: _ctrl.value,
          child: child,
        ),
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
                        border: Border.all(
                          color: _kBorderColor,
                        ),
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
        Icon(Icons.bolt_rounded, color: Colors.white.withOpacity(0.5), size: 14),
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
