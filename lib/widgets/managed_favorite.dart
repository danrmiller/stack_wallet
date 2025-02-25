import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/favorite_toggle.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class ManagedFavorite extends ConsumerStatefulWidget {
  const ManagedFavorite({
    Key? key,
    required this.walletId,
  }) : super(key: key);

  final String walletId;

  @override
  ConsumerState<ManagedFavorite> createState() => _ManagedFavoriteCardState();
}

class _ManagedFavoriteCardState extends ConsumerState<ManagedFavorite> {
  @override
  Widget build(BuildContext context) {
    final manager = ref.watch(walletsChangeNotifierProvider
        .select((value) => value.getManager(widget.walletId)));
    debugPrint("BUILD: $runtimeType with walletId ${widget.walletId}");

    return RoundedWhiteContainer(
      padding: const EdgeInsets.all(4.0),
      child: RawMaterialButton(
        onPressed: () async {
          final provider = ref
              .read(walletsChangeNotifierProvider)
              .getManagerProvider(manager.walletId);
          if (!manager.isFavorite) {
            ref.read(favoritesProvider).add(provider, true);
            ref.read(nonFavoritesProvider).remove(provider, true);
            ref
                .read(walletsServiceChangeNotifierProvider)
                .addFavorite(manager.walletId);
          } else {
            ref.read(favoritesProvider).remove(provider, true);
            ref.read(nonFavoritesProvider).add(provider, true);
            ref
                .read(walletsServiceChangeNotifierProvider)
                .removeFavorite(manager.walletId);
          }

          manager.isFavorite = !manager.isFavorite;
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            Constants.size.circularBorderRadius,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: CFColors.coin.forCoin(manager.coin).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(
                    Constants.size.circularBorderRadius,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(
                    Assets.svg.iconFor(coin: manager.coin),
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
              const SizedBox(
                width: 12,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    manager.walletName,
                    style: STextStyles.titleBold12,
                  ),
                  const SizedBox(
                    height: 2,
                  ),
                  Text(
                    "${Format.localizedStringAsFixed(
                      value: manager.cachedTotalBalance,
                      locale: ref.watch(localeServiceChangeNotifierProvider
                          .select((value) => value.locale)),
                      decimalPlaces: 8,
                    )} ${manager.coin.ticker}",
                    style: STextStyles.itemSubtitle,
                  ),
                ],
              ),
              const Spacer(),
              FavoriteToggle(
                borderRadius: BorderRadius.circular(
                  Constants.size.circularBorderRadius,
                ),
                initialState: manager.isFavorite,
                onChanged: null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
