import 'dart:async';
import 'dart:io';

import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';

class WhitelistRuleSync {
  static final _logFile = File(
    '${Platform.environment['TEMP'] ?? 'C:\\Windows\\Temp'}\\flclash_whitelist.log',
  );

  static Timer? _reloadTimer;

  static Future<void> _log(String msg) async {
    try {
      await _logFile.writeAsString(
        '${DateTime.now()}: $msg\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  /// 轻量重载，50ms 防抖
  static void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 50), () async {
      try {
        final ref = globalState.container;
        _log('applyProfile(force: true)...');
        await ref.read(setupActionProvider.notifier).applyProfile(force: true);
      } catch (e) {
        _log('Reload failed: $e');
      }
    });
  }

  /// 增量同步：只处理变化的白名单项
  static Future<void> syncAll() async {
    _log('========== syncAll ==========');

    final domains = await database.whitelistsDao.queryAll().get();
    final processes = await database.processWhitelistsDao.queryAll().get();
    final enabledDomains = domains.where((d) => d.enabled).toList();
    final enabledProcesses = processes.where((p) => p.enabled).toList();

    // 构建期望的规则集合
    final desiredRules = <String, bool>{}; // key: "action:content", enabled
    for (final d in enabledDomains) {
      desiredRules['DOMAIN-SUFFIX:${d.domain}'] = true;
    }
    for (final p in enabledProcesses) {
      desiredRules['PROCESS-NAME:${p.processName}'] = true;
    }

    // 获取现有规则
    final existingRules = await database.rulesDao.queryGlobalAddedRules().get();
    final existingWhitelistRules = existingRules.where((r) =>
        (r.ruleAction == RuleAction.DOMAIN_SUFFIX ||
         r.ruleAction == RuleAction.PROCESS_NAME) &&
        r.ruleTarget == RuleTarget.DIRECT.name).toList();

    // 构建现有规则集合
    final existingKeys = <String, int>{}; // key -> ruleId
    for (final r in existingWhitelistRules) {
      existingKeys['${r.ruleAction.name}:${r.content}'] = r.id;
    }

    // 找出需要删除的（现有但不在期望中）
    final toDelete = <int>[];
    for (final entry in existingKeys.entries) {
      if (!desiredRules.containsKey(entry.key)) {
        toDelete.add(entry.value);
      }
    }

    // 找出需要添加的（期望但不在现有中）
    final toAdd = <String>[];
    for (final key in desiredRules.keys) {
      if (!existingKeys.containsKey(key)) {
        toAdd.add(key);
      }
    }

    // 执行删除
    if (toDelete.isNotEmpty) {
      await database.rulesDao.delRules(toDelete);
      _log('Deleted ${toDelete.length} rules');
    }

    // 执行添加
    for (final key in toAdd) {
      final parts = key.split(':');
      final action = parts[0] == 'DOMAIN-SUFFIX'
          ? RuleAction.DOMAIN_SUFFIX
          : RuleAction.PROCESS_NAME;
      final content = parts.sublist(1).join(':');
      await database.rulesDao.putGlobalRule(Rule(
        ruleAction: action,
        content: content,
        ruleTarget: RuleTarget.DIRECT.name,
      ));
      _log('Added: $key -> DIRECT');
    }

    final changed = toDelete.length + toAdd.length;
    _log('Changed: $changed rules');

    // 只有变化时才触发重载
    if (changed > 0) {
      _scheduleReload();
    }

    _log('========== syncAll done ==========');
  }
}
