import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/whitelist.dart';
import 'package:fl_clash/models/process_whitelist.dart';
import 'package:fl_clash/providers/providers.dart';
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

/// Generic scaffold providing search + multi-select + bulk actions for
/// whitelist list pages.  Items must expose an `id` int (e.g. Whitelist /
/// ProcessWhitelist).
class WhitelistScaffold<T> extends StatefulWidget {
  const WhitelistScaffold({
    super.key,
    required this.filteredItems,
    required this.itemBuilder,
    required this.searchHint,
    required this.onSearchChanged,
    required this.statisticsText,
    required this.emptyMessage,
    required this.bulkActions,
    this.floatingActionButton,
    this.appBarActions = const [],
  });

  final List<T> filteredItems;
  final Widget Function(BuildContext context, T item, bool selected,
      bool multiSelectMode, VoidCallback onTap) itemBuilder;
  final String searchHint;
  final ValueChanged<String> onSearchChanged;
  final String statisticsText;
  final String emptyMessage;
  final Widget Function(Set<int> selectedIds) bulkActions;
  final Widget? floatingActionButton;
  final List<Widget> appBarActions;

  @override
  State<WhitelistScaffold<T>> createState() => _WhitelistScaffoldState<T>();
}

class _WhitelistScaffoldState<T> extends State<WhitelistScaffold<T>> {
  final _searchController = TextEditingController();
  bool _multiSelectMode = false;
  final Set<int> _selected = <int>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _idOf(T item) {
    final dynamic d = item;
    return d.id as int;
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelectMode = false;
      _selected.clear();
    });
  }

  void _selectAll() {
    setState(() {
      _selected
        ..clear()
        ..addAll(widget.filteredItems.map(_idOf));
    });
  }

  void _invertSelection() {
    setState(() {
      final filteredIds = widget.filteredItems.map(_idOf).toSet();
      final inverted = <int>{};
      for (final id in filteredIds) {
        if (!_selected.contains(id)) {
          inverted.add(id);
        }
      }
      _selected
        ..clear()
        ..addAll(inverted);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMulti = _multiSelectMode;
    final hasFiltered = widget.filteredItems.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.searchHint,
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            isCollapsed: true,
          ),
          onChanged: widget.onSearchChanged,
        ),
        actions: [
          ...widget.appBarActions,
          IconButton(
            tooltip: isMulti ? '退出多选' : '多选',
            icon: Icon(isMulti ? Icons.close : Icons.checklist),
            onPressed: () {
              setState(() {
                _multiSelectMode = !_multiSelectMode;
                _selected.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.statisticsText,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: !hasFiltered
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.list_alt,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(widget.emptyMessage),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      4,
                      16,
                      isMulti ? 16 : 100,
                    ),
                    itemCount: widget.filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.filteredItems[index];
                      final id = _idOf(item);
                      final selected = _selected.contains(id);
                      return widget.itemBuilder(
                        context,
                        item,
                        selected,
                        isMulti,
                        () {
                          if (isMulti) {
                            _toggleSelect(id);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: isMulti
          ? BottomAppBar(
              child: Row(
                children: [
                  Text('已选 ${_selected.length} 项'),
                  const Spacer(),
                  IconButton(
                    tooltip: '全选',
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectAll,
                  ),
                  IconButton(
                    tooltip: '反选',
                    icon: const Icon(Icons.swap_horiz),
                    onPressed: _invertSelection,
                  ),
                  ...widget.bulkActions(_selected),
                  IconButton(
                    tooltip: '退出多选',
                    icon: const Icon(Icons.close),
                    onPressed: _exitMultiSelect,
                  ),
                ],
              ),
            )
          : null,
      floatingActionButton: isMulti ? null : widget.floatingActionButton,
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
  String _query = '';

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
      final whitelists =
          commonDomains.map((d) => Whitelist.create(domain: d)).toList();
      ref.read(whitelistsProvider.notifier).addWhitelists(whitelists);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whitelists = ref.watch(whitelistsProvider);
    final appLocalizations = context.appLocalizations;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? whitelists
        : whitelists
            .where((w) => w.domain.toLowerCase().contains(q))
            .toList(growable: false);
    final enabledCount = whitelists.where((w) => w.enabled).length;

    return WhitelistScaffold<Whitelist>(
      filteredItems: filtered,
      searchHint: '搜索域名',
      statisticsText:
          '共 ${whitelists.length} 个域名，已启用 $enabledCount 个',
      emptyMessage: appLocalizations.noWhitelistDomains,
      onSearchChanged: (v) => setState(() => _query = v),
      appBarActions: [
        IconButton(
          tooltip: '导入常见网站',
          icon: const Icon(Icons.download),
          onPressed: _handleImportCommon,
        ),
      ],
      bulkActions: (selected) => [
        IconButton(
          tooltip: '全部启用',
          icon: const Icon(Icons.toggle_on, color: Colors.green),
          onPressed: selected.isEmpty
              ? null
              : () {
                  ref
                      .read(whitelistsProvider.notifier)
                      .batchUpdateEnabled(selected, true);
                },
        ),
        IconButton(
          tooltip: '全部禁用',
          icon: const Icon(Icons.toggle_off, color: Colors.grey),
          onPressed: selected.isEmpty
              ? null
              : () {
                  ref
                      .read(whitelistsProvider.notifier)
                      .batchUpdateEnabled(selected, false);
                },
        ),
        IconButton(
          tooltip: '删除选中',
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: selected.isEmpty
              ? null
              : () {
                  ref
                      .read(whitelistsProvider.notifier)
                      .deleteWhitelists(selected);
                },
        ),
      ],
      itemBuilder: (context, item, selected, multiSelectMode, onTap) {
        return Card(
          child: ListTile(
            leading: multiSelectMode
                ? Checkbox(value: selected, onChanged: (_) => onTap())
                : const Icon(Icons.language),
            title: Text(item.domain),
            subtitle:
                item.description != null ? Text(item.description!) : null,
            trailing: multiSelectMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.enabled,
                        onChanged: (value) {
                          ref
                              .read(whitelistsProvider.notifier)
                              .updateWhitelist(
                                item.copyWith(enabled: value),
                              );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => ref
                            .read(whitelistsProvider.notifier)
                            .deleteWhitelist(item.id),
                      ),
                    ],
                  ),
            onTap: multiSelectMode ? onTap : null,
          ),
        );
      },
      floatingActionButton: FloatingActionButton(
        heroTag: 'domain-add',
        onPressed: _handleAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProcessWhitelistTab extends ConsumerStatefulWidget {
  const ProcessWhitelistTab({super.key});

  @override
  ConsumerState<ProcessWhitelistTab> createState() =>
      _ProcessWhitelistTabState();
}

class _ProcessWhitelistTabState extends ConsumerState<ProcessWhitelistTab> {
  String _query = '';

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
            Text('路径: $exePath',
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
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
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? processWhitelists
        : processWhitelists
            .where((p) =>
                p.processName.toLowerCase().contains(q) ||
                p.exePath.toLowerCase().contains(q))
            .toList(growable: false);
    final enabledCount = processWhitelists.where((p) => p.enabled).length;

    return WhitelistScaffold<ProcessWhitelist>(
      filteredItems: filtered,
      searchHint: '搜索进程名或路径',
      statisticsText:
          '共 ${processWhitelists.length} 个进程，已启用 $enabledCount 个',
      emptyMessage: '暂无进程白名单',
      onSearchChanged: (v) => setState(() => _query = v),
      bulkActions: (selected) => [
        IconButton(
          tooltip: '全部启用',
          icon: const Icon(Icons.toggle_on, color: Colors.green),
          onPressed: selected.isEmpty
              ? null
              : () {
                  ref
                      .read(processWhitelistsProvider.notifier)
                      .batchUpdateEnabled(selected, true);
                },
        ),
        IconButton(
          tooltip: '全部禁用',
          icon: const Icon(Icons.toggle_off, color: Colors.grey),
          onPressed: selected.isEmpty
              ? null
              : () {
                  ref
                      .read(processWhitelistsProvider.notifier)
                      .batchUpdateEnabled(selected, false);
                },
        ),
        IconButton(
          tooltip: '删除选中',
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: selected.isEmpty
              ? null
              : () {
                  ref
                      .read(processWhitelistsProvider.notifier)
                      .deleteProcessWhitelists(selected);
                },
        ),
      ],
      itemBuilder: (context, item, selected, multiSelectMode, onTap) {
        return Card(
          child: ListTile(
            leading: multiSelectMode
                ? Checkbox(value: selected, onChanged: (_) => onTap())
                : const Icon(Icons.apps, color: Colors.blue),
            title: Text(item.processName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.description != null) Text(item.description!),
                Text(
                  item.exePath,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            isThreeLine: item.description != null,
            trailing: multiSelectMode
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: item.enabled,
                        onChanged: (value) {
                          ref
                              .read(processWhitelistsProvider.notifier)
                              .updateProcessWhitelist(
                                item.copyWith(enabled: value),
                              );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _handleDelete(item.id),
                      ),
                    ],
                  ),
            onTap: multiSelectMode ? onTap : null,
          ),
        );
      },
      floatingActionButton: FloatingActionButton(
        heroTag: 'process-add',
        onPressed: _handleAddProcess,
        child: const Icon(Icons.add),
      ),
    );
  }
}
