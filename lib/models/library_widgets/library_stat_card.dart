import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../../domain/entities/book.dart';

class LibraryStatCard extends StatelessWidget {
  final String label;
  final String status;
  final IconData icon;
  final Color accentColor;

  const LibraryStatCard({
    super.key,
    required this.label,
    required this.status,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        // Se l'utente non Ã¨ loggato, mostriamo 0
        if (user == null) return _buildCard("0");

        return Expanded(
          child: StreamBuilder<List<Book>>(
            stream: sl<GetUserBooksUseCase>().call(user.id, status),
            builder: (context, snapshot) {
              final count = snapshot.hasData
                  ? snapshot.data!.length.toString()
                  : "0";
              return _buildCard(count);
            },
          ),
        );
      },
    );
  }

  Widget _buildCard(String count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF252525), Color(0xFF181818)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [Colors.white, Colors.white.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
