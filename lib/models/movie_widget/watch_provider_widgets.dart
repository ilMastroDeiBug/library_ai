// lib/models/movie_widget/watch_providers_widget.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'watch_provider_model.dart';

class WatchProvidersWidget extends StatefulWidget {
  final int mediaId;
  final bool isTvSeries;

  const WatchProvidersWidget({
    super.key,
    required this.mediaId,
    required this.isTvSeries,
  });

  @override
  State<WatchProvidersWidget> createState() => _WatchProvidersWidgetState();
}

class _WatchProvidersWidgetState extends State<WatchProvidersWidget> {
  late Future<WatchProvidersResult?> _providersFuture;

  @override
  void initState() {
    super.initState();
    _providersFuture = _fetchProviders();
  }

  Future<WatchProvidersResult?> _fetchProviders() async {
    if (widget.isTvSeries) {
      return await sl<GetTvSeriesWatchProvidersUseCase>().call(widget.mediaId);
    } else {
      return await sl<GetMovieWatchProvidersUseCase>().call(widget.mediaId);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossibile aprire il link: $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WatchProvidersResult?>(
      future: _providersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data;
        // Se non ci sono dati per l'Italia, il widget scompare
        if (data == null ||
            (data.flatrate.isEmpty && data.buy.isEmpty && data.rent.isEmpty)) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "GUARDA ORA SU",
              style: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),

            // Priorità: Mostriamo prima gli abbonamenti (Netflix, Prime), poi il noleggio
            if (data.flatrate.isNotEmpty) ...[
              _buildProviderRow("In Abbonamento", data.flatrate, data.link),
              const SizedBox(height: 15),
            ],

            if (data.rent.isNotEmpty && data.flatrate.isEmpty) ...[
              _buildProviderRow("A Noleggio", data.rent, data.link),
              const SizedBox(height: 15),
            ],

            // Bottone diretto TMDB per maggiori opzioni
            if (data.link != null)
              TextButton.icon(
                onPressed: () => _launchUrl(data.link!),
                icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.orangeAccent,
                ),
                label: const Text(
                  "Tutte le opzioni di acquisto",
                  style: TextStyle(color: Colors.orangeAccent),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
              ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _buildProviderRow(
    String label,
    List<WatchProviderModel> providers,
    String? link,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: providers
              .map(
                (p) => GestureDetector(
                  onTap: () {
                    // Per ora apriamo la pagina riepilogativa TMDB per l'Italia
                    if (link != null) _launchUrl(link);
                  },
                  child: Tooltip(
                    message: p.providerName,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        p.fullLogoUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
