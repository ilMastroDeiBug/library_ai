import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/entities/tv_series.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/save_rating_use_case.dart';
import 'package:library_ai/l10n/app_localizations.dart';

class EmojiRatingWidget extends StatefulWidget {
  final dynamic media;

  const EmojiRatingWidget({super.key, required this.media});

  @override
  State<EmojiRatingWidget> createState() => _EmojiRatingWidgetState();
}

class _EmojiRatingWidgetState extends State<EmojiRatingWidget> {
  int _selectedRating = 0;
  bool _isSubmitting = false;
  bool _hasSubmitted = false;

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

  Future<void> _submitRating() async {
    print('DEBUG: _submitRating chiamato con voto $_selectedRating');
    if (_selectedRating == 0) return;

    setState(() {
      _isSubmitting = true;
    });

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

        // Chiudi il bottom sheet dopo 1.5 secondi
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      print('DEBUG UI RATING ERROR: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Errore: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 25, left: 20, right: 20, bottom: 40),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E), // Grigio scuro simile al tema
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),

          if (_hasSubmitted) ...[
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.orangeAccent,
              size: 60,
            ),
            const SizedBox(height: 15),
            Text(
              AppLocalizations.of(context)!.ratingSaved,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.ratingThanks,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ] else ...[
            Text(
              AppLocalizations.of(context)!.ratingTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.ratingDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 35),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final ratingValue = index + 1;
                final isSelected = _selectedRating == ratingValue;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = ratingValue;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.orangeAccent.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isSelected
                              ? Colors.orangeAccent
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _emojis[index],
                            style: TextStyle(
                              fontSize: isSelected
                                  ? 36
                                  : 28, // Leggermente ridotto per sicurezza
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getLabels(context)[index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.orangeAccent
                                  : Colors.white54,
                              fontSize: 9, // Leggermente ridotto
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedRating > 0 && !_isSubmitting
                    ? _submitRating
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  disabledForegroundColor: Colors.white30,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: _selectedRating > 0 ? 5 : 0,
                  shadowColor: Colors.orangeAccent.withOpacity(0.5),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.ratingSubmit,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
