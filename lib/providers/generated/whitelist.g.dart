// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../whitelist.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(whitelistsStream)
final whitelistsStreamProvider = WhitelistsStreamProvider._();

final class WhitelistsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Whitelist>>,
          List<Whitelist>,
          Stream<List<Whitelist>>
        >
    with $FutureModifier<List<Whitelist>>, $StreamProvider<List<Whitelist>> {
  WhitelistsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whitelistsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whitelistsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<Whitelist>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Whitelist>> create(Ref ref) {
    return whitelistsStream(ref);
  }
}

String _$whitelistsStreamHash() => r'89a595d2d8ac11f7ed13933bf7c598d27f7305b7';

@ProviderFor(Whitelists)
final whitelistsProvider = WhitelistsProvider._();

final class WhitelistsProvider
    extends $NotifierProvider<Whitelists, List<Whitelist>> {
  WhitelistsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'whitelistsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$whitelistsHash();

  @$internal
  @override
  Whitelists create() => Whitelists();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Whitelist> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Whitelist>>(value),
    );
  }
}

String _$whitelistsHash() => r'e6ff502eca8ce183f5d849d4ce0d765f066e2474';

abstract class _$Whitelists extends $Notifier<List<Whitelist>> {
  List<Whitelist> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Whitelist>, List<Whitelist>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Whitelist>, List<Whitelist>>,
              List<Whitelist>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
