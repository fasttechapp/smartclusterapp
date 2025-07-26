import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final Logger log = Logger('SmartClusterApp');

void setupLogging() {
  Logger.root.level = Level.ALL; // Bisa diubah ke Level.INFO atau WARNING
  Logger.root.onRecord.listen((record) {
    // Output log bisa diganti kirim ke file atau server
    debugPrint(
      '${record.level.name} | ${record.time} | ${record.loggerName}: ${record.message}',
    );
  });
}
