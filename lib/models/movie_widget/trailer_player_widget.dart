import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:library_ai/injection_container.dart';
import 'package:library_ai/domain/use_cases/movie_use_cases.dart';
import 'package:library_ai/domain/use_cases/tv_series_use_cases.dart';

class TrailerPlayerWidget extends StatefulWidget {
  final int mediaId;
  final bool isTvSeries;

  const TrailerPlayerWidget({
    super.key,
    required this.mediaId,
    required this.isTvSeries,
  });

  @override
  State<TrailerPlayerWidget> createState() => _TrailerPlayerWidgetState();
}

class _TrailerPlayerWidgetState extends State<TrailerPlayerWidget> {
  late Future<String?> _trailerFuture;
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    _trailerFuture = _fetchTrailer();
  }

  Future<String?> _fetchTrailer() async {
    if (widget.isTvSeries) {
      return await sl<GetTvSeriesTrailerUseCase>().call(widget.mediaId);
    } else {
      return await sl<GetMovieTrailerUseCase>().call(widget.mediaId);
    }
  }

  @override
  void dispose() {
    // Dobbiamo forzare la pausa e lo smaltimento profondo della webview
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _trailerFuture,
      builder: (context, snapshot) {
        // Mentre carica o in caso di errore, non mostriamo nulla (SizedBox.shrink() occupa 0 pixel)
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.hasError) {
          return const SizedBox.shrink();
        }

        // Se la chiamata è andata a buon fine ma non c'è il trailer, sparisce.
        if (!snapshot.hasData ||
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Abbiamo la chiave! Inizializziamo il controller
        _controller ??= YoutubePlayerController(
          initialVideoId: snapshot.data!,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            disableDragSeek: true,
            loop: false,
            isLive: false,
            forceHD: true,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "TRAILER UFFICIALE",
              style: TextStyle(
                color: Colors.white38,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: YoutubePlayer(
                controller: _controller!,
                showVideoProgressIndicator: true,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.orangeAccent,
                  handleColor: Colors.orangeAccent,
                ),
                bottomActions: [
                  CurrentPosition(),
                  ProgressBar(isExpanded: true),
                  RemainingDuration(),
                  const PlaybackSpeedButton(),
                ],
              ),
            ),
            const SizedBox(
              height: 40,
            ), // Spazio extra solo se il trailer esiste
          ],
        );
      },
    );
  }
}
