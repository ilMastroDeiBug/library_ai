import 'package:flutter/material.dart';

class AIAnalysisSection extends StatelessWidget {
  final String? analysisText;
  final bool isAnalyzing;
  final VoidCallback onAnalyzeTap;

  static const Color _brandColor = Colors.orangeAccent;
  static const Color _cardColor = Color(
    0xFF1A1A1A,
  ); // Grigio scurissimo per staccare dal nero puro

  const AIAnalysisSection({
    super.key,
    this.analysisText,
    required this.isAnalyzing,
    required this.onAnalyzeTap,
  });

  @override
  Widget build(BuildContext context) {
    if (analysisText != null) {
      // MOSTRA RISULTATO
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _brandColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: _brandColor.withOpacity(0.1), blurRadius: 20),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: _brandColor),
                SizedBox(width: 10),
                Text(
                  "VERDETTO DELL'ARCHITETTO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 30),
            Text(
              analysisText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.6,
              ),
            ),
          ],
        ),
      );
    } else {
      // MOSTRA BOTTONE
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: _brandColor, // Sfondo Arancione
          boxShadow: [
            BoxShadow(
              color: _brandColor.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor:
                Colors.black, // Testo e icone neri per massimo contrasto
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: isAnalyzing ? null : onAnalyzeTap,
          icon: isAnalyzing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.psychology, color: Colors.black),
          label: Text(
            isAnalyzing ? "STO PENSANDO..." : "RICHIEDI ANALISI AI",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    }
  }
}
