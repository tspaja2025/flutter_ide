import 'package:flutter_ide/syntax_highlighter/syntax_highlighter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
  late FocusNode _focusNode;
  late ScrollController _scrollController;
  double _scrollOffset = 0;
  int _selectionStart = 0;
  int _selectionEnd = 0;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _scrollController = ScrollController();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _handleTap(TapDownDetails details, int lineIndex) {
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlighter =
        widget.highlighter ?? DartSyntaxHighlighter.create(context: context);

    // Split text into lines
    final lines = widget.controller.text.split("\n");
    final List<Widget> lineWidgets = [];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final spans = highlighter.highlight(line);

      lineWidgets.add(
        GestureDetector(
          onTapDown: (details) => _handleTap(details, i),
          child: RichText(
            text: TextSpan(children: spans),
            maxLines: 1,
            softWrap: false,
          ),
        ),
      );

      // Line number overlay
      lineWidgets.add(const SizedBox(height: 2));
    }

    return Stack(
      children: [
        // Invisible text field for input
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          readOnly: widget.readOnly,
          maxLines: null,
          expands: true,
          style: const TextStyle(color: Colors.transparent),
          onChanged: (_) => setState(() {}),
          onTap: () => setState(() {}),
        ),

        // Visible syntax-highlighted text
        SingleChildScrollView(
          controller: _scrollController,
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lineWidgets,
          ),
        ),
      ],
    );
  }
}
