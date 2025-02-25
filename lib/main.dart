import 'dart:async';
import 'dart:io';

import 'package:cw_core/node.dart';
import 'package:cw_core/unspent_coins_info.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_libmonero/monero/monero.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:isar/isar.dart';
import 'package:keyboard_dismisser/keyboard_dismisser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/isar/models/log.dart';
import 'package:stackwallet/models/models.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/notification_model.dart';
import 'package:stackwallet/models/trade_wallet_lookup.dart';
import 'package:stackwallet/pages/exchange_view/exchange_view.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/pages/intro_view.dart';
import 'package:stackwallet/pages/loading_view.dart';
import 'package:stackwallet/pages/pinpad_views/create_pin_view.dart';
import 'package:stackwallet/pages/pinpad_views/lock_screen_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/restore_from_encrypted_string_view.dart';
import 'package:stackwallet/providers/exchange/available_currencies_state_provider.dart';
import 'package:stackwallet/providers/exchange/available_floating_rate_pairs_state_provider.dart';
import 'package:stackwallet/providers/exchange/changenow_initial_load_status.dart';
import 'package:stackwallet/providers/exchange/exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_exchange_form_provider.dart';
import 'package:stackwallet/providers/exchange/fixed_rate_market_pairs_provider.dart';
import 'package:stackwallet/providers/global/auto_swb_service_provider.dart';
import 'package:stackwallet/providers/global/base_currencies_provider.dart';
// import 'package:stackwallet/providers/global/has_authenticated_start_state_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/services/change_now/change_now.dart';
import 'package:stackwallet/services/debug_service.dart';
import 'package:stackwallet/services/locale_service.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/notifications_api.dart';
import 'package:stackwallet/services/notifications_service.dart';
import 'package:stackwallet/services/trade_service.dart';
import 'package:stackwallet/services/wallets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/backup_frequency_type.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/text_styles.dart';

final openedFromSWBFileStringStateProvider =
    StateProvider<String?>((ref) => null);

// main() is the entry point to the app. It initializes Hive (local database),
// runs the MyApp widget and checks for new users, caching the value in the
// miscellaneous box for later use
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  Directory appDirectory = (await getApplicationDocumentsDirectory());
  if (Platform.isIOS) {
    appDirectory = (await getLibraryDirectory());
  }
  // FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Hive.initFlutter(appDirectory.path);
  final isar = await Isar.open(
    [LogSchema],
    directory: appDirectory.path,
    inspector: false,
  );
  await Logging.instance.init(isar);
  await DebugService.instance.init(isar);

  // clear out all info logs on startup. No need to await and block
  DebugService.instance.purgeInfoLogs();

  // Registering Transaction Model Adapters
  Hive.registerAdapter(TransactionDataAdapter());
  Hive.registerAdapter(TransactionChunkAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(InputAdapter());
  Hive.registerAdapter(OutputAdapter());

  // Registering Utxo Model Adapters
  Hive.registerAdapter(UtxoDataAdapter());
  Hive.registerAdapter(UtxoObjectAdapter());
  Hive.registerAdapter(StatusAdapter());

  // Registering Lelantus Model Adapters
  Hive.registerAdapter(LelantusCoinAdapter());

  // notification model adapter
  Hive.registerAdapter(NotificationModelAdapter());

  // change now trade adapters
  Hive.registerAdapter(ExchangeTransactionAdapter());
  Hive.registerAdapter(ExchangeTransactionStatusAdapter());

  // reference lookup data adapter
  Hive.registerAdapter(TradeWalletLookupAdapter());

  // node model adapter
  Hive.registerAdapter(NodeModelAdapter());

  Hive.registerAdapter(NodeAdapter());

  Hive.registerAdapter(WalletInfoAdapter());

  Hive.registerAdapter(WalletTypeAdapter());

  Hive.registerAdapter(UnspentCoinsInfoAdapter());

  monero.onStartup();

  // final wallets = await Hive.openBox('wallets');
  // await wallets.put('currentWalletName', "");

  // NOT USED YET
  // int dbVersion = await wallets.get("db_version");
  // if (dbVersion == null || dbVersion < Constants.currentDbVersion) {
  //   if (dbVersion == null) dbVersion = 0;
  //   await DbVersionMigrator().migrate(dbVersion);
  // }

  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
  //     overlays: [SystemUiOverlay.bottom]);
  await NotificationApi.init();

  runApp(const ProviderScope(child: MyApp()));
}

/// MyApp initialises relevant services with a MultiProvider
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final localeService = LocaleService();
    localeService.loadLocale();

    return const KeyboardDismisser(
      child: MaterialAppWithTheme(),
    );
  }
}

// Sidenote: MaterialAppWithTheme and InitView are only separated for clarity. No other reason.

class MaterialAppWithTheme extends ConsumerStatefulWidget {
  const MaterialAppWithTheme({
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<MaterialAppWithTheme> createState() =>
      _MaterialAppWithThemeState();
}

class _MaterialAppWithThemeState extends ConsumerState<MaterialAppWithTheme>
    with WidgetsBindingObserver {
  static const platform = MethodChannel("STACK_WALLET_RESTORE");
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  late final Wallets _wallets;
  late final Prefs _prefs;
  late final NotificationsService _notificationsService;
  late final NodeService _nodeService;
  late final TradesService _tradesService;

  late final Completer<void> loadingCompleter;

  Future<void> load() async {
    await DB.instance.init();

    _notificationsService = ref.read(notificationsProvider);
    _nodeService = ref.read(nodeServiceChangeNotifierProvider);
    _tradesService = ref.read(tradesServiceProvider);

    NotificationApi.prefs = _prefs;
    NotificationApi.notificationsService = _notificationsService;

    ref.read(baseCurrenciesProvider).update();

    await _nodeService.updateDefaults();
    await _notificationsService.init(
      nodeService: _nodeService,
      tradesService: _tradesService,
      prefs: _prefs,
    );
    await _prefs.init();
    ref.read(priceAnd24hChangeNotifierProvider).start(true);
    await _wallets.load(_prefs);
    loadingCompleter.complete();
    // TODO: this currently hangs for a long time
    await _nodeService.updateCommunityNodes();

    if (_prefs.isAutoBackupEnabled) {
      switch (_prefs.backupFrequencyType) {
        case BackupFrequencyType.everyTenMinutes:
          ref
              .read(autoSWBServiceProvider)
              .startPeriodicBackupTimer(duration: const Duration(minutes: 10));
          break;
        case BackupFrequencyType.everyAppStart:
          ref.read(autoSWBServiceProvider).doBackup();
          break;
        case BackupFrequencyType.afterClosingAWallet:
          // ignore this case here
          break;
      }
    }
  }

  Future<void> _loadChangeNowStandardCurrencies() async {
    if (ref
            .read(availableChangeNowCurrenciesStateProvider.state)
            .state
            .isNotEmpty &&
        ref
            .read(availableFloatingRatePairsStateProvider.state)
            .state
            .isNotEmpty) {
      return;
    }
    final response = await ChangeNow.getAvailableCurrencies();
    final response2 = await ChangeNow.getAvailableFloatingRatePairs();
    if (response.value != null) {
      ref.read(availableChangeNowCurrenciesStateProvider.state).state =
          response.value!;
      if (response2.value != null) {
        ref.read(availableFloatingRatePairsStateProvider.state).state =
            response2.value!;

        if (response.value!.length > 1) {
          if (ref.read(estimatedRateExchangeFormProvider).from == null) {
            if (response.value!.where((e) => e.ticker == "btc").isNotEmpty) {
              ref.read(estimatedRateExchangeFormProvider).updateFrom(
                  response.value!.firstWhere((e) => e.ticker == "btc"), false);
            }
          }
          if (ref.read(estimatedRateExchangeFormProvider).to == null) {
            if (response.value!.where((e) => e.ticker == "doge").isNotEmpty) {
              ref.read(estimatedRateExchangeFormProvider).updateTo(
                  response.value!.firstWhere((e) => e.ticker == "doge"), false);
            }
          }
        }
      } else {
        Logging.instance.log(
            "Failed to load changeNOW available floating rate pairs: ${response2.exception?.errorMessage}",
            level: LogLevel.Error);
        ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
            ChangeNowLoadStatus.failed;
        return;
      }
    } else {
      Logging.instance.log(
          "Failed to load changeNOW currencies: ${response.exception?.errorMessage}",
          level: LogLevel.Error);
      await Future<void>.delayed(const Duration(seconds: 1));
      ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
          ChangeNowLoadStatus.failed;
      return;
    }

    ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.success;
  }

  Future<void> _loadFixedRateMarkets() async {
    Logging.instance.log("Starting initial fixed rate market data loading...",
        level: LogLevel.Info);
    if (ref.read(fixedRateMarketPairsStateProvider.state).state.isNotEmpty) {
      return;
    }

    final response3 = await ChangeNow.getAvailableFixedRateMarkets();
    if (response3.value != null) {
      ref.read(fixedRateMarketPairsStateProvider.state).state =
          response3.value!;

      if (ref.read(fixedRateExchangeFormProvider).market == null) {
        final matchingMarkets =
            response3.value!.where((e) => e.to == "doge" && e.from == "btc");
        if (matchingMarkets.isNotEmpty) {
          ref
              .read(fixedRateExchangeFormProvider)
              .updateMarket(matchingMarkets.first, true);
        }
      }

      Logging.instance.log("Initial fixed rate market data loading complete.",
          level: LogLevel.Info);
    } else {
      Logging.instance.log(
          "Failed to load changeNOW fixed rate markets: ${response3.exception?.errorMessage}",
          level: LogLevel.Error);

      ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state =
          ChangeNowLoadStatus.failed;
      return;
    }

    ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state =
        ChangeNowLoadStatus.success;
  }

  Future<void> _loadChangeNowData() async {
    List<Future<dynamic>> concurrentFutures = [];
    concurrentFutures.add(_loadChangeNowStandardCurrencies());
    if (kFixedRateEnabled) {
      concurrentFutures.add(_loadFixedRateMarkets());
    }
  }

  @override
  void initState() {
    loadingCompleter = Completer();
    WidgetsBinding.instance.addObserver(this);
    // load locale and prefs
    ref
        .read(localeServiceChangeNotifierProvider.notifier)
        .loadLocale(notify: false);

    _prefs = ref.read(prefsChangeNotifierProvider);
    _wallets = ref.read(walletsChangeNotifierProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // fetch open file if it exists
      await getOpenFile();

      if (ref.read(openedFromSWBFileStringStateProvider.state).state != null) {
        // waiting for loading to complete before going straight to restore if the app was opened via file
        await loadingCompleter.future;

        await goToRestoreSWB(
            ref.read(openedFromSWBFileStringStateProvider.state).state!);
        ref.read(openedFromSWBFileStringStateProvider.state).state = null;
      }
      // ref.read(shouldShowLockscreenOnResumeStateProvider.state).state = false;
    });

    super.initState();
  }

  @override
  dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    debugPrint("didChangeAppLifecycleState: ${state.name}");
    if (state == AppLifecycleState.resumed) {}
    switch (state) {
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        break;
      case AppLifecycleState.resumed:
        // fetch open file if it exists
        await getOpenFile();
        // go straight to restore if the app was resumed via file
        if (ref.read(openedFromSWBFileStringStateProvider.state).state !=
            null) {
          await goToRestoreSWB(
              ref.read(openedFromSWBFileStringStateProvider.state).state!);
          ref.read(openedFromSWBFileStringStateProvider.state).state = null;
        }
        // if (ref.read(hasAuthenticatedOnStartStateProvider.state).state &&
        //     ref.read(shouldShowLockscreenOnResumeStateProvider.state).state) {
        //   final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
        //
        //   if (now - _prefs.lastUnlocked > _prefs.lastUnlockedTimeout) {
        //     ref.read(shouldShowLockscreenOnResumeStateProvider.state).state =
        //         false;
        //     Navigator.of(navigatorKey.currentContext!).push(
        //       MaterialPageRoute<dynamic>(
        //         builder: (_) => LockscreenView(
        //           routeOnSuccess: "",
        //           popOnSuccess: true,
        //           biometricsAuthenticationTitle: "Unlock Stack",
        //           biometricsLocalizedReason:
        //               "Unlock your stack wallet using biometrics",
        //           biometricsCancelButtonString: "Cancel",
        //           onSuccess: () {
        //             ref
        //                 .read(shouldShowLockscreenOnResumeStateProvider.state)
        //                 .state = true;
        //           },
        //         ),
        //       ),
        //     );
        //   }
        // }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> getOpenFile() async {
    // update provider with new file content state
    ref.read(openedFromSWBFileStringStateProvider.state).state =
        await platform.invokeMethod("getOpenFile");

    // call reset to clear cached value
    await resetOpenPath();

    Logging.instance.log(
        "This is the .swb content from intent: ${ref.read(openedFromSWBFileStringStateProvider.state).state}",
        level: LogLevel.Info);
  }

  Future<void> resetOpenPath() async {
    await platform.invokeMethod("resetOpenPath");
  }

  Future<void> goToRestoreSWB(String encrypted) async {
    if (!_prefs.hasPin) {
      await Navigator.of(navigatorKey.currentContext!)
          .pushNamed(CreatePinView.routeName, arguments: true)
          .then((value) {
        if (value is! bool || value == false) {
          Navigator.of(navigatorKey.currentContext!).pushNamed(
              RestoreFromEncryptedStringView.routeName,
              arguments: encrypted);
        }
      });
    } else {
      Navigator.push(
        navigatorKey.currentContext!,
        RouteGenerator.getRoute(
          shouldUseMaterialRoute: RouteGenerator.useMaterialPageRoute,
          builder: (_) => LockscreenView(
            showBackButton: true,
            routeOnSuccess: RestoreFromEncryptedStringView.routeName,
            routeOnSuccessArguments: encrypted,
            biometricsCancelButtonString: "CANCEL",
            biometricsLocalizedReason:
                "Authenticate to restore Stack Wallet backup",
            biometricsAuthenticationTitle: "Restore Stack backup",
          ),
          settings: const RouteSettings(name: "/swbrestorelockscreen"),
        ),
      );
    }
  }

  InputBorder _buildOutlineInputBorder(Color color) {
    return OutlineInputBorder(
      borderSide: BorderSide(
        width: 1,
        color: color,
      ),
      borderRadius: BorderRadius.circular(Constants.size.circularBorderRadius),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    // ref.listen(shouldShowLockscreenOnResumeStateProvider, (previous, next) {
    //   Logging.instance.log("shouldShowLockscreenOnResumeStateProvider set to: $next",
    //       addToDebugMessagesDB: false);
    // });

    return MaterialApp(
      key: GlobalKey(),
      navigatorKey: navigatorKey,
      title: 'Stack Wallet',
      onGenerateRoute: RouteGenerator.generateRoute,
      theme: ThemeData(
        highlightColor: CFColors.splashLight,
        brightness: Brightness.light,
        fontFamily: GoogleFonts.inter().fontFamily,
        textTheme: GoogleFonts.interTextTheme().copyWith(
          button: STextStyles.button,
        ),
        radioTheme: const RadioThemeData(
          splashRadius: 0,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        // splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        buttonTheme: const ButtonThemeData(
          splashColor: CFColors.splashMed,
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            // splashFactory: NoSplash.splashFactory,
            overlayColor: MaterialStateProperty.all(CFColors.splashMed),
            minimumSize: MaterialStateProperty.all<Size>(const Size(46, 46)),
            textStyle: MaterialStateProperty.all<TextStyle>(STextStyles.button),
            foregroundColor: MaterialStateProperty.all(CFColors.white),
            backgroundColor:
                MaterialStateProperty.all<Color>(CFColors.buttonGray),
            shape: MaterialStateProperty.all<OutlinedBorder>(
              RoundedRectangleBorder(
                // 1000 to be relatively sure it keeps its pill shape
                borderRadius: BorderRadius.circular(1000),
              ),
            ),
          ),
        ),
        primaryColor: CFColors.stackAccent,
        primarySwatch: CFColors.createMaterialColor(CFColors.stackAccent),
        checkboxTheme: CheckboxThemeData(
          splashRadius: 0,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(Constants.size.checkboxBorderRadius),
          ),
          checkColor: MaterialStateColor.resolveWith(
            (state) {
              if (state.contains(MaterialState.selected)) {
                return CFColors.white;
              }
              return CFColors.link2;
            },
          ),
          fillColor: MaterialStateColor.resolveWith(
            (states) {
              if (states.contains(MaterialState.selected)) {
                return CFColors.link2;
              }
              return CFColors.disabledButton;
            },
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          color: CFColors.almostWhite,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusColor: CFColors.fieldGray,
          fillColor: CFColors.fieldGray,
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 12,
          ),
          labelStyle: STextStyles.fieldLabel,
          hintStyle: STextStyles.fieldLabel,
          enabledBorder: _buildOutlineInputBorder(CFColors.fieldGray),
          focusedBorder: _buildOutlineInputBorder(CFColors.fieldGray),
          errorBorder: _buildOutlineInputBorder(CFColors.fieldGray),
          disabledBorder: _buildOutlineInputBorder(CFColors.fieldGray),
          focusedErrorBorder: _buildOutlineInputBorder(CFColors.fieldGray),
        ),
      ),
      home: FutureBuilder(
        future: load(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // FlutterNativeSplash.remove();
            if (_wallets.hasWallets || _prefs.hasPin) {
              // return HomeView();

              // run without awaiting
              if (Constants.enableExchange) {
                _loadChangeNowData();
              }

              return const LockscreenView(
                isInitialAppLogin: true,
                routeOnSuccess: HomeView.routeName,
                biometricsAuthenticationTitle: "Unlock Stack",
                biometricsLocalizedReason:
                    "Unlock your stack wallet using biometrics",
                biometricsCancelButtonString: "Cancel",
              );
            } else {
              return const IntroView();
            }
          } else {
            // CURRENTLY DISABLED as cannot be animated
            // technically not needed as FlutterNativeSplash will overlay
            // anything returned here until the future completes but
            // FutureBuilder requires you to return something
            return const LoadingView();
          }
        },
      ),
    );
  }
}
