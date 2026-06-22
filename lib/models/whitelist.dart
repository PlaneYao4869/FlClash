import 'package:freezed_annotation/freezed_annotation.dart';

part 'whitelist.freezed.dart';
part 'whitelist.g.dart';

@freezed
abstract class Whitelist with _$Whitelist {
  const factory Whitelist({
    @Default(-1) int id,
    required String domain,
    @Default(false) bool enabled,
    String? description,
    DateTime? createdAt,
  }) = _Whitelist;

  factory Whitelist.fromJson(Map<String, Object?> json) =>
      _$WhitelistFromJson(json);

  factory Whitelist.create({
    required String domain,
    String? description,
  }) {
    return Whitelist(
      domain: domain,
      description: description,
      createdAt: DateTime.now(),
    );
  }
}
