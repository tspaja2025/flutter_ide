import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ide/widgets/editor_textfield.dart';
import 'package:path/path.dart' as path;
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() async {
  runApp(const FlutterIDE());
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

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey<_EditorTabViewState> tabKey =
      GlobalKey<_EditorTabViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: ResizablePanel.horizontal(
        children: [
          ResizablePane(
            initialSize: 260,
            child: EditorTreeView(
              onFileOpen: (path, content) {
                tabKey.currentState?.openFile(path, content);
              },
            ),
          ),
          ResizablePane(
            initialSize: MediaQuery.of(context).size.width - 260,
            child: EditorTabView(key: tabKey),
          ),
        ],
      ),
    );
  }
}

class EditorTreeView extends StatefulWidget {
  final Function(String path, String content) onFileOpen;

  const EditorTreeView({super.key, required this.onFileOpen});

  @override
  State<EditorTreeView> createState() => _EditorTreeViewState();
}

class _EditorTreeViewState extends State<EditorTreeView> {
  List<TreeNode<FileSystemNode>> treeItems = [];
  FileSystemNode? rootNode;
  bool isLoading = false;
  String? currentPath;

  // Convert FileSystemNode to TreeNode for TreeView
  List<TreeNode<FileSystemNode>> convertToTreeNodes(FileSystemNode node) {
    return (node.children ?? []).map((child) {
      return TreeItem<FileSystemNode>(
        data: child,
        expanded: child.isExpanded,
        children: child.isDirectory && child.isLoaded
            ? convertToTreeNodes(child)
            : [],
      );
    }).toList();
  }

  // Recursively build file system tree
  Future<void> loadDirectory(String directoryPath) async {
    setState(() {
      isLoading = true;
      rootNode = FileSystemNode(
        name: path.basename(directoryPath),
        path: directoryPath,
        isDirectory: true,
      );
    });

    try {
      await _loadDirectoryContents(rootNode!);

      setState(() {
        treeItems = [
          TreeItem(
            data: rootNode!,
            expanded: true,
            children: convertToTreeNodes(rootNode!),
          ),
        ];
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(title: Text("Error Loading directory: $e")),
          ),
        );
      }
    }
  }

  Future<void> _loadDirectoryContents(FileSystemNode node) async {
    if (node.isLoading || node.isLoaded) return;

    node.isLoading = true;

    try {
      final directory = Directory(node.path);
      final List<FileSystemEntity> entities = await directory.list().toList();

      node.children = [];

      // Sort directories first, then files
      entities.sort((a, b) {
        bool aIsDir = a is Directory;
        bool bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.compareTo(b.path);
      });

      for (var entity in entities) {
        // Skip hidden files and common build directories
        final basename = path.basename(entity.path);

        final childNode = FileSystemNode(
          name: basename,
          path: entity.path,
          isDirectory: entity is Directory,
        );

        node.children!.add(childNode);
      }

      node.isLoaded = true;
      node.isLoading = false;
    } catch (e) {
      node.isLoading = false;
      rethrow;
    }
  }

  // Load children on demand when expanding a node
  Future<void> expandNode(String nodePath) async {
    final node = _findNodeByPath(rootNode!, nodePath);

    if (node != null && node.isDirectory && !node.isLoaded) {
      await _loadDirectoryContents(node);

      // Rebuild the entire tree structure
      setState(() {
        treeItems = [
          TreeItem(
            data: rootNode!,
            expanded: true,
            children: convertToTreeNodes(rootNode!),
          ),
        ];
      });
    }
  }

  FileSystemNode? _findNodeByPath(FileSystemNode node, String targetPath) {
    if (node.path == targetPath) return node;

    if (node.children != null) {
      for (var child in node.children!) {
        final found = _findNodeByPath(child, targetPath);
        if (found != null) return found;
      }
    }

    return null;
  }

  Future<void> pickDirectory() async {
    String? selectedDirectory = await FilePicker.getDirectoryPath();

    if (selectedDirectory != null) {
      currentPath = selectedDirectory;
      await loadDirectory(selectedDirectory);
    }
  }

  Icon _getFileIcon(String filename) {
    final lower = filename.toLowerCase();

    switch (lower) {
      case ".gitignore":
      case ".gitattributes":
        return const Icon(LucideIcons.gitBranch, size: 16);
      case "license":
        return const Icon(LucideIcons.scale, size: 16);
    }

    final extension = path.extension(lower);

    switch (extension) {
      case ".bin":
        return const Icon(BootstrapIcons.fileBinary, size: 16);
      case ".dart":
        return const Icon(BootstrapIcons.codeSlash, size: 16);
      case ".html":
        return const Icon(BootstrapIcons.filetypeHtml, size: 16);
      case ".iml":
        return const Icon(BootstrapIcons.codeSlash, size: 16);
      case ".json":
        return const Icon(BootstrapIcons.filetypeJson, size: 16);
      case ".lock":
        return const Icon(LucideIcons.lock, size: 16);
      case ".md":
        return const Icon(BootstrapIcons.filetypeMd, size: 16);
      case ".otf":
        return const Icon(BootstrapIcons.filetypeOtf, size: 16);
      case ".png":
        return const Icon(BootstrapIcons.filetypePng, size: 16);
      case ".txt":
        return const Icon(BootstrapIcons.filetypeTxt, size: 16);
      case ".yaml":
        return const Icon(BootstrapIcons.filetypeYml, size: 16);
      default:
        return const Icon(BootstrapIcons.codeSlash, size: 16);
    }
  }

  @override
  Widget build(BuildContext context) {
    return treeItems.isEmpty
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PrimaryButton(
                onPressed: pickDirectory,
                child: const Text("Open Project"),
              ),
            ],
          )
        : TreeView(
            // Show a separate expand/collapse icon when true; otherwise use row affordance.
            expandIcon: true,
            shrinkWrap: true,
            // When true, selecting a parent can affect children (see below toggle).
            recursiveSelection: false,
            nodes: treeItems,
            // Draw connecting lines either as path curves or straight lines.
            branchLine: BranchLine.path,
            // Use a built-in handler to update selection state across nodes.
            onSelectionChanged: TreeView.defaultSelectionHandler(treeItems, (
              value,
            ) {
              setState(() {
                treeItems = value;
              });
            }),
            builder: (context, node) {
              final fileNode = node.data;
              final isDirectory = fileNode.isDirectory;
              final isPlaceholder = fileNode.name == "Loading...";
              final shouldShowExpandIcon = isDirectory && !isPlaceholder;

              return TreeItemView(
                onPressed: () async {
                  if (isDirectory && !fileNode.isLoaded && !isPlaceholder) {
                    // Mark as expanded before loading to prevent flicker
                    if (!node.expanded) {
                      setState(() {
                        fileNode.isExpanded = true;
                      });
                    }
                    await expandNode(fileNode.path);
                  } else if (!isDirectory && !isPlaceholder) {
                    final content = await File(fileNode.path).readAsString();
                    widget.onFileOpen(fileNode.path, content);
                  }
                },
                leading: isDirectory
                    ? Icon(
                        node.expanded
                            ? LucideIcons.folderOpen
                            : LucideIcons.folder,
                      )
                    : _getFileIcon(fileNode.name),
                // Expand/collapse handling; updates treeItems with new expanded state.
                onExpand: shouldShowExpandIcon
                    ? (expanded) async {
                        if (expanded && !fileNode.isLoaded) {
                          await expandNode(fileNode.path);
                        }

                        setState(() {
                          fileNode.isExpanded = expanded;
                        });
                      }
                    : null,
                child: Text(fileNode.name),
              );
            },
          );
  }
}

class EditorTabView extends StatefulWidget {
  const EditorTabView({super.key});

  @override
  State<EditorTabView> createState() => _EditorTabViewState();
}

class _EditorTabViewState extends State<EditorTabView> {
  final TextEditingController _textController = TextEditingController();
  late List<TabPaneData<EditorTab>> tabs;
  int focused = 0;

  // Store original content for each tab to detect modifications
  final Map<String, String> _originalContent = {};

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (tabs.isEmpty) return;

      if (focused >= 0 && focused < tabs.length) {
        final currentTab = tabs[focused].data;
        final currentContent = _textController.text;
        final originalContent =
            _originalContent[currentTab.path] ?? currentTab.content;

        // Mark as modified if content change
        final isModified = currentContent != originalContent;

        tabs[focused] = TabPaneData(
          tabs[focused].data.copyWith(
            content: _textController.text,
            isModified: isModified,
          ),
        );

        // Force rebuild to update tab indicators
        setState(() {});
      }
    });
    // Build the initial set of tabs. TabPaneData wraps your custom data type
    tabs = [
      TabPaneData(
        EditorTab(
          title: "Welcome",
          path: "__welcome__",
          content: "Welcome to Flutter IDE\n\nOpen a folder to get started.",
        ),
      ),
    ];
    _textController.text = tabs[0].data.content;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void openFile(String filePath, String content) {
    // Check if file is already open
    int existingIndex = tabs.indexWhere((tab) => tab.data.path == filePath);

    if (existingIndex != -1) {
      setState(() {
        focused = existingIndex;
        final tab = tabs[existingIndex].data;
        _textController.text = tab.content;
        _originalContent[filePath] = tab.content;
      });
    } else {
      setState(() {
        tabs.add(
          TabPaneData(
            EditorTab(
              title: path.basename(filePath),
              path: filePath,
              content: content,
            ),
          ),
        );
        _originalContent[filePath] = content;
        focused = tabs.length - 1;
        _textController.text = content;
      });
    }
  }

  void saveCurrentFile() async {
    if (tabs.isEmpty || focused < 0 || focused >= tabs.length) return;

    final currentTab = tabs[focused].data;
    // Can't save welcome tab
    if (currentTab.path == "__welcome__") return;

    try {
      final file = File(currentTab.path);
      await file.writeAsString(_textController.text);

      // Update original content after save
      _originalContent[currentTab.path] = _textController.text;

      setState(() {
        tabs[focused] = TabPaneData(currentTab.copyWith(isModified: false));
      });

      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(title: Text("File saved ${currentTab.title}")),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) =>
              SurfaceCard(child: Basic(title: Text("Error saving file: $e"))),
        );
      }
    }
  }

  void _closeTab(int index) {
    final tab = tabs[index].data;

    // Check if file has unsaved changes
    if (tab.isModified) {
      _showUnsavedChangesDialog(index, tab);
    } else {
      _performCloseTab(index);
    }
  }

  void _showUnsavedChangesDialog(int index, EditorTab tab) {
    // TODO: dialog
    _performCloseTab(index);
  }

  void _performCloseTab(int index) {
    setState(() {
      final tabToClose = tabs[index].data;
      _originalContent.remove(tabToClose.path);
      tabs.removeAt(index);

      // Handle focus after closing tab
      if (tabs.isEmpty) {
        tabs.add(
          TabPaneData(
            EditorTab(
              title: "Welcome",
              path: "__welcome__",
              content:
                  "Welcome to Flutter IDE\n\nOpen a folder to get started.",
            ),
          ),
        );
        _originalContent["__welcome__"] = tabs[0].data.content;
        focused = 0;
        _textController.text = tabs[0].data.content;
      } else {
        // Adjust focused index
        if (focused >= tabs.length) {
          focused = tabs.length - 1;
        } else if (focused == index && index > 0) {
          focused = index - 1;
        }
        // Ensure focused is within bounds
        if (focused >= 0 && focused < tabs.length) {
          final newTab = tabs[focused].data;
          _textController.text = newTab.content;
        }
      }
    });
  }

  TabItem _buildTabItem(int index) {
    EditorTab data = tabs[index].data;
    return TabItem(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 150),
        child: Label(
          // If file is modified show leading indicator
          leading: data.isModified
              ? const Icon(
                  BootstrapIcons.circleFill,
                  size: 8,
                  color: Colors.blue,
                )
              : null,
          trailing: Tooltip(
            tooltip: TooltipContainer(child: const Text("Close Tab")).call,
            child: IconButton.ghost(
              shape: ButtonShape.circle,
              size: ButtonSize.xSmall,
              icon: const Icon(LucideIcons.x),
              onPressed: () => _closeTab(index),
            ),
          ),
          child: Text(data.title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure focused index is valid
    if (tabs.isNotEmpty && focused >= 0 && focused < tabs.length) {
      // Ensure the text controller has the correct content for the focused tab
      final currentContent = _textController.text;
      final tabContent = tabs[focused].data.content;
      if (currentContent != tabContent) {
        _textController.text = tabContent;
      }
    }

    return TabPane<EditorTab>(
      items: tabs,
      itemBuilder: (context, item, index) {
        return _buildTabItem(index);
      },
      // The currently focused tab index.
      focused: focused,
      onFocused: (value) {
        setState(() {
          if (value >= 0 && value < tabs.length) {
            focused = value;
            _textController.text = tabs[value].data.content;
          }
        });
      },
      onSort: (value) {
        setState(() {
          tabs = value;
        });
      },
      trailing: [
        Tooltip(
          tooltip: TooltipContainer(child: const Text("Save")).call,
          child: IconButton.ghost(
            onPressed: saveCurrentFile,
            size: ButtonSize.small,
            density: ButtonDensity.iconDense,
            icon: const Icon(LucideIcons.save),
          ),
        ),
        Tooltip(
          tooltip: TooltipContainer(child: const Text("New...")).call,
          child: IconButton.ghost(
            icon: const Icon(LucideIcons.plus),
            size: ButtonSize.small,
            density: ButtonDensity.iconDense,
            onPressed: () {
              setState(() {
                tabs.add(
                  TabPaneData(
                    EditorTab(
                      title: "Untitled",
                      path: "",
                      content: "",
                      isModified: true,
                    ),
                  ),
                );
                focused = tabs.length - 1;
                _textController.text = "";
              });
            },
          ),
        ),
      ],
      child: tabs.isEmpty
          ? SizedBox(
              height: MediaQuery.of(context).size.height,
              child: const Center(
                child: Text(
                  "No tabs open. Create a new file or open a project.",
                ),
              ),
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height,
              child: ContextMenu(
                items: [
                  const MenuButton(
                    trailing: MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.cut,
                        control: true,
                      ),
                    ),
                    child: Text("Cut"),
                  ),
                  const MenuButton(
                    trailing: MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.copy,
                        control: true,
                      ),
                    ),
                    child: Text("Copy"),
                  ),
                  const MenuButton(
                    trailing: MenuShortcut(
                      activator: SingleActivator(
                        LogicalKeyboardKey.paste,
                        control: true,
                      ),
                    ),
                    child: Text("Paste"),
                  ),
                ],
                child: EditorTextField(
                  controller: _textController,
                  readOnly: tabs[focused].data.path == "__welcome__",
                ),
              ),
            ),
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
  bool isExpanded = false;
  List<FileSystemNode>? children;

  FileSystemNode({
    required this.name,
    required this.path,
    required this.isDirectory,
  });
}

// TODO:
// 1. Keyboard shortcuts for:
// 1.1 Cut (CTRL-X) / Copy (CTRL-C) / Paste (CTRL-V) / Save (CTRL-S)
