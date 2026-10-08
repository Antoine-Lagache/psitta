// ignore_for_file: avoid_print

import 'dart:io';

/// Regenerates `FULL_DOC.md` from every source Markdown file under `docs`.
void main() async {
  final docsDir = Directory('docs');
  final outputFile = File('${docsDir.path}/FULL_DOC.md');

  if (!docsDir.existsSync()) {
    print('❌ The docs/ folder does not exist.');
    exit(1);
  }

  final buffer = StringBuffer();

  // Identify the generated snapshot and preserve its intended context.
  buffer.writeln('# 📘 Full Documentation Snapshot');
  buffer.writeln('> ⚙️ Auto-generated for ChatGPT context loading.\n');
  buffer.writeln('> Each section below corresponds to a file inside /docs.\n');
  buffer.writeln('> Source project: Psitta\n');
  buffer.writeln('---\n');

  // Exclude the output itself to keep repeated generations stable.
  final mdFiles =
      docsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.md') && !f.path.endsWith('FULL_DOC.md'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in mdFiles) {
    final relativePath = file.path.replaceFirst('${docsDir.path}/', '');
    buffer.writeln('\n---\n');
    buffer.writeln('## 📄 $relativePath\n');
    buffer.writeln('````markdown');
    buffer.writeln(await file.readAsString());
    buffer.writeln('````');
  }

  await outputFile.writeAsString(buffer.toString());
  print('✅ Documentation merged successfully: ${outputFile.path}');
}
