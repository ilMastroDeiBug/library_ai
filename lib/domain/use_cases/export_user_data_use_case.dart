import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExportUserDataUseCase {
  final SupabaseClient supabase;

  ExportUserDataUseCase(this.supabase);

  Future<void> call(String userId) async {
    // 1. Scarichiamo TUTTO in parallelo per la massima velocità
    final results = await Future.wait([
      supabase.from('user_watchlist').select().eq('user_id', userId),
      supabase.from('user_tv_progress').select().eq('user_id', userId),
      supabase.from('user_books').select().eq('user_id', userId),
      supabase.from('reviews').select().eq('user_id', userId),
      supabase.from('favorites').select().eq('user_id', userId),
      supabase.from('media_ratings').select().eq('user_id', userId),
    ]);

    // 2. Strutturiamo il mega-oggetto JSON
    final exportData = {
      "export_date": DateTime.now().toIso8601String(),
      "user_id": userId,
      "watchlist": results[0],
      "tv_progress": results[1],
      "books": results[2],
      "reviews": results[3],
      "favorites": results[4],
      "ratings": results[5],
    };

    // 3. Convertiamo in stringa formattata bene (con gli spazi)
    final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

    // 4. Salviamo il file temporaneamente sul telefono
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/cinelib_export_$userId.json');
    await file.writeAsString(jsonString);

    // 5. Apriamo il popup di sistema per far condividere o salvare il file all'utente!
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Ecco il backup dei miei dati su MatchCut!');
  }
}
