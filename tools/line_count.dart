// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math';

/// Prints the `lib` tree with Dart line counts for each file and directory.
///
/// Exclusions:
/// - lib/playground/
/// - lib/archive/
void main() {
  final libDir = Directory('lib');

  final root = buildTree(libDir);

  final widths = getAllLineCounts(root);
  final width = widths.reduce(max).toString().length;

  print(yellow + root.name + reset);
  printTree(root, '', width);

  print('\nTotal Dart lines: $yellow${root.lines}$reset');
}

/// Aggregates a file-system entry and the Dart lines below it.
class TreeNode {
  final String name;
  final bool isDirectory;
  final int lines;
  final List<TreeNode> children;

  TreeNode({
    required this.name,
    required this.isDirectory,
    required this.lines,
    this.children = const [],
  });
}

/// Recursively builds a line-count tree rooted at [dir].
TreeNode buildTree(Directory dir) {
  final children = <TreeNode>[];
  var totalLines = 0;

  for (final entity in dir.listSync()) {
    if (_shouldIgnore(entity.path)) {
      continue;
    }

    if (entity is Directory) {
      final child = buildTree(entity);

      children.add(child);
      totalLines += child.lines;
    } else if (entity is File && entity.path.endsWith('.dart')) {
      final lines = entity.readAsLinesSync().length;

      children.add(
        TreeNode(name: entity.uri.pathSegments.last, isDirectory: false, lines: lines),
      );

      totalLines += lines;
    }
  }

  // Keep directories before files, then sort both groups alphabetically.
  children.sort((a, b) {
    if (a.isDirectory != b.isDirectory) {
      return a.isDirectory ? -1 : 1;
    }

    return a.name.compareTo(b.name);
  });

  return TreeNode(
    name: dir.uri.pathSegments.lastWhere((segment) => segment.isNotEmpty),
    isDirectory: true,
    lines: totalLines,
    children: children,
  );
}

bool _shouldIgnore(String path) {
  return path.contains('lib/playground') || path.contains('lib/archive');
}

/// Flattens the line counts used to align the rendered tree.
List<int> getAllLineCounts(TreeNode node) {
  return [node.lines, ...node.children.expand(getAllLineCounts)];
}

/// Prints [node] using tree branches and aligned line counts.
void printTree(TreeNode node, String prefix, int width) {
  for (var i = 0; i < node.children.length; i++) {
    final child = node.children[i];

    final isLast = i == node.children.length - 1;
    final branch = isLast ? '└─ ' : '├─ ';

    final count = child.lines.toString().padLeft(width, ' ');

    String coloredCount;
    if (child.lines < 100) {
      coloredCount = child.isDirectory
          ? '$blue$count lines$reset ─'
          : '$green$count lines$reset ─';
    } else {
      coloredCount = child.isDirectory
          ? '$brightBlue$count lines$reset ─'
          : '$brightGreen$count lines$reset ─';
    }

    print('$prefix$branch$coloredCount ${child.name}${child.isDirectory ? '/' : ''}');

    if (child.isDirectory) {
      printTree(child, prefix + (isLast ? '   ' : '│  '), width);
    }
  }
}

// ANSI colors

const reset = '\x1B[0m';
const green = '\x1B[32m';
const blue = '\x1B[34m';
const brightGreen = '\x1B[92m';
const brightBlue = '\x1B[94m';

const yellow = '\x1B[93m';
