import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_ide/models/editor_models.dart';
import 'package:flutter_ide/widgets/editor_textfield.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:path/path.dart' as path;

class EditorTabView extends StatefulWidget {
  const EditorTabView({super.key});

  @override
  State<EditorTabView> createState() => EditorTabViewState();
}

class EditorTabViewState extends State<EditorTabView> {
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

    return Expanded(
      child: TabPane<EditorTab>(
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
      ),
    );
  }
}
