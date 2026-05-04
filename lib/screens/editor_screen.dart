import 'package:flutter_ide/widgets/editor_tab_view.dart';
import 'package:flutter_ide/widgets/editor_tree_view.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final GlobalKey<EditorTabViewState> tabKey = GlobalKey<EditorTabViewState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorTreeView(
            onFileOpen: (path, content) {
              tabKey.currentState?.openFile(path, content);
            },
          ),
          EditorTabView(key: tabKey),
        ],
      ),
    );
  }
}
