import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_ide/models/editor_models.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:path/path.dart' as path;

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
        ? Container(
            width: 260,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).colorScheme.border),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                PrimaryButton(
                  onPressed: pickDirectory,
                  child: const Text("Open Project"),
                ),
              ],
            ),
          )
        : Container(
            width: 260,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).colorScheme.border),
              ),
            ),
            child: TreeView(
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
            ),
          );
  }
}
