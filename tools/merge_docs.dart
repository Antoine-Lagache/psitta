// ignore_for_file: avoid_print

import 'dart:io';

/// Merge all Markdown docs into one big FULL_DOC.md
/// Used mainly for ChatGPT / AI context loading.
/// Keeps the original folder hierarchy visible as headers.

void main() async {
  final docsDir = Directory('docs');
  final outputFile = File('${docsDir.path}/FULL_DOC.md');

  if (!docsDir.existsSync()) {
    print('❌ The docs/ folder does not exist.');
    exit(1);
  }

  final buffer = StringBuffer();

  // Add header metadata for ChatGPT
  buffer.writeln('# 📘 Full Documentation Snapshot');
  buffer.writeln('> ⚙️ Auto-generated for ChatGPT context loading.\n');
  buffer.writeln('> Each section below corresponds to a file inside /docs.\n');
  buffer.writeln('> Source project: Flutter App Langue\n');
  buffer.writeln('---\n');

  // Recursively collect all .md files except FULL_DOC.md
  final mdFiles = docsDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) =>
          f.path.endsWith('.md') && !f.path.endsWith('FULL_DOC.md'))
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
