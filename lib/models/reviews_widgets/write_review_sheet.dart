import 'dart:ui';
import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/review_use_cases.dart';
import '../../injection_container.dart';
import 'package:library_ai/l10n/app_localizations.dart';
import 'package:library_ai/services/utility_services/offline_action_guard.dart';

class WriteReviewSheet extends StatefulWidget {
  final int mediaId;
  final bool isTvSeries;

  const WriteReviewSheet({
    super.key,
    required this.mediaId,
    required this.isTvSeries,
  });

  @override
  State<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<WriteReviewSheet> {
  final TextEditingController _controller = TextEditingController();
  int _rating = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_rating == 0 || _controller.text.trim().isEmpty) return;

    // Guard offline
    if (!OfflineActionGuard.checkAndShow(context)) return;

    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await sl<SubmitReviewUseCase>().call(
        widget.mediaId,
        widget.isTvSeries ? 'tv' : 'movie',
        user.id,
        _controller.text.trim(),
        _rating.toDouble(),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _rating > 0 && _controller.text.trim().isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 10,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF080809),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.07), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle centrato
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Titolo
              Text(
                AppLocalizations.of(context)!.writeReviewTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),

              const SizedBox(height: 24),

              // Label stelle
              Text(
                'Valutazione',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 10),

              // Stelle animate
              Row(
                children: List.generate(5, (index) {
                  final starValue = index + 1;
                  final isActive = starValue <= _rating;

                  return GestureDetector(
                    onTap: () => setState(() => _rating = starValue),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: AnimatedScale(
                        scale: isActive ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutBack,
                        child: Icon(
                          isActive
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: isActive
                              ? const Color(0xFFFF8C00)
                              : Colors.white.withOpacity(0.2),
                          size: 32,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),

              // Label testo
              Text(
                'La tua recensione',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.35),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),

              // TextField frosted
              TextField(
                controller: _controller,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
                cursorColor: const Color(0xFFFF8C00),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.writeReviewHint,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.2),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF111113),
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.07),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.07),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFFFF8C00).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: AnimatedOpacity(
                  opacity: canSubmit ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 200),
                  child: GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: canSubmit
                            ? const LinearGradient(
                                colors: [Color(0xFFFF8C00), Color(0xFFE06500)],
                              )
                            : null,
                        color: canSubmit ? null : const Color(0xFF1A1A1C),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: canSubmit
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF8C00,
                                  ).withOpacity(0.2),
                                  blurRadius: 18,
                                  offset: const Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                AppLocalizations.of(
                                  context,
                                )!.writeReviewPublish,
                                style: TextStyle(
                                  color: canSubmit
                                      ? Colors.black
                                      : Colors.white.withOpacity(0.3),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  letterSpacing: 0.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
