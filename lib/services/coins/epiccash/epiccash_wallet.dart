import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_libepiccash/epic_cash.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stack_wallet_backup/generate_password.dart';
import 'package:stackwallet/hive/db.dart';
import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/models/paymint/fee_object_model.dart';
import 'package:stackwallet/models/paymint/transactions_model.dart';
import 'package:stackwallet/models/paymint/utxo_model.dart';
import 'package:stackwallet/services/coins/coin_service.dart';
import 'package:stackwallet/services/event_bus/events/global/blocks_remaining_event.dart';
import 'package:stackwallet/services/event_bus/events/global/node_connection_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/refresh_percent_changed_event.dart';
import 'package:stackwallet/services/event_bus/events/global/updated_in_background_event.dart';
import 'package:stackwallet/services/event_bus/events/global/wallet_sync_status_changed_event.dart';
import 'package:stackwallet/services/event_bus/global_event_bus.dart';
import 'package:stackwallet/services/node_service.dart';
import 'package:stackwallet/services/price.dart';
import 'package:stackwallet/utilities/constants.dart';
import 'package:stackwallet/utilities/default_nodes.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:stackwallet/utilities/test_epic_box_connection.dart';
import 'package:tuple/tuple.dart';

const int MINIMUM_CONFIRMATIONS = 10;

const String GENESIS_HASH_MAINNET = "";
const String GENESIS_HASH_TESTNET = "";

// isolate

Map<ReceivePort, Isolate> isolates = {};

Future<ReceivePort> getIsolate(Map<String, dynamic> arguments,
    {String name = ""}) async {
  ReceivePort receivePort =
      ReceivePort(); //port for isolate to receive messages.
  arguments['sendPort'] = receivePort.sendPort;
  Logging.instance.log("starting isolate ${arguments['function']} name: $name",
      level: LogLevel.Info);
  Isolate isolate = await Isolate.spawn(executeNative, arguments);
  isolates[receivePort] = isolate;
  return receivePort;
}

Future<void> executeNative(Map<String, dynamic> arguments) async {
  await Logging.instance.initInIsolate();
  final SendPort sendPort = arguments['sendPort'] as SendPort;
  final function = arguments['function'] as String;
  try {
    if (function == "scanOutPuts") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final startHeight = arguments['startHeight'] as int?;
      final numberOfBlocks = arguments['numberOfBlocks'] as int?;
      Map<String, dynamic> result = {};
      if (!(config == null ||
          password == null ||
          startHeight == null ||
          numberOfBlocks == null)) {
        var outputs =
            await scanOutPuts(config, password, startHeight, numberOfBlocks);
        result['outputs'] = outputs;
        sendPort.send(result);
        return;
      }
    } else if (function == "getPendingSlates") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final secretKeyIndex = arguments['secretKeyIndex'] as int?;
      final slates = arguments['slates'] as String;
      Map<String, dynamic> result = {};

      if (!(config == null || password == null || secretKeyIndex == null)) {
        Logging.instance
            .log("SECRET_KEY_INDEX_IS $secretKeyIndex", level: LogLevel.Info);
        result['result'] =
            await getPendingSlates(config, password, secretKeyIndex, slates);
        sendPort.send(result);
        return;
      }
    } else if (function == "subscribeRequest") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final secretKeyIndex = arguments['secretKeyIndex'] as int?;
      final epicboxConfig = arguments['epicboxConfig'] as String?;
      Map<String, dynamic> result = {};

      if (!(config == null ||
          password == null ||
          secretKeyIndex == null ||
          epicboxConfig == null)) {
        Logging.instance
            .log("SECRET_KEY_INDEX_IS $secretKeyIndex", level: LogLevel.Info);
        result['result'] = await getSubscribeRequest(
            config, password, secretKeyIndex, epicboxConfig);
        sendPort.send(result);
        return;
      }
    } else if (function == "processSlates") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final slates = arguments['slates'];
      Map<String, dynamic> result = {};

      if (!(config == null || password == null || slates == null)) {
        result['result'] =
            await processSlates(config, password, slates.toString());
        sendPort.send(result);
        return;
      }
    } else if (function == "getWalletInfo") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final refreshFromNode = arguments['refreshFromNode'] as int?;
      final minimumConfirmations = arguments['minimumConfirmations'] as int?;
      Map<String, dynamic> result = {};
      if (!(config == null ||
          password == null ||
          refreshFromNode == null ||
          minimumConfirmations == null)) {
        var res = await getWalletInfo(
            config, password, refreshFromNode, minimumConfirmations);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "getTransactions") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final refreshFromNode = arguments['refreshFromNode'] as int?;
      Map<String, dynamic> result = {};
      if (!(config == null || password == null || refreshFromNode == null)) {
        var res = await getTransactions(config, password, refreshFromNode);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "startSync") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      const int refreshFromNode = 1;
      Map<String, dynamic> result = {};
      if (!(config == null || password == null)) {
        var res = await getWalletInfo(config, password, refreshFromNode, 10);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "getTransactionFees") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final amount = arguments['amount'] as int?;
      final minimumConfirmations = arguments['minimumConfirmations'] as int?;
      Map<String, dynamic> result = {};
      if (!(config == null ||
          password == null ||
          amount == null ||
          minimumConfirmations == null)) {
        var res = await getTransactionFees(
            config, password, amount, minimumConfirmations);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    } else if (function == "createTransaction") {
      final config = arguments['config'] as String?;
      final password = arguments['password'] as String?;
      final amount = arguments['amount'] as int?;
      final address = arguments['address'] as String?;
      final secretKeyIndex = arguments['secretKeyIndex'] as int?;
      final epicboxConfig = arguments['epicboxConfig'] as String?;
      final minimumConfirmations = arguments['minimumConfirmations'] as int?;

      Map<String, dynamic> result = {};
      if (!(config == null ||
          password == null ||
          amount == null ||
          address == null ||
          secretKeyIndex == null ||
          epicboxConfig == null ||
          minimumConfirmations == null)) {
        var res = await createTransaction(config, password, amount, address,
            secretKeyIndex, epicboxConfig, minimumConfirmations);
        result['result'] = res;
        sendPort.send(result);
        return;
      }
    }
    Logging.instance.log(
        "Error Arguments for $function not formatted correctly",
        level: LogLevel.Fatal);
    sendPort.send("Error Arguments for $function not formatted correctly");
  } catch (e, s) {
    Logging.instance.log(
        "An error was thrown in this isolate $function: $e\n$s",
        level: LogLevel.Error);
    sendPort
        .send("Error An error was thrown in this isolate $function: $e\n$s");
  } finally {
    Logging.instance.isar?.close();
  }
}

void stop(ReceivePort port) {
  Isolate? isolate = isolates.remove(port);
  if (isolate != null) {
    isolate.kill(priority: Isolate.immediate);
    isolate = null;
  }
}

// Keep Wrapper functions outside of the class to avoid memory leaks and errors about receive ports and illegal arguments.
// TODO: Can get rid of this wrapper and call it in a full isolate instead of compute() if we want more control over this
Future<String> _cancelTransactionWrapper(
    Tuple3<String, String, String> data) async {
  // assuming this returns an empty string on success
  // or an error message string on failure
  return cancelTransaction(data.item1, data.item2, data.item3);
}

Future<String> _deleteWalletWrapper(Tuple2<String, String> data) async {
  return deleteWallet(data.item1, data.item2);
}

Future<String> deleteEpicWallet({
  required String walletId,
  required FlutterSecureStorageInterface secureStore,
}) async {
  String? config = await secureStore.read(key: '${walletId}_config');
  if (Platform.isIOS) {
    Directory appDir = (await getApplicationDocumentsDirectory());
    if (Platform.isIOS) {
      appDir = (await getLibraryDirectory());
    }
    final path = "${appDir.path}/epiccash";
    final String name = walletId;

    final walletDir = '$path/$name';
    var editConfig = jsonDecode(config as String);

    editConfig["wallet_dir"] = walletDir;
    config = jsonEncode(editConfig);
  }

  final password = await secureStore.read(key: '${walletId}_password');

  return compute(_deleteWalletWrapper, Tuple2(config!, password!));
}

Future<String> _initWalletWrapper(
    Tuple4<String, String, String, String> data) async {
  final String initWalletStr =
      initWallet(data.item1, data.item2, data.item3, data.item4);
  return initWalletStr;
}

Future<String> _initGetAddressInfoWrapper(
    Tuple4<String, String, int, String> data) async {
  String walletAddress =
      getAddressInfo(data.item1, data.item2, data.item3, data.item4);
  return walletAddress;
}

Future<String> _walletMnemonicWrapper(int throwaway) async {
  final String mnemonic = walletMnemonic();
  return mnemonic;
}

Future<String> _recoverWrapper(
    Tuple4<String, String, String, String> data) async {
  return recoverWallet(data.item1, data.item2, data.item3, data.item4);
}

Future<int> _getChainHeightWrapper(String config) async {
  final int chainHeight = getChainHeight(config);
  return chainHeight;
}

const String EPICPOST_ADDRESS = 'https://epicpost.stackwallet.com';

Future<bool> postSlate(String receiveAddress, String slate) async {
  Logging.instance.log("postSlate", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/postSlate");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'slate': slate
      }),
    );

    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

Future<dynamic> getSlates(String receiveAddress, String signature) async {
  Logging.instance.log("getslates", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/getSlates");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
      }),
    );

    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return response['slates'];
    } else {
      return response['error'];
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return 'Error $e $s';
  }
}

Future<bool> postCancel(
    String receiveAddress, String slate_id, signature, sendersAddress) async {
  Logging.instance.log("postCancel", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/postCancel");

    final body = jsonEncode({
      "jsonrpc": "2.0",
      "id": "0",
      'receivingAddress': receiveAddress,
      "signature": signature,
      'slate': slate_id,
      "sendersAddress": sendersAddress,
    });
    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return false;
  }
}

Future<dynamic> getCancels(String receiveAddress, String signature) async {
  Logging.instance.log("getCancels", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/getCancels");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
      }),
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return response['canceled_slates'];
    } else {
      return response['error'];
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return 'Error $e $s';
  }
}

Future<dynamic> deleteCancels(
    String receiveAddress, String signature, String slate) async {
  Logging.instance.log("deleteCancels", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/deleteCancels");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
        'slate': slate,
      }),
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Error);
    return 'Error $e $s';
  }
}

Future<dynamic> deleteSlate(
    String receiveAddress, String signature, String slate) async {
  Logging.instance.log("deleteSlate", level: LogLevel.Info);
  final Client client = Client();
  try {
    final uri = Uri.parse("$EPICPOST_ADDRESS/deleteSlate");

    final epicpost = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        'receivingAddress': receiveAddress,
        'signature': signature,
        'slate': slate,
      }),
    );
    // TODO: should the following be removed for security reasons in production?
    Logging.instance.log(epicpost.statusCode.toString(), level: LogLevel.Info);
    Logging.instance.log(epicpost.body.toString(), level: LogLevel.Info);
    final response = jsonDecode(epicpost.body.toString());
    if (response['status'] == 'success') {
      return true;
    } else {
      return false;
    }
  } catch (e, s) {
    Logging.instance.log("$e $s", level: LogLevel.Info);
    return 'Error $e $s';
  }
}

class EpicCashWallet extends CoinServiceAPI {
  static const integrationTestFlag =
      bool.fromEnvironment("IS_INTEGRATION_TEST");
  final m = Mutex();
  final syncMutex = Mutex();

  final _prefs = Prefs.instance;

  NodeModel? _epicNode;

  EpicCashWallet(
      {required String walletId,
      required String walletName,
      required Coin coin,
      PriceAPI? priceAPI,
      FlutterSecureStorageInterface? secureStore}) {
    _walletId = walletId;
    _walletName = walletName;
    _coin = coin;

    _priceAPI = priceAPI ?? PriceAPI(Client());
    _secureStore =
        secureStore ?? const SecureStorageWrapper(FlutterSecureStorage());

    Logging.instance.log("$walletName isolate length: ${isolates.length}",
        level: LogLevel.Info);
    for (final isolate in isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    isolates.clear();
  }

  @override
  Future<void> updateNode(bool shouldRefresh) async {
    _epicNode = NodeService().getPrimaryNodeFor(coin: coin) ??
        DefaultNodes.getNodeFor(coin);
    // TODO notify ui/ fire event for node changed?

    if (shouldRefresh) {
      refresh();
    }
  }

  @override
  set isFavorite(bool markFavorite) {
    DB.instance.put<dynamic>(
        boxName: walletId, key: "isFavorite", value: markFavorite);
  }

  @override
  bool get isFavorite {
    try {
      return DB.instance.get<dynamic>(boxName: walletId, key: "isFavorite")
          as bool;
    } catch (e, s) {
      Logging.instance
          .log("isFavorite fetch failed: $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  @override
  Future<List<String>> get allOwnAddresses =>
      _allOwnAddresses ??= _fetchAllOwnAddresses();
  Future<List<String>>? _allOwnAddresses;

  Future<List<String>> _fetchAllOwnAddresses() async {
    List<String> addresses = [];
    final ownAddress = await _getCurrentAddressForChain(0);
    addresses.add(ownAddress);
    return addresses;
  }

  late ReceivePort receivePort;

  Future<String> startSync() async {
    Logging.instance.log("request start sync", level: LogLevel.Info);
    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');

    if (!syncMutex.isLocked) {
      await syncMutex.protect(() async {
        Logging.instance.log("sync started", level: LogLevel.Info);
        ReceivePort receivePort = await getIsolate({
          "function": "startSync",
          "config": config,
          "password": password!,
        }, name: walletName);
        this.receivePort = receivePort;

        var message = await receivePort.first;
        if (message is String) {
          Logging.instance
              .log("this is a string $message", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("startSync isolate failed");
        }
        stop(receivePort);
        Logging.instance
            .log('Closing startSync!\n  $message', level: LogLevel.Info);
        Logging.instance.log("sync ended", level: LogLevel.Info);
      });
    } else {
      Logging.instance.log("request start sync denied", level: LogLevel.Info);
    }
    return "";
  }

  Future<String> allWalletBalances() async {
    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');

    const refreshFromNode = 0;

    dynamic message;
    await m.protect(() async {
      ReceivePort receivePort = await getIsolate({
        "function": "getWalletInfo",
        "config": config,
        "password": password!,
        "refreshFromNode": refreshFromNode,
        "minimumConfirmations": MINIMUM_CONFIRMATIONS,
      }, name: walletName);

      message = await receivePort.first;
      if (message is String) {
        Logging.instance
            .log("this is a string $message", level: LogLevel.Error);
        stop(receivePort);
        throw Exception("getWalletInfo isolate failed");
      }
      stop(receivePort);
      Logging.instance
          .log('Closing getWalletInfo!\n  $message', level: LogLevel.Info);
    });

    // return message;
    final String walletBalances = message['result'] as String;
    return walletBalances;
  }

  @override
  Future<Decimal> get availableBalance async {
    String walletBalances = await allWalletBalances();
    var jsonBalances = json.decode(walletBalances);
    final double spendable =
        jsonBalances['amount_currently_spendable'] as double;
    return Decimal.parse(spendable.toString());
  }

  @override
  // TODO: implement balanceMinusMaxFee
  Future<Decimal> get balanceMinusMaxFee => throw UnimplementedError();

  Timer? timer;
  late Coin _coin;

  @override
  Coin get coin => _coin;

  late FlutterSecureStorageInterface _secureStore;

  late PriceAPI _priceAPI;

  Future<String> cancelPendingTransactionAndPost(String tx_slate_id) async {
    final String config = await getRealConfig();
    final String password =
        (await _secureStore.read(key: '${_walletId}_password'))!;
    final int? receivingIndex = DB.instance
        .get<dynamic>(boxName: walletId, key: "receivingIndex") as int?;
    final epicboxConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');

    final slatesToCommits = await getSlatesToCommits();
    final receiveAddress = slatesToCommits[tx_slate_id]['to'] as String;
    final sendersAddress = slatesToCommits[tx_slate_id]['from'] as String;

    int? currentReceivingIndex;
    for (int i = 0; i <= receivingIndex!; i++) {
      final indexesAddress = await _getCurrentAddressForChain(i);
      if (indexesAddress == sendersAddress) {
        currentReceivingIndex = i;
        break;
      }
    }

    dynamic subscribeRequest;
    await m.protect(() async {
      ReceivePort receivePort = await getIsolate({
        "function": "subscribeRequest",
        "config": config,
        "password": password,
        "secretKeyIndex": currentReceivingIndex!,
        "epicboxConfig": epicboxConfig,
      }, name: walletName);

      var result = await receivePort.first;
      if (result is String) {
        Logging.instance.log("this is a message $result", level: LogLevel.Info);
        stop(receivePort);
        throw Exception("subscribeRequest isolate failed");
      }
      subscribeRequest = jsonDecode(result['result'] as String);
      stop(receivePort);
      Logging.instance.log('Closing subscribeRequest! $subscribeRequest',
          level: LogLevel.Info);
    });
    // TODO, once server adds signature, give this signature to the getSlates method.
    String? signature = subscribeRequest['signature'] as String?;
    String? result;
    try {
      result = await cancelPendingTransaction(tx_slate_id);
      Logging.instance.log("result?: $result", level: LogLevel.Info);
      if (result != null && !(result.toLowerCase().contains("error"))) {
        await postCancel(
            receiveAddress, tx_slate_id, signature, sendersAddress);
      }
    } catch (e, s) {
      Logging.instance.log("$e, $s", level: LogLevel.Error);
    }
    return result!;
  }

//
  /// returns an empty String on success, error message on failure
  Future<String> cancelPendingTransaction(String tx_slate_id) async {
    final String config = await getRealConfig();
    final String password =
        (await _secureStore.read(key: '${_walletId}_password'))!;

    String? result;
    await m.protect(() async {
      result = await compute(
        _cancelTransactionWrapper,
        Tuple3(
          config,
          password,
          tx_slate_id,
        ),
      );
    });
    return result!;
  }

  @override
  Future<String> confirmSend({required Map<String, dynamic> txData}) async {
    try {
      final config = await getRealConfig();
      final password = await _secureStore.read(key: '${_walletId}_password');
      final epicboxConfig =
          await _secureStore.read(key: '${_walletId}_epicboxConfig');

      // TODO determine whether it is worth sending change to a change address.
      dynamic message;
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "createTransaction",
          "config": config,
          "password": password!,
          "amount": txData['recipientAmt'],
          "address": txData['addresss'],
          "secretKeyIndex": 0,
          "epicboxConfig": epicboxConfig!,
          "minimumConfirmations": MINIMUM_CONFIRMATIONS,
        }, name: walletName);

        message = await receivePort.first;
        if (message is String) {
          Logging.instance
              .log("this is a string $message", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("createTransaction isolate failed");
        }
        stop(receivePort);
        Logging.instance.log('Closing createTransaction!\n  $message',
            level: LogLevel.Info);
      });

      // return message;
      final String sendTx = message['result'] as String;
      await putSendToAddresses(sendTx);

      Logging.instance.log("CONFIRM_RESULT_IS $sendTx", level: LogLevel.Info);

      final decodeData = json.decode(sendTx);

      if (decodeData[0] == "transaction_failed") {
        String errorMessage = decodeData[1] as String;
        throw Exception("Transaction failed with error code $errorMessage");
      } else {
        final postSlateRequest = decodeData[1];
        final postToServer = await postSlate(
            txData['addresss'] as String, postSlateRequest as String);
        Logging.instance
            .log("POST_SLATE_IS $postToServer", level: LogLevel.Info);
        //await postSlate
        final txCreateResult = decodeData[0];
        // //TODO: second problem
        final transaction = txCreateResult[0];

        // final wallet = await Hive.openBox<dynamic>(_walletId);
        // final slateToAddresses = (await wallet.get("slate_to_address")) as Map?;
        // slateToAddresses![transaction[0]['tx_slate_id']] = txData['addresss'];
        // await wallet.put('slate_to_address', slateToAddresses);
        // return transaction[0]['tx_slate_id'] as String;
        return "";
      }
    } catch (e, s) {
      Logging.instance.log("Error sending $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  /// Returns the latest receiving/change (external/internal) address for the wallet depending on [chain]
  /// and
  /// [chain] - Use 0 for receiving (external), 1 for change (internal). Should not be any other value!
  Future<String> _getCurrentAddressForChain(
    int chain,
  ) async {
    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');
    final epicboxConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');

    String? walletAddress;
    await m.protect(() async {
      walletAddress = await compute(
        _initGetAddressInfoWrapper,
        Tuple4(config, password!, chain, epicboxConfig!),
      );
    });
    Logging.instance
        .log("WALLET_ADDRESS_IS $walletAddress", level: LogLevel.Info);
    return walletAddress!;
  }

  @override
  Future<String> get currentReceivingAddress =>
      _currentReceivingAddress ??= _getCurrentAddressForChain(0);
  Future<String>? _currentReceivingAddress;

  @override
  Future<void> exit() async {
    _hasCalledExit = true;
    timer?.cancel();
    timer = null;
    stopNetworkAlivePinging();
    for (final isolate in isolates.values) {
      isolate.kill(priority: Isolate.immediate);
    }
    isolates.clear();
    Logging.instance.log("EpicCash_wallet exit finished", level: LogLevel.Info);
  }

  bool _hasCalledExit = false;

  @override
  bool get hasCalledExit => _hasCalledExit;

  Future<FeeObject> _getFees() async {
    // TODO: implement _getFees
    return FeeObject(
        numberOfBlocksFast: 10,
        numberOfBlocksAverage: 10,
        numberOfBlocksSlow: 10,
        fast: 1,
        medium: 1,
        slow: 1);
  }

  @override
  Future<FeeObject> get fees => _feeObject ??= _getFees();
  Future<FeeObject>? _feeObject;

  @override
  Future<void> fullRescan(
    int maxUnusedAddressGap,
    int maxNumberOfIndexesToCheck,
  ) async {
    refreshMutex = true;
    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: "lastScannedBlock",
          value: await getRestoreHeight());

      if (!await startScans()) {
        refreshMutex = false;
        GlobalEventBus.instance.fire(
          NodeConnectionStatusChangedEvent(
            NodeConnectionStatus.disconnected,
            walletId,
            coin,
          ),
        );
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.unableToSync,
            walletId,
            coin,
          ),
        );
        return;
      }
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
    } catch (e, s) {
      refreshMutex = false;
      Logging.instance
          .log("$e, $s", level: LogLevel.Error, printFullLength: true);
    }
    refreshMutex = false;
    return;
  }

  @override
  Future<void> initializeExisting() async {
    Logging.instance.log("Opening existing ${coin.prettyName} wallet",
        level: LogLevel.Info);

    if ((DB.instance.get<dynamic>(boxName: walletId, key: "id")) == null) {
      debugPrint("Exception was thrown");
      throw Exception(
          "Attempted to initialize an existing wallet using an unknown wallet ID!");
    }
    await _prefs.init();
    await updateNode(false);
    final data =
        DB.instance.get<dynamic>(boxName: walletId, key: "latest_tx_model")
            as TransactionData?;
    if (data != null) {
      _transactionData = Future(() => data);
    }
    // TODO: is there anything else that should be set up here whenever this wallet is first loaded again?
  }

  Future<void> storeEpicboxInfo() async {
    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');
    int index = 0;

    Logging.instance.log("This index is $index", level: LogLevel.Info);
    final epicboxConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');
    String? walletAddress;
    await m.protect(() async {
      walletAddress = await compute(
        _initGetAddressInfoWrapper,
        Tuple4(config, password!, index, epicboxConfig!),
      );
    });
    Logging.instance
        .log("WALLET_ADDRESS_IS $walletAddress", level: LogLevel.Info);
    Logging.instance
        .log("Wallet address is $walletAddress", level: LogLevel.Info);
    String addressInfo = walletAddress!;
    await _secureStore.write(
        key: '${_walletId}_address_info', value: addressInfo);
  }

  // TODO: make more robust estimate of date maybe using https://explorer.epic.tech/api-index
  int calculateRestoreHeightFrom({required DateTime date}) {
    int secondsSinceEpoch = date.millisecondsSinceEpoch ~/ 1000;
    const int epicCashFirstBlock = 1565370278;
    const double overestimateSecondsPerBlock = 61;
    int chosenSeconds = secondsSinceEpoch - epicCashFirstBlock;
    int approximateHeight = chosenSeconds ~/ overestimateSecondsPerBlock;
    debugPrint(
        "approximate height: $approximateHeight chosen_seconds: $chosenSeconds");
    int height = approximateHeight;
    if (height < 0) {
      height = 0;
    }
    return height;
  }

  @override
  Future<void> initializeNew() async {
    await _prefs.init();
    await updateNode(false);
    final mnemonic = await _getMnemonicList();
    final String mnemonicString = mnemonic.join(" ");

    final String password = generatePassword();
    String stringConfig = await getConfig();
    String epicboxConfig = await getEpicBoxConfig();

    await _secureStore.write(
        key: '${_walletId}_mnemonic', value: mnemonicString);
    await _secureStore.write(key: '${_walletId}_config', value: stringConfig);
    await _secureStore.write(key: '${_walletId}_password', value: password);
    await _secureStore.write(
        key: '${_walletId}_epicboxConfig', value: epicboxConfig);

    String name = _walletId;

    await m.protect(() async {
      await compute(
        _initWalletWrapper,
        Tuple4(
          stringConfig,
          mnemonicString,
          password,
          name,
        ),
      );
    });

    //Store Epic box address info
    await storeEpicboxInfo();

    // subtract a couple days to ensure we have a buffer for SWB
    final bufferedCreateHeight = calculateRestoreHeightFrom(
        date: DateTime.now().subtract(const Duration(days: 2)));

    await DB.instance.put<dynamic>(
        boxName: walletId, key: "restoreHeight", value: bufferedCreateHeight);

    await DB.instance
        .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'receivingAddresses', value: ["0"]);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "changeIndex", value: 0);
    await DB.instance.put<dynamic>(
      boxName: walletId,
      key: 'blocked_tx_hashes',
      value: ["0xdefault"],
    ); // A list of transaction hashes to represent frozen utxos in wallet
    // initialize address book entries
    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'addressBookEntries',
        value: <String, String>{});
    await DB.instance
        .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);
  }

  bool refreshMutex = false;

  @override
  bool get isRefreshing => refreshMutex;

  @override
  // TODO: implement maxFee
  Future<int> get maxFee => throw UnimplementedError();

  Future<List<String>> _getMnemonicList() async {
    if ((await _secureStore.read(key: '${_walletId}_mnemonic')) != null) {
      final mnemonicString =
          await _secureStore.read(key: '${_walletId}_mnemonic');
      final List<String> data = mnemonicString!.split(' ');
      return data;
    } else {
      String? mnemonicString;
      await m.protect(() async {
        mnemonicString = await compute(
          _walletMnemonicWrapper,
          0,
        );
      });
      await _secureStore.write(
          key: '${_walletId}_mnemonic', value: mnemonicString);
      final List<String> data = mnemonicString!.split(' ');
      return data;
    }
  }

  @override
  Future<List<String>> get mnemonic => _getMnemonicList();

  @override
  Future<Decimal> get pendingBalance async {
    String walletBalances = await allWalletBalances();
    final jsonBalances = json.decode(walletBalances);
    final double pending =
        jsonBalances['amount_awaiting_confirmation'] as double;
    return Decimal.parse(pending.toString());
  }

  @override
  Future<Map<String, dynamic>> prepareSend(
      {required String address,
      required int satoshiAmount,
      Map<String, dynamic>? args}) async {
    try {
      int realfee = await nativeFee(satoshiAmount);

      Map<String, dynamic> txData = {
        "fee": realfee,
        "addresss": address,
        "recipientAmt": satoshiAmount,
      };

      Logging.instance.log("prepare send: $txData", level: LogLevel.Info);
      return txData;
    } catch (e, s) {
      Logging.instance.log("Error getting fees $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<int> nativeFee(int satoshiAmount,
      {bool ifErrorEstimateFee = false}) async {
    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');

    try {
      String? transactionFees;
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "getTransactionFees",
          "config": config,
          "password": password!,
          "amount": satoshiAmount,
          "minimumConfirmations": MINIMUM_CONFIRMATIONS,
        }, name: walletName);

        var message = await receivePort.first;
        if (message is String) {
          Logging.instance
              .log("this is a string $message", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("getTransactionFees isolate failed");
        }
        stop(receivePort);
        Logging.instance.log('Closing getTransactionFees!\n  $message',
            level: LogLevel.Info);
        // return message;
        transactionFees = message['result'] as String;
      });
      debugPrint(transactionFees);
      var decodeData;
      try {
        decodeData = json.decode(transactionFees!);
      } catch (e, s) {
        if (ifErrorEstimateFee) {
          //Error Not enough funds. Required: 0.56500000, Available: 0.56200000
          if (transactionFees!.contains("Required")) {
            var splits = transactionFees!.split(" ");
            Decimal required = Decimal.zero;
            Decimal available = Decimal.zero;
            for (int i = 0; i < splits.length; i++) {
              var word = splits[i];
              if (word == "Required:") {
                required = Decimal.parse(splits[i + 1].replaceAll(",", ""));
              } else if (word == "Available:") {
                available = Decimal.parse(splits[i + 1].replaceAll(",", ""));
              }
            }
            int largestSatoshiFee =
                ((required - available) * Decimal.fromInt(100000000))
                    .toBigInt()
                    .toInt();
            Logging.instance.log("largestSatoshiFee $largestSatoshiFee",
                level: LogLevel.Info);
            return largestSatoshiFee;
          }
        }
        rethrow;
      }

      //TODO: first problem
      int realfee = 0;
      try {
        var txObject = decodeData[0];
        realfee =
            (Decimal.parse(txObject["fee"].toString())).toBigInt().toInt();
      } catch (e, s) {
        debugPrint("$e $s");
      }

      return realfee;
    } catch (e, s) {
      Logging.instance.log("Error getting fees $e - $s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<String> currentWalletDirPath() async {
    Directory appDir = (await getApplicationDocumentsDirectory());
    if (Platform.isIOS) {
      appDir = (await getLibraryDirectory());
    }
    final path = "${appDir.path}/epiccash";
    final String name = _walletId.trim();
    return '$path/$name';
  }

  Future<String> getConfig() async {
    if (_epicNode == null) {
      await updateNode(false);
    }
    final NodeModel node = _epicNode!;
    final String nodeAddress = node.host;
    int port = node.port;
    final String nodeApiAddress = "$nodeAddress:$port";
    final walletDir = await currentWalletDirPath();

    final Map<String, dynamic> config = {};
    config["wallet_dir"] = walletDir;
    config["check_node_api_http_addr"] = nodeApiAddress;
    config["chain"] = "mainnet";
    config["account"] = "default";
    config["api_listen_port"] = port;
    config["api_listen_interface"] = nodeAddress;
    String stringConfig = json.encode(config);
    return stringConfig;
  }

  Future<String> getEpicBoxConfig() async {
    return await _secureStore.read(key: '${_walletId}_epicboxConfig') ??
        DefaultNodes.defaultEpicBoxConfig;
  }

  Future<String> getRealConfig() async {
    String? config = await _secureStore.read(key: '${_walletId}_config');
    if (Platform.isIOS) {
      final walletDir = await currentWalletDirPath();
      var editConfig = jsonDecode(config as String);

      editConfig["wallet_dir"] = walletDir;
      config = jsonEncode(editConfig);
    }
    return config!;
  }

  Future<void> updateEpicboxConfig(String host, int port) async {
    String stringConfig = jsonEncode({
      "domain": host,
      "port": port,
    });
    await _secureStore.write(
        key: '${_walletId}_epicboxConfig', value: stringConfig);
    // TODO: refresh anything that needs to be refreshed/updated due to epicbox info changed
  }

  Future<bool> startScans() async {
    try {
      String stringConfig = await getConfig();
      final password = await _secureStore.read(key: '${_walletId}_password');

      var restoreHeight =
          DB.instance.get<dynamic>(boxName: walletId, key: "restoreHeight");
      var chainHeight = await this.chainHeight;
      if (!DB.instance.containsKey<dynamic>(
              boxName: walletId, key: 'lastScannedBlock') ||
          DB.instance
                  .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') ==
              null) {
        await DB.instance.put<dynamic>(
            boxName: walletId,
            key: "lastScannedBlock",
            value: await getRestoreHeight());
      }
      int lastScannedBlock = DB.instance
          .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') as int;
      const MAX_PER_LOOP = 10000;
      await getSyncPercent;
      for (; lastScannedBlock < chainHeight;) {
        chainHeight = await this.chainHeight;
        lastScannedBlock = DB.instance
            .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') as int;
        Logging.instance.log(
            "chainHeight: $chainHeight, restoreHeight: $restoreHeight, lastScannedBlock: $lastScannedBlock",
            level: LogLevel.Info);
        int? nextScannedBlock;
        await m.protect(() async {
          ReceivePort receivePort = await getIsolate({
            "function": "scanOutPuts",
            "config": stringConfig,
            "password": password,
            "startHeight": lastScannedBlock,
            "numberOfBlocks": MAX_PER_LOOP,
          }, name: walletName);

          var message = await receivePort.first;
          if (message is String) {
            Logging.instance
                .log("this is a string $message", level: LogLevel.Error);
            stop(receivePort);
            throw Exception("scanOutPuts isolate failed");
          }
          nextScannedBlock = int.parse(message['outputs'] as String);
          stop(receivePort);
          Logging.instance
              .log('Closing scanOutPuts!\n  $message', level: LogLevel.Info);
        });
        await DB.instance.put<dynamic>(
            boxName: walletId,
            key: "lastScannedBlock",
            value: nextScannedBlock!);
        await getSyncPercent;
      }
      Logging.instance.log("successfully at the tip", level: LogLevel.Info);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e, $s", level: LogLevel.Warning);
      return false;
    }
  }

  Future<double> get getSyncPercent async {
    int lastScannedBlock = DB.instance
            .get<dynamic>(boxName: walletId, key: 'lastScannedBlock') as int? ??
        0;
    final _chainHeight = await chainHeight;
    double restorePercent = lastScannedBlock / _chainHeight;
    GlobalEventBus.instance
        .fire(RefreshPercentChangedEvent(highestPercent, walletId));
    if (restorePercent > highestPercent) {
      highestPercent = restorePercent;
    }

    final int blocksRemaining = _chainHeight - lastScannedBlock;
    GlobalEventBus.instance
        .fire(BlocksRemainingEvent(blocksRemaining, walletId));

    return restorePercent < 0 ? 0.0 : restorePercent;
  }

  double highestPercent = 0;

  @override
  Future<void> recoverFromMnemonic(
      {required String mnemonic,
      required int maxUnusedAddressGap,
      required int maxNumberOfIndexesToCheck,
      required int height}) async {
    try {
      await _prefs.init();
      await updateNode(false);
      final String password = generatePassword();

      String stringConfig = await getConfig();
      String epicboxConfig = await getEpicBoxConfig();
      final String name = _walletName.trim();

      await _secureStore.write(key: '${_walletId}_mnemonic', value: mnemonic);
      await _secureStore.write(key: '${_walletId}_config', value: stringConfig);
      await _secureStore.write(key: '${_walletId}_password', value: password);
      await _secureStore.write(
          key: '${_walletId}_epicboxConfig', value: epicboxConfig);

      await compute(
        _recoverWrapper,
        Tuple4(
          stringConfig,
          password,
          mnemonic,
          name,
        ),
      );

      //Store Epic box address info
      await storeEpicboxInfo();

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "restoreHeight", value: height);

      await DB.instance
          .put<dynamic>(boxName: walletId, key: "id", value: _walletId);
      await DB.instance.put<dynamic>(
          boxName: walletId, key: 'receivingAddresses', value: ["0"]);
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "receivingIndex", value: 0);
      if (height >= 0) {
        await DB.instance.put<dynamic>(
            boxName: walletId, key: "restoreHeight", value: height);
      }
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "changeIndex", value: 0);
      await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'blocked_tx_hashes',
        value: ["0xdefault"],
      ); // A list of transaction hashes to represent frozen utxos in wallet
      // initialize address book entries
      await DB.instance.put<dynamic>(
          boxName: walletId,
          key: 'addressBookEntries',
          value: <String, String>{});
      await DB.instance
          .put<dynamic>(boxName: walletId, key: "isFavorite", value: false);

      //Scan wallet
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "scanOutPuts",
          "config": stringConfig,
          "password": password,
          "startHeight": 1550000,
          "numberOfBlocks": 100,
        }, name: walletName);

        var message = await receivePort.first;
        if (message is String) {
          Logging.instance
              .log("this is a string $message", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("scanOutPuts isolate failed");
        }
        stop(receivePort);
        Logging.instance
            .log('Closing scanOutPuts!\n  $message', level: LogLevel.Info);
      });
    } catch (e, s) {
      Logging.instance
          .log("Error recovering wallet $e\n$s", level: LogLevel.Error);
      rethrow;
    }
  }

  Future<int> getRestoreHeight() async {
    if (DB.instance
        .containsKey<dynamic>(boxName: walletId, key: "restoreHeight")) {
      return (DB.instance.get<dynamic>(boxName: walletId, key: "restoreHeight"))
          as int;
    }
    return (DB.instance.get<dynamic>(boxName: walletId, key: "creationHeight"))
        as int;
  }

  Future<int> get chainHeight async {
    final config = await getRealConfig();
    int? latestHeight;
    await m.protect(() async {
      latestHeight = await compute(
        _getChainHeightWrapper,
        config,
      );
    });
    return latestHeight!;
  }

  int get storedChainHeight {
    return DB.instance.get<dynamic>(boxName: walletId, key: "storedChainHeight")
            as int? ??
        0;
  }

  Future<void> updateStoredChainHeight({required int newHeight}) async {
    await DB.instance.put<dynamic>(
        boxName: walletId, key: "storedChainHeight", value: newHeight);
  }

  bool _shouldAutoSync = true;

  @override
  bool get shouldAutoSync => _shouldAutoSync;

  @override
  set shouldAutoSync(bool shouldAutoSync) {
    if (_shouldAutoSync != shouldAutoSync) {
      _shouldAutoSync = shouldAutoSync;
      if (!shouldAutoSync) {
        Logging.instance.log("Should autosync", level: LogLevel.Info);
        timer?.cancel();
        timer = null;
        stopNetworkAlivePinging();
      } else {
        startNetworkAlivePinging();
        refresh();
      }
    }
  }

  Future<int> setCurrentIndex() async {
    try {
      final int receivingIndex = DB.instance
          .get<dynamic>(boxName: walletId, key: "receivingIndex") as int;
      // TODO: go through pendingarray and processed array and choose the index
      //  of the last one that has not been processed, or the index after the one most recently processed;
      return receivingIndex;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return 0;
    }
  }

  Future<Map<dynamic, dynamic>> removeBadAndRepeats(
      Map<dynamic, dynamic> pendingAndProcessedSlates) async {
    var clone = <dynamic, Map<dynamic, dynamic>>{};
    for (var indexPair in pendingAndProcessedSlates.entries) {
      clone[indexPair.key] = <dynamic, dynamic>{};
      for (var pendingProcessed
          in (indexPair.value as Map<dynamic, dynamic>).entries) {
        if (pendingProcessed.value is String &&
                (pendingProcessed.value as String)
                    .contains("has already been received") ||
            (pendingProcessed.value as String)
                .contains("Error Wallet store error: DB Not Found Error")) {
        } else if (pendingProcessed.value is String &&
            pendingProcessed.value as String == "[]") {
        } else {
          clone[indexPair.key]?[pendingProcessed.key] = pendingProcessed.value;
        }
      }
    }
    return clone;
  }

  Future<Map<dynamic, dynamic>> getSlatesToCommits() async {
    try {
      var slatesToCommits =
          DB.instance.get<dynamic>(boxName: walletId, key: "slatesToCommits");
      if (slatesToCommits == null) {
        slatesToCommits = <dynamic, dynamic>{};
      } else {
        slatesToCommits = slatesToCommits as Map<dynamic, dynamic>;
      }
      return slatesToCommits as Map<dynamic, dynamic>;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return {};
    }
  }

  Future<bool> putSendToAddresses(String slateMessage) async {
    try {
      var slatesToCommits = await getSlatesToCommits();
      final slate0 = jsonDecode(slateMessage);
      final slate = jsonDecode(slate0[0] as String);
      final part1 = jsonDecode(slate[0] as String);
      final part2 = jsonDecode(slate[1] as String);
      final slateId = part1[0]['tx_slate_id'];
      final commitId = part2['tx']['body']['outputs'][0]['commit'];

      final toFromInfoString = jsonDecode(slateMessage);
      final toFromInfo = jsonDecode(toFromInfoString[1] as String);
      final from = toFromInfo['from'];
      final to = toFromInfo['to'];
      slatesToCommits[slateId] = {
        "commitId": commitId,
        "from": from,
        "to": to,
      };
      await DB.instance.put<dynamic>(
          boxName: walletId, key: "slatesToCommits", value: slatesToCommits);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return false;
    }
  }

  Future<bool> putSlatesToCommits(String slateMessage, String encoded) async {
    try {
      var slatesToCommits = await getSlatesToCommits();
      final slate = jsonDecode(slateMessage);
      final part1 = jsonDecode(slate[0] as String);
      final part2 = jsonDecode(slate[1] as String);
      final slateId = part1[0]['tx_slate_id'];
      if (slatesToCommits[slateId] != null &&
          (slatesToCommits[slateId] as Map).isNotEmpty) {
        // This happens when the sender receives the response.
        return true;
      }
      final commitId = part2['tx']['body']['outputs'][0]['commit'];

      final toFromInfoString = jsonDecode(encoded);
      final toFromInfo = jsonDecode(toFromInfoString[0] as String);
      final from = toFromInfo['from'];
      final to = toFromInfo['to'];
      slatesToCommits[slateId] = {
        "commitId": commitId,
        "from": from,
        "to": to,
      };
      await DB.instance.put<dynamic>(
          boxName: walletId, key: "slatesToCommits", value: slatesToCommits);
      return true;
    } catch (e, s) {
      Logging.instance.log("$e $s", level: LogLevel.Error);
      return false;
    }
  }

  Future<bool> processAllSlates() async {
    final int? receivingIndex = DB.instance
        .get<dynamic>(boxName: walletId, key: "receivingIndex") as int?;
    for (int currentReceivingIndex = 0;
        receivingIndex != null && currentReceivingIndex <= receivingIndex;
        currentReceivingIndex++) {
      final currentAddress =
          await _getCurrentAddressForChain(currentReceivingIndex);
      final config = await getRealConfig();
      final password = await _secureStore.read(key: '${_walletId}_password');
      final epicboxConfig =
          await _secureStore.read(key: '${_walletId}_epicboxConfig');
      dynamic subscribeRequest;
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "subscribeRequest",
          "config": config,
          "password": password,
          "secretKeyIndex": currentReceivingIndex,
          "epicboxConfig": epicboxConfig,
        }, name: walletName);

        var result = await receivePort.first;
        if (result is String) {
          Logging.instance
              .log("this is a message $result", level: LogLevel.Error);
          stop(receivePort);
          throw Exception("subscribeRequest isolate failed");
        }
        subscribeRequest = jsonDecode(result['result'] as String);
        stop(receivePort);
        Logging.instance.log('Closing subscribeRequest! $subscribeRequest',
            level: LogLevel.Info);
      });
      // TODO, once server adds signature, give this signature to the getSlates method.
      Logging.instance
          .log(subscribeRequest['signature'], level: LogLevel.Info); //
      final unprocessedSlates = await getSlates(
          currentAddress, subscribeRequest['signature'] as String);
      if (unprocessedSlates == null || unprocessedSlates is! List) {
        Logging.instance.log(
            "index $currentReceivingIndex at $currentReceivingAddress does not have any slates",
            level: LogLevel.Info);
        continue;
      }
      for (var slate in unprocessedSlates) {
        final encoded = jsonEncode([slate]);
        Logging.instance
            .log("Received Slates is $encoded", level: LogLevel.Info);

        //Decrypt Slates
        dynamic slates;
        dynamic response;
        await m.protect(() async {
          ReceivePort receivePort = await getIsolate({
            "function": "getPendingSlates",
            "config": config,
            "password": password,
            "secretKeyIndex": currentReceivingIndex,
            "slates": encoded,
          }, name: walletName);

          var result = await receivePort.first;
          if (result is String) {
            Logging.instance
                .log("this is a message $slates", level: LogLevel.Info);
            stop(receivePort);
            throw Exception("getPendingSlates isolate failed");
          }
          slates = result['result'];
          stop(receivePort);
        });

        var decoded = jsonDecode(slates as String);

        for (var decodedSlate in decoded as List) {
          //Process slates
          var decodedResponse = json.decode(decodedSlate as String);
          String slateMessage = decodedResponse[0] as String;
          await putSlatesToCommits(slateMessage, encoded);
          String slateSender = decodedResponse[1] as String;
          Logging.instance.log("SLATE_MESSAGE $slateMessage",
              printFullLength: true, level: LogLevel.Info);
          Logging.instance
              .log("SLATE_SENDER $slateSender", level: LogLevel.Info);
          await m.protect(() async {
            ReceivePort receivePort = await getIsolate({
              "function": "processSlates",
              "config": config,
              "password": password,
              "slates": slateMessage
            }, name: walletName);

            var message = await receivePort.first;
            if (message is String) {
              Logging.instance.log("this is PROCESS_SLATES message $message",
                  level: LogLevel.Error);
              stop(receivePort);
              throw Exception("processSlates isolate failed");
            }

            try {
              final String response = message['result'] as String;
              if (response == null || response == "") {
                Logging.instance.log("response: ${response.runtimeType}",
                    level: LogLevel.Info);
                await deleteSlate(currentAddress,
                    subscribeRequest['signature'] as String, slate as String);
              }
              var decodedResponse = json.decode(response);
              Logging.instance.log("PROCESS_SLATE_RESPONSE $response",
                  level: LogLevel.Info);

              final processStatus = json.decode(decodedResponse[0] as String);
              String slateStatus = processStatus['status'] as String;
              // Logging.instance.log("THIS_TEXT $processStatus");
              if (slateStatus == "PendingProcessing") {
                //Encrypt slate
                //
                String encryptedSlate = await getEncryptedSlate(
                    config,
                    password!,
                    slateSender,
                    currentReceivingIndex,
                    epicboxConfig!,
                    decodedResponse[1] as String);

                final postSlateToServer =
                    await postSlate(slateSender, encryptedSlate);

                await deleteSlate(currentAddress,
                    subscribeRequest['signature'] as String, slate as String);
                Logging.instance.log("POST_SLATE_RESPONSE $postSlateToServer",
                    level: LogLevel.Info);
              } else {
                //Finalise Slate
                final processSlate = json.decode(decodedResponse[1] as String);
                Logging.instance.log(
                    "PROCESSED_SLATE_TO_FINALIZE $processSlate",
                    level: LogLevel.Info);
                final tx = json.decode(processSlate[0] as String);
                Logging.instance.log("TX_IS $tx", level: LogLevel.Info);
                String txSlateId = tx[0]['tx_slate_id'] as String;
                Logging.instance
                    .log("TX_SLATE_ID_IS $txSlateId", level: LogLevel.Info);
//
                final postToNode = await postSlateToNode(
                    config, password!, currentReceivingIndex, txSlateId);
                await deleteSlate(currentAddress,
                    subscribeRequest['signature'] as String, slate as String);
                Logging.instance.log("POST_SLATE_RESPONSE $postToNode",
                    level: LogLevel.Info);
                //Post Slate to Node
                Logging.instance.log("Finalise slate", level: LogLevel.Info);
              }
            } catch (e, s) {
              Logging.instance.log("$e\n$s", level: LogLevel.Info);
              return false;
            }
            stop(receivePort);
            Logging.instance
                .log('Closing processSlates! $response', level: LogLevel.Info);
          });
        }
      }
    }
    return true;
  }

  Future<bool> processAllCancels() async {
    Logging.instance.log("processAllCancels", level: LogLevel.Info);
    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');
    final epicboxConfig =
        await _secureStore.read(key: '${_walletId}_epicboxConfig');
    final int? receivingIndex = DB.instance
        .get<dynamic>(boxName: walletId, key: "receivingIndex") as int?;
    final tData = await _transactionData;
    for (int currentReceivingIndex = 0;
        receivingIndex != null && currentReceivingIndex <= receivingIndex;
        currentReceivingIndex++) {
      final receiveAddress =
          await _getCurrentAddressForChain(currentReceivingIndex);

      dynamic subscribeRequest;
      await m.protect(() async {
        ReceivePort receivePort = await getIsolate({
          "function": "subscribeRequest",
          "config": config,
          "password": password,
          "secretKeyIndex": currentReceivingIndex,
          "epicboxConfig": epicboxConfig,
        }, name: walletName);

        var result = await receivePort.first;
        if (result is String) {
          Logging.instance
              .log("this is a message $result", level: LogLevel.Info);
          stop(receivePort);
          throw Exception("subscribeRequest isolate failed");
        }
        subscribeRequest = jsonDecode(result['result'] as String);
        stop(receivePort);
        Logging.instance.log('Closing subscribeRequest! $subscribeRequest',
            level: LogLevel.Info);
      });
      String? signature = subscribeRequest['signature'] as String?;
      final cancels = await getCancels(receiveAddress, signature!);

      final slatesToCommits = await getSlatesToCommits();
      for (final cancel in cancels as List<dynamic>) {
        final tx_slate_id = cancel.keys.first as String;
        if (slatesToCommits[tx_slate_id] == null) {
          continue;
        }
        final cancelRequestSender = ((cancel as Map).values.first) as String;
        final receiveAddressFromMap =
            slatesToCommits[tx_slate_id]['to'] as String;
        final sendersAddressFromMap =
            slatesToCommits[tx_slate_id]['from'] as String;
        final commitId = slatesToCommits[tx_slate_id]['commitId'] as String;

        if (sendersAddressFromMap != cancelRequestSender) {
          Logging.instance.log("this was not signed by the correct address",
              level: LogLevel.Error);
          continue;
        }

        String? result;
        try {
          result = await cancelPendingTransaction(tx_slate_id);
          if (tData?.findTransaction(commitId)?.isCancelled ?? false == true) {
            await deleteCancels(receiveAddressFromMap, signature, tx_slate_id);
          }
        } catch (e, s) {
          Logging.instance.log("$e, $s", level: LogLevel.Error);
          return false;
        }
      }
      continue;
    }
    return true;
  }

  /// Refreshes display data for the wallet
  @override
  Future<void> refresh() async {
    Logging.instance.log("Calling refresh", level: LogLevel.Info);
    if (refreshMutex) {
      Logging.instance.log("refreshMutex denied", level: LogLevel.Info);
      return;
    } else {
      refreshMutex = true;
    }

    try {
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.syncing,
          walletId,
          coin,
        ),
      );

      if (!DB.instance
          .containsKey<dynamic>(boxName: walletId, key: "creationHeight")) {
        await DB.instance.put<dynamic>(
            boxName: walletId, key: "creationHeight", value: await chainHeight);
      }

      if (!await startScans()) {
        refreshMutex = false;
        GlobalEventBus.instance.fire(
          NodeConnectionStatusChangedEvent(
            NodeConnectionStatus.disconnected,
            walletId,
            coin,
          ),
        );
        GlobalEventBus.instance.fire(
          WalletSyncStatusChangedEvent(
            WalletSyncStatus.unableToSync,
            walletId,
            coin,
          ),
        );
        return;
      }
      final int curAdd = await setCurrentIndex();

      _currentReceivingAddress = _getCurrentAddressForChain(curAdd);

      await processAllSlates();
      await processAllCancels();

      startSync();

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.0, walletId));

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(0.1, walletId));

      final currentHeight = await chainHeight;
      const storedHeight = 1; //await storedChainHeight;

      Logging.instance.log("chain height in refresh function: $currentHeight",
          level: LogLevel.Info);
      Logging.instance.log("cached height in refresh function: $storedHeight",
          level: LogLevel.Info);

      // TODO: implement refresh
      // TODO: check if it needs a refresh and if so get all of the most recent data.
      if (currentHeight != storedHeight) {
        if (currentHeight != -1) {
          // -1 failed to fetch current height
          updateStoredChainHeight(newHeight: currentHeight);
        }

        final newTxData = _fetchTransactionData();
        GlobalEventBus.instance
            .fire(RefreshPercentChangedEvent(0.50, walletId));

        _transactionData = Future(() => newTxData);

        GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
            "New data found in $walletName in background!", walletId));
      }

      GlobalEventBus.instance.fire(RefreshPercentChangedEvent(1.0, walletId));
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.synced,
          walletId,
          coin,
        ),
      );
      refreshMutex = false;

      if (shouldAutoSync) {
        timer ??= Timer.periodic(const Duration(seconds: 60), (timer) async {
          Logging.instance.log(
              "Periodic refresh check for $walletId in object instance: $hashCode",
              level: LogLevel.Info);
          // chain height check currently broken
          // if ((await chainHeight) != (await storedChainHeight)) {
          if (await refreshIfThereIsNewData()) {
            await refresh();
            GlobalEventBus.instance.fire(UpdatedInBackgroundEvent(
                "New data found in $walletName in background!", walletId));
          }
          // }
        });
      }
    } catch (error, strace) {
      refreshMutex = false;
      GlobalEventBus.instance.fire(
        NodeConnectionStatusChangedEvent(
          NodeConnectionStatus.disconnected,
          walletId,
          coin,
        ),
      );
      GlobalEventBus.instance.fire(
        WalletSyncStatusChangedEvent(
          WalletSyncStatus.unableToSync,
          walletId,
          coin,
        ),
      );
      Logging.instance.log(
          "Caught exception in refreshWalletData(): $error\n$strace",
          level: LogLevel.Warning);
    }
  }

  Future<bool> refreshIfThereIsNewData() async {
    if (_hasCalledExit) return false;
    Logging.instance.log("Can we do this here?", level: LogLevel.Fatal);
    // TODO returning true here signals this class to call refresh() after which it will fire an event that notifies the UI that new data has been fetched/found for this wallet
    return true;
    // TODO: do a quick check to see if there is any new data that would require a refresh
  }

  @override
  Future<String> send(
      {required String toAddress,
      required int amount,
      Map<String, String> args = const {}}) {
    // TODO: implement send
    throw UnimplementedError();
  }

  @override
  Future<bool> testNetworkConnection() async {
    try {
      // force unwrap optional as we want connection test to fail if wallet
      // wasn't initialized or epicbox node was set to null
      final String uriString =
          "${_epicNode!.host}:${_epicNode!.port}/v1/version";

      final Uri uri = Uri.parse(uriString);
      return await testEpicBoxNodeConnection(uri);
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Warning);
      return false;
    }
  }

  Timer? _networkAliveTimer;

  void startNetworkAlivePinging() {
    // call once on start right away
    _periodicPingCheck();

    // then periodically check
    _networkAliveTimer = Timer.periodic(
      Constants.networkAliveTimerDuration,
      (_) async {
        _periodicPingCheck();
      },
    );
  }

  void _periodicPingCheck() async {
    bool hasNetwork = await testNetworkConnection();
    _isConnected = hasNetwork;
    if (_isConnected != hasNetwork) {
      NodeConnectionStatus status = hasNetwork
          ? NodeConnectionStatus.connected
          : NodeConnectionStatus.disconnected;
      GlobalEventBus.instance
          .fire(NodeConnectionStatusChangedEvent(status, walletId, coin));
    }
  }

  void stopNetworkAlivePinging() {
    _networkAliveTimer?.cancel();
    _networkAliveTimer = null;
  }

  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<Decimal> get totalBalance async {
    String walletBalances = await allWalletBalances();
    var jsonBalances = json.decode(walletBalances);
    double total = jsonBalances['total'] as double;
    double awaiting = jsonBalances['amount_awaiting_finalization'] as double;
    total = total + awaiting;
    return Decimal.parse(total.toString());
  }

  Future<TransactionData> _fetchTransactionData() async {
    final currentChainHeight = await chainHeight;
    final config = await getRealConfig();
    final password = await _secureStore.read(key: '${_walletId}_password');
    const refreshFromNode = 0;

    dynamic message;
    await m.protect(() async {
      ReceivePort receivePort = await getIsolate({
        "function": "getTransactions",
        "config": config,
        "password": password!,
        "refreshFromNode": refreshFromNode,
      }, name: walletName);

      message = await receivePort.first;
      if (message is String) {
        Logging.instance
            .log("this is a string $message", level: LogLevel.Error);
        stop(receivePort);
        throw Exception("getTransactions isolate failed");
      }
      stop(receivePort);
      Logging.instance
          .log('Closing getTransactions!\n $message', level: LogLevel.Info);
    });
    // return message;
    final String transactions = message['result'] as String;
    final jsonTransactions = json.decode(transactions) as List;
    // for (var el in jsonTransactions) {
    //   Logging.instance.log("gettran: $el",
    //       normalLength: false, addToDebugMessagesDB: true);
    // }

    final priceData =
        await _priceAPI.getPricesAnd24hChange(baseCurrency: _prefs.currency);
    Decimal currentPrice = priceData[coin]?.item1 ?? Decimal.zero;
    final List<Map<String, dynamic>> midSortedArray = [];

    int latestTxnBlockHeight =
        DB.instance.get<dynamic>(boxName: walletId, key: "storedTxnDataHeight")
                as int? ??
            0;
    final slatesToCommits = await getSlatesToCommits();
    final cachedTransactions =
        DB.instance.get<dynamic>(boxName: walletId, key: 'latest_tx_model')
            as TransactionData?;
    var cachedMap = cachedTransactions?.getAllTransactions();
    for (var tx in jsonTransactions) {
      Logging.instance.log("tx: $tx", level: LogLevel.Info);
      final txHeight = tx["kernel_lookup_min_height"] as int? ?? 0;
      // TODO: does "confirmed" mean finalized? If so please remove this todo
      final isConfirmed = tx["confirmed"] as bool;
      // TODO: since we are now caching tx history in hive are we losing anything by skipping here?
      // TODO: we can skip this filtering if it causes issues as the cache is later merged with updated data anyways
      // this would just make processing and updating cache more efficient
      if (txHeight > 0 &&
          txHeight < latestTxnBlockHeight - MINIMUM_CONFIRMATIONS &&
          isConfirmed) {
        continue;
      }
      // Logging.instance.log("Transactions listed below");
      // Logging.instance.log(jsonTransactions);
      int amt = 0;
      if (tx["tx_type"] == "TxReceived" ||
          tx["tx_type"] == "TxReceivedCancelled") {
        amt = int.parse(tx['amount_credited'] as String);
      } else {
        int debit = int.parse(tx['amount_debited'] as String);
        int credit = int.parse(tx['amount_credited'] as String);
        int fee = int.parse((tx['fee'] ?? "0") as String);
        amt = debit - credit - fee;
      }
      final String worthNow =
          (currentPrice * Decimal.parse(amt.toString())).toStringAsFixed(2);

      DateTime dt = DateTime.parse(tx["creation_ts"] as String);

      Map<String, dynamic> midSortedTx = {};
      midSortedTx["txType"] = (tx["tx_type"] == "TxReceived" ||
              tx["tx_type"] == "TxReceivedCancelled")
          ? "Received"
          : "Sent";
      String? slateId = tx['tx_slate_id'] as String?;
      String? address = slatesToCommits[slateId]
                  ?[midSortedTx["txType"] == "TxReceived" ? "from" : "to"]
              as String? ??
          "";
      String? commitId = slatesToCommits[slateId]?['commitId'] as String?;
      Logging.instance
          .log("commitId: $commitId $slateId", level: LogLevel.Info);

      bool isCancelled = tx["tx_type"] == "TxSentCancelled" ||
          tx["tx_type"] == "TxReceivedCancelled";

      midSortedTx["slateId"] = slateId;
      midSortedTx["isCancelled"] = isCancelled;
      midSortedTx["txid"] = commitId ?? tx["id"].toString();
      midSortedTx["confirmed_status"] = isConfirmed;
      midSortedTx["timestamp"] = (dt.millisecondsSinceEpoch ~/ 1000);
      midSortedTx["amount"] = amt;
      midSortedTx["worthNow"] = worthNow;
      midSortedTx["worthAtBlockTimestamp"] = worthNow;
      midSortedTx["fees"] =
          (tx["fee"] == null) ? 0 : int.parse(tx["fee"] as String);
      midSortedTx["address"] =
          ""; // for this when you send a transaction you will just need to save in a hashmap in hive with the key being the txid, and the value being the address it was sent to. then you can look this value up right here in your hashmap.
      midSortedTx["address"] = address;
      midSortedTx["height"] = txHeight;
      int confirmations = 0;
      try {
        confirmations = currentChainHeight - txHeight;
      } catch (e, s) {
        debugPrint("$e $s");
      }
      midSortedTx["confirmations"] = confirmations;

      midSortedTx["inputSize"] = tx["num_inputs"];
      midSortedTx["outputSize"] = tx["num_outputs"];
      midSortedTx["aliens"] = <dynamic>[];
      midSortedTx["inputs"] = <dynamic>[];
      midSortedTx["outputs"] = <dynamic>[];
      midSortedTx["tx_slate_id"] = tx["tx_slate_id"];
      midSortedTx["key_id"] = tx["parent_key_id"];
      midSortedTx["otherData"] = tx["id"].toString();

      if (txHeight >= latestTxnBlockHeight) {
        latestTxnBlockHeight = txHeight;
      }

      midSortedArray.add(midSortedTx);
      cachedMap?.remove(tx["id"].toString());
      cachedMap?.remove(commitId);
      Logging.instance.log("cmap: $cachedMap", level: LogLevel.Info);
    }

    midSortedArray
        .sort((a, b) => (b["timestamp"] as int) - (a["timestamp"] as int));

    final Map<String, dynamic> result = {"dateTimeChunks": <dynamic>[]};
    final dateArray = <dynamic>[];

    for (int i = 0; i < midSortedArray.length; i++) {
      final txObject = midSortedArray[i];
      final date = extractDateFromTimestamp(txObject["timestamp"] as int);

      final txTimeArray = [txObject["timestamp"], date];

      if (dateArray.contains(txTimeArray[1])) {
        result["dateTimeChunks"].forEach((dynamic chunk) {
          if (extractDateFromTimestamp(chunk["timestamp"] as int) ==
              txTimeArray[1]) {
            if (chunk["transactions"] == null) {
              chunk["transactions"] = <Map<String, dynamic>>[];
            }
            chunk["transactions"].add(txObject);
          }
        });
      } else {
        dateArray.add(txTimeArray[1]);

        final chunk = {
          "timestamp": txTimeArray[0],
          "transactions": [txObject],
        };

        // result["dateTimeChunks"].
        result["dateTimeChunks"].add(chunk);
      }
    }
    final transactionsMap =
        TransactionData.fromJson(result).getAllTransactions();
    if (cachedMap != null) {
      transactionsMap.addAll(cachedMap);
    }

    final txModel = TransactionData.fromMap(transactionsMap);

    await DB.instance.put<dynamic>(
        boxName: walletId,
        key: 'storedTxnDataHeight',
        value: latestTxnBlockHeight);
    await DB.instance.put<dynamic>(
        boxName: walletId, key: 'latest_tx_model', value: txModel);

    return txModel;
  }

  @override
  Future<TransactionData> get transactionData =>
      _transactionData ??= _fetchTransactionData();
  Future<TransactionData>? _transactionData;

  @override
  Future<List<UtxoObject>> get unspentOutputs => throw UnimplementedError();

  @override
  bool validateAddress(String address) {
    String validate = validateSendAddress(address);
    if (int.parse(validate) == 1) {
      return true;
    } else {
      return false;
    }
  }

  @override
  String get walletId => _walletId;
  late String _walletId;

  @override
  String get walletName => _walletName;
  late String _walletName;

  @override
  set walletName(String newName) => _walletName = newName;

  @override
  void Function(bool)? get onIsActiveWalletChanged => (isActive) async {
        timer?.cancel();
        timer = null;
        if (isActive) {
          startSync();
        } else {
          for (final isolate in isolates.values) {
            isolate.kill(priority: Isolate.immediate);
          }
          isolates.clear();
        }
        this.isActive = isActive;
      };

  bool isActive = false;

  @override
  Future<int> estimateFeeFor(int satoshiAmount, int feeRate) async {
    int currentFee = await nativeFee(satoshiAmount, ifErrorEstimateFee: true);
    // TODO: implement this
    return currentFee;
  }
}
