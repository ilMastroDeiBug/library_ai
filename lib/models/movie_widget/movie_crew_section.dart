import 'package:flutter/material.dart';
import 'package:library_ai/models/movie_widget/crew_model.dart';
import 'package:library_ai/services/utility_services/tmdb_service.dart';
import 'package:library_ai/injection_container.dart';

class MovieCrewSection extends StatefulWidget {
  final int id;
  final bool isTvSeries;

  const MovieCrewSection({
    super.key,
    required this.id,
    required this.isTvSeries,
  });

  @override
  State<MovieCrewSection> createState() => _MovieCrewSectionState();
}

class _MovieCrewSectionState extends State<MovieCrewSection> {
  late Future<List<CrewMember>> _crewFuture;

  // Mappa di traduzione per i dipartimenti e l'ordine di visualizzazione
  static const Map<String, String> _departmentTranslations = {
    'Directing': 'REGIA',
    'Writing': 'SCENEGGIATURA',
    'Production': 'PRODUZIONE',
    'Sound': 'MUSICA E SUONO',
    'Art': 'SCENOGRAFIA',
  };

  // Quali dipartimenti mostrare e in che ordine
  static const List<String> _departmentOrder = [
    'Directing',
    'Writing',
    'Production',
    'Sound',
    'Art',
  ];

  @override
  void initState() {
    super.initState();
    _crewFuture = sl<TmdbService>().fetchCrew(
      widget.id,
      isTv: widget.isTvSeries,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CrewMember>>(
      future: _crewFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white24,
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final crew = snapshot.data!;

        // Raggruppa per dipartimento
        final Map<String, List<CrewMember>> groupedCrew = {};
        for (var member in crew) {
          if (!groupedCrew.containsKey(member.department)) {
            groupedCrew[member.department] = [];
          }
          // Evita duplicati dello stesso nome e job
          final exists = groupedCrew[member.department]!.any(
            (m) => m.name == member.name && m.job == member.job,
          );
          if (!exists) {
            groupedCrew[member.department]!.add(member);
          }
        }

        List<Widget> departmentWidgets = [];
        for (String depKey in _departmentOrder) {
          if (groupedCrew.containsKey(depKey) &&
              groupedCrew[depKey]!.isNotEmpty) {
            departmentWidgets.add(
              _DepartmentBlock(
                title: _departmentTranslations[depKey] ?? depKey.toUpperCase(),
                members: groupedCrew[depKey]!,
              ),
            );
          }
        }

        if (departmentWidgets.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                'Troupe',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            ...departmentWidgets,
          ],
        );
      },
    );
  }
}

class _DepartmentBlock extends StatefulWidget {
  final String title;
  final List<CrewMember> members;

  const _DepartmentBlock({required this.title, required this.members});

  @override
  State<_DepartmentBlock> createState() => _DepartmentBlockState();
}

class _DepartmentBlockState extends State<_DepartmentBlock> {
  bool _isExpanded = false;
  static const int _initialCount = 3;

  @override
  Widget build(BuildContext context) {
    final bool showButton = widget.members.length > _initialCount;
    final List<CrewMember> displayedMembers = _isExpanded
        ? widget.members
        : widget.members.take(_initialCount).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo del dipartimento
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.only(bottom: 16),
          ),

          // Lista membri
          ...displayedMembers.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      m.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.favorite_border_rounded,
                    size: 14,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 4,
                    child: Text(
                      _translateJob(m.job),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottone Mostra tutti
          if (showButton && !_isExpanded)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: InkWell(
                onTap: () => setState(() => _isExpanded = true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Text(
                    'Mostra tutti (${widget.members.length})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _translateJob(String job) {
    switch (job) {
      case 'Director':
        return 'Regista';
      case 'Executive Producer':
        return 'Produttore Esecutivo';
      case 'Producer':
        return 'Produttore';
      case 'Co-Executive Producer':
        return 'Co-Produttore Esecutivo';
      case 'Writer':
        return 'Sceneggiatore';
      case 'Screenplay':
        return 'Sceneggiatura';
      case 'Original Music Composer':
        return 'Compositore';
      case 'Music Supervisor':
        return 'Supervisore Musicale';
      case 'Production Design':
        return 'Scenografia';
      case 'Art Direction':
        return 'Direzione Artistica';
      default:
        return job;
    }
  }
}
