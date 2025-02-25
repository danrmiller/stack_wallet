import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stackwallet/pages/settings_views/global_settings_view/stack_backup_views/helpers/restore_create_backup.dart';
import 'package:stackwallet/utilities/flutter_secure_storage_interface.dart';
import 'package:stackwallet/utilities/logger.dart';
import 'package:stackwallet/utilities/prefs.dart';
import 'package:tuple/tuple.dart';

enum AutoSWBStatus {
  idle,
  backingUp,
  error,
}

class AutoSWBService extends ChangeNotifier {
  Timer? _timer;

  AutoSWBStatus _status = AutoSWBStatus.idle;
  AutoSWBStatus get status => _status;

  bool _isActiveTimer = false;
  bool get isActivePeriodicTimer => _isActiveTimer;

  final FlutterSecureStorageInterface secureStorageInterface;

  AutoSWBService(
      {this.secureStorageInterface =
          const SecureStorageWrapper(FlutterSecureStorage())});

  /// Attempt a backup.
  Future<void> doBackup() async {
    if (_status == AutoSWBStatus.backingUp) {
      Logging.instance.log(
          "AutoSWBService attempted to run doBackup() while a backup is in progress!",
          level: LogLevel.Warning);
      return;
    }
    Logging.instance
        .log("AutoSWBService.doBackup() started...", level: LogLevel.Info);

    // set running backup status and notify listeners
    _status = AutoSWBStatus.backingUp;
    notifyListeners();

    try {
      if (!Prefs.instance.isInitialized) {
        await Prefs.instance.init();
      }

      final autoBackupDirectoryPath = Prefs.instance.autoBackupLocation;
      if (autoBackupDirectoryPath == null) {
        Logging.instance.log(
            "AutoSWBService attempted to run doBackup() when no auto backup directory was set!",
            level: LogLevel.Error);
        // set error backup status and notify listeners
        _status = AutoSWBStatus.error;
        notifyListeners();
        return;
      }

      final json = await SWB.createStackWalletJSON(
          secureStorage: secureStorageInterface);
      final jsonString = jsonEncode(json);

      final adkString =
          await secureStorageInterface.read(key: "auto_adk_string");

      final adkVersionString =
          await secureStorageInterface.read(key: "auto_adk_version_string");
      final int adkVersion = int.parse(adkVersionString!);

      final DateTime now = DateTime.now();
      final String fileToSave =
          createAutoBackupFilename(autoBackupDirectoryPath, now);

      final result = await SWB.encryptStackWalletWithADK(
          fileToSave, adkString!, jsonString,
          adkVersion: adkVersion);

      if (!result) {
        throw Exception("stack auto backup service failed to create a backup");
      }

      Prefs.instance.lastAutoBackup = now;

      // delete all but the latest 3 auto backups
      trimBackups(autoBackupDirectoryPath, 3);

      Logging.instance
          .log("AutoSWBService.doBackup() succeeded", level: LogLevel.Info);
    } on Exception catch (e, s) {
      String err = getErrorMessageFromSWBException(e);
      Logging.instance.log("$err\n$s", level: LogLevel.Error);
      // set error backup status and notify listeners
      _status = AutoSWBStatus.error;
      notifyListeners();
      return;
    } catch (e, s) {
      Logging.instance.log("$e\n$s", level: LogLevel.Error);
      // set error backup status and notify listeners
      _status = AutoSWBStatus.error;
      notifyListeners();
      return;
    }

    // set done/idle backup status and notify listeners
    _status = AutoSWBStatus.idle;
    notifyListeners();
  }

  /// Trim the number of auto backup files based on age
  void trimBackups(String dirPath, int numberToKeep) {
    final dir = Directory(dirPath);
    final List<Tuple2<DateTime, FileSystemEntity>> files = [];

    for (final file in dir.listSync()) {
      String fileName = file.uri.pathSegments.last;
      // check that its a swb auto backup file
      if (fileName.startsWith("stackautobackup_") &&
          fileName.endsWith(".swb")) {
        // get date from filename
        int a = fileName.indexOf("_") + 1;
        int b = fileName.indexOf(".swb");
        final dateString = fileName.substring(a, b);

        // split date components
        final d = dateString
            .split("_")
            .map((e) => int.parse(e))
            .toList(growable: false);

        // get date from components
        final date = DateTime(d[0], d[1], d[2], d[3], d[4], d[5]);

        // add date+file to list
        files.add(Tuple2(date, file));
      }
    }

    // sort from newest to oldest
    files.sort((a, b) =>
        b.item1.millisecondsSinceEpoch - a.item1.millisecondsSinceEpoch);

    // delete any older backups if there are more than the number we want to keep
    while (files.length > numberToKeep) {
      final fileToDelete = files.removeLast().item2;
      fileToDelete.deleteSync();
    }
  }

  /// Starts a periodic timer for [duration] where at the end of the specified
  /// duration an attempt is made to run a backup. This will cancel the previous
  /// timer if it was active.
  void startPeriodicBackupTimer({
    required Duration duration,
    bool shouldNotifyListeners = true,
  }) {
    _timer?.cancel();
    _timer = Timer.periodic(duration, (_) => doBackup());
    _isActiveTimer = true;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  /// Cancel the current periodic backup timer loop.
  void stopPeriodicBackupTimer({bool shouldNotifyListeners = true}) {
    _timer?.cancel();
    _timer = null;
    _isActiveTimer = false;
    if (shouldNotifyListeners) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPeriodicBackupTimer(shouldNotifyListeners: false);
    super.dispose();
  }
}
