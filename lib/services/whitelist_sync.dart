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

  static Future<void> _log(String msg) async {
    try {
      await _logFile.writeAsString(
        '${DateTime.now()}: $msg\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  static Future<void> _triggerReload() async {
    try {
      final ref = globalState.container;
      _log('Waiting 800ms for Riverpod stream...');
      await Future.delayed(const Duration(milliseconds: 200));
      _log('Triggering applyProfile...');
      ref.read(setupActionProvider.notifier).applyProfileDebounce();
      _log('applyProfile triggered');
    } catch (e, s) {
      _log('Reload failed: $e\n$s');
    }
  }

  static Future<void> syncAll() async {
    _log('========== syncAll start ==========');

    // 1. 查询数据库
    final domains = await database.whitelistsDao.queryAll().get();
    final processes = await database.processWhitelistsDao.queryAll().get();
    _log('DB domains: ${domains.length} (enabled: ${domains.where((d) => d.enabled).length})');
    _log('DB processes: ${processes.length} (enabled: ${processes.where((p) => p.enabled).length})');

    // 2. 查询现有规则
    final existingRules = await database.rulesDao.queryGlobalAddedRules().get();
    _log('Existing global rules: ${existingRules.length}');

    // 3. 删除旧的白名单规则
    final oldRuleIds = existingRules
        .where((r) =>
            (r.ruleAction == RuleAction.DOMAIN_SUFFIX ||
             r.ruleAction == RuleAction.PROCESS_NAME) &&
            r.ruleTarget == RuleTarget.DIRECT.name)
        .map((r) => r.id)
        .toList();
    if (oldRuleIds.isNotEmpty) {
      await database.rulesDao.delRules(oldRuleIds);
      _log('Deleted ${oldRuleIds.length} old whitelist rules');
    }

    // 4. 添加域名白名单规则
    int added = 0;
    for (final d in domains.where((d) => d.enabled)) {
      await database.rulesDao.putGlobalRule(Rule(
        ruleAction: RuleAction.DOMAIN_SUFFIX,
        content: d.domain,
        ruleTarget: RuleTarget.DIRECT.name,
      ));
      _log('Added domain rule: ${d.domain} -> DIRECT');
      added++;
    }

    // 5. 添加进程白名单规则
    for (final p in processes.where((p) => p.enabled)) {
      await database.rulesDao.putGlobalRule(Rule(
        ruleAction: RuleAction.PROCESS_NAME,
        content: p.processName,
        ruleTarget: RuleTarget.DIRECT.name,
      ));
      _log('Added process rule: ${p.processName} -> DIRECT');
      added++;
    }

    _log('Total rules added: $added');

    // 6. 验证
    final verifyRules = await database.rulesDao.queryGlobalAddedRules().get();
    final whitelistRules = verifyRules
        .where((r) =>
            r.ruleTarget == RuleTarget.DIRECT.name &&
            (r.ruleAction == RuleAction.DOMAIN_SUFFIX ||
             r.ruleAction == RuleAction.PROCESS_NAME))
        .toList();
    _log('Verified whitelist rules in DB: ${whitelistRules.length}');

    // 7. 触发重载（带延迟）
    if (added > 0) {
      await _triggerReload();
    }

    _log('========== syncAll end ==========');
  }
}
