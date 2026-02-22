// lib/models/movie_widget/watch_provider_model.dart

class WatchProviderModel {
  final String providerName;
  final String logoPath;
  final int providerId;

  WatchProviderModel({
    required this.providerName,
    required this.logoPath,
    required this.providerId,
  });

  factory WatchProviderModel.fromJson(Map<String, dynamic> json) {
    return WatchProviderModel(
      providerName: json['provider_name'] ?? '',
      logoPath: json['logo_path'] ?? '',
      providerId: json['provider_id'] ?? 0,
    );
  }

  String get fullLogoUrl => 'https://image.tmdb.org/t/p/original$logoPath';
}

class WatchProvidersResult {
  final String? link;
  final List<WatchProviderModel>
  flatrate; // Piattaforme in abbonamento (Netflix, Prime)
  final List<WatchProviderModel> rent; // Piattaforme a noleggio
  final List<WatchProviderModel> buy; // Piattaforme per acquisto

  WatchProvidersResult({
    this.link,
    required this.flatrate,
    required this.rent,
    required this.buy,
  });

  factory WatchProvidersResult.empty() =>
      WatchProvidersResult(flatrate: [], rent: [], buy: []);

  factory WatchProvidersResult.fromJson(Map<String, dynamic> json) {
    List<WatchProviderModel> parseList(String key) {
      if (json[key] == null) return [];
      return (json[key] as List)
          .map((p) => WatchProviderModel.fromJson(p))
          .toList();
    }

    return WatchProvidersResult(
      link: json['link'],
      flatrate: parseList('flatrate'),
      rent: parseList('rent'),
      buy: parseList('buy'),
    );
  }
}
