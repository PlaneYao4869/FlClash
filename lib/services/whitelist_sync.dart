import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/models/whitelist.dart';
import 'package:fl_clash/models/process_whitelist.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';

class WhitelistRuleSync {
  /// 触发 Clash 配置重载
  static void _triggerReload() {
    try {
      final ref = globalState.container;
      ref.read(setupActionProvider.notifier).updateConfigDebounce();
    } catch (e) {
      print('Failed to trigger config reload: $e');
    }
  }

  /// 同步域名白名单到 Clash 规则
  static Future<void> syncDomainWhitelist() async {
    final whitelists = await database.whitelistsDao.queryEnabled().get();
    final existingRules = await database.rulesDao.queryGlobalAddedRules().get();

    final whitelistRuleIds = existingRules
        .where((rule) =>
            rule.ruleAction == RuleAction.DOMAIN_SUFFIX &&
            rule.ruleTarget == RuleTarget.DIRECT.name &&
            rule.content != null &&
            whitelists.any((w) => w.domain == rule.content))
        .map((rule) => rule.id)
        .toList();

    if (whitelistRuleIds.isNotEmpty) {
      await database.rulesDao.delRules(whitelistRuleIds);
    }

    for (final whitelist in whitelists) {
      final alreadyExists = existingRules.any((rule) =>
          rule.ruleAction == RuleAction.DOMAIN_SUFFIX &&
          rule.content == whitelist.domain &&
          rule.ruleTarget == RuleTarget.DIRECT.name &&
          !whitelistRuleIds.contains(rule.id));

      if (!alreadyExists) {
        final rule = Rule(
          ruleAction: RuleAction.DOMAIN_SUFFIX,
          content: whitelist.domain,
          ruleTarget: RuleTarget.DIRECT.name,
        );
        await database.rulesDao.putGlobalRule(rule);
      }
    }

    _triggerReload();
  }

  /// 同步进程白名单到 Clash 规则
  static Future<void> syncProcessWhitelist() async {
    final processWhitelists =
        await database.processWhitelistsDao.queryEnabled().get();
    final existingRules = await database.rulesDao.queryGlobalAddedRules().get();

    final processRuleIds = existingRules
        .where((rule) =>
            rule.ruleAction == RuleAction.PROCESS_NAME &&
            rule.ruleTarget == RuleTarget.DIRECT.name)
        .map((rule) => rule.id)
        .toList();

    if (processRuleIds.isNotEmpty) {
      await database.rulesDao.delRules(processRuleIds);
    }

    for (final pw in processWhitelists) {
      final rule = Rule(
        ruleAction: RuleAction.PROCESS_NAME,
        content: pw.processName,
        ruleTarget: RuleTarget.DIRECT.name,
      );
      await database.rulesDao.putGlobalRule(rule);
    }

    _triggerReload();
  }

  /// 同步所有白名单
  static Future<void> syncAll() async {
    await syncDomainWhitelist();
    await syncProcessWhitelist();
  }
}
