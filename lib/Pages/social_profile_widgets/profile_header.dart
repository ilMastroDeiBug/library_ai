import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import 'package:library_ai/domain/entities/social_stats.dart';
import 'package:library_ai/domain/use_cases/user_cases.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/models/settings_widgets/avatar_selection_sheet.dart';
import 'package:library_ai/models/settings_widgets/edit_profile_dialogs.dart';

/// Header profilo stile Instagram: nome + badge in alto, foto + contatori,
/// bio, bottoni Modifica / Condividi. Tutto cablato agli use cases reali.
class ProfileHeader extends StatefulWidget {
  final AppUser user;
  final SocialStats stats;
  /// Callback invocato dopo ogni aggiornamento (nome, bio, avatar)
  /// per rifare il fetch e aggiornare l'intera pagina.
  final VoidCallback? onRefresh;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.stats,
    this.onRefresh,
  });

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
  // Stato locale ottimistico per avatar / nome / bio
  late String? _photoUrl;
  late String _displayName;
  late String? _bio;

  @override
  void initState() {
    super.initState();
    _photoUrl    = widget.user.photoUrl;
    _displayName = widget.user.displayName ?? 'Cinefilo';
    _bio         = widget.user.bio;
  }

  @override
  void didUpdateWidget(covariant ProfileHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _photoUrl    = widget.user.photoUrl;
      _displayName = widget.user.displayName ?? 'Cinefilo';
      _bio         = widget.user.bio;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _badgeTitle(int count) {
    if (count < 10)  return '✦ Esordiente';
    if (count < 30)  return '✦ Appassionato';
    if (count < 75)  return '✦ Cinefilo Seriale';
    if (count < 150) return '✦ Critico in Erba';
    if (count < 300) return '✦ Cinefilo Accanito';
    if (count < 500) return '✦ Analista di Gusto';
    return '✦ Maestro del Vault';
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  void _openAvatarSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AvatarSelectionSheet(
        userId: widget.user.id,
        currentAvatarUrl: _photoUrl,
        onAvatarUpdated: () {
          widget.onRefresh?.call();
        },
      ),
    );
  }

  void _editBio() {
    EditProfileDialogs.showBioDialog(
      context,
      _bio ?? '',
      (newBio) async {
        await sl<UpdateBioUseCase>().call(widget.user.id, newBio);
        if (mounted) setState(() => _bio = newBio.isEmpty ? null : newBio);
        widget.onRefresh?.call();
      },
    );
  }

  void _shareProfile() {
    final link = 'cineshare://profile/${widget.user.id}';
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Link profilo copiato!'),
        backgroundColor: Colors.white10,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. NOME + BADGE ────────────────────────────────────────────────
          Text(
            _displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _badgeTitle(widget.stats.vaultCount),
            style: const TextStyle(
              color: Color(0xFFFF8C3A),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 18),

          // ── 2. AVATAR + CONTATORI (fila orizzontale, stile Instagram) ──────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar tappabile
              GestureDetector(
                onTap: _openAvatarSheet,
                child: Stack(
                  children: [
                    _AvatarRing(photoUrl: _photoUrl, size: 82),
                    // Badge fotocamera
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8C3A),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
                        ),
                        child: const Icon(Icons.photo_camera_rounded, size: 13, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 28),

              // Contatori
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatCol(value: widget.stats.vaultCount,      label: 'Nel Vault'),
                    _StatCol(value: widget.stats.followersCount,  label: 'Follower'),
                    _StatCol(value: widget.stats.followingCount,  label: 'Seguiti'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 3. BIO (tappabile per modificare) ─────────────────────────────
          GestureDetector(
            onTap: _editBio,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _bio != null && _bio!.isNotEmpty
                  ? Text(
                      _bio!,
                      key: const ValueKey('bio'),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    )
                  : Text(
                      'Aggiungi una bio...',
                      key: const ValueKey('no_bio'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // ── 4. BOTTONI MODIFICA / CONDIVIDI ──────────────────────────────
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: 'Modifica profilo',
                  onTap: () => _showEditSheet(context),
                ),
              ),
              const SizedBox(width: 10),
              _IconActionButton(
                icon: Icons.ios_share_rounded,
                onTap: _shareProfile,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sheet modifica ─────────────────────────────────────────────────────────

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditSheet(
        displayName: _displayName,
        bio: _bio ?? '',
        userId: widget.user.id,
        onNameSaved: (n) {
          if (mounted) setState(() => _displayName = n);
          widget.onRefresh?.call();
        },
        onBioSaved: (b) {
          if (mounted) setState(() => _bio = b.isEmpty ? null : b);
          widget.onRefresh?.call();
        },
      ),
    );
  }
}

// ─── Avatar con ring colorato ─────────────────────────────────────────────────

class _AvatarRing extends StatelessWidget {
  final String? photoUrl;
  final double size;
  const _AvatarRing({this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8C3A), Color(0xFF9B6DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF8C3A).withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF0A0A0A),
        ),
        child: ClipOval(
          child: photoUrl != null && photoUrl!.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _AvatarPlaceholder(size: size - 6),
                  errorWidget: (_, __, ___) => _AvatarPlaceholder(size: size - 6),
                )
              : _AvatarPlaceholder(size: size - 6),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  final double size;
  const _AvatarPlaceholder({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: Icon(Icons.person_rounded, color: Colors.white24, size: size * 0.45),
    );
  }
}

// ─── Colonna statistica ───────────────────────────────────────────────────────

class _StatCol extends StatelessWidget {
  final int value;
  final String label;
  const _StatCol({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.38),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Bottone azione testo ─────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Bottone icona ────────────────────────────────────────────────────────────

class _IconActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Bottom Sheet modifica profilo ────────────────────────────────────────────

class _EditSheet extends StatefulWidget {
  final String displayName;
  final String bio;
  final String userId;
  final void Function(String) onNameSaved;
  final void Function(String) onBioSaved;

  const _EditSheet({
    required this.displayName,
    required this.bio,
    required this.userId,
    required this.onNameSaved,
    required this.onBioSaved,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.displayName);
    _bioCtrl  = TextEditingController(text: widget.bio);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final newName = _nameCtrl.text.trim();
      final newBio  = _bioCtrl.text.trim();

      if (newName != widget.displayName && newName.isNotEmpty) {
        await sl<UpdateNameUseCase>().call(widget.userId, newName);
        widget.onNameSaved(newName);
      }
      if (newBio != widget.bio) {
        await sl<UpdateBioUseCase>().call(widget.userId, newBio);
        widget.onBioSaved(newBio);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp = MediaQuery.of(context).viewInsets.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, vp + 32),
          decoration: const BoxDecoration(
            color: Color(0xFF111111),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 38, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Modifica Profilo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),

              // Campo Nome
              _InputField(
                controller: _nameCtrl,
                label: 'Nome',
                icon: Icons.badge_outlined,
                maxLines: 1,
              ),
              const SizedBox(height: 14),

              // Campo Bio
              _InputField(
                controller: _bioCtrl,
                label: 'Biografia',
                icon: Icons.format_quote_rounded,
                maxLines: 4,
              ),
              const SizedBox(height: 28),

              // Bottone salva
              GestureDetector(
                onTap: _saving ? null : _save,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 50,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _saving
                        ? Colors.orangeAccent.withValues(alpha: 0.5)
                        : Colors.orangeAccent,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: _saving
                        ? []
                        : [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 6))],
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Salva modifiche',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
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

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;

  const _InputField({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF8C3A), width: 1.5),
        ),
      ),
    );
  }
}
