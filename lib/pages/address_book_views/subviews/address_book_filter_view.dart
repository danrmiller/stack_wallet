import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stackwallet/providers/global/prefs_provider.dart';
import 'package:stackwallet/providers/ui/address_book_providers/address_book_filter_provider.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';

class AddressBookFilterView extends ConsumerStatefulWidget {
  const AddressBookFilterView({Key? key}) : super(key: key);

  static const String routeName = "/addressBookFilter";

  @override
  ConsumerState<AddressBookFilterView> createState() =>
      _AddressBookFilterViewState();
}

class _AddressBookFilterViewState extends ConsumerState<AddressBookFilterView> {
  late final List<Coin> _coins;

  @override
  void initState() {
    final coins = Coin.values;

    bool showTestNet = ref.read(prefsChangeNotifierProvider).showTestNetCoins;

    if (showTestNet) {
      _coins = coins.toList(growable: false);
    } else {
      _coins = coins
          .toList(growable: false)
          .getRange(0, coins.length - kTestNetCoinCount + 1)
          .toList(growable: false);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CFColors.almostWhite,
      appBar: AppBar(
        backgroundColor: CFColors.almostWhite,
        leading: AppBarBackButton(
          onPressed: () async {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          "Filter addresses",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: LayoutBuilder(builder: (builderContext, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RoundedWhiteContainer(
                        child: Text(
                          "Only selected cryptocurrency addresses will be displayed.",
                          style: STextStyles.itemSubtitle,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        "Select cryptocurrency",
                        style: STextStyles.smallMed12,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      RoundedWhiteContainer(
                        padding: const EdgeInsets.all(0),
                        child: Wrap(
                          children: [
                            ..._coins.map(
                              (coin) => Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      if (ref
                                          .read(addressBookFilterProvider)
                                          .coins
                                          .contains(coin)) {
                                        ref
                                            .read(addressBookFilterProvider)
                                            .remove(coin, true);
                                      } else {
                                        ref
                                            .read(addressBookFilterProvider)
                                            .add(coin, true);
                                      }
                                      setState(() {});
                                    },
                                    child: Container(
                                      color: Colors.transparent,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: Checkbox(
                                                value: ref
                                                    .watch(
                                                        addressBookFilterProvider
                                                            .select((value) =>
                                                                value.coins))
                                                    .contains(coin),
                                                onChanged: (value) {
                                                  if (value is bool) {
                                                    if (value) {
                                                      ref
                                                          .read(
                                                              addressBookFilterProvider)
                                                          .add(coin, true);
                                                    } else {
                                                      ref
                                                          .read(
                                                              addressBookFilterProvider)
                                                          .remove(coin, true);
                                                    }
                                                    setState(() {});
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 12,
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  coin.prettyName,
                                                  style:
                                                      STextStyles.largeMedium14,
                                                ),
                                                const SizedBox(
                                                  height: 2,
                                                ),
                                                Text(
                                                  coin.ticker,
                                                  style:
                                                      STextStyles.itemSubtitle,
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Row(
                      //   children: [
                      //     TextButton(
                      //       onPressed: () {},
                      //       child: Text("Cancel"),
                      //     ),
                      //     SizedBox(
                      //       width: 16,
                      //     ),
                      //     TextButton(
                      //       onPressed: () {},
                      //       child: Text("Cancel"),
                      //     ),
                      //   ],
                      // )
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
