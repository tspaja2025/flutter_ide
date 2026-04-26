import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
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
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<_EditorWindowState> _editorKey =
      GlobalKey<_EditorWindowState>();

  List<TreeNode<FileSystemNode>> treeItems = [];
  bool isLoading = true;
  String? error;

  Future<Directory?> _pickProjectDirectory() async {
    final result = await FilePicker.getDirectoryPath();

    if (result == null) return null;

    return Directory(result);
  }

  Future<void> _loadProject() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final projectDir = await _pickProjectDirectory();

      if (projectDir == null) {
        throw Exception("No directory selected");
      }

      final rootNode = FileSystemNode(
        name: projectDir.path.split(Platform.pathSeparator).last,
        path: projectDir.path,
        isDirectory: true,
      );

      rootNode.children = await _loadDirectoryChildren(projectDir);
      rootNode.isLoaded = true;

      setState(() {
        treeItems = [_convertToTreeNode(rootNode)];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<List<FileSystemNode>> _loadDirectoryChildren(
    Directory directory,
  ) async {
    final List<FileSystemNode> nodes = [];

    try {
      final entities = await directory.list().toList();

      for (var entity in entities) {
        // Skip hidden files/directories
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

      // Sort: directories first, then files
      nodes.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.compareTo(b.name);
      });

      return nodes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error loading directory ${directory.path}: $e");
      }
      return [];
    }
  }

  Future<void> _expandNode(FileSystemNode node) async {
    if (!node.isDirectory || node.isLoaded) return;

    try {
      final directory = Directory(node.path);

      if (await directory.exists()) {
        final children = await _loadDirectoryChildren(directory);

        setState(() {
          node.children = children;
          node.isLoaded = true;

          treeItems = [_convertToTreeNode(_getNodeValue(treeItems.first))];
        });
      }
    } catch (e) {
      node.isLoaded = true;
      node.children = [];

      setState(() {
        treeItems = [_convertToTreeNode(_getNodeValue(treeItems.first))];
      });
    }
  }

  TreeNode<FileSystemNode>? _findNode(
    List<TreeNode<FileSystemNode>> nodes,
    String path,
  ) {
    for (final node in nodes) {
      final value = _getNodeValue(node);
      if (value.path == path) return node;

      // The left operand can't be null, so the right operand is never executed.
      final found = _findNode(node.children ?? [], path);
      if (found != null) return found;
    }
    return null;
  }

  TreeNode<FileSystemNode> _convertToTreeNode(FileSystemNode node) {
    final existing = _findNode(treeItems, node.path);

    List<TreeNode<FileSystemNode>> childNodes = [];

    if (node.isLoaded && node.children != null) {
      childNodes = node.children!
          .map((child) => _convertToTreeNode(child))
          .toList();
    } else if (node.isDirectory && !node.isLoaded) {
      final placeholderNode = FileSystemNode(
        name: "Loading...",
        path: node.path,
        isDirectory: false,
      );

      childNodes = [
        TreeItem(data: placeholderNode, expanded: false, children: []),
      ];
    }

    return TreeItem(
      data: node,
      expanded: existing?.expanded ?? false,
      children: childNodes,
    );
  }

  FileSystemNode _getNodeValue(TreeNode<FileSystemNode> node) {
    // Try different possible property names
    try {
      // Try 'value' first (most common)
      return (node as dynamic).value as FileSystemNode;
    } catch (e) {
      try {
        // Try 'data' next
        return (node as dynamic).data as FileSystemNode;
      } catch (e) {
        try {
          // Try 'item'
          return (node as dynamic).item as FileSystemNode;
        } catch (e) {
          // Try 'content'
          return (node as dynamic).content as FileSystemNode;
        }
      }
    }
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

  Future<String> _readFileContent(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      } else {
        throw Exception("File does not exist");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error reading file $filePath: $e");
      }
      return "Error reading file: $e";
    }
  }

  Future<void> _openFile(String path) async {
    try {
      // Check if file is already open
      final existingTabIndex = _findOpenTabIndex(path);

      if (existingTabIndex != -1) {
        //Focus the existing tab
        _editorKey.currentState?.focusTab(existingTabIndex);
        return;
      }

      // Read file content
      final content = await _readFileContent(path);
      final fileName = path.split(Platform.pathSeparator).last;

      // Add new tab
      _editorKey.currentState?.addTab(
        EditorTab(title: fileName, path: path, content: content),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Opening file: $path: $e");
      }
      // Error dialog
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

  int _findOpenTabIndex(String path) {
    final editorState = _editorKey.currentState;
    if (editorState == null) return -1;

    for (int i = 0; i < editorState.tabs.length; i++) {
      if (editorState.tabs[i].data.path == path) {
        return i;
      }
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
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

    return Scaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 260,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("EXPLORER").xSmall,
                      IconButton.ghost(
                        onPressed: _loadProject,
                        density: ButtonDensity.iconDense,
                        icon: const Icon(LucideIcons.folderOpen, size: 16),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                TreeView(
                  expandIcon: true,
                  shrinkWrap: true,
                  recursiveSelection: false,
                  nodes: treeItems,
                  branchLine: BranchLine.path,
                  onSelectionChanged: TreeView.defaultSelectionHandler(
                    treeItems,
                    (value) {
                      setState(() {
                        treeItems = value;
                      });
                    },
                  ),
                  builder: (context, node) {
                    final fileNode = _getNodeValue(node);
                    final isDirectory = fileNode.isDirectory;

                    // Don't show expand icon for placeholder nodes
                    final isPlaceholder = fileNode.name == "Loading...";
                    final shouldShowExpandIcon = isDirectory && !isPlaceholder;

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
                              // Call default handler to update UI
                              TreeView.defaultItemExpandHandler(
                                treeItems,
                                node,
                                (value) {
                                  setState(() {
                                    treeItems = value;
                                  });
                                },
                              )(expanded);
                            }
                          : null,
                      child: Text(fileNode.name),
                    );
                  },
                ),
              ],
            ),
          ),
          const VerticalDivider(),
          Expanded(child: EditorWindow(key: _editorKey)),
        ],
      ),
    );
  }
}

class EditorWindow extends StatefulWidget {
  const EditorWindow({super.key});

  @override
  State<EditorWindow> createState() => _EditorWindowState();
}

class _EditorWindowState extends State<EditorWindow> {
  late List<TabPaneData<EditorTab>> tabs;
  int focused = 0;
  final TextEditingController _textController = TextEditingController();

  void addTab(EditorTab tab) {
    setState(() {
      // Replace welcome tab if it's the only one
      if (tabs.length == 1 && tabs.first.data.path == "__welcome__") {
        tabs[0] = TabPaneData(tab);
        focused = 0;
      } else {
        tabs.add(TabPaneData(tab));
        focused = tabs.length - 1;
      }

      _textController.text = tab.content;
    });
  }

  void focusTab(int index) {
    setState(() {
      focused = index;
      if (index < tabs.length) {
        _textController.text = tabs[index].data.content;
      }
    });
  }

  Future<void> _saveCurrentFile() async {
    if (focused >= tabs.length) return;

    final currentTab = tabs[focused];
    final filePath = currentTab.data.path;
    final newContent = _textController.text;

    if (currentTab.data.path == "__welcome__") return;

    try {
      final file = File(filePath);
      await file.writeAsString(newContent);

      // Update tab content and reset modified flag
      setState(() {
        tabs[focused] = TabPaneData(
          currentTab.data.copyWith(content: newContent, isModified: false),
        );
      });

      // Show success indicator
      if (mounted) {
        showToast(
          context: context,
          location: ToastLocation.bottomRight,
          builder: (context, overlay) {
            return SurfaceCard(child: Basic(title: Text("File Saved")));
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
                title: Text("Error saving file"),
                subtitle: Text("$e"),
              ),
            );
          },
        );
      }
    }
  }

  void _onTextChanged() {
    if (focused >= tabs.length) return;

    final currentContent = tabs[focused].data.content;
    final newContent = _textController.text;

    if (currentContent != newContent) {
      setState(() {
        tabs[focused] = TabPaneData(
          tabs[focused].data.copyWith(content: newContent, isModified: true),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();

    tabs = [
      TabPaneData(
        EditorTab(
          title: "Welcome",
          path: "__welcome__",
          content: "Welcome to Flutter IDE\n\nOpen a folder to get started.",
        ),
      ),
    ];

    _textController.text = tabs.first.data.content;

    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        setState(() {
                          tabs.removeAt(index);
                          if (focused >= tabs.length && tabs.isNotEmpty) {
                            focused = tabs.length - 1;
                          } else if (tabs.isEmpty) {
                            _textController.clear();
                          } else {
                            _textController.text = tabs[focused].data.content;
                          }
                        });
                      },
                    ),
                    child: Text(data.title),
                  ),
                ),
              );
            },
            focused: focused,
            onFocused: (value) {
              setState(() {
                focused = value;
                if (value < tabs.length) {
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
                      "No Files open. Select a file from the explorer",
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          readOnly: tabs[focused].data.path == "__welcome__",
                          expands: true,
                          minLines: null,
                          maxLines: null,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).colorScheme.border,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text("1:1"),
                            const Gap(8),
                            const Text("Dart"),
                            const Gap(8),
                            IconButton.ghost(
                              onPressed: () {},
                              icon: const Icon(LucideIcons.terminal, size: 16),
                            ),
                          ],
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

// 1. Adopt Riverpod for state management
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

// class EditorScreen extends StatefulWidget {
//   const EditorScreen({super.key});

//   @override
//   State<StatefulWidget> createState() => _EditorScreenState();
// }

// class _EditorScreenState extends State<EditorScreen> {
//   bool openTerminal = false;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       headers: [const EditorHeader(), const Divider()],
//       footers: [const Divider(), const EditorFooter()],
//       child: ResizablePanel.horizontal(
//         children: [
//           ResizablePane(
//             initialSize: 260,
//             child: Container(
//               decoration: BoxDecoration(color: theme.colorScheme.card),
//               child: Column(children: [const EditorTreeView()]),
//             ),
//           ),
//           ResizablePane(
//             initialSize: MediaQuery.of(context).size.width - 260,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const EditorView(),
//                 if (openTerminal) const TerminalView(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class TerminalView extends StatelessWidget {
//   const TerminalView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Container(
//       decoration: BoxDecoration(
//         border: Border(top: BorderSide(color: theme.colorScheme.border)),
//       ),
//       height: 150,
//       child: Column(children: [const Text("Terminal")]),
//     );
//   }
// }

// class EditorView extends StatefulWidget {
//   const EditorView({super.key});

//   @override
//   State<EditorView> createState() => _EditorViewState();
// }

// class _EditorViewState extends State<EditorView> {
//   late List<TabPaneData<EditorTab>> tabs;
//   int focused = 0;
//   final TextEditingController _textController = TextEditingController();

//   void _onTextChanged() {
//     if (focused >= tabs.length) return;

//     final currentContent = tabs[focused].data.content;
//     final newContent = _textController.text;

//     if (currentContent != newContent) {
//       setState(() {
//         tabs[focused] = TabPaneData(
//           tabs[focused].data.copyWith(content: newContent, isModified: true),
//         );
//       });
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     tabs = [
//       TabPaneData(
//         EditorTab(
//           title: "Welcome",
//           path: "__welcome__",
//           content: "Welcome to Flutter IDE\n\nOpen a folder to get started.",
//         ),
//       ),
//     ];

//     _textController.text = tabs.first.data.content;

//     _textController.addListener(_onTextChanged);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return TabPane<EditorTab>(
//       // children: tabs.map((e) => _buildTabItem(e)).toList(),
//       // Provide the items and how to render each tab header.
//       items: tabs,
//       itemBuilder: (context, item, index) {
//         final data = item.data;

//         return TabItem(
//           child: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 200),
//             child: Label(
//               leading: data.isModified
//                   ? const Icon(LucideIcons.circle, size: 8)
//                   : null,
//               trailing: IconButton.ghost(
//                 shape: ButtonShape.circle,
//                 size: ButtonSize.xSmall,
//                 icon: const Icon(LucideIcons.x),
//                 onPressed: () {
//                   setState(() {
//                     tabs.removeAt(index);
//                     if (focused >= tabs.length && tabs.isNotEmpty) {
//                       focused = tabs.length - 1;
//                     } else if (tabs.isEmpty) {
//                       _textController.clear();
//                     } else {
//                       _textController.text = tabs[focused].data.content;
//                     }
//                   });
//                 },
//               ),
//               child: Text(data.title),
//             ),
//           ),
//         );
//       },
//       // The currently focused tab index.
//       focused: focused,
//       onFocused: (value) {
//         setState(() {
//           focused = value;
//         });
//       },
//       // Allow reordering via drag-and-drop; update the list with the new order.
//       onSort: (value) {
//         setState(() {
//           tabs = value;
//         });
//       },
//       trailing: [
//         IconButton.ghost(
//           icon: const Icon(LucideIcons.save),
//           size: ButtonSize.small,
//           density: ButtonDensity.iconDense,
//           onPressed: () {},
//         ),
//       ],
//       // The content area; you can render based on the focused index.
//       child: SizedBox(
//         width: 200,
//         height: MediaQuery.of(context).size.height - 135,
//         child: TextField(
//           controller: _textController,
//           readOnly: tabs[focused].data.path == "__welcome__",
//           expands: true,
//           minLines: null,
//           maxLines: null,
//           padding: const EdgeInsets.all(16),
//         ),
//       ),
//     );
//   }
// }

// class EditorTreeView extends StatefulWidget {
//   const EditorTreeView({super.key});

//   @override
//   State<EditorTreeView> createState() => _EditorTreeViewState();
// }

// class _EditorTreeViewState extends State<EditorTreeView> {
//   List<TreeNode<String>> treeItems = [
//     TreeItem(
//       data: "Apple",
//       expanded: true,
//       children: [
//         TreeItem(
//           data: "Red Apple",
//           children: [
//             TreeItem(data: "Red Apple 1"),
//             TreeItem(data: "Red Apple 2"),
//           ],
//         ),
//         TreeItem(data: "Green Apple"),
//       ],
//     ),
//     TreeItem(
//       data: "Banana",
//       children: [
//         TreeItem(data: "Yellow Banana"),
//         TreeItem(
//           data: "Green Banana",
//           children: [
//             TreeItem(data: "Green Banana 1"),
//             TreeItem(data: "Green Banana 2"),
//             TreeItem(data: "Green Banana 3"),
//           ],
//         ),
//       ],
//     ),
//     TreeItem(
//       data: "Cherry",
//       children: [
//         TreeItem(data: "Red Cherry"),
//         TreeItem(data: "Green Cherry"),
//       ],
//     ),
//     TreeItem(data: "Date"),
//     // Tree Root acts as a parent node with no data,
//     // it will flatten the children into the parent node
//     TreeRoot(
//       children: [
//         TreeItem(
//           data: "Elderberry",
//           children: [
//             TreeItem(data: "Black Elderberry"),
//             TreeItem(data: "Red Elderberry"),
//           ],
//         ),
//         TreeItem(
//           data: "Fig",
//           children: [
//             TreeItem(data: "Green Fig"),
//             TreeItem(data: "Purple Fig"),
//           ],
//         ),
//       ],
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return TreeView(
//       expandIcon: true,
//       shrinkWrap: true,
//       recursiveSelection: false,
//       nodes: treeItems,
//       branchLine: BranchLine.path,
//       onSelectionChanged: TreeView.defaultSelectionHandler(treeItems, (value) {
//         setState(() {
//           treeItems = value;
//         });
//       }),
//       builder: (context, node) {
//         return TreeItemView(
//           onPressed: () {},
//           trailing: node.leaf
//               ? Container(
//                   width: 16,
//                   height: 16,
//                   alignment: Alignment.center,
//                   child: const CircularProgressIndicator(),
//                 )
//               : null,
//           leading: node.leaf
//               ? const Icon(BootstrapIcons.fileImage)
//               : Icon(
//                   node.expanded
//                       ? BootstrapIcons.folder2Open
//                       : BootstrapIcons.folder2,
//                 ),
//           // Expand/collapse handling; updates treeItems with new expanded state.
//           onExpand: TreeView.defaultItemExpandHandler(treeItems, node, (value) {
//             setState(() {
//               treeItems = value;
//             });
//           }),
//           child: Text(node.data),
//         );
//       },
//     );
//   }
// }

// class EditorHeader extends StatefulWidget {
//   const EditorHeader({super.key});

//   @override
//   State<EditorHeader> createState() => _EditorHeaderState();
// }

// class _EditorHeaderState extends State<EditorHeader> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return AppBar(
//       backgroundColor: theme.colorScheme.card,
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           const Text("Flutter IDE"),
//           SizedBox(
//             width: 260,
//             child: PrimaryButton(
//               onPressed: () {
//                 showDialog(
//                   context: context,
//                   builder: (context) {
//                     return Command(
//                       builder: (context, query) async* {
//                         Map<String, List<String>> items = {
//                           "Suggestions": ["Calendar", "Search Emoji", "Launch"],
//                           "Settings": ["Profile", "Mail", "Settings"],
//                         };
//                         Map<String, Widget> icons = {
//                           "Calendar": const Icon(Icons.calendar_today),
//                           "Search Emoji": const Icon(
//                             Icons.emoji_emotions_outlined,
//                           ),
//                           "Launch": const Icon(Icons.rocket_launch_outlined),
//                           "Profile": const Icon(Icons.person_outline),
//                           "Mail": const Icon(Icons.mail_outline),
//                           "Settings": const Icon(Icons.settings_outlined),
//                         };
//                         for (final values in items.entries) {
//                           List<Widget> resultItems = [];
//                           for (final item in values.value) {
//                             if (query == null ||
//                                 item.toLowerCase().contains(
//                                   query.toLowerCase(),
//                                 )) {
//                               resultItems.add(
//                                 CommandItem(
//                                   title: Text(item),
//                                   leading: icons[item],
//                                   onTap: () {},
//                                 ),
//                               );
//                             }
//                           }
//                           if (resultItems.isNotEmpty) {
//                             // Simulate latency to showcase incremental results.
//                             await Future.delayed(const Duration(seconds: 1));
//                             yield [
//                               CommandCategory(
//                                 title: Text(values.key),
//                                 children: resultItems,
//                               ),
//                             ];
//                           }
//                         }
//                       },
//                     ).sized(width: 300, height: 300);
//                   },
//                 );
//               },
//               size: ButtonSize.small,
//               child: const Text("Project Name"),
//             ),
//           ),
//           Builder(
//             builder: (context) {
//               return IconButton.ghost(
//                 onPressed: () {
//                   showDropdown(
//                     context: context,
//                     builder: (context) {
//                       return const DropdownMenu(
//                         children: [
//                           MenuButton(child: Text("Settings")),
//                           MenuButton(child: Text("Keyboard Shortcust")),
//                         ],
//                       );
//                     },
//                   );
//                 },
//                 icon: const Icon(LucideIcons.settings, size: 16),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }

// class EditorFooter extends StatefulWidget {
//   const EditorFooter({super.key});

//   @override
//   State<EditorFooter> createState() => _EditorFooterState();
// }

// class _EditorFooterState extends State<EditorFooter> {
//   bool openTerminal = false;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return AppBar(
//       backgroundColor: theme.colorScheme.card,
//       trailing: [
//         const Text("Line/Column").small,
//         const Gap(4),
//         const Text("Language").small,
//         const Gap(4),
//         const SizedBox(height: 16, child: VerticalDivider()),
//         const Gap(4),
//         Tooltip(
//           tooltip: TooltipContainer(child: Text("Terminal")).call,
//           child: IconButton.ghost(
//             onPressed: () {
//               setState(() {
//                 openTerminal = !openTerminal;
//               });
//             },
//             shape: ButtonShape.circle,
//             size: ButtonSize.xSmall,
//             icon: const Icon(LucideIcons.terminal, size: 12),
//           ),
//         ),
//       ],
//     );
//   }
// }

// class EditorTab {
//   final String title;
//   final String path;
//   final String content;
//   final bool isModified;

//   EditorTab({
//     required this.title,
//     required this.path,
//     required this.content,
//     this.isModified = false,
//   });

//   EditorTab copyWith({
//     String? title,
//     String? path,
//     String? content,
//     bool? isModified,
//   }) {
//     return EditorTab(
//       title: title ?? this.title,
//       path: path ?? this.path,
//       content: content ?? this.content,
//       isModified: isModified ?? this.isModified,
//     );
//   }
// }
