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

  /// 延迟重载，避免频繁触发
  static void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 300), () async {
      try {
        final ref = globalState.container;
        _log('Calling applyProfile(force: true)...');
        await ref.read(setupActionProvider.notifier).applyProfile(force: true);
        _log('applyProfile done');
      } catch (e, s) {
        _log('Reload failed: $e\n$s');
      }
    });
  }

  static Future<void> syncAll() async {
    _log('========== syncAll ==========');

    // 1. 查询数据库
    final domains = await database.whitelistsDao.queryAll().get();
    final processes = await database.processWhitelistsDao.queryAll().get();
    final enabledDomains = domains.where((d) => d.enabled).toList();
    final enabledProcesses = processes.where((p) => p.enabled).toList();
    _log('Domains: ${domains.length} (${enabledDomains.length} enabled)');
    _log('Processes: ${processes.length} (${enabledProcesses.length} enabled)');

    // 2. 删除旧的白名单规则
    final existingRules = await database.rulesDao.queryGlobalAddedRules().get();
    final oldRuleIds = existingRules
        .where((r) =>
            (r.ruleAction == RuleAction.DOMAIN_SUFFIX ||
             r.ruleAction == RuleAction.PROCESS_NAME) &&
            r.ruleTarget == RuleTarget.DIRECT.name)
        .map((r) => r.id)
        .toList();
    if (oldRuleIds.isNotEmpty) {
      await database.rulesDao.delRules(oldRuleIds);
      _log('Deleted ${oldRuleIds.length} old rules');
    }

    // 3. 添加启用的规则
    int added = 0;
    for (final d in enabledDomains) {
      await database.rulesDao.putGlobalRule(Rule(
        ruleAction: RuleAction.DOMAIN_SUFFIX,
        content: d.domain,
        ruleTarget: RuleTarget.DIRECT.name,
      ));
      added++;
    }
    for (final p in enabledProcesses) {
      await database.rulesDao.putGlobalRule(Rule(
        ruleAction: RuleAction.PROCESS_NAME,
        content: p.processName,
        ruleTarget: RuleTarget.DIRECT.name,
      ));
      added++;
    }
    _log('Added $added rules');

    // 4. 延迟重载（合并多次快速调用）
    _scheduleReload();
    _log('========== syncAll done ==========');
  }
}
