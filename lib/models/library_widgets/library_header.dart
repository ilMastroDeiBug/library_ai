import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../pages/settings_page.dart'; // Assumendo che esista
import '../app_mode.dart';
import 'library_stat_card.dart';

class LibraryHeader extends StatelessWidget {
  final AppMode mode;
  final User? user;

  const LibraryHeader({super.key, required this.mode, required this.user});

  @override
  Widget build(BuildContext context) {
    final isBooks = mode == AppMode.books;

    return Stack(
      children: [
        // Sfondo con Gradiente
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A1F2C), Color(0xFF0F0F10)],
            ),
          ),
        ),
        // Elemento decorativo sfocato
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purpleAccent.withOpacity(0.05),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        // Contenuto SafeArea
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Profilo Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _buildProfileAvatar(context),
                    const SizedBox(width: 16),
                    _buildProfileText(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Search Bar
              _buildSearchBar(isBooks),
              const SizedBox(height: 30),
              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    LibraryStatCard(
                      label: "IN CODA",
                      status: "toread",
                      icon: Icons.hourglass_empty_rounded,
                      accentColor: Colors.orangeAccent,
                    ),
                    const SizedBox(width: 16),
                    LibraryStatCard(
                      label: isBooks ? "COMPLETATI" : "VISTI",
                      status: "read",
                      icon: Icons.check_circle_outline_rounded,
                      accentColor: Colors.cyanAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsPage()),
      ),
      child: Hero(
        tag: 'profile_pic',
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[900],
            backgroundImage: user?.photoURL != null
                ? NetworkImage(user!.photoURL!)
                : null,
            child: user?.photoURL == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ARCHIVIO DI',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          user?.displayName?.toUpperCase() ?? "ARCHITECT",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isBooks) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              const SizedBox(width: 15),
              Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
              const SizedBox(width: 15),
              Text(
                isBooks ? "Cerca nel database..." : "Cerca nella watchlist...",
                style: TextStyle(color: Colors.white.withOpacity(0.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
