import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:stackwallet/models/exchange/change_now/exchange_transaction_status.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/notifications/show_flush_bar.dart';
import 'package:stackwallet/pages/exchange_view/edit_trade_note_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/edit_note_view.dart';
import 'package:stackwallet/pages/wallet_view/transaction_views/transaction_details_view.dart';
import 'package:stackwallet/providers/exchange/trade_note_service_provider.dart';
import 'package:stackwallet/providers/global/trades_service_provider.dart';
import 'package:stackwallet/providers/providers.dart';
import 'package:stackwallet/utilities/assets.dart';
import 'package:stackwallet/utilities/cfcolors.dart';
import 'package:stackwallet/utilities/clipboard_interface.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/enums/flush_bar_type.dart';
import 'package:stackwallet/utilities/format.dart';
import 'package:stackwallet/utilities/text_styles.dart';
import 'package:stackwallet/widgets/custom_buttons/app_bar_icon_button.dart';
import 'package:stackwallet/widgets/rounded_container.dart';
import 'package:stackwallet/widgets/rounded_white_container.dart';
import 'package:stackwallet/widgets/stack_dialog.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

class TradeDetailsView extends ConsumerStatefulWidget {
  const TradeDetailsView({
    Key? key,
    required this.tradeId,
    required this.transactionIfSentFromStack,
    required this.walletId,
    required this.walletName,
    this.clipboard = const ClipboardWrapper(),
  }) : super(key: key);

  static const String routeName = "/tradeDetails";

  final String tradeId;
  final ClipboardInterface clipboard;
  final Transaction? transactionIfSentFromStack;
  final String? walletId;
  final String? walletName;

  @override
  ConsumerState<TradeDetailsView> createState() => _TradeDetailsViewState();
}

class _TradeDetailsViewState extends ConsumerState<TradeDetailsView> {
  late final String tradeId;
  late final ClipboardInterface clipboard;
  late final Transaction? transactionIfSentFromStack;
  late final String? walletId;

  String _note = "";

  @override
  initState() {
    tradeId = widget.tradeId;
    clipboard = widget.clipboard;
    transactionIfSentFromStack = widget.transactionIfSentFromStack;
    walletId = widget.walletId;
    super.initState();
  }

  String _fetchIconAssetForStatus(String statusString) {
    ChangeNowTransactionStatus? status;
    try {
      if (statusString.toLowerCase().startsWith("waiting")) {
        statusString = "Waiting";
      }
      status = changeNowTransactionStatusFromStringIgnoreCase(statusString);
    } on ArgumentError catch (_) {
      status = ChangeNowTransactionStatus.Failed;
    }

    debugPrint("statusstatusstatusstatus: $status");
    debugPrint("statusstatusstatusstatusSTRING: $statusString");
    switch (status) {
      case ChangeNowTransactionStatus.New:
      case ChangeNowTransactionStatus.Waiting:
      case ChangeNowTransactionStatus.Confirming:
      case ChangeNowTransactionStatus.Exchanging:
      case ChangeNowTransactionStatus.Sending:
      case ChangeNowTransactionStatus.Refunded:
      case ChangeNowTransactionStatus.Verifying:
        return Assets.svg.txExchangePending;
      case ChangeNowTransactionStatus.Finished:
        return Assets.svg.txExchange;
      case ChangeNowTransactionStatus.Failed:
        return Assets.svg.txExchangeFailed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool sentFromStack =
        transactionIfSentFromStack != null && walletId != null;

    final trade = ref.watch(tradesServiceProvider
        .select((value) => value.trades.firstWhere((e) => e.id == tradeId)));

    final bool hasTx = sentFromStack ||
        !(trade.statusObject?.status == ChangeNowTransactionStatus.New ||
            trade.statusObject?.status == ChangeNowTransactionStatus.Waiting ||
            trade.statusObject?.status == ChangeNowTransactionStatus.Refunded ||
            trade.statusObject?.status == ChangeNowTransactionStatus.Failed);

    debugPrint("sentFromStack: $sentFromStack");
    debugPrint("hasTx: $hasTx");
    debugPrint("trade: ${trade.toString()}");

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
          "Trade details",
          style: STextStyles.navBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedWhiteContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            "${trade.fromCurrency.toUpperCase()} → ${trade.toCurrency.toUpperCase()}",
                            style: STextStyles.titleBold12,
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          SelectableText(
                            "${Format.localizedStringAsFixed(value: Decimal.parse(trade.statusObject?.amountSendDecimal ?? trade.amount), locale: ref.watch(
                                  localeServiceChangeNotifierProvider
                                      .select((value) => value.locale),
                                ), decimalPlaces: trade.fromCurrency.toLowerCase() == "xmr" ? 12 : 8)} ${trade.fromCurrency.toUpperCase()}",
                            style: STextStyles.itemSubtitle,
                          ),
                        ],
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            _fetchIconAssetForStatus(
                                trade.statusObject?.status.name ??
                                    trade.statusString),
                            width: 32,
                            height: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Status",
                        style: STextStyles.itemSubtitle,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      SelectableText(
                        trade.statusObject?.status.name ?? trade.statusString,
                        style: STextStyles.itemSubtitle.copyWith(
                          color: trade.statusObject != null
                              ? CFColors.status
                                  .forStatus(trade.statusObject!.status)
                              : CFColors.stackAccent,
                        ),
                      ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                if (!sentFromStack && hasTx)
                  const SizedBox(
                    height: 12,
                  ),
                if (!sentFromStack && !hasTx)
                  RoundedContainer(
                    color: CFColors.warningBackground,
                    child: RichText(
                      text: TextSpan(
                          text: "You must send at least ${Decimal.parse(
                            trade.statusObject!.amountSendDecimal,
                          ).toStringAsFixed(
                            trade.fromCurrency.toLowerCase() == "xmr" ? 12 : 8,
                          )} ${trade.fromCurrency.toUpperCase()}. ",
                          style: STextStyles.label.copyWith(
                            color: CFColors.stackAccent,
                            fontWeight: FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text: "If you send less than ${Decimal.parse(
                                trade.statusObject!.amountSendDecimal,
                              ).toStringAsFixed(
                                trade.fromCurrency.toLowerCase() == "xmr"
                                    ? 12
                                    : 8,
                              )} ${trade.fromCurrency.toUpperCase()}, your transaction may not be converted and it may not be refunded.",
                              style: STextStyles.label.copyWith(
                                color: CFColors.stackAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ]),
                    ),
                  ),
                if (sentFromStack)
                  const SizedBox(
                    height: 12,
                  ),
                if (sentFromStack)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sent from",
                          style: STextStyles.itemSubtitle,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          widget.walletName!,
                          style: STextStyles.itemSubtitle12,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            final Coin coin = coinFromTickerCaseInsensitive(
                                trade.fromCurrency);

                            Navigator.of(context).pushNamed(
                              TransactionDetailsView.routeName,
                              arguments: Tuple3(
                                  transactionIfSentFromStack!, coin, walletId!),
                            );
                          },
                          child: Text(
                            "View transaction",
                            style: STextStyles.link2,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (sentFromStack)
                  const SizedBox(
                    height: 12,
                  ),
                if (sentFromStack)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ChangeNOW address",
                          style: STextStyles.itemSubtitle,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          trade.payinAddress,
                          style: STextStyles.itemSubtitle12,
                        ),
                      ],
                    ),
                  ),
                if (!sentFromStack && !hasTx)
                  const SizedBox(
                    height: 12,
                  ),
                if (!sentFromStack && !hasTx)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Send ${trade.fromCurrency.toUpperCase()} to this address",
                          style: STextStyles.itemSubtitle,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        SelectableText(
                          trade.payinAddress,
                          style: STextStyles.itemSubtitle12,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog<dynamic>(
                              context: context,
                              useSafeArea: false,
                              barrierDismissible: true,
                              builder: (_) {
                                final width =
                                    MediaQuery.of(context).size.width / 2;
                                return StackDialogBase(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Center(
                                        child: Text(
                                          "Recovery phrase QR code",
                                          style: STextStyles.pageTitleH2,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Center(
                                        child: RepaintBoundary(
                                          // key: _qrKey,
                                          child: SizedBox(
                                            width: width + 20,
                                            height: width + 20,
                                            child: QrImage(
                                              data: trade.payinAddress,
                                              size: width,
                                              backgroundColor: CFColors.white,
                                              foregroundColor:
                                                  CFColors.stackAccent,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Center(
                                        child: SizedBox(
                                          width: width,
                                          child: TextButton(
                                            onPressed: () async {
                                              // await _capturePng(true);
                                              Navigator.of(context).pop();
                                            },
                                            style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(
                                                CFColors.buttonGray,
                                              ),
                                            ),
                                            child: Text(
                                              "Cancel",
                                              style:
                                                  STextStyles.button.copyWith(
                                                color: CFColors.stackAccent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                Assets.svg.pencil,
                                width: 10,
                                height: 10,
                                color: CFColors.link2,
                              ),
                              const SizedBox(
                                width: 4,
                              ),
                              Text(
                                "Edit",
                                style: STextStyles.link2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Trade note",
                            style: STextStyles.itemSubtitle,
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushNamed(
                                EditTradeNoteView.routeName,
                                arguments: Tuple2(
                                  tradeId,
                                  ref
                                      .read(tradeNoteServiceProvider)
                                      .getNote(tradeId: tradeId),
                                ),
                              );
                            },
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  Assets.svg.pencil,
                                  width: 10,
                                  height: 10,
                                  color: CFColors.link2,
                                ),
                                const SizedBox(
                                  width: 4,
                                ),
                                Text(
                                  "Edit",
                                  style: STextStyles.link2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      SelectableText(
                        ref.watch(tradeNoteServiceProvider.select(
                            (value) => value.getNote(tradeId: tradeId))),
                        style: STextStyles.itemSubtitle12,
                      ),
                    ],
                  ),
                ),
                if (sentFromStack)
                  const SizedBox(
                    height: 12,
                  ),
                if (sentFromStack)
                  RoundedWhiteContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Transaction note",
                              style: STextStyles.itemSubtitle,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  EditNoteView.routeName,
                                  arguments: Tuple3(
                                    transactionIfSentFromStack!.txid,
                                    walletId!,
                                    _note,
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  SvgPicture.asset(
                                    Assets.svg.pencil,
                                    width: 10,
                                    height: 10,
                                    color: CFColors.link2,
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  Text(
                                    "Edit",
                                    style: STextStyles.link2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        FutureBuilder(
                          future: ref.watch(
                              notesServiceChangeNotifierProvider(walletId!)
                                  .select((value) => value.getNoteFor(
                                      txid: transactionIfSentFromStack!.txid))),
                          builder:
                              (builderContext, AsyncSnapshot<String> snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              _note = snapshot.data ?? "";
                            }
                            return SelectableText(
                              _note,
                              style: STextStyles.itemSubtitle12,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Date",
                        style: STextStyles.itemSubtitle,
                      ),
                      // Flexible(
                      //   child: FittedBox(
                      //     fit: BoxFit.scaleDown,
                      //     child:
                      SelectableText(
                        Format.extractDateFrom(
                            trade.date.millisecondsSinceEpoch ~/ 1000),
                        style: STextStyles.itemSubtitle12,
                      ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Exchange",
                        style: STextStyles.itemSubtitle,
                      ),
                      // Flexible(
                      //   child: FittedBox(
                      //     fit: BoxFit.scaleDown,
                      //     child:
                      SelectableText(
                        "ChangeNOW",
                        style: STextStyles.itemSubtitle12,
                      ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Row(
                    children: [
                      Text(
                        "Trade ID",
                        style: STextStyles.itemSubtitle,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            trade.id,
                            style: STextStyles.itemSubtitle12,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          GestureDetector(
                            onTap: () async {
                              final data = ClipboardData(text: trade.id);
                              await clipboard.setData(data);
                              showFloatingFlushBar(
                                type: FlushBarType.info,
                                message: "Copied to clipboard",
                                context: context,
                              );
                            },
                            child: SvgPicture.asset(
                              Assets.svg.copy,
                              color: CFColors.link2,
                              width: 12,
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                RoundedWhiteContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Tracking",
                        style: STextStyles.itemSubtitle,
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      GestureDetector(
                        onTap: () {
                          final url =
                              "https://changenow.io/exchange/txs/${trade.id}";
                          launchUrl(
                            Uri.parse(url),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                        child: Text(
                          "https://changenow.io/exchange/txs/${trade.id}",
                          style: STextStyles.link2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
