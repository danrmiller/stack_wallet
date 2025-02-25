import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/models/wallet_restore_state.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_views/recovery_phrase_view.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/sub_widgets/restoring_item_card.dart';
import 'package:stackwallet/providers/stack_restore/stack_restoring_ui_state_provider.dart';
import 'package:stackwallet/route_generator.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/stack_restoring_status.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/loading_indicator.dart';
import 'package:stackwallet/widgets/rounded_container.dart';

class RestoringWalletCard extends ConsumerStatefulWidget {
  const RestoringWalletCard({
    Key? key,
    required this.provider,
  }) : super(key: key);

  final ChangeNotifierProvider<WalletRestoreState> provider;

  @override
  ConsumerState<RestoringWalletCard> createState() =>
      _RestoringWalletCardState();
}

class _RestoringWalletCardState extends ConsumerState<RestoringWalletCard> {
  late final ChangeNotifierProvider<WalletRestoreState> provider;

  Widget _getIconForState(StackRestoringStatus state) {
    switch (state) {
      case StackRestoringStatus.waiting:
        return SvgPicture.asset(
          Assets.svg.loader,
          color: CFColors.buttonGray,
        );
      case StackRestoringStatus.restoring:
        return const LoadingIndicator();
      // return SvgPicture.asset(
      //   Assets.svg.loader,
      //   color: CFColors.stackGreen,
      // );
      case StackRestoringStatus.success:
        return SvgPicture.asset(
          Assets.svg.checkCircle,
          color: CFColors.stackGreen,
        );
      case StackRestoringStatus.failed:
        return SvgPicture.asset(
          Assets.svg.circleAlert,
          color: CFColors.error,
        );
    }
  }

  @override
  void initState() {
    provider = widget.provider;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final coin = ref.watch(provider.select((value) => value.coin));
    final restoringStatus =
        ref.watch(provider.select((value) => value.restoringState));
    return RestoringItemCard(
      left: SizedBox(
        width: 32,
        height: 32,
        child: RoundedContainer(
          padding: const EdgeInsets.all(0),
          color: CFColors.coin.forCoin(coin),
          child: Center(
            child: SvgPicture.asset(
              Assets.svg.iconFor(
                coin: coin,
              ),
              height: 20,
              width: 20,
            ),
          ),
        ),
      ),
      onRightTapped: restoringStatus == StackRestoringStatus.failed
          ? () async {
              final manager = ref.read(provider).manager!;

              ref.read(stackRestoringUIStateProvider).update(
                  walletId: manager.walletId,
                  restoringStatus: StackRestoringStatus.restoring);

              try {
                final mnemonicList = await manager.mnemonic;
                const maxUnusedAddressGap = 20;
                const maxNumberOfIndexesToCheck = 1000;

                if (mnemonicList.isEmpty) {
                  await manager.recoverFromMnemonic(
                    mnemonic: ref.read(provider).mnemonic!,
                    maxUnusedAddressGap: maxUnusedAddressGap,
                    maxNumberOfIndexesToCheck: maxNumberOfIndexesToCheck,
                    height: ref.read(provider).height ?? 0,
                  );
                } else {
                  await manager.fullRescan(
                    maxUnusedAddressGap,
                    maxNumberOfIndexesToCheck,
                  );
                }

                if (mounted) {
                  final address = await manager.currentReceivingAddress;

                  ref.read(stackRestoringUIStateProvider).update(
                        walletId: manager.walletId,
                        restoringStatus: StackRestoringStatus.success,
                        address: address,
                      );
                }
              } catch (_) {
                if (mounted) {
                  ref.read(stackRestoringUIStateProvider).update(
                        walletId: manager.walletId,
                        restoringStatus: StackRestoringStatus.failed,
                      );
                }
              }
            }
          : null,
      right: SizedBox(
        width: 20,
        height: 20,
        child: _getIconForState(
          ref.watch(provider.select((value) => value.restoringState)),
        ),
      ),
      title:
          "${ref.watch(provider.select((value) => value.walletName))} (${coin.ticker})",
      subTitle: restoringStatus == StackRestoringStatus.failed
          ? Text(
              "Unable to restore. Tap icon to retry.",
              style: STextStyles.errorSmall,
            )
          : ref.watch(provider.select((value) => value.address)) != null
              ? Text(
                  ref.watch(provider.select((value) => value.address))!,
                  style: STextStyles.infoSmall,
                )
              : null,
      button: restoringStatus == StackRestoringStatus.failed
          ? Container(
              height: 20,
              decoration: BoxDecoration(
                color: CFColors.buttonGray,
                borderRadius: BorderRadius.circular(
                  1000,
                ),
              ),
              child: RawMaterialButton(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                splashColor: CFColors.splashLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    1000,
                  ),
                ),
                onPressed: () async {
                  final mnemonic = ref.read(provider).mnemonic;

                  if (mnemonic != null) {
                    Navigator.of(context).push(
                      RouteGenerator.getRoute(
                        builder: (_) => RecoverPhraseView(
                          walletName: ref.read(provider).walletName,
                          mnemonic: mnemonic.split(" "),
                        ),
                      ),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    "Show recovery phrase",
                    style: STextStyles.infoSmall.copyWith(
                      color: CFColors.stackAccent,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
