import 'dart:async';

import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/models/process_whitelist.dart';
import 'package:fl_clash/services/whitelist_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/process_whitelist.g.dart';

@riverpod
Stream<List<ProcessWhitelist>> processWhitelistsStream(Ref ref) {
  return database.processWhitelistsDao.queryAll().watch();
}

@Riverpod(keepAlive: true)
class ProcessWhitelists extends _$ProcessWhitelists {
  @override
  List<ProcessWhitelist> build() {
    return ref.watch(processWhitelistsStreamProvider).value ?? [];
  }

  Future<void> _syncRules() async {
    try {
      await WhitelistRuleSync.syncAll();
    } catch (e) {
      print('Failed to sync process whitelist rules: $e');
    }
  }

  Future<void> addProcessWhitelist(ProcessWhitelist whitelist) async {
    final previous = List<ProcessWhitelist>.from(state);
    state = [...previous, whitelist];

    try {
      await database.processWhitelistsDao.insertProcessWhitelist(whitelist);
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> updateProcessWhitelist(ProcessWhitelist whitelist) async {
    final previous = List<ProcessWhitelist>.from(state);
    final index = previous.indexWhere((item) => item.id == whitelist.id);
    if (index == -1) return;

    final newList = List<ProcessWhitelist>.from(previous);
    newList[index] = whitelist;
    state = newList;

    try {
      await database.processWhitelistsDao.updateProcessWhitelist(whitelist);
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteProcessWhitelist(int id) async {
    final previous = List<ProcessWhitelist>.from(state);
    state = previous.where((item) => item.id != id).toList();

    try {
      await database.processWhitelistsDao.deleteProcessWhitelist(id);
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteProcessWhitelists(Set<int> ids) async {
    final previous = List<ProcessWhitelist>.from(state);
    state = previous.where((item) => !ids.contains(item.id)).toList();
    try {
      for (final id in ids) {
        await database.processWhitelistsDao.deleteProcessWhitelist(id);
      }
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> batchUpdateEnabled(Set<int> ids, bool enabled) async {
    final previous = List<ProcessWhitelist>.from(state);
    state = [
      for (final item in previous)
        if (ids.contains(item.id)) item.copyWith(enabled: enabled) else item
    ];
    try {
      for (final id in ids) {
        final item = previous.firstWhere((p) => p.id == id);
        await database.processWhitelistsDao.updateProcessWhitelist(
          item.copyWith(enabled: enabled),
        );
      }
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    final previous = List<ProcessWhitelist>.from(state);
    state = [];

    try {
      await database.processWhitelistsDao.deleteAll();
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }
}
