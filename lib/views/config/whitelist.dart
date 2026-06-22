import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/whitelist.dart';
import 'package:fl_clash/models/process_whitelist.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class WhitelistPage extends ConsumerStatefulWidget {
  const WhitelistPage({super.key});

  @override
  ConsumerState<WhitelistPage> createState() => _WhitelistPageState();
}

class _WhitelistPageState extends ConsumerState<WhitelistPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.whitelistManagement),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '域名白名单', icon: Icon(Icons.language)),
            Tab(text: '进程白名单', icon: Icon(Icons.apps)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DomainWhitelistTab(),
          ProcessWhitelistTab(),
        ],
      ),
    );
  }
}

class DomainWhitelistTab extends ConsumerStatefulWidget {
  const DomainWhitelistTab({super.key});

  @override
  ConsumerState<DomainWhitelistTab> createState() => _DomainWhitelistTabState();
}

class _DomainWhitelistTabState extends ConsumerState<DomainWhitelistTab> {
  final _domainController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _domainController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleAdd() async {
    final appLocalizations = context.appLocalizations;
    _domainController.clear();
    _descriptionController.clear();

    final result = await showDialog<Whitelist>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.addWhitelist),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _domainController,
              decoration: InputDecoration(
                labelText: appLocalizations.domainName,
                hintText: '例如: baidu.com',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: appLocalizations.descriptionOptional,
                hintText: '例如: 百度搜索',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () {
              final domain = _domainController.text.trim();
              if (domain.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入域名')),
                );
                return;
              }
              Navigator.of(context).pop(
                Whitelist.create(
                  domain: domain,
                  description: _descriptionController.text.trim().isEmpty
                      ? null
                      : _descriptionController.text.trim(),
                ),
              );
            },
            child: Text(appLocalizations.add),
          ),
        ],
      ),
    );

    if (result != null) {
      ref.read(whitelistsProvider.notifier).addWhitelist(result);
    }
  }

  Future<void> _handleImportCommon() async {
    final commonDomains = [
      'baidu.com', 'bilibili.com', 'taobao.com', 'jd.com',
      'weibo.com', 'zhihu.com', 'douyin.com', 'qq.com',
      'weixin.qq.com', '163.com', '126.com', 'sina.com',
      'csdn.net', 'github.com', 'gitee.com', 'aliyun.com',
      'tencent.com', 'huawei.com', 'xiaomi.com', 'apple.com',
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.appLocalizations.importCommonWebsites),
        content: Text('将导入 ${commonDomains.length} 个常见国内网站到白名单'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.appLocalizations.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final whitelists = commonDomains.map((d) => Whitelist.create(domain: d)).toList();
      ref.read(whitelistsProvider.notifier).addWhitelists(whitelists);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whitelists = ref.watch(whitelistsProvider);
    final appLocalizations = context.appLocalizations;

    return Scaffold(
      body: whitelists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(appLocalizations.noWhitelistDomains),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: whitelists.length,
              itemBuilder: (context, index) {
                final item = whitelists[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(item.domain),
                    subtitle: item.description != null ? Text(item.description!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: item.enabled,
                          onChanged: (value) {
                            ref.read(whitelistsProvider.notifier)
                                .updateWhitelist(item.copyWith(enabled: value));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => ref.read(whitelistsProvider.notifier).deleteWhitelist(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'import',
            onPressed: _handleImportCommon,
            child: const Icon(Icons.download),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _handleAdd,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class ProcessWhitelistTab extends ConsumerStatefulWidget {
  const ProcessWhitelistTab({super.key});

  @override
  ConsumerState<ProcessWhitelistTab> createState() => _ProcessWhitelistTabState();
}

class _ProcessWhitelistTabState extends ConsumerState<ProcessWhitelistTab> {
  Future<void> _handleAddProcess() async {
    final appLocalizations = context.appLocalizations;
    
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['exe'],
      dialogTitle: '选择要直连的程序',
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final exePath = file.path!;
    final processName = p.basename(exePath);

    final existing = ref.read(processWhitelistsProvider);
    if (existing.any((item) => item.processName == processName)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$processName 已在白名单中')),
        );
      }
      return;
    }

    final descriptionController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加进程白名单'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('程序: $processName'),
            const SizedBox(height: 8),
            Text('路径: $exePath', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '例如: 微信',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(processWhitelistsProvider.notifier).addProcessWhitelist(
        ProcessWhitelist.create(
          processName: processName,
          exePath: exePath,
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        ),
      );
    }
  }

  Future<void> _handleDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后该程序将恢复走代理'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.appLocalizations.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(processWhitelistsProvider.notifier).deleteProcessWhitelist(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final processWhitelists = ref.watch(processWhitelistsProvider);

    return Scaffold(
      body: processWhitelists.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.apps, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('暂无进程白名单'),
                  SizedBox(height: 8),
                  Text('点击右下角 + 添加要直连的程序', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: processWhitelists.length,
              itemBuilder: (context, index) {
                final item = processWhitelists[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.apps, color: Colors.blue),
                    title: Text(item.processName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description != null) Text(item.description!),
                        Text(
                          item.exePath,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    isThreeLine: item.description != null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: item.enabled,
                          onChanged: (value) {
                            ref.read(processWhitelistsProvider.notifier)
                                .updateProcessWhitelist(item.copyWith(enabled: value));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _handleDelete(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddProcess,
        child: const Icon(Icons.add),
      ),
    );
  }
}
