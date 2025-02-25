import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/wallet/wallet_balance_toggle_state_provider.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/wallet_balance_toggle_state.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class WalletBalanceToggleSheet extends ConsumerWidget {
  const WalletBalanceToggleSheet({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final maxHeight = MediaQuery.of(context).size.height * 0.60;

    return Container(
      decoration: const BoxDecoration(
        color: CFColors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: LimitedBox(
        maxHeight: maxHeight,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: 0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: CFColors.fieldGray,
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                  ),
                  width: 60,
                  height: 4,
                ),
              ),
              const SizedBox(
                height: 36,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  "Wallet balance",
                  style: STextStyles.pageTitleH2,
                  textAlign: TextAlign.left,
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              RawMaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  final state =
                      ref.read(walletBalanceToggleStateProvider.state).state;
                  if (state != WalletBalanceToggleState.available) {
                    ref.read(walletBalanceToggleStateProvider.state).state =
                        WalletBalanceToggleState.available;
                  }
                  Navigator.of(context).pop();
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Radio(
                          activeColor: CFColors.link2,
                          value: WalletBalanceToggleState.available,
                          groupValue: ref
                              .watch(walletBalanceToggleStateProvider.state)
                              .state,
                          onChanged: (_) {
                            ref
                                .read(walletBalanceToggleStateProvider.state)
                                .state = WalletBalanceToggleState.available;
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Available balance",
                            style: STextStyles.titleBold12,
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          // TODO need text from design
                          Text(
                            "Current spendable (unlocked) balance",
                            style: STextStyles.itemSubtitle12.copyWith(
                              color: CFColors.neutral60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              RawMaterialButton(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                onPressed: () {
                  final state =
                      ref.read(walletBalanceToggleStateProvider.state).state;
                  if (state != WalletBalanceToggleState.full) {
                    ref.read(walletBalanceToggleStateProvider.state).state =
                        WalletBalanceToggleState.full;
                  }
                  Navigator.of(context).pop();
                },
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: Radio(
                          activeColor: CFColors.link2,
                          value: WalletBalanceToggleState.full,
                          groupValue: ref
                              .watch(walletBalanceToggleStateProvider.state)
                              .state,
                          onChanged: (_) {
                            ref
                                .read(walletBalanceToggleStateProvider.state)
                                .state = WalletBalanceToggleState.full;
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Full balance",
                            style: STextStyles.titleBold12,
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          // TODO need text from design
                          Text(
                            "Total wallet balance",
                            style: STextStyles.itemSubtitle12.copyWith(
                              color: CFColors.neutral60,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 40,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
