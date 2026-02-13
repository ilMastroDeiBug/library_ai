import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/entities/book.dart';

class AddBookSheet extends StatefulWidget {
  const AddBookSheet({super.key});

  @override
  State<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<AddBookSheet> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  bool _isLoading = false;

  Future<void> _save() async {
    if (_titleController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final authRepo = sl<AuthRepository>();
      final userStream = await authRepo.userStream.first;
      
      if (userStream == null) return;

      final newBook = Book(
        id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        author: _authorController.text.isNotEmpty
            ? _authorController.text
            : 'Sconosciuto',
        description: 'Aggiunto manualmente',
        status: 'toread',
      );

      // USE CASE
      await sl<AddBookUseCase>().call(newBook, userStream.id);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Errore add book: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nuova Avventura (Manuale)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          _buildInput(_titleController, "Titolo del libro"),
          const SizedBox(height: 15),
          _buildInput(_authorController, "Autore"),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isLoading ? null : _save,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "Salva nella Libreria",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
      ),
    );
  }
}
