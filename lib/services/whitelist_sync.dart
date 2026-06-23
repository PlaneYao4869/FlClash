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

  /// 延迟重载，500ms 防抖
  static void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final ref = globalState.container;
        _log('Calling applyProfile(force: true)...');
        await ref.read(setupActionProvider.notifier).applyProfile(force: true);
        _log('applyProfile done');
      } catch (e) {
        _log('Reload failed: $e');
      }
    });
  }

  static Future<void> syncAll() async {
    _log('========== syncAll ==========');

    final domains = await database.whitelistsDao.queryAll().get();
    final processes = await database.processWhitelistsDao.queryAll().get();
    final enabledDomains = domains.where((d) => d.enabled).toList();
    final enabledProcesses = processes.where((p) => p.enabled).toList();

    _log('Domains: ${domains.length} (${enabledDomains.length} enabled)');
    _log('Processes: ${processes.length} (${enabledProcesses.length} enabled)');

    // 获取现有规则
    final existingRules = await database.rulesDao.queryGlobalAddedRules().get();

    // 删除旧的白名单规则
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

    // 添加域名白名单规则
    int added = 0;
    for (final d in enabledDomains) {
      await database.rulesDao.putGlobalRule(Rule(
        ruleAction: RuleAction.DOMAIN_SUFFIX,
        content: d.domain,
        ruleTarget: RuleTarget.DIRECT.name,
      ));
      _log('Added domain: ${d.domain} -> DIRECT');
      added++;
    }

    // 添加进程白名单规则
    for (final p in enabledProcesses) {
      await database.rulesDao.putGlobalRule(Rule(
        ruleAction: RuleAction.PROCESS_NAME,
        content: p.processName,
        ruleTarget: RuleTarget.DIRECT.name,
      ));
      _log('Added process: ${p.processName} -> DIRECT');
      added++;
    }

    _log('Total added: $added rules');

    // 验证规则已写入
    final verifyRules = await database.rulesDao.queryGlobalAddedRules().get();
    final whitelistRules = verifyRules
        .where((r) =>
            r.ruleTarget == RuleTarget.DIRECT.name &&
            (r.ruleAction == RuleAction.DOMAIN_SUFFIX ||
             r.ruleAction == RuleAction.PROCESS_NAME))
        .toList();
    _log('Verified whitelist rules: ${whitelistRules.length}');

    // 触发重载
    if (added > 0) {
      _scheduleReload();
    }

    _log('========== syncAll done ==========');
  }
}
