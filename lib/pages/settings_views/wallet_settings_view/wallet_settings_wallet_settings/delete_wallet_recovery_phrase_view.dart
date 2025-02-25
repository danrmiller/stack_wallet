import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/add_wallet_views/new_wallet_recovery_phrase_view/sub_widgets/mnemonic_table.dart';
import 'package:stackwallet/pages/home_view/home_view.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/services/coins/manager.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';

class DeleteWalletRecoveryPhraseView extends ConsumerStatefulWidget {
  const DeleteWalletRecoveryPhraseView({
    Key? key,
    required this.manager,
    required this.mnemonic,
    this.clipboardInterface = const ClipboardWrapper(),
  }) : super(key: key);

  static const routeName = "/deleteWalletRecoveryPhrase";

  final Manager manager;
  final List<String> mnemonic;

  final ClipboardInterface clipboardInterface;

  @override
  ConsumerState<DeleteWalletRecoveryPhraseView> createState() =>
      _DeleteWalletRecoveryPhraseViewState();
}

class _DeleteWalletRecoveryPhraseViewState
    extends ConsumerState<DeleteWalletRecoveryPhraseView> {
  late Manager _manager;
  late List<String> _mnemonic;
  late ClipboardInterface _clipboardInterface;

  @override
  void initState() {
    _manager = widget.manager;
    _mnemonic = widget.mnemonic;
    _clipboardInterface = widget.clipboardInterface;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        leading: AppBarBackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: AspectRatio(
              aspectRatio: 1,
              child: AppBarIconButton(
                color: CFColors.almostWhite,
                shadows: const [],
                icon: SvgPicture.asset(
                  Assets.svg.copy,
                  width: 20,
                  height: 20,
                ),
                onPressed: () async {
                  final words = await _manager.mnemonic;
                  await _clipboardInterface
                      .setData(ClipboardData(text: words.join(" ")));
                  showFloatingFlushBar(
                    type: FlushBarType.info,
                    message: "Copied to clipboard",
                    iconAsset: Assets.svg.copy,
                    context: context,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(
              height: 4,
            ),
            Text(
              _manager.walletName,
              textAlign: TextAlign.center,
              style: STextStyles.label.copyWith(
                fontSize: 12,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              "Recovery Phrase",
              textAlign: TextAlign.center,
              style: STextStyles.pageTitleH1,
            ),
            const SizedBox(
              height: 16,
            ),
            Container(
              decoration: BoxDecoration(
                color: CFColors.white,
                borderRadius:
                    BorderRadius.circular(Constants.size.circularBorderRadius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Please write down your recovery phrase in the correct order and save it to keep your funds secure. You will also be asked to verify the words on the next screen.",
                  style: STextStyles.label.copyWith(
                    color: CFColors.stackAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            Expanded(
              child: SingleChildScrollView(
                child: MnemonicTable(
                  words: _mnemonic,
                ),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextButton(
              style: Theme.of(context).textButtonTheme.style?.copyWith(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      CFColors.stackAccent,
                    ),
                  ),
              onPressed: () {
                showDialog<dynamic>(
                  barrierDismissible: true,
                  context: context,
                  builder: (_) => StackDialog(
                    title: "Thanks! Your wallet will be deleted.",
                    leftButton: TextButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(
                          CFColors.buttonGray,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        "Cancel",
                        style: STextStyles.button.copyWith(
                          color: CFColors.stackAccent,
                        ),
                      ),
                    ),
                    rightButton: TextButton(
                      style: Theme.of(context).textButtonTheme.style?.copyWith(
                            backgroundColor: MaterialStateProperty.all<Color>(
                              CFColors.stackAccent,
                            ),
                          ),
                      onPressed: () async {
                        final walletId = _manager.walletId;
                        final walletsInstance =
                            ref.read(walletsChangeNotifierProvider);
                        await ref
                            .read(walletsServiceChangeNotifierProvider)
                            .deleteWallet(_manager.walletName, true);

                        if (mounted) {
                          Navigator.of(context).popUntil(
                              ModalRoute.withName(HomeView.routeName));
                        }

                        // wait for widget tree to dispose of any widgets watching the manager
                        await Future<void>.delayed(const Duration(seconds: 1));
                        walletsInstance.removeWallet(walletId: walletId);
                      },
                      child: Text(
                        "Ok",
                        style: STextStyles.button,
                      ),
                    ),
                  ),
                );
              },
              child: Text(
                "Continue",
                style: STextStyles.button,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
