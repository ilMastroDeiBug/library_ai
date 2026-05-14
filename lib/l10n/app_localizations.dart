import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @watchlist.
  ///
  /// In it, this message translates to:
  /// **'Watchlist'**
  String get watchlist;

  /// No description provided for @currentlyWatching.
  ///
  /// In it, this message translates to:
  /// **'STAI GUARDANDO'**
  String get currentlyWatching;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca nella lista...'**
  String get searchHint;

  /// No description provided for @watched.
  ///
  /// In it, this message translates to:
  /// **'VISTI'**
  String get watched;

  /// No description provided for @watching.
  ///
  /// In it, this message translates to:
  /// **'STAI GUARDANDO'**
  String get watching;

  /// No description provided for @toWatch.
  ///
  /// In it, this message translates to:
  /// **'DA VEDERE'**
  String get toWatch;

  /// No description provided for @favorites.
  ///
  /// In it, this message translates to:
  /// **'PREFERITI'**
  String get favorites;

  /// No description provided for @navHome.
  ///
  /// In it, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navVault.
  ///
  /// In it, this message translates to:
  /// **'Vault'**
  String get navVault;

  /// No description provided for @navExplore.
  ///
  /// In it, this message translates to:
  /// **'Esplora'**
  String get navExplore;

  /// No description provided for @navAI.
  ///
  /// In it, this message translates to:
  /// **'Studio AI'**
  String get navAI;

  /// No description provided for @sideMenuExplore.
  ///
  /// In it, this message translates to:
  /// **'ESPLORA'**
  String get sideMenuExplore;

  /// No description provided for @sideMenuCinemaTv.
  ///
  /// In it, this message translates to:
  /// **'Cinema & Serie TV'**
  String get sideMenuCinemaTv;

  /// No description provided for @sideMenuCommunity.
  ///
  /// In it, this message translates to:
  /// **'COMMUNITY'**
  String get sideMenuCommunity;

  /// No description provided for @sideMenuSocial.
  ///
  /// In it, this message translates to:
  /// **'CineShare Social'**
  String get sideMenuSocial;

  /// No description provided for @sideMenuProject.
  ///
  /// In it, this message translates to:
  /// **'IL PROGETTO'**
  String get sideMenuProject;

  /// No description provided for @sideMenuInfoSupport.
  ///
  /// In it, this message translates to:
  /// **'Info & Supporto'**
  String get sideMenuInfoSupport;

  /// No description provided for @exploreBooks.
  ///
  /// In it, this message translates to:
  /// **'Esplora\nLibri'**
  String get exploreBooks;

  /// No description provided for @exploreTv.
  ///
  /// In it, this message translates to:
  /// **'Esplora\nSerie TV'**
  String get exploreTv;

  /// No description provided for @exploreCinema.
  ///
  /// In it, this message translates to:
  /// **'Esplora\nCinema'**
  String get exploreCinema;

  /// No description provided for @searchBooksPaused.
  ///
  /// In it, this message translates to:
  /// **'Ricerca libri sospesa...'**
  String get searchBooksPaused;

  /// No description provided for @searchPlaceholder.
  ///
  /// In it, this message translates to:
  /// **'Cerca un titolo, regista o autore...'**
  String get searchPlaceholder;

  /// No description provided for @inTheatersNow.
  ///
  /// In it, this message translates to:
  /// **'Al Cinema ora'**
  String get inTheatersNow;

  /// No description provided for @mostPopular.
  ///
  /// In it, this message translates to:
  /// **'Più Popolari'**
  String get mostPopular;

  /// No description provided for @topRated.
  ///
  /// In it, this message translates to:
  /// **'Grandi Successi (Top)'**
  String get topRated;

  /// No description provided for @upcoming.
  ///
  /// In it, this message translates to:
  /// **'Prossime Uscite'**
  String get upcoming;

  /// No description provided for @trending.
  ///
  /// In it, this message translates to:
  /// **'Trend della Settimana'**
  String get trending;

  /// No description provided for @airingToday.
  ///
  /// In it, this message translates to:
  /// **'In onda Oggi'**
  String get airingToday;

  /// No description provided for @onTheAir.
  ///
  /// In it, this message translates to:
  /// **'Novità in arrivo'**
  String get onTheAir;

  /// No description provided for @bestOfAllTime.
  ///
  /// In it, this message translates to:
  /// **'Le Migliori di sempre'**
  String get bestOfAllTime;

  /// No description provided for @movies.
  ///
  /// In it, this message translates to:
  /// **'Film'**
  String get movies;

  /// No description provided for @tvSeries.
  ///
  /// In it, this message translates to:
  /// **'Serie TV'**
  String get tvSeries;

  /// No description provided for @exploreBooksPaused.
  ///
  /// In it, this message translates to:
  /// **'Esplorazione in Pausa'**
  String get exploreBooksPaused;

  /// No description provided for @exploreBooksPausedDesc.
  ///
  /// In it, this message translates to:
  /// **'Stiamo mappando i generi letterari perfetti per garantirti risultati precisi e in lingua italiana.'**
  String get exploreBooksPausedDesc;

  /// No description provided for @searchBooksDisabled.
  ///
  /// In it, this message translates to:
  /// **'Ricerca disabilitata.\nIl Vault dei Libri è in arrivo!'**
  String get searchBooksDisabled;

  /// No description provided for @moviesAndTv.
  ///
  /// In it, this message translates to:
  /// **'Film & Serie TV'**
  String get moviesAndTv;

  /// No description provided for @actors.
  ///
  /// In it, this message translates to:
  /// **'Attori'**
  String get actors;

  /// No description provided for @searchMoviesTv.
  ///
  /// In it, this message translates to:
  /// **'Cerca Film o Serie TV'**
  String get searchMoviesTv;

  /// No description provided for @searchActors.
  ///
  /// In it, this message translates to:
  /// **'Cerca Attori'**
  String get searchActors;

  /// No description provided for @noResultsFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato trovato'**
  String get noResultsFound;

  /// No description provided for @viewProgress.
  ///
  /// In it, this message translates to:
  /// **'PROGRESSO VISIONE'**
  String get viewProgress;

  /// No description provided for @watchedAction.
  ///
  /// In it, this message translates to:
  /// **'VISTO'**
  String get watchedAction;

  /// No description provided for @plot.
  ///
  /// In it, this message translates to:
  /// **'TRAMA'**
  String get plot;

  /// No description provided for @noPlotAvailable.
  ///
  /// In it, this message translates to:
  /// **'Nessuna trama disponibile.'**
  String get noPlotAvailable;

  /// No description provided for @ratingSaved.
  ///
  /// In it, this message translates to:
  /// **'Valutazione salvata!'**
  String get ratingSaved;

  /// No description provided for @ratingThanks.
  ///
  /// In it, this message translates to:
  /// **'Grazie per il tuo feedback.'**
  String get ratingThanks;

  /// No description provided for @ratingTitle.
  ///
  /// In it, this message translates to:
  /// **'Quanto ti è piaciuto?'**
  String get ratingTitle;

  /// No description provided for @ratingDescription.
  ///
  /// In it, this message translates to:
  /// **'Questa valutazione verrà utilizzata per comprendere meglio i tuoi gusti e offrirti consigli IA sempre più personalizzati.'**
  String get ratingDescription;

  /// No description provided for @ratingSubmit.
  ///
  /// In it, this message translates to:
  /// **'Invia Valutazione'**
  String get ratingSubmit;

  /// No description provided for @ratingTerrible.
  ///
  /// In it, this message translates to:
  /// **'Pessimo'**
  String get ratingTerrible;

  /// No description provided for @ratingBoring.
  ///
  /// In it, this message translates to:
  /// **'Noioso'**
  String get ratingBoring;

  /// No description provided for @ratingOk.
  ///
  /// In it, this message translates to:
  /// **'Ok'**
  String get ratingOk;

  /// No description provided for @ratingGood.
  ///
  /// In it, this message translates to:
  /// **'Bello'**
  String get ratingGood;

  /// No description provided for @ratingMasterpiece.
  ///
  /// In it, this message translates to:
  /// **'Capolavoro'**
  String get ratingMasterpiece;

  /// No description provided for @settingsLanguageError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile salvare la lingua: '**
  String get settingsLanguageError;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In it, this message translates to:
  /// **'SELEZIONA LINGUA'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageDesc.
  ///
  /// In it, this message translates to:
  /// **'Applica a interfaccia e risultati di ricerca'**
  String get settingsLanguageDesc;

  /// No description provided for @settingsProfileTitle.
  ///
  /// In it, this message translates to:
  /// **'IL MIO PROFILO'**
  String get settingsProfileTitle;

  /// No description provided for @settingsNoBio.
  ///
  /// In it, this message translates to:
  /// **'Nessuna biografia impostata. Racconta chi sei.'**
  String get settingsNoBio;

  /// No description provided for @settingsExperience.
  ///
  /// In it, this message translates to:
  /// **'ESPERIENZA'**
  String get settingsExperience;

  /// No description provided for @settingsContentLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua Contenuti'**
  String get settingsContentLanguage;

  /// No description provided for @settingsCurrently.
  ///
  /// In it, this message translates to:
  /// **'Attualmente'**
  String get settingsCurrently;

  /// No description provided for @settingsAccountManagement.
  ///
  /// In it, this message translates to:
  /// **'GESTIONE ACCOUNT'**
  String get settingsAccountManagement;

  /// No description provided for @settingsDisplayName.
  ///
  /// In it, this message translates to:
  /// **'Nome Visualizzato'**
  String get settingsDisplayName;

  /// No description provided for @settingsTapToSet.
  ///
  /// In it, this message translates to:
  /// **'Tocca per impostare'**
  String get settingsTapToSet;

  /// No description provided for @settingsBio.
  ///
  /// In it, this message translates to:
  /// **'Biografia'**
  String get settingsBio;

  /// No description provided for @settingsEditDesc.
  ///
  /// In it, this message translates to:
  /// **'Modifica la tua descrizione'**
  String get settingsEditDesc;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In it, this message translates to:
  /// **'Elimina Account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountDesc.
  ///
  /// In it, this message translates to:
  /// **'Rimuovi permanentemente i dati'**
  String get settingsDeleteAccountDesc;

  /// No description provided for @settingsLogout.
  ///
  /// In it, this message translates to:
  /// **'DISCONNETTI'**
  String get settingsLogout;

  /// No description provided for @settingsEditName.
  ///
  /// In it, this message translates to:
  /// **'Modifica Nome'**
  String get settingsEditName;

  /// No description provided for @settingsEnterNewName.
  ///
  /// In it, this message translates to:
  /// **'Inserisci nuovo nome'**
  String get settingsEnterNewName;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'ANNULLA'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'SALVA'**
  String get save;

  /// No description provided for @settingsYourBio.
  ///
  /// In it, this message translates to:
  /// **'La tua Biografia'**
  String get settingsYourBio;

  /// No description provided for @settingsTellUsAboutYou.
  ///
  /// In it, this message translates to:
  /// **'Racconta qualcosa di te...'**
  String get settingsTellUsAboutYou;

  /// No description provided for @settingsDeleteError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'eliminazione.'**
  String get settingsDeleteError;

  /// No description provided for @settingsDeleteWarning.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler eliminare il tuo account?\n\nQuesta azione è IRREVERSIBILE. Tutti i tuoi salvataggi, librerie e analisi AI andranno persi per sempre.'**
  String get settingsDeleteWarning;

  /// No description provided for @settingsDeleteForever.
  ///
  /// In it, this message translates to:
  /// **'Elimina per sempre'**
  String get settingsDeleteForever;

  /// No description provided for @settingsSaveError.
  ///
  /// In it, this message translates to:
  /// **'Errore salvataggio: '**
  String get settingsSaveError;

  /// No description provided for @settingsChooseAvatar.
  ///
  /// In it, this message translates to:
  /// **'SCEGLI IL TUO AVATAR'**
  String get settingsChooseAvatar;

  /// No description provided for @settingsSaveAvatar.
  ///
  /// In it, this message translates to:
  /// **'SALVA AVATAR'**
  String get settingsSaveAvatar;

  /// No description provided for @castTitle.
  ///
  /// In it, this message translates to:
  /// **'CAST'**
  String get castTitle;

  /// No description provided for @castUnavailable.
  ///
  /// In it, this message translates to:
  /// **'Info cast non disponibili.'**
  String get castUnavailable;

  /// No description provided for @reviewsLoginToVote.
  ///
  /// In it, this message translates to:
  /// **'Accedi per votare'**
  String get reviewsLoginToVote;

  /// No description provided for @reviewsDeleteOnlyYours.
  ///
  /// In it, this message translates to:
  /// **'Puoi eliminare solo le tue recensioni'**
  String get reviewsDeleteOnlyYours;

  /// No description provided for @reviewsDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare recensione?'**
  String get reviewsDeleteTitle;

  /// No description provided for @reviewsDeleteDesc.
  ///
  /// In it, this message translates to:
  /// **'Questa azione non può essere annullata.'**
  String get reviewsDeleteDesc;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @reviewsDeleteError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile eliminare la recensione'**
  String get reviewsDeleteError;

  /// No description provided for @reviewsLoginToWrite.
  ///
  /// In it, this message translates to:
  /// **'Accedi per scrivere una recensione'**
  String get reviewsLoginToWrite;

  /// No description provided for @reviewsTitle.
  ///
  /// In it, this message translates to:
  /// **'RECENSIONI'**
  String get reviewsTitle;

  /// No description provided for @reviewsSortRelevance.
  ///
  /// In it, this message translates to:
  /// **'Più rilevanti'**
  String get reviewsSortRelevance;

  /// No description provided for @reviewsSortRecent.
  ///
  /// In it, this message translates to:
  /// **'Più recenti'**
  String get reviewsSortRecent;

  /// No description provided for @reviewsSortRating.
  ///
  /// In it, this message translates to:
  /// **'Voti più alti'**
  String get reviewsSortRating;

  /// No description provided for @reviewsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Nessuna recensione. Sii il primo!'**
  String get reviewsEmpty;

  /// No description provided for @reviewsViewAll.
  ///
  /// In it, this message translates to:
  /// **'Vedi tutte le recensioni'**
  String get reviewsViewAll;

  /// No description provided for @reviewsWrite.
  ///
  /// In it, this message translates to:
  /// **'Scrivi una recensione'**
  String get reviewsWrite;

  /// No description provided for @reviewsFromTMDB.
  ///
  /// In it, this message translates to:
  /// **'Da TMDB'**
  String get reviewsFromTMDB;

  /// No description provided for @reviewsDeleteTooltip.
  ///
  /// In it, this message translates to:
  /// **'Elimina recensione'**
  String get reviewsDeleteTooltip;

  /// No description provided for @providersLinkError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile aprire il link: '**
  String get providersLinkError;

  /// No description provided for @providersWatchNow.
  ///
  /// In it, this message translates to:
  /// **'GUARDA ORA SU'**
  String get providersWatchNow;

  /// No description provided for @providersFlatrate.
  ///
  /// In it, this message translates to:
  /// **'In Abbonamento'**
  String get providersFlatrate;

  /// No description provided for @providersRent.
  ///
  /// In it, this message translates to:
  /// **'A Noleggio'**
  String get providersRent;

  /// No description provided for @providersAllOptions.
  ///
  /// In it, this message translates to:
  /// **'Tutte le opzioni di acquisto'**
  String get providersAllOptions;

  /// No description provided for @actorLoginToFavorite.
  ///
  /// In it, this message translates to:
  /// **'Accedi per aggiungere ai preferiti.'**
  String get actorLoginToFavorite;

  /// No description provided for @actorAddedToFavorites.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto ai Preferiti ❤️'**
  String get actorAddedToFavorites;

  /// No description provided for @actorRemovedFromFavorites.
  ///
  /// In it, this message translates to:
  /// **'Rimosso dai Preferiti 💔'**
  String get actorRemovedFromFavorites;

  /// No description provided for @actorFavoriteError.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'aggiornamento dei preferiti.'**
  String get actorFavoriteError;

  /// No description provided for @actorError.
  ///
  /// In it, this message translates to:
  /// **'Errore: '**
  String get actorError;

  /// No description provided for @actorBiographyTitle.
  ///
  /// In it, this message translates to:
  /// **'BIOGRAFIA'**
  String get actorBiographyTitle;

  /// No description provided for @actorFilmographyTitle.
  ///
  /// In it, this message translates to:
  /// **'FILMOGRAFIA'**
  String get actorFilmographyTitle;

  /// No description provided for @actorNoBio.
  ///
  /// In it, this message translates to:
  /// **'Nessuna biografia disponibile per questo attore.'**
  String get actorNoBio;

  /// No description provided for @actorReadMore.
  ///
  /// In it, this message translates to:
  /// **'Leggi di più'**
  String get actorReadMore;

  /// No description provided for @actorShowLess.
  ///
  /// In it, this message translates to:
  /// **'Mostra meno'**
  String get actorShowLess;

  /// No description provided for @actorNoFilmography.
  ///
  /// In it, this message translates to:
  /// **'Nessuna informazione sulla filmografia.'**
  String get actorNoFilmography;

  /// No description provided for @allReviewsLoginToVote.
  ///
  /// In it, this message translates to:
  /// **'Accedi per votare le recensioni.'**
  String get allReviewsLoginToVote;

  /// No description provided for @allReviewsTmdbCannotVote.
  ///
  /// In it, this message translates to:
  /// **'Le recensioni di TMDB non possono essere votate.'**
  String get allReviewsTmdbCannotVote;

  /// No description provided for @allReviewsDeleteOnlyYours.
  ///
  /// In it, this message translates to:
  /// **'Puoi eliminare solo le tue recensioni.'**
  String get allReviewsDeleteOnlyYours;

  /// No description provided for @allReviewsDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare recensione?'**
  String get allReviewsDeleteTitle;

  /// No description provided for @allReviewsDeleteDesc.
  ///
  /// In it, this message translates to:
  /// **'Questa azione non può essere annullata.'**
  String get allReviewsDeleteDesc;

  /// No description provided for @allReviewsDeleted.
  ///
  /// In it, this message translates to:
  /// **'Recensione eliminata.'**
  String get allReviewsDeleted;

  /// No description provided for @allReviewsDeleteError.
  ///
  /// In it, this message translates to:
  /// **'Impossibile eliminare la recensione.'**
  String get allReviewsDeleteError;

  /// No description provided for @allReviewsLoginToWrite.
  ///
  /// In it, this message translates to:
  /// **'Accedi per scrivere una recensione.'**
  String get allReviewsLoginToWrite;

  /// No description provided for @allReviewsWrite.
  ///
  /// In it, this message translates to:
  /// **'Scrivi'**
  String get allReviewsWrite;

  /// No description provided for @allReviewsCount.
  ///
  /// In it, this message translates to:
  /// **'{count} Recensioni'**
  String allReviewsCount(int count);

  /// No description provided for @allReviewsLoading.
  ///
  /// In it, this message translates to:
  /// **'Caricamento...'**
  String get allReviewsLoading;

  /// No description provided for @allReviewsSortRelevant.
  ///
  /// In it, this message translates to:
  /// **'Rilevanti'**
  String get allReviewsSortRelevant;

  /// No description provided for @allReviewsSortRecent.
  ///
  /// In it, this message translates to:
  /// **'Recenti'**
  String get allReviewsSortRecent;

  /// No description provided for @allReviewsSortHighRating.
  ///
  /// In it, this message translates to:
  /// **'Voti Alti'**
  String get allReviewsSortHighRating;

  /// No description provided for @allReviewsSortLowRating.
  ///
  /// In it, this message translates to:
  /// **'Voti Bassi'**
  String get allReviewsSortLowRating;

  /// No description provided for @allReviewsEmpty.
  ///
  /// In it, this message translates to:
  /// **'Ancora nessuna recensione.'**
  String get allReviewsEmpty;

  /// No description provided for @allReviewsDeleteTooltip.
  ///
  /// In it, this message translates to:
  /// **'Elimina recensione'**
  String get allReviewsDeleteTooltip;

  /// No description provided for @writeReviewTitle.
  ///
  /// In it, this message translates to:
  /// **'La tua Recensione'**
  String get writeReviewTitle;

  /// No description provided for @writeReviewHint.
  ///
  /// In it, this message translates to:
  /// **'Cosa ne pensi?'**
  String get writeReviewHint;

  /// No description provided for @writeReviewPublish.
  ///
  /// In it, this message translates to:
  /// **'Pubblica'**
  String get writeReviewPublish;

  /// No description provided for @genreNoResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get genreNoResults;

  /// No description provided for @aboutDonationMsg.
  ///
  /// In it, this message translates to:
  /// **'Presto potrai supportarmi con Ko-fi o PayPal!'**
  String get aboutDonationMsg;

  /// No description provided for @aboutAdMsg.
  ///
  /// In it, this message translates to:
  /// **'Caricamento sponsor... (Integrazione AdMob in arrivo)'**
  String get aboutAdMsg;

  /// No description provided for @aboutBehindTheScenes.
  ///
  /// In it, this message translates to:
  /// **'Dietro le quinte'**
  String get aboutBehindTheScenes;

  /// No description provided for @aboutVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione 1.0.0 (Beta)'**
  String get aboutVersion;

  /// No description provided for @aboutStoryPart1.
  ///
  /// In it, this message translates to:
  /// **'Ciao! Sono lo sviluppatore di CineShare e ho '**
  String get aboutStoryPart1;

  /// No description provided for @aboutStoryAge.
  ///
  /// In it, this message translates to:
  /// **'16 anni'**
  String get aboutStoryAge;

  /// No description provided for @aboutStoryPart2.
  ///
  /// In it, this message translates to:
  /// **'.\n\nHo costruito questa piattaforma da solo, unendo gestione dei media e Intelligenza Artificiale.\n\n'**
  String get aboutStoryPart2;

  /// No description provided for @aboutNextGoal.
  ///
  /// In it, this message translates to:
  /// **'Il Prossimo Obiettivo'**
  String get aboutNextGoal;

  /// No description provided for @aboutIosGoalTitle.
  ///
  /// In it, this message translates to:
  /// **'Sbarco su iOS & Libri'**
  String get aboutIosGoalTitle;

  /// No description provided for @aboutIosGoalDesc.
  ///
  /// In it, this message translates to:
  /// **'L\'account sviluppatore Apple costa 99\$/anno. Con il tuo supporto porterò CineShare su iPhone e sbloccherò l\'intera sezione Libri, grazie al servizio di ISBN!'**
  String get aboutIosGoalDesc;

  /// No description provided for @aboutHowToHelp.
  ///
  /// In it, this message translates to:
  /// **'Come puoi aiutarmi?'**
  String get aboutHowToHelp;

  /// No description provided for @aboutDonateCoffeeTitle.
  ///
  /// In it, this message translates to:
  /// **'Offrimi un Caffè (Server)'**
  String get aboutDonateCoffeeTitle;

  /// No description provided for @aboutDonateCoffeeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Supporta questo progetto'**
  String get aboutDonateCoffeeSubtitle;

  /// No description provided for @aboutWatchAdTitle.
  ///
  /// In it, this message translates to:
  /// **'Guarda uno Sponsor'**
  String get aboutWatchAdTitle;

  /// No description provided for @aboutWatchAdSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Supportami gratis guardando un video di 30s'**
  String get aboutWatchAdSubtitle;

  /// No description provided for @aboutRateTitle.
  ///
  /// In it, this message translates to:
  /// **'Lascia 5 Stelle'**
  String get aboutRateTitle;

  /// No description provided for @aboutRateSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Aiuta l\'algoritmo a far crescere l\'app'**
  String get aboutRateSubtitle;

  /// No description provided for @homeLibrary.
  ///
  /// In it, this message translates to:
  /// **'La Biblioteca'**
  String get homeLibrary;

  /// No description provided for @homeVaultTitle.
  ///
  /// In it, this message translates to:
  /// **'Il Vault Definitivo'**
  String get homeVaultTitle;

  /// No description provided for @homeVaultDesc.
  ///
  /// In it, this message translates to:
  /// **'Stiamo costruendo un ecosistema perfetto per i tuoi libri: dati curati, copertine in HD e analisi IA avanzate.\n\nNon scendiamo a compromessi sulla qualità. In arrivo nei prossimi aggiornamenti.'**
  String get homeVaultDesc;

  /// No description provided for @homeNotifyMe.
  ///
  /// In it, this message translates to:
  /// **'Avvisami al rilascio'**
  String get homeNotifyMe;

  /// No description provided for @homeVaultNotifyMsg.
  ///
  /// In it, this message translates to:
  /// **'✨ Grazie! Ti avviseremo non appena il Vault dei libri sarà sbloccato.'**
  String get homeVaultNotifyMsg;

  /// No description provided for @homeWatching.
  ///
  /// In it, this message translates to:
  /// **'STAI GUARDANDO'**
  String get homeWatching;

  /// No description provided for @bookToRead.
  ///
  /// In it, this message translates to:
  /// **'DA LEGGERE'**
  String get bookToRead;

  /// No description provided for @bookRead.
  ///
  /// In it, this message translates to:
  /// **'LETTO'**
  String get bookRead;

  /// No description provided for @bookSynopsis.
  ///
  /// In it, this message translates to:
  /// **'SINOSSI'**
  String get bookSynopsis;

  /// No description provided for @bookNoDescription.
  ///
  /// In it, this message translates to:
  /// **'Nessuna descrizione disponibile.'**
  String get bookNoDescription;

  /// No description provided for @settingsUnknownUser.
  ///
  /// In it, this message translates to:
  /// **'Utente Misterioso'**
  String get settingsUnknownUser;

  /// No description provided for @libSearchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca nella lista...'**
  String get libSearchHint;

  /// No description provided for @libSelect.
  ///
  /// In it, this message translates to:
  /// **'Seleziona'**
  String get libSelect;

  /// No description provided for @libCancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get libCancel;

  /// No description provided for @libErrorOperation.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'operazione.'**
  String get libErrorOperation;

  /// No description provided for @libBulkDelete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get libBulkDelete;

  /// No description provided for @libBulkWatching.
  ///
  /// In it, this message translates to:
  /// **'Stai Guardando'**
  String get libBulkWatching;

  /// No description provided for @libBulkWatched.
  ///
  /// In it, this message translates to:
  /// **'Visti'**
  String get libBulkWatched;

  /// No description provided for @libBulkRead.
  ///
  /// In it, this message translates to:
  /// **'Letti'**
  String get libBulkRead;

  /// No description provided for @libEmptyNoResults.
  ///
  /// In it, this message translates to:
  /// **'NESSUN RISULTATO'**
  String get libEmptyNoResults;

  /// No description provided for @libEmptyNoFavorites.
  ///
  /// In it, this message translates to:
  /// **'NESSUN PREFERITO'**
  String get libEmptyNoFavorites;

  /// No description provided for @libEmptyNoItems.
  ///
  /// In it, this message translates to:
  /// **'NESSUN ELEMENTO'**
  String get libEmptyNoItems;

  /// No description provided for @libFilterAll.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get libFilterAll;

  /// No description provided for @libFilterMovies.
  ///
  /// In it, this message translates to:
  /// **'Film'**
  String get libFilterMovies;

  /// No description provided for @libFilterTvSeries.
  ///
  /// In it, this message translates to:
  /// **'Serie TV'**
  String get libFilterTvSeries;

  /// No description provided for @libFilterActors.
  ///
  /// In it, this message translates to:
  /// **'Attori'**
  String get libFilterActors;

  /// No description provided for @deleteBookTitle.
  ///
  /// In it, this message translates to:
  /// **'Eliminare?'**
  String get deleteBookTitle;

  /// No description provided for @deleteBookContent.
  ///
  /// In it, this message translates to:
  /// **'Rimuovere \"{title}\" dalla libreria è un\'azione irreversibile.'**
  String deleteBookContent(String title);

  /// No description provided for @libHeaderVault.
  ///
  /// In it, this message translates to:
  /// **'Il tuo\nVault'**
  String get libHeaderVault;

  /// No description provided for @libHeaderWatchlist.
  ///
  /// In it, this message translates to:
  /// **'La tua\nWatchlist'**
  String get libHeaderWatchlist;

  /// No description provided for @heroBannerMovieOfDay.
  ///
  /// In it, this message translates to:
  /// **'FILM DEL GIORNO'**
  String get heroBannerMovieOfDay;

  /// No description provided for @heroBannerTvTrending.
  ///
  /// In it, this message translates to:
  /// **'SERIE TV IN TENDENZA'**
  String get heroBannerTvTrending;

  /// No description provided for @heroBannerMoreInfo.
  ///
  /// In it, this message translates to:
  /// **'Maggiori Info'**
  String get heroBannerMoreInfo;

  /// No description provided for @aiAnalysisTitle.
  ///
  /// In it, this message translates to:
  /// **'VERDETTO DELL\'ARCHITETTO'**
  String get aiAnalysisTitle;

  /// No description provided for @aiAnalysisThinking.
  ///
  /// In it, this message translates to:
  /// **'STO PENSANDO...'**
  String get aiAnalysisThinking;

  /// No description provided for @aiAnalysisRequest.
  ///
  /// In it, this message translates to:
  /// **'RICHIEDI ANALISI AI'**
  String get aiAnalysisRequest;

  /// No description provided for @socialFeed.
  ///
  /// In it, this message translates to:
  /// **'Feed'**
  String get socialFeed;

  /// No description provided for @socialFriends.
  ///
  /// In it, this message translates to:
  /// **'Amici'**
  String get socialFriends;

  /// No description provided for @socialMessages.
  ///
  /// In it, this message translates to:
  /// **'Messaggi'**
  String get socialMessages;

  /// No description provided for @socialProfile.
  ///
  /// In it, this message translates to:
  /// **'Profilo'**
  String get socialProfile;

  /// No description provided for @statsVotes.
  ///
  /// In it, this message translates to:
  /// **'voti'**
  String get statsVotes;

  /// No description provided for @libTabRead.
  ///
  /// In it, this message translates to:
  /// **'LETTI'**
  String get libTabRead;

  /// No description provided for @libTabReading.
  ///
  /// In it, this message translates to:
  /// **'IN LETTURA'**
  String get libTabReading;

  /// No description provided for @libTabToRead.
  ///
  /// In it, this message translates to:
  /// **'DA LEGGERE'**
  String get libTabToRead;

  /// No description provided for @libManualInsertWip.
  ///
  /// In it, this message translates to:
  /// **'Inserimento manuale in fase di sviluppo.'**
  String get libManualInsertWip;

  /// No description provided for @bookStatsLength.
  ///
  /// In it, this message translates to:
  /// **'LUNGHEZZA'**
  String get bookStatsLength;

  /// No description provided for @bookStatsRating.
  ///
  /// In it, this message translates to:
  /// **'VALUTAZIONE'**
  String get bookStatsRating;

  /// No description provided for @bookStatsReviews.
  ///
  /// In it, this message translates to:
  /// **'{count} recensioni'**
  String bookStatsReviews(int count);

  /// No description provided for @trailerTitle.
  ///
  /// In it, this message translates to:
  /// **'TRAILER UFFICIALE'**
  String get trailerTitle;

  /// No description provided for @trackerSeasonLabel.
  ///
  /// In it, this message translates to:
  /// **'Stagione {n}'**
  String trackerSeasonLabel(int n);

  /// No description provided for @trackerSeasonEpisode.
  ///
  /// In it, this message translates to:
  /// **'STAGIONE {season} • EPISODIO {episode}'**
  String trackerSeasonEpisode(int season, int episode);

  /// No description provided for @trackerRemoveFromHere.
  ///
  /// In it, this message translates to:
  /// **'Rimuovere da qui in poi?'**
  String get trackerRemoveFromHere;

  /// No description provided for @trackerMarkUpToHere.
  ///
  /// In it, this message translates to:
  /// **'Contrassegnare fino a qui?'**
  String get trackerMarkUpToHere;

  /// No description provided for @trackerCancel.
  ///
  /// In it, this message translates to:
  /// **'ANNULLA'**
  String get trackerCancel;

  /// No description provided for @trackerConfirm.
  ///
  /// In it, this message translates to:
  /// **'CONFERMA'**
  String get trackerConfirm;

  /// No description provided for @searchMoviePrefix.
  ///
  /// In it, this message translates to:
  /// **'Film • {year}'**
  String searchMoviePrefix(String year);

  /// No description provided for @searchTvPrefix.
  ///
  /// In it, this message translates to:
  /// **'Serie TV • {year}'**
  String searchTvPrefix(String year);

  /// No description provided for @searchMovieOnly.
  ///
  /// In it, this message translates to:
  /// **'Film'**
  String get searchMovieOnly;

  /// No description provided for @searchTvOnly.
  ///
  /// In it, this message translates to:
  /// **'Serie TV'**
  String get searchTvOnly;

  /// No description provided for @offlineTitle.
  ///
  /// In it, this message translates to:
  /// **'SEI OFFLINE'**
  String get offlineTitle;

  /// No description provided for @offlineSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Nessun problema, goditi la tua libreria.'**
  String get offlineSubtitle;

  /// No description provided for @logicLoginToSave.
  ///
  /// In it, this message translates to:
  /// **'Accedi per salvare.'**
  String get logicLoginToSave;

  /// No description provided for @logicRemovedFromLibrary.
  ///
  /// In it, this message translates to:
  /// **'Rimosso dalla libreria'**
  String get logicRemovedFromLibrary;

  /// No description provided for @logicMarkedAsWatched.
  ///
  /// In it, this message translates to:
  /// **'Segnato come Visto'**
  String get logicMarkedAsWatched;

  /// No description provided for @logicAddedToWatchlist.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto ai Da Vedere'**
  String get logicAddedToWatchlist;

  /// No description provided for @logicAddedToWatching.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto a In Corso'**
  String get logicAddedToWatching;

  /// No description provided for @logicSaveError.
  ///
  /// In it, this message translates to:
  /// **'Errore nel salvataggio. Riprova.'**
  String get logicSaveError;

  /// No description provided for @logicLoginToFavorite.
  ///
  /// In it, this message translates to:
  /// **'Accedi per aggiungere ai preferiti.'**
  String get logicLoginToFavorite;

  /// No description provided for @logicAddedToFavorites.
  ///
  /// In it, this message translates to:
  /// **'Aggiunto ai Preferiti ❤️'**
  String get logicAddedToFavorites;

  /// No description provided for @logicRemovedFromFavorites.
  ///
  /// In it, this message translates to:
  /// **'Rimosso dai Preferiti 💔'**
  String get logicRemovedFromFavorites;

  /// No description provided for @logicFavoriteError.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'aggiornamento dei preferiti.'**
  String get logicFavoriteError;

  /// No description provided for @homeHeaderFiction.
  ///
  /// In it, this message translates to:
  /// **'NARRATIVA'**
  String get homeHeaderFiction;

  /// No description provided for @homeHeaderKnowledge.
  ///
  /// In it, this message translates to:
  /// **'CONOSCENZA & SVILUPPO'**
  String get homeHeaderKnowledge;

  /// No description provided for @homeHeaderOtherInterests.
  ///
  /// In it, this message translates to:
  /// **'ALTRI INTERESSI'**
  String get homeHeaderOtherInterests;

  /// No description provided for @homeHeaderFeaturedMovies.
  ///
  /// In it, this message translates to:
  /// **'FILM IN EVIDENZA'**
  String get homeHeaderFeaturedMovies;

  /// No description provided for @homeHeaderAction.
  ///
  /// In it, this message translates to:
  /// **'AZIONE & ADRENALINA'**
  String get homeHeaderAction;

  /// No description provided for @homeHeaderDrama.
  ///
  /// In it, this message translates to:
  /// **'SENTIMENTO & STORIA'**
  String get homeHeaderDrama;

  /// No description provided for @homeHeaderFantasy.
  ///
  /// In it, this message translates to:
  /// **'FANTASTICO & DARK'**
  String get homeHeaderFantasy;

  /// No description provided for @homeHeaderEntertainment.
  ///
  /// In it, this message translates to:
  /// **'INTRATTENIMENTO'**
  String get homeHeaderEntertainment;

  /// No description provided for @homeHeaderFeaturedTv.
  ///
  /// In it, this message translates to:
  /// **'SERIE TV IN EVIDENZA'**
  String get homeHeaderFeaturedTv;

  /// No description provided for @homeHeaderWonder.
  ///
  /// In it, this message translates to:
  /// **'SENSE OF WONDER'**
  String get homeHeaderWonder;

  /// No description provided for @homeHeaderTvDrama.
  ///
  /// In it, this message translates to:
  /// **'DRAMMA & TENSIONE'**
  String get homeHeaderTvDrama;

  /// No description provided for @homeHeaderTvEntertainment.
  ///
  /// In it, this message translates to:
  /// **'INTRATTENIMENTO TV'**
  String get homeHeaderTvEntertainment;

  /// No description provided for @homeTitleBestsellers.
  ///
  /// In it, this message translates to:
  /// **'Bestsellers & Classici'**
  String get homeTitleBestsellers;

  /// No description provided for @homeTitleThriller.
  ///
  /// In it, this message translates to:
  /// **'Thriller & Suspense'**
  String get homeTitleThriller;

  /// No description provided for @homeTitleSciFi.
  ///
  /// In it, this message translates to:
  /// **'Sci-Fi & Cyberpunk'**
  String get homeTitleSciFi;

  /// No description provided for @homeTitleFantasyEpico.
  ///
  /// In it, this message translates to:
  /// **'Fantasy Epico'**
  String get homeTitleFantasyEpico;

  /// No description provided for @homeTitleAdventure.
  ///
  /// In it, this message translates to:
  /// **'Avventura'**
  String get homeTitleAdventure;

  /// No description provided for @homeTitleRomance.
  ///
  /// In it, this message translates to:
  /// **'Romance & Love Stories'**
  String get homeTitleRomance;

  /// No description provided for @homeTitleHorror.
  ///
  /// In it, this message translates to:
  /// **'Horror & Dark'**
  String get homeTitleHorror;

  /// No description provided for @homeTitleMystery.
  ///
  /// In it, this message translates to:
  /// **'Gialli & Mistery'**
  String get homeTitleMystery;

  /// No description provided for @homeTitleHistoricalFiction.
  ///
  /// In it, this message translates to:
  /// **'Romanzi Storici'**
  String get homeTitleHistoricalFiction;

  /// No description provided for @homeTitleMindset.
  ///
  /// In it, this message translates to:
  /// **'Mindset & Crescita'**
  String get homeTitleMindset;

  /// No description provided for @homeTitleBusiness.
  ///
  /// In it, this message translates to:
  /// **'Business & Finanza'**
  String get homeTitleBusiness;

  /// No description provided for @homeTitlePsychology.
  ///
  /// In it, this message translates to:
  /// **'Psicologia'**
  String get homeTitlePsychology;

  /// No description provided for @homeTitlePhilosophy.
  ///
  /// In it, this message translates to:
  /// **'Filosofia'**
  String get homeTitlePhilosophy;

  /// No description provided for @homeTitleScience.
  ///
  /// In it, this message translates to:
  /// **'Scienza & Tecnologia'**
  String get homeTitleScience;

  /// No description provided for @homeTitleHistory.
  ///
  /// In it, this message translates to:
  /// **'Storia'**
  String get homeTitleHistory;

  /// No description provided for @homeTitleBiography.
  ///
  /// In it, this message translates to:
  /// **'Biografie'**
  String get homeTitleBiography;

  /// No description provided for @homeTitleArtDesign.
  ///
  /// In it, this message translates to:
  /// **'Arte & Design'**
  String get homeTitleArtDesign;

  /// No description provided for @homeTitleGraphicManga.
  ///
  /// In it, this message translates to:
  /// **'Graphic Novels & Manga'**
  String get homeTitleGraphicManga;

  /// No description provided for @homeTitleCooking.
  ///
  /// In it, this message translates to:
  /// **'Cucina & Food'**
  String get homeTitleCooking;

  /// No description provided for @homeTitleTravel.
  ///
  /// In it, this message translates to:
  /// **'Viaggi'**
  String get homeTitleTravel;

  /// No description provided for @homeTitleAction.
  ///
  /// In it, this message translates to:
  /// **'Azione'**
  String get homeTitleAction;

  /// No description provided for @homeTitleCrime.
  ///
  /// In it, this message translates to:
  /// **'Crime'**
  String get homeTitleCrime;

  /// No description provided for @homeTitleWar.
  ///
  /// In it, this message translates to:
  /// **'Guerra'**
  String get homeTitleWar;

  /// No description provided for @homeTitleDrama.
  ///
  /// In it, this message translates to:
  /// **'Drammatico'**
  String get homeTitleDrama;

  /// No description provided for @homeTitleWestern.
  ///
  /// In it, this message translates to:
  /// **'Western'**
  String get homeTitleWestern;

  /// No description provided for @homeTitleAnimation.
  ///
  /// In it, this message translates to:
  /// **'Animazione'**
  String get homeTitleAnimation;

  /// No description provided for @homeTitleComedy.
  ///
  /// In it, this message translates to:
  /// **'Commedia'**
  String get homeTitleComedy;

  /// No description provided for @homeTitleFamily.
  ///
  /// In it, this message translates to:
  /// **'Per la Famiglia'**
  String get homeTitleFamily;

  /// No description provided for @homeTitleMusic.
  ///
  /// In it, this message translates to:
  /// **'Musica'**
  String get homeTitleMusic;

  /// No description provided for @homeTitleDocumentaries.
  ///
  /// In it, this message translates to:
  /// **'Documentari'**
  String get homeTitleDocumentaries;

  /// No description provided for @homeTitleSciFiFantasy.
  ///
  /// In it, this message translates to:
  /// **'Sci-Fi & Fantasy'**
  String get homeTitleSciFiFantasy;

  /// No description provided for @homeTitleActionAdventure.
  ///
  /// In it, this message translates to:
  /// **'Action & Adventure'**
  String get homeTitleActionAdventure;

  /// No description provided for @homeTitleWarPolitics.
  ///
  /// In it, this message translates to:
  /// **'Guerra & Politica'**
  String get homeTitleWarPolitics;

  /// No description provided for @homeTitleSoap.
  ///
  /// In it, this message translates to:
  /// **'Soap Opera'**
  String get homeTitleSoap;

  /// No description provided for @homeTitleKids.
  ///
  /// In it, this message translates to:
  /// **'Kids'**
  String get homeTitleKids;

  /// No description provided for @homeTitleRealityTalk.
  ///
  /// In it, this message translates to:
  /// **'Reality & Talk'**
  String get homeTitleRealityTalk;

  /// No description provided for @sideMenuDataPortability.
  ///
  /// In it, this message translates to:
  /// **'PORTABILITÀ DATI'**
  String get sideMenuDataPortability;

  /// No description provided for @sideMenuImportLetterboxd.
  ///
  /// In it, this message translates to:
  /// **'Importa da Letterboxd'**
  String get sideMenuImportLetterboxd;

  /// No description provided for @importLetterboxdLoginRequired.
  ///
  /// In it, this message translates to:
  /// **'Devi essere loggato per importare i dati'**
  String get importLetterboxdLoginRequired;

  /// No description provided for @importLetterboxdSuccess.
  ///
  /// In it, this message translates to:
  /// **'Importazione completata con successo! 🎉'**
  String get importLetterboxdSuccess;

  /// No description provided for @importLetterboxdError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'importazione: {error}'**
  String importLetterboxdError(String error);

  /// No description provided for @importLetterboxdTitle.
  ///
  /// In it, this message translates to:
  /// **'Importa da Letterboxd'**
  String get importLetterboxdTitle;

  /// No description provided for @importLetterboxdHeadline.
  ///
  /// In it, this message translates to:
  /// **'Passa a CineShare in 30 secondi.'**
  String get importLetterboxdHeadline;

  /// No description provided for @importLetterboxdSubtitle.
  ///
  /// In it, this message translates to:
  /// **'I tuoi dati ti appartengono. Importa la tua storia cinematografica da Letterboxd senza sforzo.'**
  String get importLetterboxdSubtitle;

  /// No description provided for @importLetterboxdStep1.
  ///
  /// In it, this message translates to:
  /// **'Vai su Letterboxd.com > Settings > Export Data.'**
  String get importLetterboxdStep1;

  /// No description provided for @importLetterboxdStep2.
  ///
  /// In it, this message translates to:
  /// **'Estrai il file ZIP che ti hanno mandato.'**
  String get importLetterboxdStep2;

  /// No description provided for @importLetterboxdStep3.
  ///
  /// In it, this message translates to:
  /// **'Carica il file watched.csv, ratings.csv o reviews.csv qui.'**
  String get importLetterboxdStep3;

  /// No description provided for @importLetterboxdProgress.
  ///
  /// In it, this message translates to:
  /// **'Importazione in corso... {processed} / {total}'**
  String importLetterboxdProgress(int processed, int total);

  /// No description provided for @importLetterboxdButton.
  ///
  /// In it, this message translates to:
  /// **'Carica il file CSV'**
  String get importLetterboxdButton;

  /// No description provided for @sideMenuExportData.
  ///
  /// In it, this message translates to:
  /// **'Esporta i tuoi dati'**
  String get sideMenuExportData;

  /// No description provided for @exportDataSuccess.
  ///
  /// In it, this message translates to:
  /// **'Esportazione pronta! Condividi il file.'**
  String get exportDataSuccess;

  /// No description provided for @exportDataError.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'esportazione: {error}'**
  String exportDataError(String error);

  /// No description provided for @aiStudioTitle.
  ///
  /// In it, this message translates to:
  /// **'Studio AI'**
  String get aiStudioTitle;

  /// No description provided for @aiStudioSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Intelligenza cinematografica al tuo servizio.'**
  String get aiStudioSubtitle;

  /// No description provided for @aiStudioTokensRemaining.
  ///
  /// In it, this message translates to:
  /// **'{count} token rimanenti'**
  String aiStudioTokensRemaining(int count);

  /// No description provided for @aiStudioInsufficientTokens.
  ///
  /// In it, this message translates to:
  /// **'Token insufficienti. Te ne servono {cost}.'**
  String aiStudioInsufficientTokens(int cost);

  /// No description provided for @aiStudioOpening.
  ///
  /// In it, this message translates to:
  /// **'Apertura {name}…'**
  String aiStudioOpening(String name);

  /// No description provided for @aiFeatureVaultSyncTitle.
  ///
  /// In it, this message translates to:
  /// **'Vault Sync'**
  String get aiFeatureVaultSyncTitle;

  /// No description provided for @aiFeatureVaultSyncDesc.
  ///
  /// In it, this message translates to:
  /// **'Incrocia i Vault di due utenti per trovare il titolo perfetto per la serata. Esclude automaticamente ciò che hai già visto.'**
  String get aiFeatureVaultSyncDesc;

  /// No description provided for @aiFeatureVaultSyncBadge.
  ///
  /// In it, this message translates to:
  /// **'Max 3 sincronizzazioni/settimana'**
  String get aiFeatureVaultSyncBadge;

  /// No description provided for @aiFeatureWatchNowTitle.
  ///
  /// In it, this message translates to:
  /// **'What to Watch NOW'**
  String get aiFeatureWatchNowTitle;

  /// No description provided for @aiFeatureWatchNowDesc.
  ///
  /// In it, this message translates to:
  /// **'Vuoi uno sci-fi su Netflix stasera? L\'IA incrocia i tuoi abbonamenti con i tuoi gusti e risolve la serata in secondi.'**
  String get aiFeatureWatchNowDesc;

  /// No description provided for @aiFeatureWatchNowBadge.
  ///
  /// In it, this message translates to:
  /// **'Filtro streaming live'**
  String get aiFeatureWatchNowBadge;

  /// No description provided for @aiFeatureMoodTitle.
  ///
  /// In it, this message translates to:
  /// **'Mood Mapper'**
  String get aiFeatureMoodTitle;

  /// No description provided for @aiFeatureMoodDesc.
  ///
  /// In it, this message translates to:
  /// **'Mappa le emozioni post-visione con cursori. Analisi del mood mensile con suggerimenti calibrati su di te.'**
  String get aiFeatureMoodDesc;

  /// No description provided for @aiFeatureMoodBadge.
  ///
  /// In it, this message translates to:
  /// **'Analisi ultimo mese'**
  String get aiFeatureMoodBadge;

  /// No description provided for @aiFeatureShieldTitle.
  ///
  /// In it, this message translates to:
  /// **'Scudo Spoiler'**
  String get aiFeatureShieldTitle;

  /// No description provided for @aiFeatureShieldDesc.
  ///
  /// In it, this message translates to:
  /// **'Protezione attiva in tempo reale. L\'IA blurra i post della community oltre il tuo punto di progresso.'**
  String get aiFeatureShieldDesc;

  /// No description provided for @aiFeatureShieldBadge.
  ///
  /// In it, this message translates to:
  /// **'Protezione dinamica'**
  String get aiFeatureShieldBadge;

  /// No description provided for @aiFeatureMemoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Memory Forge'**
  String get aiFeatureMemoryTitle;

  /// No description provided for @aiFeatureMemoryDesc.
  ///
  /// In it, this message translates to:
  /// **'Recap personalizzato della trama fino al punto esatto salvato nel Vault. Riprendi le saghe dimenticate senza spoiler.'**
  String get aiFeatureMemoryDesc;

  /// No description provided for @aiFeatureMemoryBadge.
  ///
  /// In it, this message translates to:
  /// **'Anti-amnesia'**
  String get aiFeatureMemoryBadge;

  /// No description provided for @aiFeatureSceneTitle.
  ///
  /// In it, this message translates to:
  /// **'Scene Correlation'**
  String get aiFeatureSceneTitle;

  /// No description provided for @aiFeatureSceneDesc.
  ///
  /// In it, this message translates to:
  /// **'Carica un frame o uno spezzone video: l\'IA identifica l\'opera e suggerisce titoli correlati per stile, regia e trama.'**
  String get aiFeatureSceneDesc;

  /// No description provided for @aiFeatureSceneBadge.
  ///
  /// In it, this message translates to:
  /// **'Analisi visiva avanzata'**
  String get aiFeatureSceneBadge;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
