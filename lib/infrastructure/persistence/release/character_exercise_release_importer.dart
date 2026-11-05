import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:psitta/infrastructure/persistence/dao/content_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/field_definition_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/character_exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/content/content_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/field_definition/field_definition_persistence.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

typedef CharacterReleaseAssetLoader = Future<Uint8List> Function(String path);

const _assetDirectory = 'assets/content/v0_2';
const _releaseId = 'v0_2_character_exercises';
const _fileName = 'character_exercises.jsonl.gz';

/// Adds the frozen v0.2 kana curriculum to an existing or new database once.
///
/// Release rows commit in one transaction, so an interrupted import can be
/// retried without leaving partial content. Existing rendered cards identify
/// the release without requiring a database schema migration.
final class CharacterExerciseReleaseImporter {
  final sqlite.SqliteDatabase _database;
  final CharacterReleaseAssetLoader _loadAsset;

  CharacterExerciseReleaseImporter(
    this._database, {
    CharacterReleaseAssetLoader? loadAsset,
  }) : _loadAsset = loadAsset ?? _loadBundledAsset;

  static Future<Uint8List> _loadBundledAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<bool> importIfNeeded() async {
    final manifestBytes = await _loadAsset('$_assetDirectory/manifest.json');
    final manifest = _asMap(jsonDecode(utf8.decode(manifestBytes)));
    if (manifest['schema_version'] != 1 ||
        manifest['kind'] != 'psitta_v0_2_character_exercises' ||
        manifest['release_id'] != _releaseId) {
      throw const FormatException('Unsupported character exercise manifest');
    }

    final counts = _asMap(manifest['counts']);
    final metadata = _asMap(_asMap(manifest['files'])[_fileName]);
    final compressed = await _loadAsset('$_assetDirectory/$_fileName');
    if (sha256.convert(compressed).toString() != metadata['sha256']) {
      throw const FormatException('Character release archive checksum mismatch');
    }
    final decoded = gzip.decode(compressed);
    if (sha256.convert(decoded).toString() != metadata['jsonl_sha256']) {
      throw const FormatException('Character release JSONL checksum mismatch');
    }
    final rows = const LineSplitter()
        .convert(utf8.decode(decoded))
        .where((line) => line.isNotEmpty)
        .map((line) => _asMap(jsonDecode(line)))
        .toList();
    _validateRows(rows, counts);

    final expectedCards = rows.map(_renderedCardKey).toSet();
    final existingReleaseRows = await _existingReleaseRows(_database);
    final matchingRows = expectedCards.intersection(existingReleaseRows).length;
    if (matchingRows == rows.length) return false;
    if (matchingRows > 0) {
      throw StateError(
        'The character release is only partially present; refusing to duplicate it',
      );
    }

    final contentDao = ContentDao(_database);
    final exerciseDao = ExerciseDao(_database);
    final definitionDao = FieldDefinitionDao(_database);

    return _database.writeTransaction((txn) async {
      final existingRows = await _existingReleaseRows(txn);
      final existingMatches = expectedCards.intersection(existingRows).length;
      if (existingMatches == rows.length) return false;
      if (existingMatches > 0) {
        throw StateError(
          'The character release is only partially present; refusing to duplicate it',
        );
      }

      final frontId = await definitionDao.insertInTransaction(
        txn,
        FieldDefinitionPersistence(valueType: 'html', side: 'front'),
      );
      final backId = await definitionDao.insertInTransaction(
        txn,
        FieldDefinitionPersistence(valueType: 'html', side: 'back'),
      );

      for (final row in rows) {
        final contentId = await contentDao.insertInTransaction(
          txn,
          ContentPersistence(
            fieldValues: [
              FieldValuePersistence(
                fieldDefinitionId: frontId,
                textValue: _html(row, 'front_html'),
                displayOrder: 0,
              ),
              FieldValuePersistence(
                fieldDefinitionId: backId,
                textValue: _html(row, 'back_html'),
                displayOrder: 0,
              ),
            ],
          ),
        );
        await exerciseDao.insertInTransaction(
          txn,
          CharacterExerciseMapper.newCharacterExercise(contentId),
        );
      }

      return true;
    });
  }

  Future<Set<String>> _existingReleaseRows(sqlite.SqliteReadContext database) async {
    final rows = await database.getAll('''
      SELECT front.text_value AS front_html, back.text_value AS back_html
      FROM character_exercise ce
      JOIN exercise e ON e.id = ce.exercise_id
      JOIN field_value front ON front.content_id = ce.content_id
      JOIN field_definition front_definition
        ON front_definition.id = front.field_definition_id AND front_definition.side = 'front'
      JOIN field_value back ON back.content_id = ce.content_id
      JOIN field_definition back_definition
        ON back_definition.id = back.field_definition_id AND back_definition.side = 'back'
      WHERE e.type = 'character'
      ''');
    return rows.map((row) => jsonEncode([row['front_html'], row['back_html']])).toSet();
  }

  void _validateRows(List<Map<String, dynamic>> rows, Map<String, dynamic> counts) {
    if (rows.length != counts['exercise_count'] ||
        rows.length != 309 ||
        counts['character_exercise_count'] != 218 ||
        counts['word_exercise_count'] != 91) {
      throw const FormatException('Character release counts do not match the manifest');
    }
    final ids = <String>{};
    final renderedCards = <String>{};
    var characterCount = 0;
    var wordCount = 0;
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      final kind = row['kind'];
      if ((kind != 'character_exercise' && kind != 'word_exercise') ||
          row['order'] != index + 1 ||
          row['exercise_id'] is! String ||
          !ids.add(row['exercise_id'] as String)) {
        throw FormatException('Invalid character release row at index $index');
      }
      if (kind == 'character_exercise') {
        characterCount++;
      } else {
        wordCount++;
      }
      _asMap(row['target']);
      final renderedCard = _renderedCardKey(row);
      if (!renderedCards.add(renderedCard)) {
        throw const FormatException('Character release contains duplicate cards');
      }
    }
    if (characterCount != counts['character_exercise_count'] ||
        wordCount != counts['word_exercise_count']) {
      throw const FormatException(
        'Character release exercise types do not match the manifest',
      );
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected a JSON object in character release');
  }

  static String _html(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing $key in character release');
  }

  static String _renderedCardKey(Map<String, dynamic> row) =>
      jsonEncode([_html(row, 'front_html'), _html(row, 'back_html')]);
}
