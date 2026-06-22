import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/whitelist.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WhitelistPage extends ConsumerStatefulWidget {
  const WhitelistPage({super.key});

  @override
  ConsumerState<WhitelistPage> createState() => _WhitelistPageState();
}

class _WhitelistPageState extends ConsumerState<WhitelistPage> {
  final _key = utils.id;
  final _domainController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _domainController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleAddOrUpdate([Whitelist? whitelist]) async {
    final isEditing = whitelist != null;
    final appLocalizations = context.appLocalizations;
    final title = isEditing ? appLocalizations.editWhitelist : appLocalizations.addWhitelist;
    
    _domainController.text = whitelist?.domain ?? '';
    _descriptionController.text = whitelist?.description ?? '';

    final result = await showDialog<Whitelist>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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
                  SnackBar(content: Text('请输入域名')),
                );
                return;
              }
              
              final newWhitelist = isEditing
                  ? whitelist!.copyWith(
                      domain: domain,
                      description: _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                    )
                  : Whitelist.create(
                      domain: domain,
                      description: _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                    );
              
              Navigator.of(context).pop(newWhitelist);
            },
            child: Text(isEditing ? appLocalizations.save : appLocalizations.add),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (isEditing) {
      ref.read(whitelistsProvider.notifier).updateWhitelist(result);
    } else {
      ref.read(whitelistsProvider.notifier).addWhitelist(result);
    }
  }

  Future<void> _handleDelete(int id) async {
    final appLocalizations = context.appLocalizations;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.tip),
        content: Text('确定要删除这个白名单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(whitelistsProvider.notifier).deleteWhitelist(id);
    }
  }

  Future<void> _handleDeleteSelected() async {
    final selectedIds = ref.read(itemsProvider(_key));
    if (selectedIds.isEmpty) return;

    final appLocalizations = context.appLocalizations;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.tip),
        content: Text('确定要删除选中的 ${selectedIds.length} 个白名单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(whitelistsProvider.notifier).deleteWhitelists(selectedIds.cast<int>());
      ref.read(itemsProvider(_key).notifier).value = {};
    }
  }

  void _handleSelectAll() {
    final ids = ref.read(whitelistsProvider).value?.map((item) => item.id).toSet() ?? {};
    ref.read(itemsProvider(_key).notifier).update((selected) {
      return selected.containsAll(ids) ? {} : ids;
    });
  }

  void _handleSelected(int id) {
    ref.read(itemsProvider(_key).notifier).update((selected) {
      return Set<int>.from(selected)..addOrRemove(id);
    });
  }

  Future<void> _handleImportCommon() async {
    final commonDomains = [
      'baidu.com',
      'bilibili.com',
      'taobao.com',
      'jd.com',
      'weibo.com',
      'zhihu.com',
      'douyin.com',
      'kuaishou.com',
      'qq.com',
      'weixin.qq.com',
      '163.com',
      '126.com',
      'sina.com',
      'sohu.com',
      'ifeng.com',
      'csdn.net',
      'cnblogs.com',
      'oschina.net',
      'github.com',
      'gitee.com',
      'aliyun.com',
      'tencent.com',
      'huawei.com',
      'xiaomi.com',
      'apple.com',
      'microsoft.com',
      'google.com.hk',
    ];

    final appLocalizations = context.appLocalizations;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLocalizations.importCommonWebsites),
        content: Text('将导入 ${commonDomains.length} 个常见国内网站到白名单，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(appLocalizations.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(appLocalizations.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final whitelists = commonDomains.map((domain) {
        return Whitelist.create(domain: domain);
      }).toList();
      
      ref.read(whitelistsProvider.notifier).addWhitelists(whitelists);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导入 ${commonDomains.length} 个网站')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final whitelists = ref.watch(whitelistsProvider).value ?? [];
    final selectedIds = ref.watch(itemsProvider(_key));
    final appLocalizations = context.appLocalizations;

    return CommonPopScope(
      onPop: (_) {
        if (selectedIds.isNotEmpty) {
          ref.read(itemsProvider(_key).notifier).value = {};
          return false;
        }
        Navigator.of(context).pop();
        return false;
      },
      child: BaseScaffold(
        title: appLocalizations.whitelistManagement,
        actions: [
          if (selectedIds.isNotEmpty) ...[
            CommonMinIconButtonTheme(
              child: IconButton.filledTonal(
                onPressed: _handleDeleteSelected,
                icon: const Icon(Icons.delete),
              ),
            ),
            const SizedBox(width: 2),
            CommonMinFilledButtonTheme(
              child: FilledButton(
                onPressed: _handleSelectAll,
                child: Text(appLocalizations.selectAll),
              ),
            ),
          ] else ...[
            CommonMinIconButtonTheme(
              child: IconButton.filledTonal(
                onPressed: _handleImportCommon,
                icon: const Icon(Icons.download),
                tooltip: appLocalizations.importCommonWebsites,
              ),
            ),
            const SizedBox(width: 2),
            CommonMinFilledButtonTheme(
              child: FilledButton.tonal(
                onPressed: () => _handleAddOrUpdate(),
                child: Text(appLocalizations.add),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
        body: whitelists.isEmpty
            ? NullStatus(
                label: appLocalizations.noWhitelistDomains,
                illustration: const Icon(Icons.list_alt, size: 64, color: Colors.grey),
              )
            : ReorderableList(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                itemBuilder: (context, index) {
                  final whitelist = whitelists[index];
                  final position = ItemPosition.get(index, whitelists.length);
                  return ReorderableDelayedDragStartListener(
                    key: ObjectKey(whitelist),
                    index: index,
                    child: ItemPositionProvider(
                      position: position,
                      child: WhitelistItem(
                        whitelist: whitelist,
                        isEditing: selectedIds.isNotEmpty,
                        isSelected: selectedIds.contains(whitelist.id),
                        onSelected: () => _handleSelected(whitelist.id),
                        onEdit: () => _handleAddOrUpdate(whitelist),
                        onDelete: () => _handleDelete(whitelist.id),
                      ),
                    ),
                  );
                },
                itemExtent: 72,
                itemCount: whitelists.length,
                onReorder: ref.read(whitelistsProvider.notifier).reorder,
              ),
      ),
    );
  }
}

class WhitelistItem extends StatelessWidget {
  final Whitelist whitelist;
  final bool isEditing;
  final bool isSelected;
  final VoidCallback onSelected;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WhitelistItem({
    super.key,
    required this.whitelist,
    required this.isEditing,
    required this.isSelected,
    required this.onSelected,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: isEditing
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onSelected(),
              )
            : const Icon(Icons.language),
        title: Text(
          whitelist.domain,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: whitelist.description != null
            ? Text(whitelist.description!)
            : null,
        trailing: isEditing
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                  ),
                ],
              ),
        onTap: isEditing ? onSelected : onEdit,
      ),
    );
  }
}
