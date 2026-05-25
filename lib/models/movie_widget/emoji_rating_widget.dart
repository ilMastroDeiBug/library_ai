import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/save_rating_use_case.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';

class EmojiRatingWidget extends StatefulWidget {
  final dynamic media;

  const EmojiRatingWidget({super.key, required this.media});

  @override
  State<EmojiRatingWidget> createState() => _EmojiRatingWidgetState();
}

class _EmojiRatingWidgetState extends State<EmojiRatingWidget>
    with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

  late AnimationController _successController;
  late Animation<double> _successScale;

  // Emojis sostituiti con testi visivi per evitare rendering inconsistente
  final List<String> _emojis = ["🤢", "🥱", "😐", "🙂", "🤩"];

  List<String> _getLabels(BuildContext context) {
    return [
      AppLocalizations.of(context)!.ratingTerrible,
      AppLocalizations.of(context)!.ratingBoring,
      AppLocalizations.of(context)!.ratingOk,
      AppLocalizations.of(context)!.ratingGood,
      AppLocalizations.of(context)!.ratingMasterpiece,
    ];
  }

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) return;

    // Guard offline — blocca senza crash
    if (!OfflineActionGuard.checkAndShow(context)) return;

    setState(() => _isSubmitting = true);

    final user = sl<AuthRepository>().currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    try {
      final isTv = widget.media is TvSeries;
      final mediaId = widget.media.id;

      await sl<SaveRatingUseCase>().call(
        userId: user.id,
        mediaId: mediaId,
        mediaType: isTv ? 'tv' : 'movie',
        rating: _selectedRating,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _hasSubmitted = true;
        });
        _successController.forward();

        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: const Color(0xFF1A0A00),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            top: 10,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            // Nero profondo quasi puro
            color: const Color(0xFF080809),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 8, bottom: 28),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              if (_hasSubmitted) ...[
                // Stato SUCCESS
                ScaleTransition(
                  scale: _successScale,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C00).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFFF8C00).withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFFFF8C00),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context)!.ratingSaved,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.ratingThanks,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                // Titolo
                Text(
                  AppLocalizations.of(context)!.ratingTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.ratingDescription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 32),

                // Griglia emoji
                Row(
                  children: List.generate(5, (index) {
                    final ratingValue = index + 1;
                    final isSelected = _selectedRating == ratingValue;

                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = ratingValue),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 2,
                          ),
                          decoration: BoxDecoration(
                            // Sfondo: nero pece base, arancio quando selezionato
                            color: isSelected
                                ? const Color(0xFFFF8C00).withOpacity(0.1)
                                : const Color(0xFF111113),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF8C00).withOpacity(0.5)
                                  : Colors.white.withOpacity(0.06),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.2 : 1.0,
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOutBack,
                                child: Text(
                                  _emojis[index],
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getLabels(context)[index],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected
                                      ? const Color(0xFFFF8C00)
                                      : Colors.white.withOpacity(0.3),
                                  fontSize: 9,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: AnimatedOpacity(
                    opacity: _selectedRating > 0 ? 1.0 : 0.35,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: _selectedRating > 0 && !_isSubmitting
                          ? _submitRating
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _selectedRating > 0
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8C00),
                                    Color(0xFFE06500),
                                  ],
                                )
                              : null,
                          color: _selectedRating == 0
                              ? const Color(0xFF1A1A1C)
                              : null,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: _selectedRating > 0
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF8C00,
                                    ).withOpacity(0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  AppLocalizations.of(context)!.ratingSubmit,
                                  style: TextStyle(
                                    color: _selectedRating > 0
                                        ? Colors.black
                                        : Colors.white.withOpacity(0.3),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
