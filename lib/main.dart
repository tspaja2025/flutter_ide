import 'package:flutter_ide/screens/editor_screen.dart';
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
