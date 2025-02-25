import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/new_wallet_recovery_phrase_view.dart';
import 'package:stackwallet/pages/add_wallet_views/verify_recovery_phrase_view/sub_widgets/word_table.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:tuple/tuple.dart';

class VerifyRecoveryPhraseView extends ConsumerStatefulWidget {
  const VerifyRecoveryPhraseView({
    Key? key,
    required this.manager,
    required this.mnemonic,
  }) : super(key: key);

  static const routeName = "/verifyRecoveryPhrase";

  final Manager manager;
  final List<String> mnemonic;

  @override
  ConsumerState<VerifyRecoveryPhraseView> createState() =>
      _VerifyRecoveryPhraseViewState();
}

class _VerifyRecoveryPhraseViewState
    extends ConsumerState<VerifyRecoveryPhraseView>
// with WidgetsBindingObserver
{
  late Manager _manager;
  late List<String> _mnemonic;

  @override
  void initState() {
    _manager = widget.manager;
    _mnemonic = widget.mnemonic;
    // WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  @override
  dispose() {
    // WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   switch (state) {
  //     case AppLifecycleState.inactive:
  //       debugPrint(
  //           "VerifyRecoveryPhraseView ========================= Inactive");
  //       break;
  //     case AppLifecycleState.paused:
  //       debugPrint("VerifyRecoveryPhraseView ========================= Paused");
  //       break;
  //     case AppLifecycleState.resumed:
  //       debugPrint(
  //           "VerifyRecoveryPhraseView ========================= Resumed");
  //       break;
  //     case AppLifecycleState.detached:
  //       debugPrint(
  //           "VerifyRecoveryPhraseView ========================= Detached");
  //       break;
  //   }
  // }

  Tuple2<List<String>, String> randomize(
      List<String> mnemonic, int chosenIndex, int wordsToShow) {
    final List<String> remaining = [];
    final String chosenWord = mnemonic[chosenIndex];

    for (int i = 0; i < mnemonic.length; i++) {
      if (chosenWord != mnemonic[i]) {
        remaining.add(mnemonic[i]);
      }
    }

    final random = Random();

    final List<String> result = [];

    for (int i = 0; i < wordsToShow - 1; i++) {
      final randomIndex = random.nextInt(remaining.length);
      result.add(remaining.removeAt(randomIndex));
    }

    result.insert(random.nextInt(wordsToShow), chosenWord);

    debugPrint("Mnemonic game correct word: $chosenWord");

    return Tuple2(result, chosenWord);
  }

  Future<bool> onWillPop() async {
    // await delete();
    Navigator.of(context).popUntil(
      ModalRoute.withName(
        // NewWalletRecoveryPhraseWarningView.routeName,
        NewWalletRecoveryPhraseView.routeName,
      ),
    );
    return false;
  }

  // Future<void> delete() async {
  //   await ref
  //       .read(walletsServiceChangeNotifierProvider)
  //       .deleteWallet(_manager.walletName, false);
  //   await _manager.exitCurrentWallet();
  // }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");
    final correctIndex =
        ref.watch(verifyMnemonicWordIndexStateProvider.state).state;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarBackButton(
            onPressed: () async {
              // await delete();
              Navigator.of(context).popUntil(
                ModalRoute.withName(
                  // NewWalletRecoveryPhraseWarningView.routeName,
                  NewWalletRecoveryPhraseView.routeName,
                ),
              );
            },
          ),
        ),
        body: Container(
          color: CFColors.almostWhite,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "Verify recovery phrase",
                  textAlign: TextAlign.center,
                  style: STextStyles.label.copyWith(
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  "Tap word number ",
                  textAlign: TextAlign.center,
                  style: STextStyles.pageTitleH1,
                ),
                const SizedBox(
                  height: 12,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: CFColors.fieldGray,
                    borderRadius: BorderRadius.circular(
                        Constants.size.circularBorderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    child: Text(
                      "${correctIndex + 1}",
                      textAlign: TextAlign.center,
                      style: STextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 32,
                        letterSpacing: 0.25,
                      ),
                    ),
                  ),
                ),
                WordTable(
                  words: randomize(_mnemonic, correctIndex, 9).item1,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (_, ref, __) {
                          final selectedWord = ref
                              .watch(
                                  verifyMnemonicSelectedWordStateProvider.state)
                              .state;
                          final correctWord = ref
                              .watch(
                                  verifyMnemonicCorrectWordStateProvider.state)
                              .state;

                          return TextButton(
                            onPressed: selectedWord.isNotEmpty
                                ? () async {
                                    if (correctWord == selectedWord) {
                                      await ref
                                          .read(
                                              walletsServiceChangeNotifierProvider)
                                          .setMnemonicVerified(
                                            walletId: _manager.walletId,
                                          );

                                      ref
                                          .read(walletsChangeNotifierProvider
                                              .notifier)
                                          .addWallet(
                                              walletId: _manager.walletId,
                                              manager: _manager);

                                      if (mounted) {
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                                HomeView.routeName,
                                                (route) => false);
                                      }

                                      showFloatingFlushBar(
                                        type: FlushBarType.success,
                                        message:
                                            "Correct! Your wallet is set up.",
                                        iconAsset: Assets.svg.check,
                                        context: context,
                                      );
                                    } else {
                                      showFloatingFlushBar(
                                        type: FlushBarType.warning,
                                        message: "Incorrect. Please try again.",
                                        iconAsset: Assets.svg.circleX,
                                        context: context,
                                      );

                                      final int next =
                                          Random().nextInt(_mnemonic.length);
                                      ref
                                          .read(
                                              verifyMnemonicWordIndexStateProvider
                                                  .state)
                                          .update((state) => next);

                                      ref
                                          .read(
                                              verifyMnemonicCorrectWordStateProvider
                                                  .state)
                                          .update((state) => _mnemonic[next]);

                                      ref
                                          .read(
                                              verifyMnemonicSelectedWordStateProvider
                                                  .state)
                                          .update((state) => "");
                                    }
                                  }
                                : null,
                            style: selectedWord.isNotEmpty
                                ? Theme.of(context)
                                    .textButtonTheme
                                    .style
                                    ?.copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        CFColors.stackAccent,
                                      ),
                                    )
                                : Theme.of(context)
                                    .textButtonTheme
                                    .style
                                    ?.copyWith(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                        CFColors.stackAccent.withOpacity(
                                          0.25,
                                        ),
                                      ),
                                    ),
                            child: Text(
                              "Continue",
                              style: STextStyles.button,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
