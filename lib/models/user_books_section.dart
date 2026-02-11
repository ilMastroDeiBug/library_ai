import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/utility_services/user_books_service.dart';
import '../../models/book_model.dart';
import '../../models/book_card.dart'; // Assicurati che l'import sia giusto

class UserBooksSection extends StatelessWidget {
  final String title;
  final String status;
  final UserBooksService _service = UserBooksService();

  UserBooksSection({super.key, required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.arrow_forward, color: Colors.white54, size: 16),
            ],
          ),
        ),
        SizedBox(
          height: 240, // Altezza coerente con le altre sezioni
          child: StreamBuilder<QuerySnapshot>(
            stream: _service.getUserBooksStream(status),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }
              final docs = snapshot.data!.docs;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(left: 20),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  // Creiamo il Book in modo sicuro (con fallback)
                  final book = Book(
                    id: docs[index].id,
                    title: data['title'] ?? 'Senza Titolo',
                    author: data['author'] ?? 'Sconosciuto',
                    thumbnailUrl: data['thumbnailUrl'] ?? '',
                    description: data['description'] ?? '',
                    pageCount: data['pageCount'],
                    averageRating: (data['averageRating'] as num?)?.toDouble(),
                    ratingsCount: data['ratingsCount'],
                  );
                  return BookCard(book: book);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Center(
        child: Text(
          "Nessun libro in lista.\nCerca e aggiungi il primo!",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[500]),
        ),
      ),
    );
  }
}
