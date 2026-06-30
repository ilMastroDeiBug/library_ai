// lib/models/movie_widget/watch_providers_widget.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';
import 'package:library_ai/services/utility_services/language_service.dart';
import 'watch_provider_model.dart';
import 'package:library_ai/l10n/app_localizations.dart';

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
  final LanguageService _languageService = sl<LanguageService>();

  @override
  void initState() {
    super.initState();
    _providersFuture = _fetchProviders();
    _languageService.addListener(_handleLanguageChanged);
  }

  @override
  void dispose() {
    _languageService.removeListener(_handleLanguageChanged);
    super.dispose();
  }

  void _handleLanguageChanged() {
    if (!mounted) return;
    setState(() {
      _providersFuture = _fetchProviders();
    });
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
      debugPrint("${AppLocalizations.of(context)!.providersLinkError}$url");
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
            Text(
              AppLocalizations.of(context)!.providersWatchNow,
              style: const TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 15),

            // Priorità: Mostriamo prima gli abbonamenti (Netflix, Prime), poi il noleggio
            if (data.flatrate.isNotEmpty) ...[
              _buildProviderRow(AppLocalizations.of(context)!.providersFlatrate, data.flatrate, data.link),
              const SizedBox(height: 15),
            ],

            if (data.rent.isNotEmpty && data.flatrate.isEmpty) ...[
              _buildProviderRow(AppLocalizations.of(context)!.providersRent, data.rent, data.link),
              const SizedBox(height: 15),
            ],

            // Bottone diretto TMDB per maggiori opzioni
            if (data.link != null)
              TextButton.icon(
                onPressed: () => _launchUrl(data.link!),
                icon: const Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  AppLocalizations.of(context)!.providersAllOptions,
                  style: const TextStyle(color: Colors.white),
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
                      child: CachedNetworkImage(
                        imageUrl: p.fullLogoUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[800],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        errorWidget: (ctx, url, error) => Container(
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
