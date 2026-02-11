import 'package:flutter/material.dart';

class AIAnalysisSection extends StatelessWidget {
  final String? analysisText;
  final bool isAnalyzing;
  final VoidCallback onAnalyzeTap;

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
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.cyanAccent),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          ),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
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
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.psychology, color: Colors.white),
          label: Text(
            isAnalyzing ? "STO PENSANDO..." : "RICHIEDI ANALISI AI",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }
}
