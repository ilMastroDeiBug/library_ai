import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/domain/use_cases/collection_use_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/models/login_widgets/cascading_background.dart';

class CreateCollectionPage extends StatefulWidget {
  const CreateCollectionPage({super.key});

  @override
  State<CreateCollectionPage> createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  void _createCollection() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final user = sl<AuthRepository>().currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await sl<CreateCollectionUseCase>().call(
        user.id,
        name,
        description: _descriptionController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Raccolta creata con successo!'),
            backgroundColor: Colors.white,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: ${e.toString()}'),
            backgroundColor: Colors.white,
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          const Positioned.fill(
            child: Opacity(
              opacity: 0.5,
              child: CascadingBackground(
                speed1: 140,
                speed2: 130,
                speed3: 150,
                speed4: 125,
                indexOffset: 5,
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  "Nuova Raccolta",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Dai un nome alla tua curatela.",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                  decoration: InputDecoration(
                                    hintText: "Nome (es. 'Fever Dream')",
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _descriptionController,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: "Descrizione (opzionale)",
                                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.05),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _createCollection,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                                          )
                                        : const Text(
                                            "Crea Raccolta",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }
}
