import 'dart:io';

/// Script pour compter le nombre de lignes de code Dart dans le répertoire lib,
/// en excluant les fichiers dans lib/playground/.
void main() {
  final libDir = Directory('lib');
  int totalLines = 0;

  // Parcours récursif
  void countLines(Directory dir) {
    for (var entity in dir.listSync(recursive: false)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        // Ignore les fichiers dans lib/playground/
        if (!entity.path.contains('lib/playground/')) {
          final lines = entity.readAsLinesSync().length;
          totalLines += lines;
          print('${entity.path}: $lines lignes');
        }
      } else if (entity is Directory) {
        // Ne pas descendre dans playground
        if (!entity.path.contains('lib/playground')) {
          countLines(entity);
        }
      }
    }
  }

  countLines(libDir);

  print('\nTotal de lignes Dart (hors playground) : $totalLines');
}
