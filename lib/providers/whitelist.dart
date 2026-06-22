import 'dart:async';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/models/whitelist.dart';
import 'package:fl_clash/services/whitelist_sync.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/whitelist.g.dart';

@riverpod
Stream<List<Whitelist>> whitelistsStream(Ref ref) {
  return database.whitelistsDao.queryAll().watch();
}

@Riverpod(keepAlive: true)
class Whitelists extends _$Whitelists {
  @override
  List<Whitelist> build() {
    return ref.watch(whitelistsStreamProvider).value ?? [];
  }

  Future<void> _syncRules() async {
    try {
      await WhitelistRuleSync.syncWhitelistToRules();
    } catch (e) {
      print('Failed to sync whitelist rules: $e');
    }
  }

  Future<void> addWhitelist(Whitelist whitelist) async {
    final previous = List<Whitelist>.from(state);
    state = [...previous, whitelist];
    
    try {
      await database.whitelistsDao.insertWhitelist(whitelist);
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> addWhitelists(List<Whitelist> whitelists) async {
    final previous = List<Whitelist>.from(state);
    state = [...previous, ...whitelists];
    
    try {
      for (final whitelist in whitelists) {
        await database.whitelistsDao.insertWhitelist(whitelist);
      }
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> updateWhitelist(Whitelist whitelist) async {
    final previous = List<Whitelist>.from(state);
    final index = previous.indexWhere((item) => item.id == whitelist.id);
    if (index == -1) return;
    
    final newList = List<Whitelist>.from(previous);
    newList[index] = whitelist;
    state = newList;
    
    try {
      await database.whitelistsDao.updateWhitelist(whitelist);
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteWhitelist(int id) async {
    final previous = List<Whitelist>.from(state);
    state = previous.where((item) => item.id != id).toList();
    
    try {
      await database.whitelistsDao.deleteWhitelist(id);
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteWhitelists(Set<int> ids) async {
    final previous = List<Whitelist>.from(state);
    state = previous.where((item) => !ids.contains(item.id)).toList();
    
    try {
      for (final id in ids) {
        await database.whitelistsDao.deleteWhitelist(id);
      }
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    final previous = List<Whitelist>.from(state);
    state = [];
    
    try {
      await database.whitelistsDao.deleteAll();
      await _syncRules();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  void reorder(int oldIndex, int newIndex) {
    final previous = List<Whitelist>.from(state);
    final newList = List<Whitelist>.from(previous);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final item = newList.removeAt(oldIndex);
    newList.insert(newIndex, item);
    state = newList;
  }
}
