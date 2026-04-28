// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ProjectDirectory)
final projectDirectoryProvider = ProjectDirectoryProvider._();

final class ProjectDirectoryProvider
    extends $NotifierProvider<ProjectDirectory, Directory?> {
  ProjectDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'projectDirectoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$projectDirectoryHash();

  @$internal
  @override
  ProjectDirectory create() => ProjectDirectory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Directory? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Directory?>(value),
    );
  }
}

String _$projectDirectoryHash() => r'b431adcf2394545c58a994eafd49b9477bcf6f07';

abstract class _$ProjectDirectory extends $Notifier<Directory?> {
  Directory? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<Directory?, Directory?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Directory?, Directory?>,
              Directory?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FileTree)
final fileTreeProvider = FileTreeProvider._();

final class FileTreeProvider
    extends $NotifierProvider<FileTree, List<FileSystemNode>> {
  FileTreeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fileTreeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fileTreeHash();

  @$internal
  @override
  FileTree create() => FileTree();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<FileSystemNode> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<FileSystemNode>>(value),
    );
  }
}

String _$fileTreeHash() => r'a7fb60c53a3662e4e8237f7ebac1af8f6372ca10';

abstract class _$FileTree extends $Notifier<List<FileSystemNode>> {
  List<FileSystemNode> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<FileSystemNode>, List<FileSystemNode>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<FileSystemNode>, List<FileSystemNode>>,
              List<FileSystemNode>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(EditorTabs)
final editorTabsProvider = EditorTabsProvider._();

final class EditorTabsProvider
    extends $NotifierProvider<EditorTabs, List<TabPaneData<EditorTab>>> {
  EditorTabsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorTabsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorTabsHash();

  @$internal
  @override
  EditorTabs create() => EditorTabs();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<TabPaneData<EditorTab>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<TabPaneData<EditorTab>>>(value),
    );
  }
}

String _$editorTabsHash() => r'2cf99832b827663578def3cbd4e930dd4a13db30';

abstract class _$EditorTabs extends $Notifier<List<TabPaneData<EditorTab>>> {
  List<TabPaneData<EditorTab>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<List<TabPaneData<EditorTab>>, List<TabPaneData<EditorTab>>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                List<TabPaneData<EditorTab>>,
                List<TabPaneData<EditorTab>>
              >,
              List<TabPaneData<EditorTab>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(FocusedTabIndex)
final focusedTabIndexProvider = FocusedTabIndexProvider._();

final class FocusedTabIndexProvider
    extends $NotifierProvider<FocusedTabIndex, int> {
  FocusedTabIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'focusedTabIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$focusedTabIndexHash();

  @$internal
  @override
  FocusedTabIndex create() => FocusedTabIndex();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$focusedTabIndexHash() => r'72aa6322e8bb908cf9032004ef925919623e2593';

abstract class _$FocusedTabIndex extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(TerminalVisibility)
final terminalVisibilityProvider = TerminalVisibilityProvider._();

final class TerminalVisibilityProvider
    extends $NotifierProvider<TerminalVisibility, bool> {
  TerminalVisibilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'terminalVisibilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$terminalVisibilityHash();

  @$internal
  @override
  TerminalVisibility create() => TerminalVisibility();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$terminalVisibilityHash() =>
    r'646d2fda12db3264604d7350a043519be2bdac65';

abstract class _$TerminalVisibility extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(IsLoading)
final isLoadingProvider = IsLoadingProvider._();

final class IsLoadingProvider extends $NotifierProvider<IsLoading, bool> {
  IsLoadingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isLoadingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isLoadingHash();

  @$internal
  @override
  IsLoading create() => IsLoading();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isLoadingHash() => r'6ac30569da3716850a790157336f5b7fc1da29cc';

abstract class _$IsLoading extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ErrorMessage)
final errorMessageProvider = ErrorMessageProvider._();

final class ErrorMessageProvider
    extends $NotifierProvider<ErrorMessage, String?> {
  ErrorMessageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'errorMessageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$errorMessageHash();

  @$internal
  @override
  ErrorMessage create() => ErrorMessage();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$errorMessageHash() => r'60385c7e1e595ea2231b76c8b70a26409cf3734f';

abstract class _$ErrorMessage extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
