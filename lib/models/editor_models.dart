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
  bool isLoaded;
  bool isLoading;
  bool isExpanded;
  List<FileSystemNode>? children;

  FileSystemNode({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.isLoaded = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.children,
  });

  FileSystemNode copyWith({
    String? name,
    String? path,
    bool? isDirectory,
    bool? isLoaded,
    bool? isLoading,
    bool? isExpanded,
    List<FileSystemNode>? children,
  }) {
    return FileSystemNode(
      name: name ?? this.name,
      path: path ?? this.path,
      isDirectory: isDirectory ?? this.isDirectory,
      isLoaded: isLoaded ?? this.isLoaded,
      isLoading: isLoading ?? this.isLoading,
      isExpanded: isExpanded ?? this.isExpanded,
      children: children ?? this.children,
    );
  }
}
