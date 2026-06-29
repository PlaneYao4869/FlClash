part of 'database.dart';

@DataClassName('RawProcessWhitelist')
@TableIndex(name: 'idx_process_whitelist_name', columns: {#processName})
class ProcessWhitelists extends Table {
  @override
  String get tableName => 'process_whitelists';

  IntColumn get id => integer()();

  TextColumn get processName => text()();

  TextColumn get exePath => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [ProcessWhitelists])
class ProcessWhitelistsDao extends DatabaseAccessor<Database>
    with _$ProcessWhitelistsDaoMixin {
  ProcessWhitelistsDao(super.attachedDatabase);

  Selectable<ProcessWhitelist> queryAll() {
    return select(processWhitelists).map((row) => row.toProcessWhitelist());
  }

  Selectable<ProcessWhitelist> queryEnabled() {
    return (select(processWhitelists)
      ..where((t) => t.enabled.equals(true))).map((row) => row.toProcessWhitelist());
  }

  Future<int> insertProcessWhitelist(ProcessWhitelist whitelist) {
    return into(processWhitelists).insert(whitelist.toCompanion());
  }

  Future<bool> updateProcessWhitelist(ProcessWhitelist whitelist) {
    return update(processWhitelists).replace(whitelist.toCompanion());
  }

  Future<int> deleteProcessWhitelist(int id) {
    return (delete(processWhitelists)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteProcessWhitelists(Set<int> ids) {
    return (delete(processWhitelists)..where((t) => t.id.isIn(ids))).go();
  }

  Future<int> deleteAll() {
    return delete(processWhitelists).go();
  }

  Future<int> count() async {
    final query = selectOnly(processWhitelists)..addColumns([processWhitelists.id.count()]);
    final result = await query.getSingle();
    return result.read(processWhitelists.id.count()) ?? 0;
  }
}

extension RawProcessWhitelistExtension on RawProcessWhitelist {
  ProcessWhitelist toProcessWhitelist() {
    return ProcessWhitelist(
      id: id,
      processName: processName,
      exePath: exePath,
      enabled: enabled,
      description: description,
      createdAt: createdAt,
    );
  }
}

extension ProcessWhitelistExtension on ProcessWhitelist {
  ProcessWhitelistsCompanion toCompanion() {
    return ProcessWhitelistsCompanion.insert(
      id: id == -1 ? const Value.absent() : Value(id),
      processName: processName,
      exePath: exePath,
      enabled: Value(enabled),
      description: Value(description),
      createdAt: Value(createdAt),
    );
  }
}
