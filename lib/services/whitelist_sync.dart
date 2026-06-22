import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/models/clash_config.dart';
import 'package:fl_clash/models/whitelist.dart';
import 'package:fl_clash/enum/enum.dart';

class WhitelistRuleSync {
  static Future<void> syncWhitelistToRules() async {
    final whitelists = await database.whitelistsDao.queryEnabled().get();
    final existingRules = await database.rulesDao.queryGlobalAddedRules().get();
    
    // 找出旧的白名单规则（DOMAIN-SUFFIX + DIRECT 且域名在白名单中的）
    final whitelistRuleIds = existingRules
        .where((rule) =>
            rule.ruleAction == RuleAction.DOMAIN_SUFFIX &&
            rule.ruleTarget == RuleTarget.DIRECT.name &&
            rule.content != null &&
            whitelists.any((w) => w.domain == rule.content))
        .map((rule) => rule.id)
        .toList();
    
    // 删除旧的白名单规则
    if (whitelistRuleIds.isNotEmpty) {
      await database.rulesDao.delRules(whitelistRuleIds);
    }
    
    // 添加新的白名单规则
    for (final whitelist in whitelists) {
      // 检查是否已有该域名的规则
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
  }
}
