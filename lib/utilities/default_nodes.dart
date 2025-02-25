import 'dart:convert';

import 'package:stackwallet/models/node_model.dart';
import 'package:stackwallet/utilities/enums/coin_enum.dart';

abstract class DefaultNodes {
  static String _nodeId(Coin coin) => "default_${coin.name}";
  static const String defaultName = "Stack Default";

  static List<NodeModel> get all => [
        bitcoin,
        dogecoin,
        firo,
        monero,
        epicCash,
        bitcoinTestnet,
        dogecoinTestnet,
        firoTestnet,
      ];

  static NodeModel get bitcoin => NodeModel(
        host: "bitcoin.stackwallet.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.bitcoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get dogecoin => NodeModel(
        host: "dogecoin.stackwallet.com",
        port: 50022,
        name: defaultName,
        id: _nodeId(Coin.dogecoin),
        useSSL: true,
        enabled: true,
        coinName: Coin.dogecoin.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get firo => NodeModel(
        host: "firo.stackwallet.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.firo),
        useSSL: true,
        enabled: true,
        coinName: Coin.firo.name,
        isFailover: true,
        isDown: false,
      );

  // TODO: eventually enable ssl and set scheme to https
  // currently get certificate failure
  static NodeModel get monero => NodeModel(
        host: "http://monero.stackwallet.com",
        port: 18081,
        name: defaultName,
        id: _nodeId(Coin.monero),
        useSSL: false,
        enabled: true,
        coinName: Coin.monero.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get epicCash => NodeModel(
        host: "http://epiccash.stackwallet.com",
        port: 3413,
        name: defaultName,
        id: _nodeId(Coin.epicCash),
        useSSL: false,
        enabled: true,
        coinName: Coin.epicCash.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get bitcoinTestnet => NodeModel(
        host: "electrumx-testnet.cypherstack.com",
        port: 51002,
        name: defaultName,
        id: _nodeId(Coin.bitcoinTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.bitcoinTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get firoTestnet => NodeModel(
        host: "firo-testnet.stackwallet.com",
        port: 50002,
        name: defaultName,
        id: _nodeId(Coin.firoTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.firoTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel get dogecoinTestnet => NodeModel(
        host: "dogecoin-testnet.stackwallet.com",
        port: 50022,
        name: defaultName,
        id: _nodeId(Coin.dogecoinTestNet),
        useSSL: true,
        enabled: true,
        coinName: Coin.dogecoinTestNet.name,
        isFailover: true,
        isDown: false,
      );

  static NodeModel getNodeFor(Coin coin) {
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

  static final String defaultEpicBoxConfig = jsonEncode({
    "domain": "209.127.179.199",
    "port": 13420,
  });
}
