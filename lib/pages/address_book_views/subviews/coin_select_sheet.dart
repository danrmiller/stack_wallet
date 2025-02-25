import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';

class CoinSelectSheet extends StatelessWidget {
  const CoinSelectSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            left: 24,
            right: 24,
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
              Text(
                "Select address cryptocurrency",
                style: STextStyles.pageTitleH2,
                textAlign: TextAlign.left,
              ),
              const SizedBox(
                height: 16,
              ),
              Flexible(
                child: Consumer(
                  builder: (_, ref, __) {
                    bool showTestNet = ref.watch(
                      prefsChangeNotifierProvider
                          .select((value) => value.showTestNetCoins),
                    );

                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: showTestNet
                          ? Coin.values.length
                          : Coin.values.length - kTestNetCoinCount,
                      itemBuilder: (builderContext, index) {
                        final coin = Coin.values[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: RawMaterialButton(
                            // splashColor: CFColors.splashLight,
                            onPressed: () {
                              Navigator.of(context).pop(coin);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.iconFor(coin: coin),
                                    height: 20,
                                    width: 20,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    coin.prettyName,
                                    style: STextStyles.itemSubtitle12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
