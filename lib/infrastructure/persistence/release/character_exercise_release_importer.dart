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
/// Release rows and the installed-release marker commit in one transaction, so
/// an interrupted import can be retried without leaving partial content.
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
    final manifestHash = sha256.convert(manifestBytes).toString();
    final manifest = _asMap(jsonDecode(utf8.decode(manifestBytes)));
    if (manifest['schema_version'] != 1 ||
        manifest['kind'] != 'psitta_v0_2_character_exercises' ||
        manifest['release_id'] != _releaseId) {
      throw const FormatException('Unsupported character exercise manifest');
    }

    final installed = await _database.getAll(
      'SELECT manifest_sha256 FROM installed_content_release WHERE release_id = ?',
      [_releaseId],
    );
    if (installed.isNotEmpty) {
      if (installed.single['manifest_sha256'] != manifestHash) {
        throw StateError('Installed character release checksum does not match');
      }
      return false;
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

    final contentDao = ContentDao(_database);
    final exerciseDao = ExerciseDao(_database);
    final definitionDao = FieldDefinitionDao(_database);

    return _database.writeTransaction((txn) async {
      final existing = await txn.getAll(
        'SELECT manifest_sha256 FROM installed_content_release WHERE release_id = ?',
        [_releaseId],
      );
      if (existing.isNotEmpty) {
        if (existing.single['manifest_sha256'] != manifestHash) {
          throw StateError('Installed character release checksum does not match');
        }
        return false;
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

      await txn.execute(
        'INSERT INTO installed_content_release (release_id, manifest_sha256) VALUES (?, ?)',
        [_releaseId, manifestHash],
      );
      return true;
    });
  }

  void _validateRows(List<Map<String, dynamic>> rows, Map<String, dynamic> counts) {
    if (rows.length != counts['exercise_count'] ||
        rows.length != 309 ||
        counts['character_exercise_count'] != 218 ||
        counts['word_exercise_count'] != 91) {
      throw const FormatException('Character release counts do not match the manifest');
    }
    final ids = <String>{};
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
      _html(row, 'front_html');
      _html(row, 'back_html');
    }
    if (characterCount != counts['character_exercise_count'] ||
        wordCount != counts['word_exercise_count']) {
      throw const FormatException('Character release exercise types do not match the manifest');
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
}