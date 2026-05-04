import 'package:shadcn_flutter/shadcn_flutter.dart';

class SyntaxHighlighter {
  final Map<String, List<Pattern>> tokenPatterns;
  final Map<String, TextStyle> tokenStyles;
  final TextStyle defaultStyle;

  SyntaxHighlighter({
    required this.tokenPatterns,
    required this.tokenStyles,
    required this.defaultStyle,
  });

  List<TextSpan> highlight(String text) {
    if (text.isEmpty) return [TextSpan(text: text, style: defaultStyle)];

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    // Find all matches across all token types
    final List<_Match> allMatches = [];

    for (final entry in tokenPatterns.entries) {
      final tokenType = entry.key;
      final style = tokenStyles[tokenType] ?? defaultStyle;

      for (final pattern in entry.value) {
        final matches = pattern.allMatches(text);
        for (final match in matches) {
          allMatches.add(
            _Match(
              start: match.start,
              end: match.end,
              style: style,
              text: match.group(0)!,
            ),
          );
        }
      }
    }

    // Sort matches by start position, then by length
    // longest first for overlapping
    allMatches.sort((a, b) {
      if (a.start != b.start) return a.start.compareTo(b.start);
      return b.end.compareTo(a.end); // longer matches first
    });

    // Remove overlapping matches
    // prioritize longer matches
    final filteredMatches = <_Match>[];
    int lastEnd = -1;

    for (final match in allMatches) {
      if (match.start >= lastEnd) {
        filteredMatches.add(match);
        lastEnd = match.end;
      }
    }

    // Build TextSpans
    for (final match in filteredMatches) {
      // Add text before match
      if (currentIndex < match.start) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: defaultStyle,
          ),
        );
      }

      // Add highlighted match
      spans.add(TextSpan(text: match.text, style: match.style));

      currentIndex = match.end;
    }

    // Add remaining text
    if (currentIndex < text.length) {
      spans.add(
        TextSpan(text: text.substring(currentIndex), style: defaultStyle),
      );
    }

    return spans;
  }
}

class _Match {
  final int start;
  final int end;
  final TextStyle style;
  final String text;

  _Match({
    required this.start,
    required this.end,
    required this.style,
    required this.text,
  });
}

class DartSyntaxHighlighter {
  static SyntaxHighlighter create({required BuildContext context}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SyntaxHighlighter(
      defaultStyle: TextStyle(color: colors.primary, fontFamily: "monospace"),
      tokenPatterns: {
        "keyword": [
          RegExp(
            r'\b(break|case|catch|class|const|continue|default|do|else|enum|extends|final|finally|for|if|in|is|new|return|super|switch|this|throw|try|var|void|while|with|abstract|as|await|dynamic|export|external|factory|get|implements|import|library|mixin|operator|part|set|static|sync|typedef|yield)\b',
          ),
          RegExp(r'\b(true|false|null)\b'),
        ],
        "string": [
          RegExp(r'"(?:\\.|[^"\\])*"'),
          RegExp(r"'(?:\\.|[^'\\])*'"),
          RegExp(r'r"(?:\\.|[^"\\])*"'),
          RegExp(r"r'(?:\\.|[^'\\])*'"),
        ],
        "number": [
          RegExp(r'\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b'),
          RegExp(r'\b0x[0-9A-Fa-f]+\b'),
        ],
        "comment": [
          RegExp(r'//[^\n]*'),
          RegExp(r'/\*[\s\S]*?\*/', multiLine: true),
        ],
        "builtin_type": [
          RegExp(
            r'\b(int|double|num|String|bool|List|Map|Set|Future|Stream|void|dynamic|Object|Iterable)\b',
          ),
        ],
        "annotation": [RegExp(r'@\w+')],
        "function_call": [RegExp(r'\b\w+(?=\()')],
      },
      tokenStyles: {
        "keyword": TextStyle(
          color: colors.primary,
          fontWeight: FontWeight.bold,
        ),
        "string": TextStyle(color: Colors.green.shade400),
        "number": TextStyle(color: Colors.orange.shade400),
        "comment": TextStyle(
          color: Colors.gray.shade600,
          fontStyle: FontStyle.italic,
        ),
        "builtin_type": TextStyle(color: colors.secondary),
        "annotation": TextStyle(color: Colors.purple.shade400),
        "function_call": TextStyle(color: colors.primary),
      },
    );
  }
}
