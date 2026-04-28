import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

part "main.g.dart";

void main() async {
  runApp(const ProviderScope(child: FlutterIDE()));
}

class FlutterIDE extends StatelessWidget {
  const FlutterIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter IDE",
      home: const EditorScreen(),
    );
  }
}

class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final GlobalKey<EditorWindowState> _editorKey =
      GlobalKey<EditorWindowState>();

  @override
  void initState() {
    super.initState();
    // Auto-load project from command line args or saved state if needed
  }

  Future<Directory?> _pickProjectDirectory() async {
    final result = await FilePicker.getDirectoryPath();
    if (result == null) return null;
    return Directory(result);
  }

  Future<void> _loadProject() async {
    final isLoadingNotifier = ref.read(isLoadingProvider.notifier);
    final errorNotifier = ref.read(errorMessageProvider.notifier);

    isLoadingNotifier.setLoading(true);
    errorNotifier.setError(null);

    try {
      final projectDir = await _pickProjectDirectory();
      if (projectDir == null) {
        throw Exception("No directory selected");
      }

      // Update project directory provider
      ref.read(projectDirectoryProvider.notifier).setDirectory(projectDir);

      // Load file tree
      await ref.read(fileTreeProvider.notifier).loadFileTree(projectDir);

      isLoadingNotifier.setLoading(false);
    } catch (e) {
      isLoadingNotifier.setLoading(false);
      errorNotifier.setError(e.toString());
    }
  }

  Future<void> _openFile(String path) async {
    try {
      final content = await _readFileContent(path);
      final fileName = path.split(Platform.pathSeparator).last;

      final tab = EditorTab(title: fileName, path: path, content: content);

      ref.read(editorTabsProvider.notifier).addTab(tab);
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Error"),
            content: Text("Failed to open file: $e"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<String> _readFileContent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      throw Exception("File does not exist");
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error reading file $filePath: $e");
      }
      return "Error reading file: $e";
    }
  }

  Future<void> _expandNode(FileSystemNode node) async {
    await ref.read(fileTreeProvider.notifier).expandNode(node);
    setState(() {}); // Trigger rebuild for tree view
  }

  List<TreeNode<FileSystemNode>> _convertToTreeNode(
    List<FileSystemNode> nodes,
  ) {
    return nodes.map((node) {
      List<TreeNode<FileSystemNode>> childNodes = [];

      if (node.isLoaded && node.children != null) {
        childNodes = _convertToTreeNode(node.children!);
      }

      return TreeItem<FileSystemNode>(
        data: node,
        expanded: node.isLoaded,
        children: childNodes,
      );
    }).toList();
  }

  Icon _getFileIcon(String fileName) {
    final extension = fileName.split(".").last.toLowerCase();
    switch (extension) {
      case "bin":
        return const Icon(BootstrapIcons.fileBinary);
      case "dart":
        return const Icon(BootstrapIcons.codeSlash);
      case "html":
        return const Icon(BootstrapIcons.filetypeHtml);
      case "json":
        return const Icon(BootstrapIcons.filetypeJson);
      case "md":
        return const Icon(BootstrapIcons.filetypeMd);
      case "otf":
        return const Icon(BootstrapIcons.filetypeOtf);
      case "png":
        return const Icon(BootstrapIcons.filetypePng);
      case "txt":
        return const Icon(BootstrapIcons.filetypeTxt);
      case "yaml":
        return const Icon(BootstrapIcons.filetypeYml);
      default:
        return const Icon(BootstrapIcons.fileCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorMessageProvider);
    final projectDir = ref.watch(projectDirectoryProvider);
    final fileTree = ref.watch(fileTreeProvider);
    final terminalVisible = ref.watch(terminalVisibilityProvider);

    if (!isLoading && projectDir == null) {
      return Scaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.folderOpen, size: 48),
              const SizedBox(height: 16),
              const Text("No project opened"),
              const SizedBox(height: 16),
              PrimaryButton(
                onPressed: _loadProject,
                child: const Text("Open Project Folder"),
              ),
            ],
          ),
        ),
      );
    }

    if (isLoading) {
      return const Scaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Loading project..."),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.triangleAlert, size: 48),
              const SizedBox(height: 16),
              Text("Error: $error"),
              const SizedBox(height: 16),
              PrimaryButton(
                onPressed: _loadProject,
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    final treeNodes = _convertToTreeNode(fileTree);

    return Scaffold(
      headers: [
        AppBar(
          backgroundColor: theme.colorScheme.card,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Flutter IDE"),
              SizedBox(
                width: 260,
                child: OutlineButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return Command(
                          builder: (context, query) async* {
                            Map<String, List<String>> items = {
                              "Suggestions": [
                                "Calendar",
                                "Search Emoji",
                                "Launch",
                              ],
                              "Settings": ["Profile", "Mail", "Settings"],
                            };
                            Map<String, Widget> icons = {
                              "Calendar": const Icon(Icons.calendar_today),
                              "Search Emoji": const Icon(
                                Icons.emoji_emotions_outlined,
                              ),
                              "Launch": const Icon(
                                Icons.rocket_launch_outlined,
                              ),
                              "Profile": const Icon(Icons.person_outline),
                              "Mail": const Icon(Icons.mail_outline),
                              "Settings": const Icon(Icons.settings_outlined),
                            };
                            for (final values in items.entries) {
                              List<Widget> resultItems = [];
                              for (final item in values.value) {
                                if (query == null ||
                                    item.toLowerCase().contains(
                                      query.toLowerCase(),
                                    )) {
                                  resultItems.add(
                                    CommandItem(
                                      title: Text(item),
                                      leading: icons[item],
                                      onTap: () {},
                                    ),
                                  );
                                }
                              }
                              if (resultItems.isNotEmpty) {
                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                                yield [
                                  CommandCategory(
                                    title: Text(values.key),
                                    children: resultItems,
                                  ),
                                ];
                              }
                            }
                          },
                        ).sized(width: 300, height: 300);
                      },
                    );
                  },
                  size: ButtonSize.small,
                  child: Text(
                    projectDir?.path.split('/').last ?? "Project Name",
                  ),
                ),
              ),
              Builder(
                builder: (context) {
                  return IconButton.ghost(
                    onPressed: () {
                      showDropdown(
                        context: context,
                        builder: (context) {
                          return const DropdownMenu(
                            children: [
                              MenuButton(child: Text("Settings")),
                              MenuButton(child: Text("Keymap")),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(LucideIcons.settings, size: 16),
                  );
                },
              ),
            ],
          ),
        ),
        const Divider(),
      ],
      footers: [
        const Divider(),
        AppBar(
          backgroundColor: theme.colorScheme.card,
          trailing: [
            const Text("Line/Column").small,
            const Gap(4),
            const Text("Language").small,
            const Gap(4),
            const SizedBox(height: 16, child: VerticalDivider()),
            const Gap(4),
            Tooltip(
              tooltip: TooltipContainer(child: Text("Terminal")).call,
              child: IconButton.ghost(
                onPressed: () {
                  ref.read(terminalVisibilityProvider.notifier).toggle();
                },
                shape: ButtonShape.circle,
                size: ButtonSize.xSmall,
                icon: const Icon(LucideIcons.terminal, size: 12),
              ),
            ),
          ],
        ),
      ],
      child: ResizablePanel.horizontal(
        children: [
          ResizablePane(
            initialSize: 260,
            child: Container(
              decoration: BoxDecoration(color: theme.colorScheme.card),
              child: Column(
                children: [
                  TreeView(
                    expandIcon: true,
                    shrinkWrap: true,
                    recursiveSelection: false,
                    nodes: treeNodes,
                    branchLine: BranchLine.path,
                    onSelectionChanged: TreeView.defaultSelectionHandler(
                      treeNodes,
                      (value) {
                        setState(() {});
                      },
                    ),
                    builder: (context, node) {
                      final fileNode = node.data;
                      final isDirectory = fileNode.isDirectory;
                      final isPlaceholder = fileNode.name == "Loading...";
                      final shouldShowExpandIcon =
                          isDirectory && !isPlaceholder;

                      return TreeItemView(
                        onPressed: () {
                          if (isDirectory &&
                              !fileNode.isLoaded &&
                              !isPlaceholder) {
                            _expandNode(fileNode);
                          } else if (!isDirectory && !isPlaceholder) {
                            _openFile(fileNode.path);
                          }
                        },
                        leading: isDirectory
                            ? Icon(
                                node.expanded
                                    ? LucideIcons.folderOpen
                                    : LucideIcons.folder,
                              )
                            : _getFileIcon(fileNode.name),
                        onExpand: shouldShowExpandIcon
                            ? (expanded) async {
                                if (expanded && !fileNode.isLoaded) {
                                  await _expandNode(fileNode);
                                }
                                // Trigger rebuild to update expansion state
                                setState(() {});
                              }
                            : null,
                        child: Text(fileNode.name),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          ResizablePane(
            initialSize: MediaQuery.of(context).size.width - 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: EditorWindow(key: _editorKey)),
                if (terminalVisible)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: theme.colorScheme.border),
                      ),
                    ),
                    height: 150,
                    child: const Column(children: [Text("Terminal")]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EditorWindow extends ConsumerStatefulWidget {
  const EditorWindow({super.key});

  @override
  ConsumerState<EditorWindow> createState() => EditorWindowState();
}

class EditorWindowState extends ConsumerState<EditorWindow> {
  final TextEditingController _textController = TextEditingController();
  bool _isUpdatingFromProvider = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);

    // Initialize with first tab content
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabs = ref.read(editorTabsProvider);
      if (tabs.isNotEmpty) {
        _textController.text =
            tabs[ref.read(focusedTabIndexProvider)].data.content;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isUpdatingFromProvider) return;

    final focusedIndex = ref.read(focusedTabIndexProvider);
    final newContent = _textController.text;

    ref
        .read(editorTabsProvider.notifier)
        .updateTabContent(focusedIndex, newContent);
  }

  Future<void> _saveCurrentFile() async {
    final focusedIndex = ref.read(focusedTabIndexProvider);
    final tabs = ref.read(editorTabsProvider);

    if (focusedIndex >= tabs.length) return;
    if (tabs[focusedIndex].data.path == "__welcome__") return;

    try {
      await ref.read(editorTabsProvider.notifier).saveTab(focusedIndex);

      if (mounted) {
        showToast(
          context: context,
          location: ToastLocation.bottomRight,
          builder: (context, overlay) {
            return const SurfaceCard(child: Basic(title: Text("File Saved")));
          },
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          location: ToastLocation.bottomRight,
          builder: (context, overlay) {
            return SurfaceCard(
              child: Basic(
                title: const Text("Error saving file"),
                subtitle: Text("$e"),
              ),
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ref.watch(editorTabsProvider);
    final focusedIndex = ref.watch(focusedTabIndexProvider);

    // Update text controller when focused tab changes
    if (focusedIndex < tabs.length) {
      final currentContent = _textController.text;
      final tabContent = tabs[focusedIndex].data.content;

      if (currentContent != tabContent && !_isUpdatingFromProvider) {
        _isUpdatingFromProvider = true;
        _textController.text = tabContent;
        _isUpdatingFromProvider = false;
      }
    }

    return Column(
      children: [
        Expanded(
          child: TabPane<EditorTab>(
            items: tabs,
            itemBuilder: (context, item, index) {
              final data = item.data;

              return TabItem(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Label(
                    leading: data.isModified
                        ? const Icon(LucideIcons.circle, size: 8)
                        : null,
                    trailing: IconButton.ghost(
                      shape: ButtonShape.circle,
                      size: ButtonSize.xSmall,
                      icon: const Icon(LucideIcons.x),
                      onPressed: () {
                        ref.read(editorTabsProvider.notifier).removeTab(index);
                      },
                    ),
                    child: Text(data.title),
                  ),
                ),
              );
            },
            focused: focusedIndex,
            onFocused: (value) {
              ref.read(focusedTabIndexProvider.notifier).setIndex(value);
            },
            onSort: (value) {
              // Handle tab reordering if needed
              // You might want to add this to your provider
              // setState(() {
              //   tabs = value;
              // });
            },
            trailing: [
              IconButton.ghost(
                icon: const Icon(LucideIcons.save),
                size: ButtonSize.small,
                density: ButtonDensity.iconDense,
                onPressed: _saveCurrentFile,
              ),
            ],
            child: tabs.isEmpty
                ? const Center(
                    child: Text(
                      "No files open. Select a file from the explorer",
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          readOnly:
                              tabs[focusedIndex].data.path == "__welcome__",
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class EditorTab {
  final String title;
  final String path;
  final String content;
  final bool isModified;

  EditorTab({
    required this.title,
    required this.path,
    required this.content,
    this.isModified = false,
  });

  EditorTab copyWith({
    String? title,
    String? path,
    String? content,
    bool? isModified,
  }) {
    return EditorTab(
      title: title ?? this.title,
      path: path ?? this.path,
      content: content ?? this.content,
      isModified: isModified ?? this.isModified,
    );
  }
}

class FileSystemNode {
  final String name;
  final String path;
  final bool isDirectory;
  bool isLoaded = false;
  bool isLoading = false;
  List<FileSystemNode>? children;

  FileSystemNode({
    required this.name,
    required this.path,
    required this.isDirectory,
  });
}

@riverpod
class ProjectDirectory extends _$ProjectDirectory {
  @override
  Directory? build() => null;

  void setDirectory(Directory directory) {
    state = directory;
  }

  void clear() {
    state = null;
  }
}

@riverpod
class FileTree extends _$FileTree {
  @override
  List<FileSystemNode> build() {
    final projectDir = ref.watch(projectDirectoryProvider);
    if (projectDir != null) {
      loadFileTree(projectDir);
    }
    return [];
  }

  Future<void> loadFileTree(Directory directory) async {
    final rootNode = FileSystemNode(
      name: directory.path.split(Platform.pathSeparator).last,
      path: directory.path,
      isDirectory: true,
    );

    rootNode.children = await loadDirectoryChildren(directory);
    rootNode.isLoaded = true;

    state = [rootNode];
  }

  Future<List<FileSystemNode>> loadDirectoryChildren(
    Directory directory,
  ) async {
    final List<FileSystemNode> nodes = [];

    try {
      final entities = await directory.list().toList();

      for (var entity in entities) {
        final name = entity.path.split(Platform.pathSeparator).last;
        if (name.startsWith(".")) continue;

        nodes.add(
          FileSystemNode(
            name: name,
            path: entity.path,
            isDirectory: entity is Directory,
          ),
        );
      }

      nodes.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      return nodes;
    } catch (e) {
      return [];
    }
  }

  Future<void> expandNode(FileSystemNode node) async {
    if (!node.isDirectory || node.isLoaded) return;

    try {
      final directory = Directory(node.path);

      if (await directory.exists()) {
        final children = await loadDirectoryChildren(directory);

        node.children = children;
        node.isLoaded = true;

        state = [...state];
      }
    } catch (e) {
      node.isLoaded = true;
      node.children = [];
      state = [...state];
    }
  }
}

@riverpod
class EditorTabs extends _$EditorTabs {
  @override
  List<TabPaneData<EditorTab>> build() {
    return [
      TabPaneData(
        EditorTab(
          title: "Welcome",
          path: "__welcome__",
          content: "Welcome to Flutter IDE\n\nOpen a folder  to get started.",
        ),
      ),
    ];
  }

  void addTab(EditorTab tab) {
    // Replace welcome tab if it's the only one
    if (state.length == 1 && state.first.data.path == "__welcome__") {
      state = [TabPaneData(tab)];
    } else {
      // Check if tab already exists
      final existingIndex = findTabIndex(tab.path);
      if (existingIndex != -1) {
        // Focus existing tab
        ref.read(focusedTabIndexProvider.notifier).setIndex(existingIndex);
        return;
      }
      state = [...state, TabPaneData(tab)];
    }
    // Focus the new tab
    ref.read(focusedTabIndexProvider.notifier).setIndex(state.length - 1);
  }

  void updateTabContent(int index, String content) {
    if (index >= state.length) return;

    final currentTab = state[index];
    final isModified = currentTab.data.content != content;

    state = [
      for (int i = 0; i < state.length; i++)
        if (i == index)
          TabPaneData(
            currentTab.data.copyWith(content: content, isModified: isModified),
          )
        else
          state[i],
    ];
  }

  Future<void> saveTab(int index) async {
    if (index >= state.length) return;

    final tab = state[index];
    if (tab.data.path == "__welcome__") return;

    try {
      final file = File(tab.data.path);
      await file.writeAsString(tab.data.content);

      // Mark as saved (not modified)
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            TabPaneData(tab.data.copyWith(isModified: false))
          else
            state[i],
      ];
    } catch (e) {
      rethrow;
    }
  }

  void removeTab(int index) {
    if (index >= state.length) return;

    final newTabs = [...state];
    newTabs.removeAt(index);

    if (newTabs.isEmpty) {
      state = [
        TabPaneData(
          EditorTab(
            title: "Welcome",
            path: "__welcome__",
            content: "No files open. Select a file from the explorer.",
          ),
        ),
      ];
      ref.read(focusedTabIndexProvider.notifier).setIndex(0);
    } else {
      state = newTabs;
      if (ref.read(focusedTabIndexProvider) >= state.length) {
        ref.read(focusedTabIndexProvider.notifier).setIndex(state.length - 1);
      }
    }
  }

  int findTabIndex(String path) {
    for (int i = 0; i < state.length; i++) {
      if (state[i].data.path == path) {
        return i;
      }
    }
    return -1;
  }
}

@riverpod
class FocusedTabIndex extends _$FocusedTabIndex {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

@riverpod
class TerminalVisibility extends _$TerminalVisibility {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

@riverpod
class IsLoading extends _$IsLoading {
  @override
  bool build() => false;

  void setLoading(bool loading) {
    state = loading;
  }
}

@riverpod
class ErrorMessage extends _$ErrorMessage {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }
}

// 1. Adopt Riverpod for state management - Done
// 2. Separate business logic from UI
// 3. Improved error handling
// 4. Keyboard shortcuts
// 5. Syntax highlighting
// 6. Search functionality
// 7. File operations context menu
// 8. Settings persistance
// 9. Tree view performance
// 10. Multi-file operations
// 11. Git Integration
// 12. Testing
