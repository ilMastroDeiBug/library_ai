import 'package:flutter/material.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/use_cases/review_use_cases.dart';
import '../../injection_container.dart';

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
  double _rating = 0;
  bool _isLoading = false;

  void _submit() async {
    if (_rating == 0 || _controller.text.trim().isEmpty) return;

    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await sl<SubmitReviewUseCase>().call(
        widget.mediaId,
        widget.isTvSeries ? 'tv' : 'movie',
        user.id,
        _controller.text.trim(),
        _rating,
      );
      if (mounted)
        Navigator.pop(context, true); // Restituisce true se ha successo
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF161618),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "La tua Recensione",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: Colors.orangeAccent,
                  size: 36,
                ),
                onPressed: () => setState(() => _rating = index + 1.0),
              );
            }),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Cosa ne pensi?",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "Pubblica",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
