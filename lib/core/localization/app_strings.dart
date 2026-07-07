import '../constants/game_language.dart';

/// All literal UI strings, in English and Turkish. Emojis, brand names
/// (`CraftAI`), `AppConstants.appVersion`, and element names are dynamic /
/// language-independent and are not part of this class.
///
/// Usage: `final t = AppStrings.of(context.watch<SettingsProvider>().language);`
class AppStringsData {
  const AppStringsData({
    required this.navPlay,
    required this.navStats,
    required this.navSettings,
    required this.tagline,
    required this.continueWithGoogle,
    required this.continueAsGuest,
    required this.chooseHowToPlay,
    required this.gameModes,
    required this.mainGameBadge,
    required this.settingsHeroSubtitle,
    required this.noFavoritesYet,
    required this.freeModeTitle,
    required this.freeModeSubtitle,
    required this.targetModeTitle,
    required this.targetModeSubtitle,
    required this.challengeModeTitle,
    required this.challengeModeSubtitle,
    required this.alchemyTableModeTitle,
    required this.alchemyTableModeSubtitle,
    required this.alchemyTableHint,
    required this.alchemyFeatureTubes,
    required this.alchemyFeatureMortar,
    required this.alchemyFeatureMystical,
    required this.alchemyFeatureTap,
    required this.alchemyTapToContinue,
    required this.alchemyHowToPlayLabel,
    required this.alchemyHowToStep1,
    required this.alchemyHowToStep2,
    required this.alchemyHowToStep3,
    required this.alchemyHowToStep4,
    required this.alchemyBrewing,
    required this.startNewWorldTitle,
    required this.cancel,
    required this.reset,
    required this.yourWorlds,
    required this.freeModeEmptyHeader,
    required this.emptyTapToBegin,
    required this.resetWorldTooltip,
    required this.targetModeQuestion,
    required this.targetModeDescription,
    required this.targetModeHint,
    required this.start,
    required this.congratulations,
    required this.keepPlaying,
    required this.newTarget,
    required this.changeTarget,
    required this.discoveries,
    required this.clearTable,
    required this.sortTooltip,
    required this.sortByTime,
    required this.sortByName,
    required this.sortByEmoji,
    required this.sortByRandom,
    required this.elementsTabLabel,
    required this.dragToCombineHint,
    required this.overview,
    required this.totalDiscovered,
    required this.activeWorlds,
    required this.bestWorld,
    required this.saveSlots,
    required this.perWorld,
    required this.firstDiscoveries,
    required this.languagesPlayed,
    required this.perLanguage,
    required this.badgesTitle,
    required this.account,
    required this.challengeTimesSaved,
    required this.signOut,
    required this.signInWithGoogle,
    required this.appearance,
    required this.darkMode,
    required this.darkModeSubtitle,
    required this.feedback,
    required this.soundEffects,
    required this.soundEffectsSubtitle,
    required this.haptics,
    required this.hapticsSubtitle,
    required this.about,
    required this.howToPlay,
    required this.aboutCraftAI,
    required this.dangerZone,
    required this.resetAllWorlds,
    required this.howToPlayStep1,
    required this.howToPlayStep2,
    required this.howToPlayStep3,
    required this.howToPlayStep4,
    required this.gotIt,
    required this.aboutDescription,
    required this.resetAllWorldsTitle,
    required this.resetAllWorldsBody,
    required this.resetAll,
    required this.allWorldsReset,
    required this.signInForLeaderboard,
    required this.signIn,
    required this.todaysChallenge,
    required this.leaderboard,
    required this.noLeaderboardYet,
    required this.player,
    required this.viewLeaderboard,
    required this.dragElementsHere,
    required this.crafting,
    required this.challengeAppBarTitle,
    required this.languageSectionLabel,
    required this.languageSubtitle,
    required this.eraseWorldConfirm,
    required this.elementsDiscoveredSoFar,
    required this.worldTitle,
    required this.elementsDiscoveredCount,
    required this.firstDiscoveryToast,
    required this.youDiscovered,
    required this.discoveriesTitle,
    required this.searchHint,
    required this.noMatches,
    required this.signedInAs,
    required this.completedIn,
    required this.foundWordIn,
    required this.firstDiscoverySnack,
    required this.communitySuggestionsLabel,
    required this.suggestCombinationTile,
    required this.reviewSuggestionsTile,
    required this.suggestCombinationTitle,
    required this.suggestCombinationIntro,
    required this.elementALabel,
    required this.elementBLabel,
    required this.suggestedResultNameLabel,
    required this.suggestedResultEmojiLabel,
    required this.submitSuggestion,
    required this.suggestionSubmitted,
    required this.yourSuggestions,
    required this.noSuggestionsYet,
    required this.suggestionStatusPending,
    required this.suggestionStatusApproved,
    required this.suggestionStatusRejected,
    required this.reviewSuggestionsTitle,
    required this.noPendingSuggestions,
    required this.approve,
    required this.reject,
    required this.suggestedBy,
    required this.noCombinationMessage,
    required this.offlineError,
    required this.combineFailedError,
    required this.dailyQuestsTitle,
    required this.questCombine,
    required this.questDiscover,
    required this.share,
    required this.shareCardTitle,
    required this.shareDiscoveryText,
    required this.dailyReminder,
    required this.dailyReminderSubtitle,
    required this.dailyReminderNotifTitle,
    required this.dailyReminderNotifBody,
    required this.recipesTitle,
    required this.noRecipesKnown,
    required this.deleteAccount,
    required this.deleteAccountConfirmTitle,
    required this.deleteAccountConfirmBody,
    required this.deleteConfirmAction,
    required this.accountDeleted,
    required this.accountDeleteFailed,
  });

  // Login
  final String tagline;
  final String continueWithGoogle;
  final String continueAsGuest;

  // Worlds (mode picker)
  final String chooseHowToPlay;
  final String gameModes;
  final String mainGameBadge;
  final String settingsHeroSubtitle;
  final String noFavoritesYet;
  final String freeModeTitle;
  final String freeModeSubtitle;
  final String targetModeTitle;
  final String targetModeSubtitle;
  final String challengeModeTitle;
  final String challengeModeSubtitle;
  final String alchemyTableModeTitle;
  final String alchemyTableModeSubtitle;
  final String alchemyTableHint;
  final String alchemyFeatureTubes;
  final String alchemyFeatureMortar;
  final String alchemyFeatureMystical;
  final String alchemyFeatureTap;
  final String alchemyTapToContinue;
  final String alchemyHowToPlayLabel;
  final String alchemyHowToStep1;
  final String alchemyHowToStep2;
  final String alchemyHowToStep3;
  final String alchemyHowToStep4;
  final String alchemyBrewing;

  // Free Mode
  final String startNewWorldTitle;
  final String cancel;
  final String reset;
  final String yourWorlds;
  final String freeModeEmptyHeader;
  final String emptyTapToBegin;
  final String resetWorldTooltip;

  // Bottom nav
  final String navPlay;
  final String navStats;
  final String navSettings;

  // Target Mode
  final String targetModeQuestion;
  final String targetModeDescription;
  final String targetModeHint;
  final String start;
  final String congratulations;
  final String keepPlaying;
  final String newTarget;
  final String changeTarget;

  // Shared game screen
  final String discoveries;
  final String clearTable;
  final String sortTooltip;
  final String sortByTime;
  final String sortByName;
  final String sortByEmoji;
  final String sortByRandom;
  final String elementsTabLabel;
  final String dragToCombineHint;

  // Stats
  final String overview;
  final String totalDiscovered;
  final String activeWorlds;
  final String bestWorld;
  final String saveSlots;
  final String perWorld;
  final String firstDiscoveries;
  final String languagesPlayed;
  final String perLanguage;
  final String badgesTitle;

  // Settings
  final String account;
  final String challengeTimesSaved;
  final String signOut;
  final String signInWithGoogle;
  final String appearance;
  final String darkMode;
  final String darkModeSubtitle;
  final String feedback;
  final String soundEffects;
  final String soundEffectsSubtitle;
  final String haptics;
  final String hapticsSubtitle;
  final String about;
  final String howToPlay;
  final String aboutCraftAI;
  final String dangerZone;
  final String resetAllWorlds;
  final String howToPlayStep1;
  final String howToPlayStep2;
  final String howToPlayStep3;
  final String howToPlayStep4;
  final String gotIt;
  final String aboutDescription;
  final String resetAllWorldsTitle;
  final String resetAllWorldsBody;
  final String resetAll;
  final String allWorldsReset;
  final String languageSectionLabel;
  final String languageSubtitle;

  // Challenge Mode
  final String signInForLeaderboard;
  final String signIn;
  final String todaysChallenge;
  final String leaderboard;
  final String noLeaderboardYet;
  final String player;
  final String viewLeaderboard;
  final String challengeAppBarTitle;

  // Craft canvas
  final String dragElementsHere;
  final String crafting;

  // Dynamic / interpolated strings
  final String Function(String sessionId) eraseWorldConfirm;
  final String Function(int count) elementsDiscoveredSoFar;
  final String Function(String id) worldTitle;
  final String Function(int count) elementsDiscoveredCount;
  final String Function(String emoji, String name) firstDiscoveryToast;
  final String Function(String label) youDiscovered;
  final String Function(String sessionId) discoveriesTitle;
  final String Function(int count) searchHint;
  final String Function(String query) noMatches;
  final String Function(String name) signedInAs;
  final String Function(String time) completedIn;
  final String Function(String word, String time) foundWordIn;
  final String Function(String emoji, String name) firstDiscoverySnack;

  // Community suggestions (Turkish-only "A + B = C" feature)
  final String communitySuggestionsLabel;
  final String suggestCombinationTile;
  final String reviewSuggestionsTile;
  final String suggestCombinationTitle;
  final String suggestCombinationIntro;
  final String elementALabel;
  final String elementBLabel;
  final String suggestedResultNameLabel;
  final String suggestedResultEmojiLabel;
  final String submitSuggestion;
  final String suggestionSubmitted;
  final String yourSuggestions;
  final String noSuggestionsYet;
  final String suggestionStatusPending;
  final String suggestionStatusApproved;
  final String suggestionStatusRejected;
  final String reviewSuggestionsTitle;
  final String noPendingSuggestions;
  final String approve;
  final String reject;
  final String Function(String name) suggestedBy;

  // Combine errors (localized; shown as snackbars in-game)
  final String noCombinationMessage;
  final String offlineError;
  final String combineFailedError;

  // Daily quests (Stats tab)
  final String dailyQuestsTitle;
  final String Function(int n) questCombine;
  final String Function(int n) questDiscover;

  // Discovery sharing
  final String share;
  final String shareCardTitle;
  final String Function(String name) shareDiscoveryText;

  // Daily challenge reminder (local notification)
  final String dailyReminder;
  final String dailyReminderSubtitle;
  final String dailyReminderNotifTitle;
  final String dailyReminderNotifBody;

  // Element encyclopedia (recipes)
  final String recipesTitle;
  final String noRecipesKnown;

  // Account deletion (Google Play / KVKK requirement)
  final String deleteAccount;
  final String deleteAccountConfirmTitle;
  final String deleteAccountConfirmBody;
  final String deleteConfirmAction;
  final String accountDeleted;
  final String accountDeleteFailed;
}

final _en = AppStringsData(
  navPlay: 'Play',
  navStats: 'Stats',
  navSettings: 'Settings',
  tagline: 'Combine elements, discover everything.',
  continueWithGoogle: 'Continue with Google',
  continueAsGuest: 'Continue as Guest',
  chooseHowToPlay: 'Choose how you want to play',
  gameModes: 'Game modes',
  mainGameBadge: 'MAIN GAME',
  settingsHeroSubtitle: 'Personalize your experience',
  noFavoritesYet: 'No favorites yet — long-press an element to star it',
  freeModeTitle: 'Space Mode',
  freeModeSubtitle: 'Craft freely on an infinite space canvas',
  targetModeTitle: 'Target Mode',
  targetModeSubtitle: 'Pick a word and race to discover it',
  challengeModeTitle: 'Challenge Mode',
  challengeModeSubtitle: "Today's word, timed — climb the leaderboard",
  alchemyTableModeTitle: 'Alchemy Table',
  alchemyTableModeSubtitle: 'A mystical 2.5D lab — tap to brew in the mortar',
  alchemyTableHint: 'Select two elements to combine in the mortar',
  alchemyFeatureTubes: '2 Test tubes',
  alchemyFeatureMortar: 'Mortar & pestle',
  alchemyFeatureMystical: 'Mystical 2.5D',
  alchemyFeatureTap: 'Tap to brew',
  alchemyTapToContinue: 'Tap to continue brewing',
  alchemyHowToPlayLabel: '✨  How to play',
  alchemyHowToStep1: 'Tap any element in the tray to fill Tube A',
  alchemyHowToStep2: 'Tap a second element to fill Tube B',
  alchemyHowToStep3:
      'Watch the mortar grind them together and reveal a new element!',
  alchemyHowToStep4: "Not every pair combines — keep experimenting!",
  alchemyBrewing: 'Brewing...',
  startNewWorldTitle: 'Start a new world?',
  cancel: 'Cancel',
  reset: 'Reset',
  yourWorlds: 'Your worlds',
  freeModeEmptyHeader: 'Combine elements, discover everything',
  emptyTapToBegin: 'Empty - tap to begin',
  resetWorldTooltip: 'Reset world',
  targetModeQuestion: 'What word do you want to discover?',
  targetModeDescription:
      'Start from the basics and keep combining until you craft this exact '
      'word. Your progress is saved between attempts.',
  targetModeHint: 'e.g. Robot, Volcano, Castle...',
  start: 'Start',
  congratulations: '🎉 Congratulations!',
  keepPlaying: 'Keep playing',
  newTarget: 'New target',
  changeTarget: 'Change target',
  discoveries: 'Discoveries',
  clearTable: 'Clear table',
  sortTooltip: 'Sort elements',
  sortByTime: 'Discovery order',
  sortByName: 'Name (A-Z)',
  sortByEmoji: 'Emoji',
  sortByRandom: 'Shuffle',
  elementsTabLabel: 'Elements',
  dragToCombineHint: '· drag to combine',
  overview: 'Overview',
  totalDiscovered: 'Total discovered',
  activeWorlds: 'Active worlds',
  bestWorld: 'Best world',
  saveSlots: 'Save slots',
  perWorld: 'Per world',
  firstDiscoveries: 'World-first discoveries',
  languagesPlayed: 'Languages played',
  perLanguage: 'Per language',
  badgesTitle: 'Badges',
  account: 'Account',
  challengeTimesSaved: 'Your Challenge Mode times are saved to the leaderboard',
  signOut: 'Sign out',
  signInWithGoogle: 'Sign in with Google',
  appearance: 'Appearance',
  darkMode: 'Dark mode',
  darkModeSubtitle: 'Easier on the eyes at night',
  feedback: 'Feedback',
  soundEffects: 'Sound effects',
  soundEffectsSubtitle: 'Play sounds when crafting',
  haptics: 'Haptics',
  hapticsSubtitle: 'Vibrate on combine & discovery',
  about: 'About',
  howToPlay: 'How to play',
  aboutCraftAI: 'About CraftAI',
  dangerZone: 'Danger zone',
  resetAllWorlds: 'Reset all worlds',
  howToPlayStep1: '1. Drag an element from the tray onto the table.',
  howToPlayStep2: '2. Drop one element on top of another to combine them.',
  howToPlayStep3: '3. Discover new elements — some may be a world-first! 🎉',
  howToPlayStep4: '4. Not every pair combines. Keep experimenting!',
  gotIt: 'Got it',
  aboutDescription:
      'An infinite crafting game. Combine elements to discover everything — '
      'powered by AI for brand-new combinations no one has found before.',
  resetAllWorldsTitle: 'Reset all worlds?',
  resetAllWorldsBody:
      'This erases progress in every world on this device. Discoveries '
      'shared online are not affected. This cannot be undone.',
  resetAll: 'Reset all',
  allWorldsReset: 'All worlds reset.',
  languageSectionLabel: 'Language',
  languageSubtitle:
      'Switching language starts a separate set of worlds, with their own '
      'progress and leaderboards.',
  signInForLeaderboard: "Sign in with Google to appear on today's leaderboard.",
  signIn: 'Sign in',
  todaysChallenge: "🏆 Today's Challenge",
  leaderboard: 'Leaderboard',
  noLeaderboardYet:
      "🏆 No one on the board yet — find today's word now and claim the top spot!",
  player: 'Player',
  viewLeaderboard: 'View leaderboard',
  challengeAppBarTitle: '🏆 Challenge',
  dragElementsHere: 'Drag elements here to combine them',
  crafting: 'Crafting...',
  eraseWorldConfirm: (sessionId) =>
      'This will erase all elements discovered in World $sessionId on this '
      'device. This cannot be undone.',
  elementsDiscoveredSoFar: (count) => '$count elements discovered so far',
  worldTitle: (id) => 'World $id',
  elementsDiscoveredCount: (count) => '$count elements discovered',
  firstDiscoveryToast: (emoji, name) =>
      '🎉 First discovery in the world: $emoji $name',
  youDiscovered: (label) => 'You discovered $label!',
  discoveriesTitle: (sessionId) => 'World $sessionId · Discoveries',
  searchHint: (count) => 'Search $count discoveries...',
  noMatches: (query) => 'No elements match "$query"',
  signedInAs: (name) => 'Signed in as $name',
  completedIn: (time) => '✅ Completed in $time',
  foundWordIn: (word, time) => "You found '$word' in $time!",
  firstDiscoverySnack: (emoji, name) => '🌟 First discovery: $emoji $name!',
  communitySuggestionsLabel: 'Community Suggestions',
  suggestCombinationTile: 'Suggest a combination',
  reviewSuggestionsTile: 'Review suggestions (Admin)',
  suggestCombinationTitle: 'Suggest a Combination',
  suggestCombinationIntro:
      'Think a combination should give a different result? Suggest it '
      "below — if approved, it'll become the new result for everyone.",
  elementALabel: '1st element',
  elementBLabel: '2nd element',
  suggestedResultNameLabel: 'Suggested result name',
  suggestedResultEmojiLabel: 'Suggested result emoji',
  submitSuggestion: 'Submit',
  suggestionSubmitted: 'Suggestion submitted, thank you!',
  yourSuggestions: 'Your suggestions',
  noSuggestionsYet: "You haven't submitted any suggestions yet.",
  suggestionStatusPending: 'Pending',
  suggestionStatusApproved: 'Approved',
  suggestionStatusRejected: 'Rejected',
  reviewSuggestionsTitle: 'Review Suggestions',
  noPendingSuggestions: 'No pending suggestions.',
  approve: 'Approve',
  reject: 'Reject',
  suggestedBy: (name) => 'Suggested by: $name',
  noCombinationMessage: "🤔 These don't seem to combine into anything.",
  offlineError: '📡 No internet connection — check your network and try again.',
  combineFailedError: 'Something went wrong — please try again.',
  dailyQuestsTitle: 'Daily quests',
  questCombine: (n) => 'Make $n combinations',
  questDiscover: (n) => 'Discover $n new elements',
  share: 'Share',
  shareCardTitle: 'New discovery!',
  shareDiscoveryText: (name) =>
      'I discovered "$name" in CraftAI! 🧪 Can you craft it too?',
  dailyReminder: 'Daily challenge reminder',
  dailyReminderSubtitle: 'Get notified when a new daily word is ready',
  dailyReminderNotifTitle: "Today's challenge is ready! 🏆",
  dailyReminderNotifBody: 'A new word is waiting — can you craft it fastest?',
  recipesTitle: 'Known recipes',
  noRecipesKnown:
      'No recipes found on this device yet — this may be a starting element.',
  deleteAccount: 'Delete my account',
  deleteAccountConfirmTitle: 'Delete account?',
  deleteAccountConfirmBody:
      'This permanently deletes your account, cloud backup, challenge times '
      'and suggestions. Local progress on this device stays. This cannot be '
      'undone.',
  deleteConfirmAction: 'Delete',
  accountDeleted: 'Your account has been deleted.',
  accountDeleteFailed: 'Account deletion failed — please try again.',
);

final _tr = AppStringsData(
  navPlay: 'Oyna',
  navStats: 'İstatistik',
  navSettings: 'Ayarlar',
  tagline: 'Elementleri birleştir, her şeyi keşfet.',
  continueWithGoogle: 'Google ile devam et',
  continueAsGuest: 'Misafir olarak devam et',
  chooseHowToPlay: 'Nasıl oynamak istediğini seç',
  gameModes: 'Oyun modları',
  mainGameBadge: 'ANA OYUN',
  settingsHeroSubtitle: 'Deneyimini kişiselleştir',
  noFavoritesYet: 'Henüz favori yok — yıldızlamak için bir elemente uzun bas',
  freeModeTitle: 'Uzay Modu',
  freeModeSubtitle: 'Sonsuz uzay tuvalinde özgürce birleştir',
  targetModeTitle: 'Hedef Mod',
  targetModeSubtitle: 'Bir kelime seç ve onu keşfetmek için yarış',
  challengeModeTitle: 'Yarışma Modu',
  challengeModeSubtitle: 'Günün kelimesi, süreyle — lider tablosunda yüksel',
  alchemyTableModeTitle: 'Simya Masası',
  alchemyTableModeSubtitle: 'Gizemli 2.5D laboratuvar — havanda demle!',
  alchemyTableHint: 'Havanda birleştirmek için iki element seç',
  alchemyFeatureTubes: '2 Deney Tüpü',
  alchemyFeatureMortar: 'Havan ve Tokmak',
  alchemyFeatureMystical: 'Gizemli 2.5D',
  alchemyFeatureTap: 'Demlemek için dokun',
  alchemyTapToContinue: 'Demlemeye devam etmek için dokun',
  alchemyHowToPlayLabel: '✨  Nasıl oynanır',
  alchemyHowToStep1: 'Tüp A\'yı doldurmak için tepsiden bir elemente dokun',
  alchemyHowToStep2: 'Tüp B\'yi doldurmak için ikinci bir elemente dokun',
  alchemyHowToStep3:
      'Havanın onları birleştirip yeni bir element ortaya çıkarmasını izle!',
  alchemyHowToStep4: 'Her çift birleşmez — denemeye devam et!',
  alchemyBrewing: 'Demleniyor...',
  startNewWorldTitle: 'Yeni bir dünyaya mı başlansın?',
  cancel: 'Vazgeç',
  reset: 'Sıfırla',
  yourWorlds: 'Dünyaların',
  freeModeEmptyHeader: 'Elementleri birleştir, her şeyi keşfet',
  emptyTapToBegin: 'Boş - başlamak için dokun',
  resetWorldTooltip: 'Dünyayı sıfırla',
  targetModeQuestion: 'Hangi kelimeyi keşfetmek istiyorsun?',
  targetModeDescription:
      'Temel elementlerden başla ve tam olarak bu kelimeyi elde edene kadar '
      'birleştirmeye devam et. İlerlemen denemeler arasında kaydedilir.',
  targetModeHint: 'örn. Robot, Volkan, Kale...',
  start: 'Başla',
  congratulations: '🎉 Tebrikler!',
  keepPlaying: 'Oynamaya devam et',
  newTarget: 'Yeni hedef',
  changeTarget: 'Hedefi değiştir',
  discoveries: 'Keşifler',
  clearTable: 'Masayı temizle',
  sortTooltip: 'Elementleri sırala',
  sortByTime: 'Keşif sırası',
  sortByName: 'İsim (A-Z)',
  sortByEmoji: 'Emoji',
  sortByRandom: 'Karıştır',
  elementsTabLabel: 'Elementler',
  dragToCombineHint: '· birleştirmek için sürükle',
  overview: 'Genel Bakış',
  totalDiscovered: 'Toplam keşif',
  activeWorlds: 'Aktif dünyalar',
  bestWorld: 'En iyi dünya',
  saveSlots: 'Kayıt yuvaları',
  perWorld: 'Dünya başına',
  firstDiscoveries: 'Dünyada ilk keşfedilen',
  languagesPlayed: 'Oynanan diller',
  perLanguage: 'Dil başına',
  badgesTitle: 'Rozetler',
  account: 'Hesap',
  challengeTimesSaved: 'Yarışma Modu sürelerin lider tablosuna kaydediliyor',
  signOut: 'Çıkış yap',
  signInWithGoogle: 'Google ile giriş yap',
  appearance: 'Görünüm',
  darkMode: 'Karanlık mod',
  darkModeSubtitle: 'Geceleri gözlere daha az yorucu',
  feedback: 'Geri Bildirim',
  soundEffects: 'Ses efektleri',
  soundEffectsSubtitle: 'Birleştirirken ses çal',
  haptics: 'Titreşim',
  hapticsSubtitle: 'Birleştirme ve keşifte titret',
  about: 'Hakkında',
  howToPlay: 'Nasıl oynanır',
  aboutCraftAI: 'CraftAI Hakkında',
  dangerZone: 'Tehlikeli bölge',
  resetAllWorlds: 'Tüm dünyaları sıfırla',
  howToPlayStep1: '1. Tepsiden bir elementi sürükleyip masaya bırak.',
  howToPlayStep2:
      '2. Bir elementi başka bir elementin üzerine bırakarak birleştir.',
  howToPlayStep3:
      '3. Yeni elementler keşfet — bazıları dünya çapında ilk olabilir! 🎉',
  howToPlayStep4: '4. Her çift birleşmez. Denemeye devam et!',
  gotIt: 'Anladım',
  aboutDescription:
      'Sonsuz bir üretim oyunu. Her şeyi keşfetmek için elementleri '
      'birleştir — kimsenin daha önce bulmadığı yepyeni kombinasyonlar için '
      'yapay zeka ile desteklenir.',
  resetAllWorldsTitle: 'Tüm dünyalar sıfırlansın mı?',
  resetAllWorldsBody:
      'Bu, bu cihazdaki tüm dünyalardaki ilerlemeyi siler. Çevrimiçi '
      'paylaşılan keşifler bundan etkilenmez. Bu işlem geri alınamaz.',
  resetAll: 'Tümünü sıfırla',
  allWorldsReset: 'Tüm dünyalar sıfırlandı.',
  languageSectionLabel: 'Dil',
  languageSubtitle:
      'Dili değiştirmek, kendi ilerlemesi ve lider tablosu olan ayrı bir '
      'dünya setine geçer.',
  signInForLeaderboard:
      'Bugünün lider tablosunda görünmek için Google ile giriş yap.',
  signIn: 'Giriş yap',
  todaysChallenge: '🏆 Günün Yarışması',
  leaderboard: 'Lider Tablosu',
  noLeaderboardYet:
      '🏆 Tabloda henüz kimse yok — günün kelimesini hemen bul, ilk sıraya yerleş!',
  player: 'Oyuncu',
  viewLeaderboard: 'Lider tablosunu gör',
  challengeAppBarTitle: '🏆 Yarışma',
  dragElementsHere: 'Birleştirmek için elementleri buraya sürükle',
  crafting: 'Üretiliyor...',
  eraseWorldConfirm: (sessionId) =>
      'Bu, bu cihazdaki $sessionId numaralı Dünyada keşfedilen tüm '
      'elementleri silecek. Bu işlem geri alınamaz.',
  elementsDiscoveredSoFar: (count) => 'Şimdiye kadar $count element keşfedildi',
  worldTitle: (id) => 'Dünya $id',
  elementsDiscoveredCount: (count) => '$count element keşfedildi',
  firstDiscoveryToast: (emoji, name) => '🎉 Dünyada ilk keşif: $emoji $name',
  youDiscovered: (label) => '$label keşfedildi!',
  discoveriesTitle: (sessionId) => 'Dünya $sessionId · Keşifler',
  searchHint: (count) => '$count keşif içinde ara...',
  noMatches: (query) => '"$query" ile eşleşen element yok',
  signedInAs: (name) => '$name olarak giriş yapıldı',
  completedIn: (time) => '✅ $time sürede tamamlandı',
  foundWordIn: (word, time) => "'$word' kelimesini $time sürede buldun!",
  firstDiscoverySnack: (emoji, name) => '🌟 İlk keşif: $emoji $name!',
  communitySuggestionsLabel: 'Topluluk Önerileri',
  suggestCombinationTile: 'Kombinasyon öner',
  reviewSuggestionsTile: 'Önerileri incele (Admin)',
  suggestCombinationTitle: 'Kombinasyon Öner',
  suggestCombinationIntro:
      'Bir kombinasyonun farklı bir sonuç vermesi gerektiğini mi '
      'düşünüyorsun? Aşağıdan öner — onaylanırsa herkes için yeni sonuç bu '
      'olur.',
  elementALabel: '1. element',
  elementBLabel: '2. element',
  suggestedResultNameLabel: 'Önerilen sonuç ismi',
  suggestedResultEmojiLabel: 'Önerilen sonuç emojisi',
  submitSuggestion: 'Gönder',
  suggestionSubmitted: 'Öneri gönderildi, teşekkürler!',
  yourSuggestions: 'Önerilerin',
  noSuggestionsYet: 'Henüz bir öneri göndermedin.',
  suggestionStatusPending: 'Bekliyor',
  suggestionStatusApproved: 'Onaylandı',
  suggestionStatusRejected: 'Reddedildi',
  reviewSuggestionsTitle: 'Önerileri İncele',
  noPendingSuggestions: 'Bekleyen öneri yok.',
  approve: 'Onayla',
  reject: 'Reddet',
  suggestedBy: (name) => 'Öneren: $name',
  noCombinationMessage: '🤔 Bu ikisi birleşip bir şey oluşturmuyor gibi.',
  offlineError:
      '📡 İnternet bağlantısı yok — bağlantını kontrol edip tekrar dene.',
  combineFailedError: 'Bir şeyler ters gitti — lütfen tekrar dene.',
  dailyQuestsTitle: 'Günlük görevler',
  questCombine: (n) => '$n birleştirme yap',
  questDiscover: (n) => '$n yeni element keşfet',
  share: 'Paylaş',
  shareCardTitle: 'Yeni keşif!',
  shareDiscoveryText: (name) =>
      'CraftAI\'da "$name" keşfettim! 🧪 Sen de bulabilir misin?',
  dailyReminder: 'Günlük yarışma hatırlatıcısı',
  dailyReminderSubtitle: 'Yeni günün kelimesi hazır olunca haber ver',
  dailyReminderNotifTitle: 'Bugünün yarışması hazır! 🏆',
  dailyReminderNotifBody:
      'Yeni bir kelime seni bekliyor — en hızlı sen bulabilir misin?',
  recipesTitle: 'Bilinen tarifler',
  noRecipesKnown: 'Bu cihazda henüz tarifi yok — başlangıç elementi olabilir.',
  deleteAccount: 'Hesabımı sil',
  deleteAccountConfirmTitle: 'Hesap silinsin mi?',
  deleteAccountConfirmBody:
      'Hesabın, bulut yedeğin, yarışma sürelerin ve önerilerin kalıcı olarak '
      'silinir. Bu cihazdaki yerel ilerleme durur. Bu işlem geri alınamaz.',
  deleteConfirmAction: 'Sil',
  accountDeleted: 'Hesabın silindi.',
  accountDeleteFailed: 'Hesap silinemedi — lütfen tekrar dene.',
);

final _de = AppStringsData(
  navPlay: 'Spielen',
  navStats: 'Statistik',
  navSettings: 'Einstellungen',
  tagline: 'Elemente kombinieren, alles entdecken.',
  continueWithGoogle: 'Mit Google fortfahren',
  continueAsGuest: 'Als Gast fortfahren',
  chooseHowToPlay: 'Wähle, wie du spielen möchtest',
  gameModes: 'Spielmodi',
  mainGameBadge: 'HAUPTSPIEL',
  settingsHeroSubtitle: 'Personalisiere dein Erlebnis',
  noFavoritesYet:
      'Noch keine Favoriten — halte ein Element gedrückt, um es zu markieren',
  freeModeTitle: 'Weltraum-Modus',
  freeModeSubtitle: 'Kombiniere frei auf einer endlosen Weltraum-Leinwand',
  targetModeTitle: 'Zielmodus',
  targetModeSubtitle: 'Wähle ein Wort und race, um es zu entdecken',
  challengeModeTitle: 'Herausforderungsmodus',
  challengeModeSubtitle:
      'Das heutige Wort, zeitgesteuert — erklimme die Rangliste',
  alchemyTableModeTitle: 'Alchemietisch',
  alchemyTableModeSubtitle: 'Ein mystisches 2,5D-Labor — tippe und braue!',
  alchemyTableHint: 'Wähle zwei Elemente zum Kombinieren im Mörser',
  alchemyFeatureTubes: '2 Reagenzgläser',
  alchemyFeatureMortar: 'Mörser & Stößel',
  alchemyFeatureMystical: 'Mystisches 2,5D',
  alchemyFeatureTap: 'Zum Brauen tippen',
  alchemyTapToContinue: 'Tippen, um weiter zu brauen',
  alchemyHowToPlayLabel: '✨  So spielst du',
  alchemyHowToStep1: 'Tippe ein Element im Tablett an, um Röhrchen A zu füllen',
  alchemyHowToStep2: 'Tippe ein zweites Element an, um Röhrchen B zu füllen',
  alchemyHowToStep3:
      'Sieh zu, wie der Mörser sie zerkleinert und ein neues Element enthüllt!',
  alchemyHowToStep4:
      'Nicht jedes Paar kombiniert sich — experimentiere weiter!',
  alchemyBrewing: 'Brauen...',
  startNewWorldTitle: 'Eine neue Welt beginnen?',
  cancel: 'Abbrechen',
  reset: 'Zurücksetzen',
  yourWorlds: 'Deine Welten',
  freeModeEmptyHeader: 'Elemente kombinieren, alles entdecken',
  emptyTapToBegin: 'Leer – tippen zum Starten',
  resetWorldTooltip: 'Welt zurücksetzen',
  targetModeQuestion: 'Welches Wort möchtest du entdecken?',
  targetModeDescription:
      'Beginne mit den Grundelementen und kombiniere weiter, bis du genau '
      'dieses Wort erschaffst. Dein Fortschritt wird gespeichert.',
  targetModeHint: 'z. B. Roboter, Vulkan, Burg...',
  start: 'Starten',
  congratulations: '🎉 Glückwunsch!',
  keepPlaying: 'Weiter spielen',
  newTarget: 'Neues Ziel',
  changeTarget: 'Ziel ändern',
  discoveries: 'Entdeckungen',
  clearTable: 'Tisch leeren',
  sortTooltip: 'Elemente sortieren',
  sortByTime: 'Entdeckungsreihenfolge',
  sortByName: 'Name (A-Z)',
  sortByEmoji: 'Emoji',
  sortByRandom: 'Zufällig',
  elementsTabLabel: 'Elemente',
  dragToCombineHint: '· ziehen zum Kombinieren',
  overview: 'Übersicht',
  totalDiscovered: 'Gesamt entdeckt',
  activeWorlds: 'Aktive Welten',
  bestWorld: 'Beste Welt',
  saveSlots: 'Speicherplätze',
  perWorld: 'Pro Welt',
  firstDiscoveries: 'Welt-Ersttdeckungen',
  languagesPlayed: 'Gespielte Sprachen',
  perLanguage: 'Pro Sprache',
  badgesTitle: 'Abzeichen',
  account: 'Konto',
  challengeTimesSaved:
      'Deine Zeiten im Herausforderungsmodus werden in der Rangliste gespeichert',
  signOut: 'Abmelden',
  signInWithGoogle: 'Mit Google anmelden',
  appearance: 'Erscheinungsbild',
  darkMode: 'Dunkelmodus',
  darkModeSubtitle: 'Augenschonender bei Nacht',
  feedback: 'Rückmeldung',
  soundEffects: 'Soundeffekte',
  soundEffectsSubtitle: 'Töne beim Kombinieren abspielen',
  haptics: 'Haptik',
  hapticsSubtitle: 'Vibration beim Kombinieren & Entdecken',
  about: 'Über',
  howToPlay: 'Spielanleitung',
  aboutCraftAI: 'Über CraftAI',
  dangerZone: 'Gefahrenzone',
  resetAllWorlds: 'Alle Welten zurücksetzen',
  howToPlayStep1: '1. Ziehe ein Element aus der Leiste auf den Tisch.',
  howToPlayStep2: '2. Lege ein Element auf ein anderes, um sie zu kombinieren.',
  howToPlayStep3:
      '3. Entdecke neue Elemente — manche sind weltweite Erstentdeckungen! 🎉',
  howToPlayStep4: '4. Nicht jedes Paar kombiniert sich. Experimentiere weiter!',
  gotIt: 'Verstanden',
  aboutDescription:
      'Ein unendliches Kombinationsspiel. Kombiniere Elemente, um alles zu '
      'entdecken — mit KI für brandneue Kombinationen, die noch niemand gefunden hat.',
  resetAllWorldsTitle: 'Alle Welten zurücksetzen?',
  resetAllWorldsBody:
      'Dies löscht den Fortschritt in allen Welten auf diesem Gerät. '
      'Online geteilte Entdeckungen sind nicht betroffen. Dies kann nicht rückgängig gemacht werden.',
  resetAll: 'Alle zurücksetzen',
  allWorldsReset: 'Alle Welten zurückgesetzt.',
  languageSectionLabel: 'Sprache',
  languageSubtitle:
      'Das Wechseln der Sprache startet ein separates Set von Welten mit '
      'eigenem Fortschritt und eigener Rangliste.',
  signInForLeaderboard:
      'Melde dich mit Google an, um in der heutigen Rangliste zu erscheinen.',
  signIn: 'Anmelden',
  todaysChallenge: '🏆 Heutige Herausforderung',
  leaderboard: 'Rangliste',
  noLeaderboardYet:
      '🏆 Noch niemand auf dem Board — finde das Tageswort und sichere dir Platz 1!',
  player: 'Spieler',
  viewLeaderboard: 'Rangliste anzeigen',
  challengeAppBarTitle: '🏆 Herausforderung',
  dragElementsHere: 'Elemente hierher ziehen, um sie zu kombinieren',
  crafting: 'Kombiniere...',
  eraseWorldConfirm: (sessionId) =>
      'Hiermit werden alle in Welt $sessionId entdeckten Elemente auf diesem '
      'Gerät gelöscht. Dies kann nicht rückgängig gemacht werden.',
  elementsDiscoveredSoFar: (count) => '$count Elemente bisher entdeckt',
  worldTitle: (id) => 'Welt $id',
  elementsDiscoveredCount: (count) => '$count Elemente entdeckt',
  firstDiscoveryToast: (emoji, name) =>
      '🎉 Weltweite Erstentdeckung: $emoji $name',
  youDiscovered: (label) => 'Du hast $label entdeckt!',
  discoveriesTitle: (sessionId) => 'Welt $sessionId · Entdeckungen',
  searchHint: (count) => '$count Entdeckungen durchsuchen...',
  noMatches: (query) => 'Keine Elemente entsprechen "$query"',
  signedInAs: (name) => 'Angemeldet als $name',
  completedIn: (time) => '✅ Abgeschlossen in $time',
  foundWordIn: (word, time) => 'Du hast "$word" in $time gefunden!',
  firstDiscoverySnack: (emoji, name) => '🌟 Erstentdeckung: $emoji $name!',
  communitySuggestionsLabel: 'Community-Vorschläge',
  suggestCombinationTile: 'Kombination vorschlagen',
  reviewSuggestionsTile: 'Vorschläge prüfen (Admin)',
  suggestCombinationTitle: 'Kombination vorschlagen',
  suggestCombinationIntro:
      'Denkst du, eine Kombination sollte ein anderes Ergebnis liefern? '
      'Schlage es unten vor — wenn genehmigt, wird es das neue Ergebnis für alle.',
  elementALabel: '1. Element',
  elementBLabel: '2. Element',
  suggestedResultNameLabel: 'Vorgeschlagener Ergebnisname',
  suggestedResultEmojiLabel: 'Vorgeschlagenes Ergebnis-Emoji',
  submitSuggestion: 'Einreichen',
  suggestionSubmitted: 'Vorschlag eingereicht, danke!',
  yourSuggestions: 'Deine Vorschläge',
  noSuggestionsYet: 'Du hast noch keine Vorschläge eingereicht.',
  suggestionStatusPending: 'Ausstehend',
  suggestionStatusApproved: 'Genehmigt',
  suggestionStatusRejected: 'Abgelehnt',
  reviewSuggestionsTitle: 'Vorschläge prüfen',
  noPendingSuggestions: 'Keine ausstehenden Vorschläge.',
  approve: 'Genehmigen',
  reject: 'Ablehnen',
  suggestedBy: (name) => 'Vorgeschlagen von: $name',
  noCombinationMessage: '🤔 Diese beiden scheinen sich zu nichts zu verbinden.',
  offlineError:
      '📡 Keine Internetverbindung — prüfe dein Netzwerk und versuche es erneut.',
  combineFailedError: 'Etwas ist schiefgelaufen — bitte versuche es erneut.',
  dailyQuestsTitle: 'Tägliche Aufgaben',
  questCombine: (n) => 'Mache $n Kombinationen',
  questDiscover: (n) => 'Entdecke $n neue Elemente',
  share: 'Teilen',
  shareCardTitle: 'Neue Entdeckung!',
  shareDiscoveryText: (name) =>
      'Ich habe "$name" in CraftAI entdeckt! 🧪 Schaffst du es auch?',
  dailyReminder: 'Tägliche Challenge-Erinnerung',
  dailyReminderSubtitle:
      'Benachrichtige mich, wenn ein neues Tageswort bereit ist',
  dailyReminderNotifTitle: 'Die heutige Challenge ist bereit! 🏆',
  dailyReminderNotifBody: 'Ein neues Wort wartet — bist du am schnellsten?',
  recipesTitle: 'Bekannte Rezepte',
  noRecipesKnown:
      'Noch keine Rezepte auf diesem Gerät — vielleicht ein Startelement.',
  deleteAccount: 'Mein Konto löschen',
  deleteAccountConfirmTitle: 'Konto löschen?',
  deleteAccountConfirmBody:
      'Dein Konto, Cloud-Backup, Challenge-Zeiten und Vorschläge werden '
      'dauerhaft gelöscht. Lokaler Fortschritt auf diesem Gerät bleibt. '
      'Das kann nicht rückgängig gemacht werden.',
  deleteConfirmAction: 'Löschen',
  accountDeleted: 'Dein Konto wurde gelöscht.',
  accountDeleteFailed: 'Kontolöschung fehlgeschlagen — bitte erneut versuchen.',
);

final _es = AppStringsData(
  navPlay: 'Jugar',
  navStats: 'Estadísticas',
  navSettings: 'Ajustes',
  tagline: 'Combina elementos, descubre todo.',
  continueWithGoogle: 'Continuar con Google',
  continueAsGuest: 'Continuar como invitado',
  chooseHowToPlay: 'Elige cómo quieres jugar',
  gameModes: 'Modos de juego',
  mainGameBadge: 'JUEGO PRINCIPAL',
  settingsHeroSubtitle: 'Personaliza tu experiencia',
  noFavoritesYet:
      'Aún no hay favoritos — mantén pulsado un elemento para marcarlo',
  freeModeTitle: 'Modo Espacial',
  freeModeSubtitle: 'Combina libremente en un lienzo espacial infinito',
  targetModeTitle: 'Modo Objetivo',
  targetModeSubtitle: 'Elige una palabra y compite para descubrirla',
  challengeModeTitle: 'Modo Desafío',
  challengeModeSubtitle:
      'La palabra del día, cronometrada — escala la clasificación',
  alchemyTableModeTitle: 'Mesa de Alquimia',
  alchemyTableModeSubtitle: 'Un laboratorio 2.5D místico — ¡toca y mezcla!',
  alchemyTableHint: 'Selecciona dos elementos para combinar en el mortero',
  alchemyFeatureTubes: '2 Tubos de ensayo',
  alchemyFeatureMortar: 'Mortero y maja',
  alchemyFeatureMystical: 'Místico 2.5D',
  alchemyFeatureTap: 'Toca para preparar',
  alchemyTapToContinue: 'Toca para seguir preparando',
  alchemyHowToPlayLabel: '✨  Cómo jugar',
  alchemyHowToStep1:
      'Toca cualquier elemento de la bandeja para llenar el Tubo A',
  alchemyHowToStep2: 'Toca un segundo elemento para llenar el Tubo B',
  alchemyHowToStep3:
      '¡Observa cómo el mortero los mezcla y revela un nuevo elemento!',
  alchemyHowToStep4: 'No todos los pares se combinan — ¡sigue experimentando!',
  alchemyBrewing: 'Preparando...',
  startNewWorldTitle: '¿Comenzar un nuevo mundo?',
  cancel: 'Cancelar',
  reset: 'Reiniciar',
  yourWorlds: 'Tus mundos',
  freeModeEmptyHeader: 'Combina elementos, descubre todo',
  emptyTapToBegin: 'Vacío - toca para comenzar',
  resetWorldTooltip: 'Reiniciar mundo',
  targetModeQuestion: '¿Qué palabra quieres descubrir?',
  targetModeDescription:
      'Empieza desde lo básico y sigue combinando hasta crear exactamente '
      'esta palabra. Tu progreso se guarda entre intentos.',
  targetModeHint: 'ej. Robot, Volcán, Castillo...',
  start: 'Comenzar',
  congratulations: '🎉 ¡Felicitaciones!',
  keepPlaying: 'Seguir jugando',
  newTarget: 'Nuevo objetivo',
  changeTarget: 'Cambiar objetivo',
  discoveries: 'Descubrimientos',
  clearTable: 'Limpiar mesa',
  sortTooltip: 'Ordenar elementos',
  sortByTime: 'Orden de descubrimiento',
  sortByName: 'Nombre (A-Z)',
  sortByEmoji: 'Emoji',
  sortByRandom: 'Aleatorio',
  elementsTabLabel: 'Elementos',
  dragToCombineHint: '· arrastra para combinar',
  overview: 'Resumen',
  totalDiscovered: 'Total descubierto',
  activeWorlds: 'Mundos activos',
  bestWorld: 'Mejor mundo',
  saveSlots: 'Ranuras de guardado',
  perWorld: 'Por mundo',
  firstDiscoveries: 'Primeros descubrimientos mundiales',
  languagesPlayed: 'Idiomas jugados',
  perLanguage: 'Por idioma',
  badgesTitle: 'Insignias',
  account: 'Cuenta',
  challengeTimesSaved:
      'Tus tiempos del Modo Desafío se guardan en la clasificación',
  signOut: 'Cerrar sesión',
  signInWithGoogle: 'Iniciar sesión con Google',
  appearance: 'Apariencia',
  darkMode: 'Modo oscuro',
  darkModeSubtitle: 'Más suave para los ojos de noche',
  feedback: 'Comentarios',
  soundEffects: 'Efectos de sonido',
  soundEffectsSubtitle: 'Reproducir sonidos al combinar',
  haptics: 'Háptica',
  hapticsSubtitle: 'Vibrar al combinar y descubrir',
  about: 'Acerca de',
  howToPlay: 'Cómo jugar',
  aboutCraftAI: 'Acerca de CraftAI',
  dangerZone: 'Zona de peligro',
  resetAllWorlds: 'Reiniciar todos los mundos',
  howToPlayStep1: '1. Arrastra un elemento de la bandeja a la mesa.',
  howToPlayStep2: '2. Suelta un elemento sobre otro para combinarlos.',
  howToPlayStep3:
      '3. ¡Descubre nuevos elementos — algunos pueden ser los primeros del mundo! 🎉',
  howToPlayStep4: '4. No todos los pares se combinan. ¡Sigue experimentando!',
  gotIt: 'Entendido',
  aboutDescription:
      'Un juego de creación infinita. Combina elementos para descubrir todo '
      '— impulsado por IA para combinaciones nuevas que nadie ha encontrado antes.',
  resetAllWorldsTitle: '¿Reiniciar todos los mundos?',
  resetAllWorldsBody:
      'Esto borra el progreso en todos los mundos de este dispositivo. '
      'Los descubrimientos compartidos en línea no se ven afectados. Esto no se puede deshacer.',
  resetAll: 'Reiniciar todo',
  allWorldsReset: 'Todos los mundos reiniciados.',
  languageSectionLabel: 'Idioma',
  languageSubtitle:
      'Cambiar el idioma inicia un conjunto separado de mundos con su '
      'propio progreso y clasificaciones.',
  signInForLeaderboard:
      'Inicia sesión con Google para aparecer en la clasificación de hoy.',
  signIn: 'Iniciar sesión',
  todaysChallenge: '🏆 Desafío de Hoy',
  leaderboard: 'Clasificación',
  noLeaderboardYet:
      '🏆 Nadie en la tabla aún — ¡encuentra la palabra del día y quédate con el primer puesto!',
  player: 'Jugador',
  viewLeaderboard: 'Ver clasificación',
  challengeAppBarTitle: '🏆 Desafío',
  dragElementsHere: 'Arrastra elementos aquí para combinarlos',
  crafting: 'Combinando...',
  eraseWorldConfirm: (sessionId) =>
      'Esto borrará todos los elementos descubiertos en el Mundo $sessionId '
      'en este dispositivo. Esto no se puede deshacer.',
  elementsDiscoveredSoFar: (count) =>
      '$count elementos descubiertos hasta ahora',
  worldTitle: (id) => 'Mundo $id',
  elementsDiscoveredCount: (count) => '$count elementos descubiertos',
  firstDiscoveryToast: (emoji, name) =>
      '🎉 Primer descubrimiento mundial: $emoji $name',
  youDiscovered: (label) => '¡Descubriste $label!',
  discoveriesTitle: (sessionId) => 'Mundo $sessionId · Descubrimientos',
  searchHint: (count) => 'Buscar $count descubrimientos...',
  noMatches: (query) => 'Ningún elemento coincide con "$query"',
  signedInAs: (name) => 'Conectado como $name',
  completedIn: (time) => '✅ Completado en $time',
  foundWordIn: (word, time) => '¡Encontraste "$word" en $time!',
  firstDiscoverySnack: (emoji, name) =>
      '🌟 Primer descubrimiento: $emoji $name!',
  communitySuggestionsLabel: 'Sugerencias de la comunidad',
  suggestCombinationTile: 'Sugerir una combinación',
  reviewSuggestionsTile: 'Revisar sugerencias (Admin)',
  suggestCombinationTitle: 'Sugerir una combinación',
  suggestCombinationIntro:
      '¿Crees que una combinación debería dar un resultado diferente? '
      'Sugiérelo abajo — si se aprueba, se convertirá en el nuevo resultado para todos.',
  elementALabel: '1er elemento',
  elementBLabel: '2do elemento',
  suggestedResultNameLabel: 'Nombre del resultado sugerido',
  suggestedResultEmojiLabel: 'Emoji del resultado sugerido',
  submitSuggestion: 'Enviar',
  suggestionSubmitted: '¡Sugerencia enviada, gracias!',
  yourSuggestions: 'Tus sugerencias',
  noSuggestionsYet: 'Aún no has enviado ninguna sugerencia.',
  suggestionStatusPending: 'Pendiente',
  suggestionStatusApproved: 'Aprobado',
  suggestionStatusRejected: 'Rechazado',
  reviewSuggestionsTitle: 'Revisar sugerencias',
  noPendingSuggestions: 'No hay sugerencias pendientes.',
  approve: 'Aprobar',
  reject: 'Rechazar',
  suggestedBy: (name) => 'Sugerido por: $name',
  noCombinationMessage: '🤔 Estos dos no parecen combinar en nada.',
  offlineError:
      '📡 Sin conexión a internet — revisa tu red e inténtalo de nuevo.',
  combineFailedError: 'Algo salió mal — inténtalo de nuevo.',
  dailyQuestsTitle: 'Misiones diarias',
  questCombine: (n) => 'Haz $n combinaciones',
  questDiscover: (n) => 'Descubre $n elementos nuevos',
  share: 'Compartir',
  shareCardTitle: '¡Nuevo descubrimiento!',
  shareDiscoveryText: (name) =>
      '¡Descubrí "$name" en CraftAI! 🧪 ¿Puedes crearlo tú también?',
  dailyReminder: 'Recordatorio del desafío diario',
  dailyReminderSubtitle: 'Avísame cuando haya una nueva palabra del día',
  dailyReminderNotifTitle: '¡El desafío de hoy está listo! 🏆',
  dailyReminderNotifBody: 'Una nueva palabra te espera — ¿serás el más rápido?',
  recipesTitle: 'Recetas conocidas',
  noRecipesKnown:
      'Aún no hay recetas en este dispositivo — puede ser un elemento inicial.',
  deleteAccount: 'Eliminar mi cuenta',
  deleteAccountConfirmTitle: '¿Eliminar cuenta?',
  deleteAccountConfirmBody:
      'Tu cuenta, copia en la nube, tiempos de desafío y sugerencias se '
      'eliminan permanentemente. El progreso local en este dispositivo se '
      'conserva. Esto no se puede deshacer.',
  deleteConfirmAction: 'Eliminar',
  accountDeleted: 'Tu cuenta ha sido eliminada.',
  accountDeleteFailed: 'No se pudo eliminar la cuenta — inténtalo de nuevo.',
);

final _pt = AppStringsData(
  navPlay: 'Jogar',
  navStats: 'Estatísticas',
  navSettings: 'Configurações',
  tagline: 'Combine elementos, descubra tudo.',
  continueWithGoogle: 'Continuar com o Google',
  continueAsGuest: 'Continuar como convidado',
  chooseHowToPlay: 'Escolha como quer jogar',
  gameModes: 'Modos de jogo',
  mainGameBadge: 'JOGO PRINCIPAL',
  settingsHeroSubtitle: 'Personalize sua experiência',
  noFavoritesYet:
      'Ainda sem favoritos — mantenha pressionado um elemento para marcá-lo',
  freeModeTitle: 'Modo Espacial',
  freeModeSubtitle: 'Combine livremente em uma tela espacial infinita',
  targetModeTitle: 'Modo Alvo',
  targetModeSubtitle: 'Escolha uma palavra e corra para descobri-la',
  challengeModeTitle: 'Modo Desafio',
  challengeModeSubtitle: 'A palavra do dia, cronometrada — suba no ranking',
  alchemyTableModeTitle: 'Mesa de Alquimia',
  alchemyTableModeSubtitle: 'Um laboratório 2.5D místico — toque e prepare!',
  alchemyTableHint: 'Selecione dois elementos para combinar no almofariz',
  alchemyFeatureTubes: '2 Tubos de ensaio',
  alchemyFeatureMortar: 'Almofariz e pilão',
  alchemyFeatureMystical: 'Místico 2.5D',
  alchemyFeatureTap: 'Toque para preparar',
  alchemyTapToContinue: 'Toque para continuar preparando',
  alchemyHowToPlayLabel: '✨  Como jogar',
  alchemyHowToStep1:
      'Toque em qualquer elemento na bandeja para encher o Tubo A',
  alchemyHowToStep2: 'Toque em um segundo elemento para encher o Tubo B',
  alchemyHowToStep3: 'Veja o almofariz triturá-los e revelar um novo elemento!',
  alchemyHowToStep4: 'Nem todo par se combina — continue experimentando!',
  alchemyBrewing: 'Preparando...',
  startNewWorldTitle: 'Começar um novo mundo?',
  cancel: 'Cancelar',
  reset: 'Reiniciar',
  yourWorlds: 'Seus mundos',
  freeModeEmptyHeader: 'Combine elementos, descubra tudo',
  emptyTapToBegin: 'Vazio - toque para começar',
  resetWorldTooltip: 'Reiniciar mundo',
  targetModeQuestion: 'Qual palavra você quer descobrir?',
  targetModeDescription:
      'Comece do básico e continue combinando até criar exatamente '
      'esta palavra. Seu progresso é salvo entre tentativas.',
  targetModeHint: 'ex. Robô, Vulcão, Castelo...',
  start: 'Começar',
  congratulations: '🎉 Parabéns!',
  keepPlaying: 'Continuar jogando',
  newTarget: 'Novo alvo',
  changeTarget: 'Mudar alvo',
  discoveries: 'Descobertas',
  clearTable: 'Limpar mesa',
  sortTooltip: 'Ordenar elementos',
  sortByTime: 'Ordem de descoberta',
  sortByName: 'Nome (A-Z)',
  sortByEmoji: 'Emoji',
  sortByRandom: 'Aleatório',
  elementsTabLabel: 'Elementos',
  dragToCombineHint: '· arraste para combinar',
  overview: 'Visão geral',
  totalDiscovered: 'Total descoberto',
  activeWorlds: 'Mundos ativos',
  bestWorld: 'Melhor mundo',
  saveSlots: 'Slots de salvamento',
  perWorld: 'Por mundo',
  firstDiscoveries: 'Primeiras descobertas mundiais',
  languagesPlayed: 'Idiomas jogados',
  perLanguage: 'Por idioma',
  badgesTitle: 'Emblemas',
  account: 'Conta',
  challengeTimesSaved: 'Seus tempos no Modo Desafio são salvos no ranking',
  signOut: 'Sair',
  signInWithGoogle: 'Entrar com o Google',
  appearance: 'Aparência',
  darkMode: 'Modo escuro',
  darkModeSubtitle: 'Mais suave para os olhos à noite',
  feedback: 'Feedback',
  soundEffects: 'Efeitos sonoros',
  soundEffectsSubtitle: 'Reproduzir sons ao combinar',
  haptics: 'Háptica',
  hapticsSubtitle: 'Vibrar ao combinar e descobrir',
  about: 'Sobre',
  howToPlay: 'Como jogar',
  aboutCraftAI: 'Sobre CraftAI',
  dangerZone: 'Zona de perigo',
  resetAllWorlds: 'Reiniciar todos os mundos',
  howToPlayStep1: '1. Arraste um elemento da bandeja para a mesa.',
  howToPlayStep2: '2. Solte um elemento sobre outro para combiná-los.',
  howToPlayStep3:
      '3. Descubra novos elementos — alguns podem ser descobertas mundiais! 🎉',
  howToPlayStep4: '4. Nem todo par se combina. Continue experimentando!',
  gotIt: 'Entendi',
  aboutDescription:
      'Um jogo de criação infinita. Combine elementos para descobrir tudo '
      '— alimentado por IA para combinações novas que ninguém encontrou antes.',
  resetAllWorldsTitle: 'Reiniciar todos os mundos?',
  resetAllWorldsBody:
      'Isso apaga o progresso em todos os mundos neste dispositivo. '
      'Descobertas compartilhadas online não são afetadas. Isso não pode ser desfeito.',
  resetAll: 'Reiniciar tudo',
  allWorldsReset: 'Todos os mundos reiniciados.',
  languageSectionLabel: 'Idioma',
  languageSubtitle:
      'Mudar o idioma inicia um conjunto separado de mundos com seu '
      'próprio progresso e rankings.',
  signInForLeaderboard: 'Entre com o Google para aparecer no ranking de hoje.',
  signIn: 'Entrar',
  todaysChallenge: '🏆 Desafio de Hoje',
  leaderboard: 'Ranking',
  noLeaderboardYet:
      '🏆 Ninguém no placar ainda — encontre a palavra do dia e garanta o primeiro lugar!',
  player: 'Jogador',
  viewLeaderboard: 'Ver ranking',
  challengeAppBarTitle: '🏆 Desafio',
  dragElementsHere: 'Arraste elementos aqui para combiná-los',
  crafting: 'Combinando...',
  eraseWorldConfirm: (sessionId) =>
      'Isso apagará todos os elementos descobertos no Mundo $sessionId '
      'neste dispositivo. Isso não pode ser desfeito.',
  elementsDiscoveredSoFar: (count) => '$count elementos descobertos até agora',
  worldTitle: (id) => 'Mundo $id',
  elementsDiscoveredCount: (count) => '$count elementos descobertos',
  firstDiscoveryToast: (emoji, name) =>
      '🎉 Primeira descoberta mundial: $emoji $name',
  youDiscovered: (label) => 'Você descobriu $label!',
  discoveriesTitle: (sessionId) => 'Mundo $sessionId · Descobertas',
  searchHint: (count) => 'Pesquisar $count descobertas...',
  noMatches: (query) => 'Nenhum elemento corresponde a "$query"',
  signedInAs: (name) => 'Conectado como $name',
  completedIn: (time) => '✅ Concluído em $time',
  foundWordIn: (word, time) => 'Você encontrou "$word" em $time!',
  firstDiscoverySnack: (emoji, name) => '🌟 Primeira descoberta: $emoji $name!',
  communitySuggestionsLabel: 'Sugestões da comunidade',
  suggestCombinationTile: 'Sugerir uma combinação',
  reviewSuggestionsTile: 'Revisar sugestões (Admin)',
  suggestCombinationTitle: 'Sugerir uma combinação',
  suggestCombinationIntro:
      'Acha que uma combinação deveria dar um resultado diferente? '
      'Sugira abaixo — se aprovado, se tornará o novo resultado para todos.',
  elementALabel: '1º elemento',
  elementBLabel: '2º elemento',
  suggestedResultNameLabel: 'Nome do resultado sugerido',
  suggestedResultEmojiLabel: 'Emoji do resultado sugerido',
  submitSuggestion: 'Enviar',
  suggestionSubmitted: 'Sugestão enviada, obrigado!',
  yourSuggestions: 'Suas sugestões',
  noSuggestionsYet: 'Você ainda não enviou nenhuma sugestão.',
  suggestionStatusPending: 'Pendente',
  suggestionStatusApproved: 'Aprovado',
  suggestionStatusRejected: 'Rejeitado',
  reviewSuggestionsTitle: 'Revisar sugestões',
  noPendingSuggestions: 'Nenhuma sugestão pendente.',
  approve: 'Aprovar',
  reject: 'Rejeitar',
  suggestedBy: (name) => 'Sugerido por: $name',
  noCombinationMessage: '🤔 Esses dois não parecem combinar em nada.',
  offlineError:
      '📡 Sem conexão com a internet — verifique sua rede e tente novamente.',
  combineFailedError: 'Algo deu errado — tente novamente.',
  dailyQuestsTitle: 'Missões diárias',
  questCombine: (n) => 'Faça $n combinações',
  questDiscover: (n) => 'Descubra $n novos elementos',
  share: 'Compartilhar',
  shareCardTitle: 'Nova descoberta!',
  shareDiscoveryText: (name) =>
      'Descobri "$name" no CraftAI! 🧪 Você também consegue?',
  dailyReminder: 'Lembrete do desafio diário',
  dailyReminderSubtitle: 'Avise-me quando houver uma nova palavra do dia',
  dailyReminderNotifTitle: 'O desafio de hoje está pronto! 🏆',
  dailyReminderNotifBody:
      'Uma nova palavra espera por você — será o mais rápido?',
  recipesTitle: 'Receitas conhecidas',
  noRecipesKnown:
      'Ainda não há receitas neste dispositivo — pode ser um elemento inicial.',
  deleteAccount: 'Excluir minha conta',
  deleteAccountConfirmTitle: 'Excluir conta?',
  deleteAccountConfirmBody:
      'Sua conta, backup na nuvem, tempos de desafio e sugestões serão '
      'excluídos permanentemente. O progresso local neste dispositivo é '
      'mantido. Isso não pode ser desfeito.',
  deleteConfirmAction: 'Excluir',
  accountDeleted: 'Sua conta foi excluída.',
  accountDeleteFailed: 'Falha ao excluir a conta — tente novamente.',
);

/// Returns the string set for [language]. See [AppStringsData].
class AppStrings {
  const AppStrings._();

  static AppStringsData of(GameLanguage language) => switch (language) {
    GameLanguage.turkishV2 => _tr,
    GameLanguage.english => _en,
    GameLanguage.german => _de,
    GameLanguage.spanish => _es,
    GameLanguage.portuguese => _pt,
  };
}
