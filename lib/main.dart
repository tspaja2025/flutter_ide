import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
        expanded: false,
        children: child.isDirectory
            ? (child.isLoaded
                  ? convertToTreeNodes(child)
                  : [TreeItem(data: child)])
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
        // if (basename.startsWith('.') ||
        //             basename == 'node_modules' ||
        //             basename == 'build' ||
        //             basename == 'dist' ||
        //             basename == '.dart_tool') {
        //           continue;
        //         }

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

      // Update tree structure
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

      if (mounted) {
        showToast(
          context: context,
          builder: (context, overlay) => SurfaceCard(
            child: Basic(title: Text("Opened: $selectedDirectory")),
          ),
        );
      }
    }
  }

  Icon _getFileIcon(String filename) {
    final extension = path.extension(filename).toLowerCase();

    switch (extension) {
      case ".bin":
        return const Icon(BootstrapIcons.fileBinary, size: 16);
      case ".dart":
        return const Icon(BootstrapIcons.codeSlash, size: 16);
      case ".html":
        return const Icon(BootstrapIcons.filetypeHtml, size: 16);
      case ".json":
        return const Icon(BootstrapIcons.filetypeJson, size: 16);
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
        return const Icon(BootstrapIcons.folder, size: 16);
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

              return TreeItemView(
                onPressed: () async {
                  if (!fileNode.isDirectory) {
                    final content = await File(fileNode.path).readAsString();
                    widget.onFileOpen(fileNode.path, content);
                  }
                },
                leading: fileNode.isDirectory
                    ? Icon(
                        node.expanded
                            ? LucideIcons.folderOpen
                            : LucideIcons.folder,
                      )
                    : _getFileIcon(fileNode.name),
                // Expand/collapse handling; updates treeItems with new expanded state.
                onExpand: TreeView.defaultItemExpandHandler(treeItems, node, (
                  value,
                ) {
                  setState(() {
                    treeItems = value;
                  });
                }),
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

  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      if (tabs.isEmpty) return;

      tabs[focused] = TabPaneData(
        tabs[focused].data.copyWith(
          content: _textController.text,
          isModified: true,
        ),
      );
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
        _textController.text = tabs[existingIndex].data.content;
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
        focused = tabs.length - 1;
        _textController.text = content;
      });
    }
  }

  // Render a single tab header item. It shows a badge-like count and a close button.
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
              onPressed: () {
                setState(() {
                  tabs.removeAt(index);
                  if (focused >= tabs.length) {
                    focused = tabs.length - 1;
                  }
                });
              },
            ),
          ),
          child: Text(data.title),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TabPane<EditorTab>(
      // children: tabs.map((e) => _buildTabItem(e)).toList(),
      // Provide the items and how to render each tab header.
      items: tabs,
      itemBuilder: (context, item, index) {
        return _buildTabItem(index);
      },
      // The currently focused tab index.
      focused: focused,
      onFocused: (value) {
        setState(() {
          focused = value;
          _textController.text = tabs[value].data.content;
        });
      },
      // Allow reordering via drag-and-drop; update the list with the new order.
      onSort: (value) {
        setState(() {
          tabs = value;
        });
      },
      trailing: [
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
              });
            },
          ),
        ),
      ],
      // The content area; you can render based on the focused index.
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        // child: EditorTextField(
        //   controller: _textController,
        //   readOnly: tabs[focused].data.path == "__welcome__",
        // ),
        child: TextField(
          controller: _textController,
          readOnly: tabs[focused].data.path == "__welcome__",
          expands: true,
          minLines: null,
          maxLines: null,
          padding: const EdgeInsets.all(16),
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
  List<FileSystemNode>? children;

  FileSystemNode({
    required this.name,
    required this.path,
    required this.isDirectory,
  });
}

class SyntaxHighlighter {
  // TODO
}

class _Match {
  // TODO
}

class DartSyntaxHighlighter {
  // TODO
}

class EditorTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool readOnly;
  final SyntaxHighlighter? highlighter;
  final EdgeInsets padding;

  const EditorTextField({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.highlighter,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  State<EditorTextField> createState() => _EditorTextFieldState();
}

class _EditorTextFieldState extends State<EditorTextField> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

// Problems:
// 1. Closing all tabs throws error
// TODO:
// 1. Syntax highlighting
// 2. file saving (CTRL+S)
// 3. Context Menu
// Advanced
// 1. Brace Matching
// 2. Auto-completion suggestions
// 3. Performance optimizations
// 3.1. Virtualization for large files
// 3.2. Cache highlighted lines
// 3.3. Only re-highlight visible lines
// 3.4. Use compute for heavy processing
// 4. Language detection
