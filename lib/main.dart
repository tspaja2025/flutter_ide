import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
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
  List<TreeNode<FileSystemNode>> treeItems = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Replace with your project path or allow user selection
      final projectDir = Directory("C:/Users/user/Documents/paja/flutter_ide");

      if (!await projectDir.exists()) {
        throw Exception("Project directory does not exist");
      }

      final rootNode = FileSystemNode(
        name: projectDir.path.split(Platform.pathSeparator).last,
        path: projectDir.path,
        isDirectory: true,
      );

      // Load root level children asynchronously
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

  TreeNode<FileSystemNode> _convertToTreeNode(FileSystemNode node) {
    List<TreeNode<FileSystemNode>> childNodes = [];

    if (node.isLoaded && node.children != null) {
      // Directory has been loaded - show actual children
      childNodes = node.children!
          .map((child) => _convertToTreeNode(child))
          .toList();
    } else if (node.isDirectory && !node.isLoaded) {
      // Directory not loaded yet - add a placeholder child to show expand icon
      // This is a dummy node that will be replaced when expanded
      final placeholderNode = FileSystemNode(
        name: "Loading...",
        path: node.path,
        isDirectory: false,
      );
      childNodes = [
        TreeItem(data: placeholderNode, expanded: false, children: []),
      ];
    }

    return TreeItem(data: node, expanded: false, children: childNodes);
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
      case "dart":
        return const Icon(BootstrapIcons.codeSlash);
      default:
        return const Icon(BootstrapIcons.fileImage);
    }
  }

  void _openFile(String path) {
    if (kDebugMode) {
      // Implement file opening logic
      debugPrint("Opening file: $path");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(child: Center(child: CircularProgressIndicator()));
    }

    if (error != null) {
      return Scaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(BootstrapIcons.exclamationTriangle, size: 48),
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
            width: 320,
            child: TreeView(
              expandIcon: true,
              shrinkWrap: true,
              recursiveSelection: false,
              nodes: treeItems,
              branchLine: BranchLine.path,
              onSelectionChanged: TreeView.defaultSelectionHandler(treeItems, (
                value,
              ) {
                setState(() {
                  treeItems = value;
                });
              }),
              builder: (context, node) {
                final fileNode = _getNodeValue(node);
                final isDirectory = fileNode.isDirectory;

                // Don't show expand icon for placeholder nodes
                final isPlaceholder = fileNode.name == "Loading...";
                final shouldShowExpandIcon = isDirectory && !isPlaceholder;

                return TreeItemView(
                  onPressed: () {
                    if (isDirectory && !fileNode.isLoaded && !isPlaceholder) {
                      _expandNode(fileNode);
                    } else if (!isDirectory && !isPlaceholder) {
                      _openFile(fileNode.path);
                    }
                  },
                  leading: isDirectory
                      ? Icon(
                          node.expanded
                              ? BootstrapIcons.folder2Open
                              : BootstrapIcons.folder2,
                        )
                      : _getFileIcon(fileNode.name),
                  onExpand: shouldShowExpandIcon
                      ? (expanded) async {
                          if (expanded && !fileNode.isLoaded) {
                            await _expandNode(fileNode);
                          }
                          // Call default handler to update UI
                          TreeView.defaultItemExpandHandler(treeItems, node, (
                            value,
                          ) {
                            setState(() {
                              treeItems = value;
                            });
                          })(expanded);
                        }
                      : null,
                  child: Text(fileNode.name),
                );
              },
            ),
          ),
          const VerticalDivider(),
          Flexible(
            child: Column(
              children: [
                const Gap(16),
                const Text("Flutter IDE - Welcome!"),
                const Gap(8),
                const Text("Select a file from the explorer to open it"),
              ],
            ),
          ),
        ],
      ),
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

// Something to add:
// Ignore patterns e.g .git, node_modules, .DS_Store
// Loading indicators
// Cache loaded directories to avoid reloading
// Show the contents of a file
// Tabs
//
// Packages to consider:
// file_picker - For project directory selection
// path_provider - For accessing common directories
// flutter_file_manager - For advanced file operations
