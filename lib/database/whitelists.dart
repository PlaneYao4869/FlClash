part of 'database.dart';

@DataClassName('RawWhitelist')
@TableIndex(name: 'idx_whitelist_domain', columns: {#domain})
class Whitelists extends Table {
  @override
  String get tableName => 'whitelists';

  IntColumn get id => integer()();

  TextColumn get domain => text()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  TextColumn get description => text().nullable()();

  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [Whitelists])
class WhitelistsDao extends DatabaseAccessor<Database>
    with _$WhitelistsDaoMixin {
  WhitelistsDao(super.attachedDatabase);

  Selectable<Whitelist> queryAll() {
    return select(whitelists).map((row) => row.toWhitelist());
  }

  Selectable<Whitelist> queryEnabled() {
    return (select(whitelists)
      ..where((t) => t.enabled.equals(true))).map((row) => row.toWhitelist());
  }

  Future<int> insertWhitelist(Whitelist whitelist) {
    return into(whitelists).insert(whitelist.toCompanion());
  }

  Future<bool> updateWhitelist(Whitelist whitelist) {
    return update(whitelists).replace(whitelist.toCompanion());
  }

  Future<int> deleteWhitelist(int id) {
    return (delete(whitelists)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteAll() {
    return delete(whitelists).go();
  }

  Future<int> count() async {
    final query = selectOnly(whitelists)..addColumns([whitelists.id.count()]);
    final result = await query.getSingle();
    return result.read(whitelists.id.count()) ?? 0;
  }
}

extension RawWhitelistExtension on RawWhitelist {
  Whitelist toWhitelist() {
    return Whitelist(
      id: id,
      domain: domain,
      enabled: enabled,
      description: description,
      createdAt: createdAt,
    );
  }
}

extension WhitelistExtension on Whitelist {
  WhitelistsCompanion toCompanion() {
    return WhitelistsCompanion(
      id: id == -1 ? const Value.absent() : Value(id),
      Value(domain),
      Value(enabled),
      Value(description),
      Value(createdAt),
    );
  }
}
