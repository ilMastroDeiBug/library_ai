# Run from repository root. Creates .bak backups before overwriting.
$files = @{}

# 1) lib/Pages/library_page.dart
$files['lib/Pages/library_page.dart'] = @'
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../models/app_mode.dart';
// Import Widget Modulari
import '../models/library_widgets/library_header.dart';
import '../models/library_widgets/library_grid.dart';

class LibraryPage extends StatefulWidget {
  final AppMode mode;
  final VoidCallback onOpenDrawer;

  const LibraryPage({
    super.key,
    required this.mode,
    required this.onOpenDrawer,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  Widget build(BuildContext context) {
    final isBooks = widget.mode == AppMode.books;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F10),
      floatingActionButton: isBooks ? _buildFab(context) : null,
      body: StreamBuilder(
        stream: sl<AuthRepository>().userStream,
        builder: (context, snapshot) {
          final user = snapshot.data;

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    expandedHeight: 350,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF0F0F10),
                    leading: IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: widget.onOpenDrawer,
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: LibraryHeader(mode: widget.mode, user: user),
                    ),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F0F10),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        child: TabBar(
                          overlayColor: WidgetStateProperty.all(
                            Colors.transparent,
                          ),
                          indicatorColor: Colors.white,
                          indicatorWeight: 2,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white38,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                          tabs: [
                            const Tab(text: "DA LEGGERE"),
                            Tab(text: isBooks ? "COMPLETATI" : "VISTI"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  LibraryGrid(mode: widget.mode, status: "toread"),
                  LibraryGrid(mode: widget.mode, status: "read"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'fab_library',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Usa il tasto + nella Home per aggiungere libri!"),
            ),
          );
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
'@

# 2) lib/Pages/side_menu.dart
$files['lib/Pages/side_menu.dart'] = @'
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../../models/app_mode.dart';
import '../../pages/settings_page.dart';
// Import Widget Modulari
import '../models/side_menu_widgets/side_menu_header.dart';
import '../models/side_menu_widgets/side_menu_item.dart';
import '../models/side_menu_widgets/logout_button.dart';

class SideMenu extends StatelessWidget {
  final AppMode currentMode;
  final bool isSocialActive;
  final Function(AppMode) onModeChanged;
  final VoidCallback onSocialTap;

  // IL COLORE DEL BRAND
  static const Color _brandColor = Colors.orangeAccent;

  const SideMenu({
    super.key,
    required this.currentMode,
    required this.isSocialActive,
    required this.onModeChanged,
    required this.onSocialTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Drawer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F)],
              ),
            ),
            child: Column(
              children: [
                // 1. HEADER
                SideMenuHeader(user: user),

                const SizedBox(height: 20),

                // 2. LISTA MENU
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      _buildSectionLabel("ESPLORA"),

                      SideMenuItem(
                        icon: Icons.auto_stories_rounded,
                        text: "Libreria Libri",
                        isSelected: !isSocialActive && currentMode == AppMode.books,
                        activeColor: _brandColor, // Uniformato
                        onTap: () {
                          onModeChanged(AppMode.books);
                          Navigator.pop(context);
                        },
                      ),

                      SideMenuItem(
                        icon: Icons.movie_filter_rounded,
                        text: "Cinema & TV",
                        isSelected:
                            !isSocialActive && currentMode == AppMode.movies,
                        activeColor: _brandColor, // Uniformato
                        onTap: () {
                          onModeChanged(AppMode.movies);
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 25),
                      _buildSectionLabel("COMMUNITY"),

                      SideMenuItem(
                        icon: Icons.public,
                        text: "Social Network",
                        isSelected: isSocialActive,
                        activeColor: _brandColor, // Uniformato
                        onTap: () {
                          onSocialTap();
                          Navigator.pop(context);
                        },
                      ),

                      const SizedBox(height: 25),
                      const Divider(color: Colors.white10, height: 1),
                      const SizedBox(height: 25),

                      _buildSectionLabel("ALTRO"),

                      SideMenuItem(
                        icon: Icons.settings_rounded,
                        text: "Impostazioni",
                        isSelected: false,
                        activeColor: Colors.white,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // 3. FOOTER
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                  child: LogoutButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Label uniformata al colore del brand
  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          color: _brandColor.withOpacity(0.6), // Giallognolo trasparente
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
'@

# 3) lib/Pages/book_detail_page.dart (full overwrite with the refactor for auth fallback)
$files['lib/Pages/book_detail_page.dart'] = @'
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import '../../domain/entities/book.dart';
import '../../services/utility_services/ai_service.dart';
import '/models/book_widgets/book_stats_bar.dart';
import '../models/ai_analysis_section.dart';

class BookDetailPage extends StatefulWidget {
  final Book book;
  const BookDetailPage({super.key, required this.book});

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  bool _isAnalyzing = false;
  static const Color _brandColor = Colors.orangeAccent;

  Future<void> _handleStatusToggle(Book liveBook, String currentStatus) async {
    try {
      final newStatus = await sl<ToggleBookStatusUseCase>().call(
        liveBook.id,
        currentStatus,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'read'
                  ? "Salvato in libreria."
                  : "Spostato in 'Da Leggere'.",
            ),
            backgroundColor: newStatus == 'read' ? Colors.green : _brandColor,
          ),
        );
      }
    } catch (e) {
      // Fallback per libri non ancora nel DB
      try {
        final authRepo = sl<AuthRepository>();
        final userStream = await authRepo.userStream.first;

        if (userStream != null) {
          final bookToSave = Book(
            id: liveBook.id,
            title: liveBook.title,
            author: liveBook.author,
            description: liveBook.description,
            thumbnailUrl: liveBook.thumbnailUrl,
            pageCount: liveBook.pageCount,
            rating: liveBook.rating,
            ratingsCount: liveBook.ratingsCount,
            status: currentStatus == 'read' ? 'toread' : 'read',
          );
          await sl<AddBookUseCase>().call(bookToSave, userStream.id);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Libro aggiunto al Database."),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (innerE) {
        print("Errore critico salvataggio: $innerE");
      }
    }
  }

  Future<void> _handleAnalysis(Book liveBook) async {
    setState(() => _isAnalyzing = true);
    try {
      final aiService = AIService();

      final analysis = await aiService.analyzeMedia(
        title: liveBook.title,
        type: 'book',
        userProfile: "16 anni, Developer, MMA",
        creator: liveBook.author,
      );

      // Salva l'analisi nel DB usando lo Use Case
      await sl<SaveBookAnalysisUseCase>().call(liveBook.id, analysis);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Errore analisi: $e")));
      }
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .doc(widget.book.id)
          .snapshots(),
      builder: (context, snapshot) {
        Book liveBook = widget.book;
        String currentStatus = 'toread';
        String? storedAnalysis;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          liveBook = Book.fromFirestore(data, widget.book.id);
          currentStatus = liveBook.status;
          storedAnalysis = liveBook.aiAnalysis;
        }
        final isRead = currentStatus == 'read';

        return Scaffold(
          backgroundColor: const Color(0xFF121212),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 400,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          liveBook.thumbnailUrl,
                          fit: BoxFit.cover,
                          color: Colors.black.withOpacity(0.6),
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey[900]),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xFF121212)],
                              stops: [0.3, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Hero(
                          tag: liveBook.id,
                          child: Container(
                            height: 240,
                            width: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: _brandColor.withOpacity(0.2),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                              image: DecorationImage(
                                image: NetworkImage(liveBook.thumbnailUrl),
                                fit: BoxFit.cover,
                                onError: (_, __) {},
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text(
                        liveBook.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        liveBook.author.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _brandColor,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 30),
                      BookStatsBar(book: liveBook),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isRead
                                ? const Color(0xFF1B5E20)
                                : _brandColor,
                            foregroundColor: isRead
                                ? Colors.white
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 5,
                            shadowColor: _brandColor.withOpacity(0.3),
                          ),
                          onPressed: () =>
                              _handleStatusToggle(liveBook, currentStatus),
                          icon: Icon(
                            isRead ? Icons.undo : Icons.check_circle_outline,
                          ),
                          label: Text(
                            isRead ? "COMPLETATO" : "SEGNA COME LETTO",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      AIAnalysisSection(
                        analysisText: storedAnalysis,
                        isAnalyzing: _isAnalyzing,
                        onAnalyzeTap: () => _handleAnalysis(liveBook),
                      ),
                      const SizedBox(height: 40),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "SINOSSI",
                          style: TextStyle(
                            color: Colors.white30,
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        liveBook.description.isNotEmpty
                            ? liveBook.description
                            : "Nessuna descrizione disponibile.",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
'@

# 4) lib/models/user_books_section.dart
$files['lib/models/user_books_section.dart'] = @'
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import 'package:library_ai/domain/entities/book.dart';
import 'package:library_ai/models/book_widgets/book_card.dart';

class UserBooksSection extends StatelessWidget {
  final String title;
  final String status;

  const UserBooksSection({
    super.key,
    required this.title,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) return const SizedBox();

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
              height: 240,
              child: StreamBuilder<List<Book>>(
                stream: sl<GetUserBooksUseCase>().call(user.id, status),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildEmptyState();
                  }
                  final books = snapshot.data!;
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 20),
                    itemCount: books.length,
                    itemBuilder: (context, index) => BookCard(book: books[index]),
                  );
                },
              ),
            ),
          ],
        );
      },
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
      child: const Center(
        child: Text(
          "Nessun libro per ora",
          style: TextStyle(color: Colors.white30),
        ),
      ),
    );
  }
}
'@

# 5) lib/models/library_widgets/library_stat_card.dart
$files['lib/models/library_widgets/library_stat_card.dart'] = @'
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
        // Se l'utente non è loggato, mostriamo 0
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
'@

# 6) lib/models/library_widgets/library_grid.dart
$files['lib/models/library_widgets/library_grid.dart'] = @'
import 'package:flutter/material.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/book_use_cases.dart';
import 'package:library_ai/domain/repositories/auth_repository.dart';
import '../../domain/entities/book.dart';
import '/models/book_widgets/book_card.dart';
import '../app_mode.dart';
import 'delete_book_dialog.dart';

class LibraryGrid extends StatelessWidget {
  final AppMode mode;
  final String status;

  const LibraryGrid({super.key, required this.mode, required this.status});

  Future<void> _handleDelete(
    BuildContext context,
    String bookId,
    String title,
  ) async {
    showDialog(
      context: context,
      builder: (ctx) => DeleteBookDialog(
        bookTitle: title,
        onConfirm: () async {
          try {
            // USE CASE: DELETE
            await sl<DeleteBookUseCase>().call(bookId);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Dato rimosso dal database."),
                  backgroundColor: Colors.redAccent.withOpacity(0.8),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBooks = mode == AppMode.books;
    if (!isBooks) return _buildMoviesPlaceholder();

    return StreamBuilder(
      stream: sl<AuthRepository>().userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) return _buildEmptyState();

        return Container(
          color: const Color(0xFF0F0F10),
          child: StreamBuilder<List<Book>>(
            stream: sl<GetUserBooksUseCase>().call(user.id, status),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState();
              }

              final books = snapshot.data!;

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 100),
                itemCount: books.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 25,
                ),
                itemBuilder: (context, index) {
                  final book = books[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onLongPress: () => _handleDelete(context, book.id, book.title),
                    child: BookCard(book: book),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == 'toread'
                ? Icons.bookmark_add_outlined
                : Icons.done_all_rounded,
            size: 60,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 15),
          Text(
            status == 'toread'
                ? "Database vuoto.\nAggiungi nuovi input."
                : "Nessun task completato.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.3), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMoviesPlaceholder() {
    return const Center(
      child: Text(
        "Sezione Cinema in arrivo...",
        style: TextStyle(color: Colors.white30),
      ),
    );
  }
}
'@

# 7) lib/models/book_widgets/add_book_sheet.dart
$files['lib/models/book_widgets/add_book_sheet.dart'] = @'
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
'@

# 8) lib/models/library_widgets/library_header.dart
$files['lib/models/library_widgets/library_header.dart'] = @'
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import '../../pages/settings_page.dart';
import '../app_mode.dart';
import 'library_stat_card.dart';

class LibraryHeader extends StatelessWidget {
  final AppMode mode;
  final AppUser? user;

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
            child: user != null
                ? Text(
                    (user!.displayName?.isNotEmpty ?? false)
                        ? user!.displayName![0].toUpperCase()
                        : (user!.email.isNotEmpty ? user!.email[0].toUpperCase() : 'A'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white),
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
'@

# 9) lib/models/side_menu_widgets/side_menu_header.dart
$files['lib/models/side_menu_widgets/side_menu_header.dart'] = @'
import 'package:flutter/material.dart';
import 'package:library_ai/domain/entities/app_user.dart';
import '../../pages/settings_page.dart';

class SideMenuHeader extends StatelessWidget {
  final AppUser? user;

  const SideMenuHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Chiude il drawer
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
        child: Row(
          children: [
            // Avatar con Glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFF2C2C2C),
                child: user != null
                    ? Text(
                        (user!.displayName?.isNotEmpty ?? false)
                            ? user!.displayName![0].toUpperCase()
                            : (user!.email.isNotEmpty ? user!.email[0].toUpperCase() : 'A'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 15),
            // Testi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? "Architect",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? "user@example.com",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'@

# Write files with backups
foreach ($path in $files.Keys) {
  $full = Join-Path (Get-Location) $path
  $dir = Split-Path $full -Parent
  if (-not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  if (Test-Path $full) {
    Copy-Item $full "$full.bak" -Force
    Write-Host "Backup created: $full.bak"
  }
  $files[$path] | Set-Content -Path $full -Encoding UTF8
  Write-Host "Wrote: $path"
}

Write-Host "Done. Consider running 'flutter analyze' and formatting files."