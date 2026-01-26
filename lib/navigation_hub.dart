import 'package:flutter/material.dart';
import 'package:library_ai/Pages/explore_page.dart';
import 'package:library_ai/Pages/library_page.dart';
import 'pages/home_page.dart';

class NavigationHub extends StatefulWidget {
  const NavigationHub({super.key});

  @override
  State<NavigationHub> createState() => _NavigationHubState();
}

class _NavigationHubState extends State<NavigationHub> {
  int _selectedIndex = 0; // Meglio partire dalla Home (indice 0)

  // Lista delle pagine
  final List<Widget> _pages = [
    const HomePage(), // 0
    const LibraryPage(), // 1
    const ExplorePage(), // 2
    const Center(
      child: Text("AI Summary Studio", style: TextStyle(color: Colors.white)),
    ), // 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sfondo generale scuro per evitare flash bianchi durante le transizioni
      backgroundColor: const Color(0xFF232526),

      body: _pages[_selectedIndex],

      bottomNavigationBar: Container(
        // Aggiungiamo un bordo superiore sottile per staccare la barra dal contenuto
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          // --- STILE DARK ---
          backgroundColor: const Color(0xFF232526), // Sfondo scuro
          elevation: 0, // Rimuoviamo l'ombra di default (usiamo il bordo sopra)
          type: BottomNavigationBarType
              .fixed, // Necessario quando hai 4+ icone per non farle "ballare"
          // --- COLORI ---
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.cyanAccent, // Icona attiva (Neon)
          unselectedItemColor: Colors.grey, // Icona inattiva (Spenta)
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),

          onTap: _onItemTapped,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home), // Icona piena quando attiva
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Libreria',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Esplora',
            ),
            // Ho aggiunto il quarto bottone per l'AI
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome_outlined),
              activeIcon: Icon(Icons.auto_awesome),
              label: 'Studio AI',
            ),
          ],
        ),
      ),
    );
  }
}
