import 'dart:async';
import 'dart:io';

import 'package:fl_clash/pages/error.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rust_api/rust_api.dart';

import 'application.dart';
import 'common/common.dart';

Future<void> _writeLog(String msg) async {
  try {
    final file = File('${Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp'}\\flclash_crash.log');
    await file.writeAsString('${DateTime.now()}: $msg\n', mode: FileMode.append);
  } catch (_) {}
}

Future<void> main() async {
  await _writeLog('=== FlClash starting ===');
  try {
    await _writeLog('Step 1: WidgetsFlutterBinding');
    WidgetsFlutterBinding.ensureInitialized();
    
    await _writeLog('Step 2: RustLib.init');
    if (system.isDesktop) {
      await RustLib.init();
    }
    
    await _writeLog('Step 3: system.version');
    final version = await system.version;
    
    await _writeLog('Step 4: globalState.init');
    final container = await globalState.init(version);
    
    await _writeLog('Step 5: HttpOverrides');
    HttpOverrides.global = FlClashHttpOverrides();
    
    await _writeLog('Step 6: runApp');
    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const Application(),
      ),
    );
    await _writeLog('=== FlClash started OK ===');
  } catch (e, s) {
    await _writeLog('CRASH: $e\n$s');
    return runApp(
      MaterialApp(
        home: InitErrorScreen(error: e, stack: s),
      ),
    );
  }
}
