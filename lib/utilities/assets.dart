import 'package:stackwallet/utilities/enums/coin_enum.dart';

abstract class Assets {
  static const svg = _SVG();
  static const png = _PNG();
  static const lottie = _ANIMATIONS();
  static const socials = _SOCIALS();
}

class _SOCIALS {
  const _SOCIALS();

  String get discord => "assets/svg/socials/discord.svg";
  String get reddit => "assets/svg/socials/reddit-alien-brands.svg";
  String get twitter => "assets/svg/socials/twitter-brands.svg";
  String get telegram => "assets/svg/socials/telegram-brands.svg";
}

class _SVG {
  const _SVG();

  String get plus => "assets/svg/plus.svg";
  String get gear => "assets/svg/gear.svg";
  String get bell => "assets/svg/bell.svg";
  String get bellNew => "assets/svg/bell-new.svg";
  String get stackIcon => "assets/svg/stack-icon1.svg";
  String get arrowLeft => "assets/svg/arrow-left-fa.svg";
  String get star => "assets/svg/star.svg";
  String get copy => "assets/svg/copy-fa.svg";
  String get circleX => "assets/svg/x-circle.svg";
  String get check => "assets/svg/check.svg";
  String get circleAlert => "assets/svg/alert-circle2.svg";
  String get arrowDownLeft => "assets/svg/arrow-down-left.svg";
  String get arrowUpRight => "assets/svg/arrow-up-right.svg";
  String get bars => "assets/svg/bars.svg";
  String get filter => "assets/svg/filter.svg";
  String get pending => "assets/svg/pending.svg";
  String get exchange => "assets/svg/exchange-2.svg";
  String get buy => "assets/svg/buy-coins-icon.svg";
  String get radio => "assets/svg/signal-stream.svg";
  String get arrowRotate => "assets/svg/arrow-rotate.svg";
  String get arrowRotate2 => "assets/svg/arrow-rotate2.svg";
  String get alertCircle => "assets/svg/alert-circle.svg";
  String get checkCircle => "assets/svg/circle-check.svg";
  String get clipboard => "assets/svg/clipboard.svg";
  String get qrcode => "assets/svg/qrcode1.svg";
  String get ellipsis => "assets/svg/gear-3.svg";
  String get chevronDown => "assets/svg/chevron-down.svg";
  String get swap => "assets/svg/swap.svg";
  String get downloadFolder => "assets/svg/folder-down.svg";
  String get lock => "assets/svg/lock-keyhole.svg";
  String get network => "assets/svg/network-wired.svg";
  String get addressBook => "assets/svg/address-book.svg";
  String get arrowRotate3 => "assets/svg/rotate-exclamation.svg";
  String get delete => "assets/svg/delete.svg";
  String get arrowRight => "assets/svg/arrow-right.svg";
  String get dollarSign => "assets/svg/dollar-sign.svg";
  String get language => "assets/svg/language2.svg";
  String get sun => "assets/svg/sun-bright2.svg";
  String get pencil => "assets/svg/pen-solid-fa.svg";
  String get search => "assets/svg/magnifying-glass.svg";
  String get thickX => "assets/svg/x-fat.svg";
  String get x => "assets/svg/x.svg";
  String get user => "assets/svg/user.svg";
  String get trash => "assets/svg/trash.svg";
  String get eye => "assets/svg/eye.svg";
  String get eyeSlash => "assets/svg/eye-slash.svg";
  String get folder => "assets/svg/folder.svg";
  String get calendar => "assets/svg/calendar-days.svg";
  String get circleQuestion => "assets/svg/circle-question.svg";
  String get circleInfo => "assets/svg/info-circle.svg";
  String get key => "assets/svg/key.svg";
  String get node => "assets/svg/node-alt.svg";
  String get radioProblem => "assets/svg/signal-problem-alt.svg";
  String get radioSyncing => "assets/svg/signal-sync-alt.svg";
  String get walletSettings => "assets/svg/wallet-settings.svg";
  String get verticalEllipsis => "assets/svg/ellipsis-vertical1.svg";
  String get dice => "assets/svg/dice-alt.svg";
  String get circleArrowUpRight => "assets/svg/circle-arrow-up-right2.svg";
  String get loader => "assets/svg/loader.svg";
  String get backupAdd => "assets/svg/add-backup.svg";
  String get backupAuto => "assets/svg/auto-backup.svg";
  String get backupRestore => "assets/svg/restore-backup.svg";
  String get solidSliders => "assets/svg/sliders-solid.svg";
  String get questionMessage => "assets/svg/message-question.svg";
  String get envelope => "assets/svg/envelope.svg";

  String get receive => "assets/svg/tx-icon-receive.svg";
  String get receivePending => "assets/svg/tx-icon-receive-pending.svg";
  String get receiveCancelled => "assets/svg/tx-icon-receive-failed.svg";

  String get send => "assets/svg/tx-icon-send.svg";
  String get sendPending => "assets/svg/tx-icon-send-pending.svg";
  String get sendCancelled => "assets/svg/tx-icon-send-failed.svg";

  String get ellipse1 => "assets/svg/Ellipse-43.svg";
  String get ellipse2 => "assets/svg/Ellipse-42.svg";

  String get txExchange => "assets/svg/tx-exchange-icon.svg";
  String get txExchangePending => "assets/svg/tx-exchange-icon-pending.svg";
  String get txExchangeFailed => "assets/svg/tx-exchange-icon-failed.svg";

  String get bitcoin => "assets/svg/coin_icons/Bitcoin.svg";
  String get dogecoin => "assets/svg/coin_icons/Dogecoin.svg";
  String get epicCash => "assets/svg/coin_icons/EpicCash.svg";
  String get firo => "assets/svg/coin_icons/Firo.svg";
  String get monero => "assets/svg/coin_icons/Monero.svg";

// TODO provide proper assets
  String get bitcoinTestnet => "assets/svg/coin_icons/Bitcoin.svg";
  String get firoTestnet => "assets/svg/coin_icons/Firo.svg";
  String get dogecoinTestnet => "assets/svg/coin_icons/Dogecoin.svg";

  String iconFor({required Coin coin}) {
    switch (coin) {
      case Coin.bitcoin:
        return bitcoin;
      case Coin.dogecoin:
        return dogecoin;
      case Coin.epicCash:
        return epicCash;
      case Coin.firo:
        return firo;
      case Coin.monero:
        return monero;
      case Coin.bitcoinTestNet:
        return bitcoinTestnet;
      case Coin.firoTestNet:
        return firoTestnet;
      case Coin.dogecoinTestNet:
        return dogecoinTestnet;
    }
  }
}

class _PNG {
  const _PNG();

  String get stack => "assets/images/stack.png";
  String get splash => "assets/images/splash.png";

  String get monero => "assets/images/monero.png";
  String get firo => "assets/images/firo.png";
  String get dogecoin => "assets/images/doge.png";
  String get bitcoin => "assets/images/bitcoin.png";
  String get epicCash => "assets/images/epic-cash.png";

  String imageFor({required Coin coin}) {
    switch (coin) {
      case Coin.bitcoin:
      case Coin.bitcoinTestNet:
        return bitcoin;
      case Coin.dogecoin:
      case Coin.dogecoinTestNet:
        return dogecoin;
      case Coin.epicCash:
        return epicCash;
      case Coin.firo:
      case Coin.firoTestNet:
        return firo;
      case Coin.monero:
        return monero;
    }
  }
}

class _ANIMATIONS {
  const _ANIMATIONS();

  String get test => "assets/lottie/test.json";
  String get test2 => "assets/lottie/test2.json";
}
