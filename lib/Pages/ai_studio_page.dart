import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/ai_use_cases.dart';

class AiStudioPage extends StatefulWidget {
  const AiStudioPage({super.key});

  @override
  State<AiStudioPage> createState() => _AiStudioPageState();
}

class _AiStudioPageState extends State<AiStudioPage> with TickerProviderStateMixin {
  late final AnimationController _bgController;
  late final Stream<int>? _tokensStream;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat(reverse: true);

    final currentUser = sl<AuthRepository>().currentUser;
    if (currentUser != null) {
      _tokensStream = sl<GetAiTokensUseCase>().call(currentUser.id);
    } else {
      _tokensStream = null;
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Zinc-950 base
      body: Stack(
        children: [
          // Ambient Animated Background (Mesh Gradient emulation)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _MeshGradientPainter(_bgController.value),
                );
              },
            ),
          ),
          
          // Noise Filter for "Performance Guardrails" DOM cost note
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.03,
                child: Image.asset(
                  'assets/images/noise.png', // Assuming app has a noise texture or just use a generic fallback
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              ),
                            ),
                            _buildTokenPill(),
                          ],
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "AI Studio",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.5,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Intelligence algorithms over your cinematic vault.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.5),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bento Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  sliver: SliverGrid.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: const [
                      _BentoCard(
                        title: "Vault Sync",
                        description: "Matchmaker per serate. Incrocia i Vault.",
                        icon: Icons.sync_rounded,
                        tokenCost: 3,
                        accentColor: Color(0xFF10B981), // Emerald
                      ),
                      _BentoCard(
                        title: "What to Watch NOW",
                        description: "Filtro Streaming Dinamico.",
                        icon: Icons.play_circle_outline_rounded,
                        tokenCost: 2,
                        accentColor: Color(0xFF3B82F6), // Blue
                      ),
                      _BentoCard(
                        title: "Mood Mapper",
                        description: "Analitica Emotiva Mensile.",
                        icon: Icons.waves_rounded,
                        tokenCost: 1,
                        accentColor: Color(0xFFF43F5E), // Rose
                      ),
                      _BentoCard(
                        title: "Hot Takes & Debates",
                        description: "Arena social con IA.",
                        icon: Icons.local_fire_department_outlined,
                        tokenCost: 1,
                        accentColor: Color(0xFFF59E0B), // Amber
                      ),
                    ],
                  ),
                ),
                
                // Full Width Card
                const SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverToBoxAdapter(
                    child: _BentoCard(
                      title: "Scene Correlation",
                      description: "Identifica l'opera da un frame e suggerisce correlati.",
                      icon: Icons.center_focus_weak_rounded,
                      tokenCost: 3,
                      accentColor: Color(0xFFA855F7), // Purple variant (can adjust)
                      isWide: true,
                    ),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenPill() {
    return StreamBuilder<int>(
      stream: _tokensStream,
      builder: (context, snapshot) {
        final tokens = snapshot.data ?? 15;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.generating_tokens_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                tokens.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace', // Monospace for numbers (Rule 6)
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BentoCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final int tokenCost;
  final Color accentColor;
  final bool isWide;

  const _BentoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.tokenCost,
    required this.accentColor,
    this.isWide = false,
  });

  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isHovered = true),
        onTapUp: (_) => setState(() => _isHovered = false),
        onTapCancel: () => setState(() => _isHovered = false),
        onTap: () {
          // Trigger Edge Function later
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, _isHovered ? -4 : 0, 0)
            ..scale(_isHovered ? 0.98 : 1.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32), // High-end radii
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  border: Border.all(
                    color: _isHovered ? widget.accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    if (_isHovered)
                      BoxShadow(
                        color: widget.accentColor.withOpacity(0.05),
                        blurRadius: 40,
                        offset: const Offset(0, 0),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Animated Icon
                        AnimatedBuilder(
                          animation: _floatAnim,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -2 * _floatAnim.value),
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(color: widget.accentColor.withOpacity(0.2)),
                            ),
                            child: Icon(widget.icon, color: widget.accentColor, size: 24),
                          ),
                        ),
                        // Token Cost Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 12, color: Colors.white54),
                              const SizedBox(width: 4),
                              Text(
                                widget.tokenCost.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.white54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!widget.isWide) const Spacer(),
                    if (widget.isWide) const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
}

class _MeshGradientPainter extends CustomPainter {
  final double animationValue;
  _MeshGradientPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF10B981).withOpacity(0.05) // Emerald tint
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
      
    final paint2 = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.05) // Blue tint
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    // Orbiting blobs
    canvas.drawCircle(
      Offset(size.width * 0.2 + (size.width * 0.1 * animationValue), size.height * 0.3),
      150,
      paint1,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8 - (size.width * 0.1 * animationValue), size.height * 0.7),
      200,
      paint2,
    );
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => 
      oldDelegate.animationValue != animationValue;
}
