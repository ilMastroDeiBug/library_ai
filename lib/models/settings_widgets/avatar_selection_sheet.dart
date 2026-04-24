import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';

class AvatarSelectionSheet extends StatefulWidget {
  final String userId;
  final String? currentAvatarUrl;
  final VoidCallback onAvatarUpdated;

  const AvatarSelectionSheet({
    super.key,
    required this.userId,
    this.currentAvatarUrl,
    required this.onAvatarUpdated,
  });

  @override
  State<AvatarSelectionSheet> createState() => _AvatarSelectionSheetState();
}

class _AvatarSelectionSheetState extends State<AvatarSelectionSheet> {
  bool _isSaving = false;
  String? _selectedUrl;

  // Seeds scelti con cura che generano i Bottts più belli
  final List<String> _avatarSeeds = [
    'Felix',
    'Jude',
    'Aneka',
    'Milo',
    'Luna',
    'Leo',
    'Avery',
    'Eden',
    'Riley',
    'Cleo',
    'Oliver',
    'Jasper',
    'Harper',
    'Quinn',
    'Rowan',
  ];

  String _generateUrl(String seed) {
    // API v9 sicura, stile Micah (Premium UI), dimensione fissa 150px
    return 'https://api.dicebear.com/9.x/micah/png?seed=$seed&backgroundColor=transparent&size=150';
  }

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.currentAvatarUrl;
  }

  Future<void> _saveAvatar() async {
    if (_selectedUrl == null || _selectedUrl == widget.currentAvatarUrl) {
      Navigator.pop(context); // Se non cambia nulla, chiudi e basta
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Chiama il database
      await sl<UpdateAvatarUseCase>().call(widget.userId, _selectedUrl!);

      // 2. Avvisa la UI di aggiornarsi IN TEMPO REALE
      widget.onAvatarUpdated();

      // 3. Chiudi il popup
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore salvataggio: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: const Color(0xFF161618).withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.8),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "SCEGLI IL TUO AVATAR",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),

              // GRIGLIA AVATAR
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: _avatarSeeds.length,
                  itemBuilder: (context, index) {
                    final url = _generateUrl(_avatarSeeds[index]);
                    final isSelected = _selectedUrl == url;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedUrl = url),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orangeAccent.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.orangeAccent
                                : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.orangeAccent.withOpacity(0.4),
                                    blurRadius: 15,
                                  ),
                                ]
                              : [],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            url,
                            // Gestione errori per non far crashare l'app se manca la rete
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                                  Icons.wifi_off_rounded,
                                  color: Colors.white38,
                                ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.orangeAccent,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // TASTO SALVA
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 10,
                      shadowColor: Colors.orangeAccent.withOpacity(0.5),
                    ),
                    onPressed: _isSaving ? null : _saveAvatar,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "SALVA AVATAR",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.5,
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
