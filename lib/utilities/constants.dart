import 'dart:io';

import 'package:stackwallet/utilities/enums/coin_enum.dart';

class _LayoutSizing {
  const _LayoutSizing();

  double get circularBorderRadius => 8.0;
  double get checkboxBorderRadius => 4.0;

  double get standardPadding => 16.0;
}

abstract class Constants {
  static const size = _LayoutSizing();

  static final bool enableExchange = !Platform.isIOS;

  //TODO: correct for monero?
  static const int satsPerCoinMonero = 1000000000000;
  static const int satsPerCoin = 100000000;
  static const int decimalPlaces = 8;

  static const int notificationsMax = 0xFFFFFFFF;
  static const Duration networkAliveTimerDuration = Duration(seconds: 10);

  static const int pinLength = 4;

  // enable testnet
  // TODO: currently unused
  static const bool allowTestnets = true;

  // Enable Logger.print statements
  static const bool disableLogger = false;

  static const int currentDbVersion = 0;

  static List<int> possibleLengthsForCoin(Coin coin) {
    final List<int> values = [];
    switch (coin) {
      case Coin.bitcoin:
      case Coin.dogecoin:
      case Coin.firo:
      case Coin.bitcoinTestNet:
      case Coin.dogecoinTestNet:
      case Coin.firoTestNet:
      case Coin.epicCash:
        values.addAll([24, 21, 18, 15, 12]);
        break;

      case Coin.monero:
        values.addAll([25]);
        break;
    }
    return values;
  }

  static int targetBlockTimeInSeconds(Coin coin) {
    // TODO verify values
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return 600;

      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
        return 60;

      case Coin.firo:
      case Coin.firoTestNet:
        return 150;

      case Coin.epicCash:
        return 60;

      case Coin.monero:
        return 120;
    }
  }

  static const int seedPhraseWordCountBip39 = 24;
  static const int seedPhraseWordCountMonero = 25;

  static const Map<int, String> monthMapShort = {
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  };

  static const Map<int, String> monthMap = {
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };
}
