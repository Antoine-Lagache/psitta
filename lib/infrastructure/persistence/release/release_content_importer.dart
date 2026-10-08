import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:psitta/infrastructure/persistence/dao/content_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/exercise_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/field_definition_dao.dart';
import 'package:psitta/infrastructure/persistence/dao/sentence_group_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/sentence_exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/exercise/word_exercise_mapper.dart';
import 'package:psitta/infrastructure/persistence/mappers/sentence_mapper.dart';
import 'package:psitta/infrastructure/persistence/models/content/content_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/field_definition/field_definition_persistence.dart';
import 'package:psitta/infrastructure/persistence/models/sentence/sentence_group_persistence.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

typedef ReleaseAssetLoader = Future<Uint8List> Function(String path);

const _assetDirectory = 'assets/content/v0_1';
const _wordFile = 'word_exercises.jsonl.gz';
const _sentenceFile = 'sentence_exercises.jsonl.gz';

/// Installs the frozen v0.1 corpus into an empty, migrated database.
///
/// All rows commit together. Existing databases, including user progress, are
/// left intact; replacing a corpus requires a separate versioned migration.
final class ReleaseContentImporter {
  final sqlite.SqliteDatabase _database;
  final ReleaseAssetLoader _loadAsset;

  ReleaseContentImporter(this._database, {ReleaseAssetLoader? loadAsset})
    : _loadAsset = loadAsset ?? _loadBundledAsset;

  static Future<Uint8List> _loadBundledAsset(String path) async {
    final data = await rootBundle.load(path);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<bool> importIfEmpty() async {
    if (await _hasExercises()) return false;

    final manifest = _asMap(jsonDecode(utf8.decode(await _loadAsset('$_assetDirectory/manifest.json'))));
    if (manifest['schema_version'] != 1 ||
        manifest['kind'] != 'psitta_v0_1_html_exercises') {
      throw const FormatException('Unsupported release content manifest');
    }
    final counts = _asMap(manifest['counts']);
    final files = _asMap(manifest['files']);
    final words = await _readRows(_wordFile, _asMap(files[_wordFile]));
    final sentences = await _readRows(_sentenceFile, _asMap(files[_sentenceFile]));
    final instanceCount = sentences.fold<int>(
      0,
      (sum, row) => sum + _asList(row['instances']).length,
    );
    if (words.length != counts['word_exercises'] ||
        sentences.length != counts['sentence_exercises'] ||
        instanceCount != counts['sentence_instances']) {
      throw const FormatException('Release content counts do not match the manifest');
    }
    _validateOrder(words, 'word_exercise', 'word');
    _validateOrder(sentences, 'sentence_exercise', 'sentence');

    final contentDao = ContentDao(_database);
    final exerciseDao = ExerciseDao(_database);
    final definitionDao = FieldDefinitionDao(_database);
    final groupDao = SentenceGroupDao(_database);

    return _database.writeTransaction((txn) async {
      if (await _hasExercisesIn(txn)) return false;

      final frontId = await definitionDao.insertInTransaction(
        txn,
        FieldDefinitionPersistence(valueType: 'html', side: 'front'),
      );
      final backId = await definitionDao.insertInTransaction(
        txn,
        FieldDefinitionPersistence(valueType: 'html', side: 'back'),
      );

      Future<int> insertContent(Map<String, dynamic> row) {
        return contentDao.insertInTransaction(
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
      }

      // Autoincremented exercise IDs preserve the corpus order within each type.
      for (final word in words) {
        final contentId = await insertContent(word);
        await exerciseDao.insertInTransaction(
          txn,
          WordExerciseMapper.newWordExercise(contentId),
        );
      }
      for (final sentence in sentences) {
        final instances = <SentenceInstancePersistence>[];
        final seen = <String>{};
        for (final raw in _asList(sentence['instances'])) {
          final instance = _asMap(raw);
          final instanceId = instance['instance_id'];
          if (instanceId is! String || !seen.add(instanceId)) {
            throw const FormatException('Invalid or repeated sentence instance ID');
          }
          instances.add(SentenceMapper.newInstance(await insertContent(instance)));
        }
        if (instances.isEmpty) {
          throw const FormatException('Sentence group cannot be empty');
        }
        final groupId = await groupDao.insertSentenceGroupInTransaction(
          txn,
          SentenceGroupPersistence(sentenceInstances: instances),
        );
        await exerciseDao.insertInTransaction(
          txn,
          SentenceExerciseMapper.newSentenceExercise(groupId, instances.length),
        );
      }
      return true;
    });
  }

  Future<bool> _hasExercises() => _database.readTransaction(_hasExercisesIn);

  Future<bool> _hasExercisesIn(sqlite.SqliteReadContext txn) async =>
      (await txn.getAll('SELECT 1 FROM exercise LIMIT 1')).isNotEmpty;

  Future<List<Map<String, dynamic>>> _readRows(
    String fileName,
    Map<String, dynamic> metadata,
  ) async {
    final compressed = await _loadAsset('$_assetDirectory/$fileName');
    if (sha256.convert(compressed).toString() != metadata['sha256']) {
      throw FormatException('Release content checksum mismatch: $fileName');
    }
    final decoded = gzip.decode(compressed);
    if (sha256.convert(decoded).toString() != metadata['jsonl_sha256']) {
      throw FormatException('Release JSONL checksum mismatch: $fileName');
    }
    return const LineSplitter()
        .convert(utf8.decode(decoded))
        .where((line) => line.isNotEmpty)
        .map((line) => _asMap(jsonDecode(line)))
        .toList();
  }

  void _validateOrder(List<Map<String, dynamic>> rows, String kind, String prefix) {
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      if (row['kind'] != kind ||
          row['order'] != index + 1 ||
          row['exercise_id'] != '$prefix-${(index + 1).toString().padLeft(4, '0')}') {
        throw FormatException('Invalid $kind order at index $index');
      }
    }
  }

  static Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    throw const FormatException('Expected a JSON object in release content');
  }

  static List<dynamic> _asList(Object? value) {
    if (value is List<dynamic>) return value;
    throw const FormatException('Expected a JSON array in release content');
  }

  static String _html(Map<String, dynamic> row, String key) {
    final value = row[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing $key in release content');
  }
}
