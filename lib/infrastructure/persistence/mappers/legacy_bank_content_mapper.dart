import 'dart:collection';

import 'package:html/parser.dart' as html_parser;
import 'package:sqlite_async/sqlite_async.dart' as sqlite;

/// A portable bank change prepared from the pre-bank content tables.
///
/// The mapper deliberately excludes SRS state, answer history, session state,
/// and local media paths. Those are user/device data, not bank content.
final class LegacyBankContentChange {
  final String changeType;
  final Map<String, Object?> payload;

  const LegacyBankContentChange({required this.changeType, required this.payload});
}

/// Converts the current normalized content schema into root-commit snapshots.
///
/// IDs from the content database are preserved as decimal strings. The
/// bundled database is the source of these IDs in 0.3; converting them to
/// strings matches `exercise_progress.exercise_id` while retaining their
/// identity and ordering. Local SQLite IDs are never included for field
/// definitions, field values, or media files.
final class LegacyBankContentMapper {
  const LegacyBankContentMapper();

  Future<List<LegacyBankContentChange>> map(
    sqlite.SqliteWriteContext database,
  ) async {
    final changes = <LegacyBankContentChange>[];

    final referencedContentIds = <int>{};
    final exerciseRows = await database.getAll('''
      SELECT
        e.id AS exercise_id,
        e.type AS exercise_type,
        e.training_count_max,
        we.content_id AS word_content_id,
        ce.content_id AS character_content_id,
        se.sentence_group_id
      FROM exercise e
      LEFT JOIN word_exercise we ON we.exercise_id = e.id
      LEFT JOIN character_exercise ce ON ce.exercise_id = e.id
      LEFT JOIN sentence_exercise se ON se.exercise_id = e.id
      ORDER BY e.id
      ''');

    final groupsRows = await database.getAll('SELECT id FROM sentence_group ORDER BY id');
    final sentenceRows = await database.getAll('''
      SELECT id, sentence_group_id, content_id
      FROM sentence_instance
      ORDER BY sentence_group_id, id
      ''');

    final sentenceIdsByGroup = <int, List<String>>{};
    for (final row in sentenceRows) {
      final groupId = row['sentence_group_id'] as int;
      final contentId = row['content_id'] as int;
      referencedContentIds.add(contentId);
      sentenceIdsByGroup.putIfAbsent(groupId, () => []).add(_id(row['id'] as int));
    }

    final sentenceGroupIds = groupsRows.map((row) => row['id'] as int).toSet();
    for (final groupId in sentenceIdsByGroup.keys) {
      if (!sentenceGroupIds.contains(groupId)) {
        throw StateError('Sentence instance references missing group $groupId');
      }
    }

    final sentenceExerciseGroupIds = <int>{};
    for (final row in exerciseRows) {
      final exerciseId = row['exercise_id'] as int;
      final type = row['exercise_type'] as String;
      final Map<String, Object?> payload = {
        'exercise_id': _id(exerciseId),
        'exercise_type': type,
        'training_count_max': row['training_count_max'] as int,
      };

      switch (type) {
        case 'word':
          final contentId = _requiredInt(row['word_content_id'], 'word', exerciseId);
          referencedContentIds.add(contentId);
          payload['content_id'] = _id(contentId);
          break;
        case 'character':
          final contentId = _requiredInt(
            row['character_content_id'],
            'character',
            exerciseId,
          );
          referencedContentIds.add(contentId);
          payload['content_id'] = _id(contentId);
          break;
        case 'sentence':
          final groupId = _requiredInt(row['sentence_group_id'], 'sentence', exerciseId);
          if (!sentenceGroupIds.contains(groupId)) {
            throw StateError('Sentence exercise $exerciseId references missing group $groupId');
          }
          sentenceExerciseGroupIds.add(groupId);
          payload['sentence_group_id'] = _id(groupId);
          break;
        default:
          throw StateError('Unsupported legacy exercise type "$type"');
      }

      changes.add(LegacyBankContentChange(changeType: 'add exercise', payload: payload));
    }

    for (final row in sentenceRows) {
      changes.add(
        LegacyBankContentChange(
          changeType: 'add sentence',
          payload: {
            'sentence_id': _id(row['id'] as int),
            'content_id': _id(row['content_id'] as int),
          },
        ),
      );
    }

    for (final groupId in sentenceGroupIds.toList()..sort()) {
      changes.add(
        LegacyBankContentChange(
          changeType: 'add sentence group',
          payload: {
            'sentence_group_id': _id(groupId),
            'sentence_ids': List<String>.unmodifiable(
              sentenceIdsByGroup[groupId] ?? const <String>[],
            ),
          },
        ),
      );
    }

    final contentChanges = await _mapContent(database, referencedContentIds);
    changes.addAll(contentChanges.changes);

    for (final groupId in sentenceExerciseGroupIds) {
      if ((sentenceIdsByGroup[groupId] ?? const []).isEmpty) {
        throw StateError('Sentence exercise references empty group $groupId');
      }
    }

    for (final media in contentChanges.mediaBySha.values) {
      changes.add(
        LegacyBankContentChange(
          changeType: 'add media',
          payload: {
            'sha256': media['sha256'],
            'mime_type': media['mime_type'],
            'size': media['size'],
          },
        ),
      );
    }

    // Emit referenced entities before entities that point to them, then sort
    // by ID within each kind so generated change IDs are deterministic.
    changes.sort(_compareChanges);
    return List.unmodifiable(changes);
  }

  Future<_MappedContent> _mapContent(
    sqlite.SqliteWriteContext database,
    Set<int> contentIds,
  ) async {
    if (contentIds.isEmpty) {
      return const _MappedContent([], {});
    }

    final orderedContentIds = contentIds.toList()..sort();
    final rows = <Map<String, Object?>>[];
    // Keep below SQLite's historical 999 bind-parameter limit. The corpus
    // contains several thousand content records, so one IN clause is unsafe.
    const batchSize = 500;
    for (var offset = 0; offset < orderedContentIds.length; offset += batchSize) {
      final batch = orderedContentIds.skip(offset).take(batchSize).toList();
      final placeholders = List.filled(batch.length, '?').join(', ');
      rows.addAll(await database.getAll('''
      SELECT
        c.id AS content_id,
        fv.display_order,
        fv.text_value,
        fd.value_type,
        fd.side,
        m.sha256 AS media_sha256
      FROM content c
      LEFT JOIN field_value fv ON fv.content_id = c.id
      LEFT JOIN field_definition fd ON fd.id = fv.field_definition_id
      LEFT JOIN media m ON m.id = fv.media_id
      WHERE c.id IN ($placeholders)
      ORDER BY c.id, fv.display_order, fv.id
      ''', batch));
    }

    final fieldsByContent = <int, List<Map<String, Object?>>>{};
    final referencedMediaShas = <String>{};
    for (final row in rows) {
      final contentId = row['content_id'] as int;
      final fields = fieldsByContent.putIfAbsent(contentId, () => []);
      if (row['display_order'] == null) {
        continue;
      }

      if (row['value_type'] == null || row['side'] == null) {
        throw StateError('Content $contentId references a missing field definition');
      }

      final field = <String, Object?>{
        'value_type': row['value_type'],
        'side': row['side'],
        'display_order': row['display_order'],
      };
      final sha256 = row['media_sha256'] as String?;
      final textValue = row['text_value'] as String?;
      if (sha256 != null && textValue == null) {
        field['media_sha256'] = sha256;
        referencedMediaShas.add(sha256);
      } else if (sha256 == null && textValue != null) {
        field['text_value'] = textValue;
        if (row['value_type'] == 'html') {
          referencedMediaShas.addAll(_mediaHashesInHtml(textValue));
        }
      } else {
        throw StateError(
          'Content $contentId has a field with both or neither text and media values',
        );
      }
      fields.add(field);
    }

    final mediaRows = await database.getAll('SELECT sha256, mime_type, size FROM media');
    final mediaBySha = <String, Map<String, Object?>>{
      for (final row in mediaRows)
        row['sha256'] as String: {
          'sha256': row['sha256'],
          'mime_type': row['mime_type'],
          'size': row['size'],
        },
    };
    final referencedMedia = <String, Map<String, Object?>>{};
    for (final sha256 in referencedMediaShas) {
      final metadata = mediaBySha[sha256];
      if (metadata == null) {
        throw StateError('Content references media $sha256, but no media row exists');
      }
      referencedMedia[sha256] = metadata;
    }

    final changes = <LegacyBankContentChange>[];
    for (final id in orderedContentIds) {
      final fields = fieldsByContent[id];
      if (fields == null) {
        throw StateError('Referenced content $id does not exist');
      }
      changes.add(
        LegacyBankContentChange(
          changeType: 'add content',
          payload: {
            'content_id': _id(id),
            'fields': List<Map<String, Object?>>.unmodifiable(fields),
          },
        ),
      );
    }
    return _MappedContent(changes, UnmodifiableMapView(referencedMedia));
  }

  static Set<String> _mediaHashesInHtml(String html) {
    final fragment = html_parser.parseFragment(html);
    final hashes = <String>{};
    for (final element in fragment.querySelectorAll('[src], [poster]')) {
      for (final attribute in ['src', 'poster']) {
        final value = element.attributes[attribute];
        if (value == null || !value.startsWith('media://')) continue;
        final sha256 = value.substring('media://'.length);
        if (sha256.isEmpty) {
          throw const FormatException('HTML media reference has an empty SHA-256');
        }
        hashes.add(sha256);
      }
    }
    return hashes;
  }

  static int _compareChanges(
    LegacyBankContentChange left,
    LegacyBankContentChange right,
  ) {
    final typeOrder = _changeOrder(left.changeType).compareTo(
      _changeOrder(right.changeType),
    );
    if (typeOrder != 0) return typeOrder;
    final leftId = _entityId(left);
    final rightId = _entityId(right);
    if (left.changeType == 'add media') {
      return leftId.compareTo(rightId);
    }
    return int.parse(leftId).compareTo(int.parse(rightId));
  }

  static int _changeOrder(String type) => switch (type) {
    'add media' => 0,
    'add content' => 1,
    'add sentence' => 2,
    'add sentence group' => 3,
    'add exercise' => 4,
    _ => throw StateError('Unsupported generated change type "$type"'),
  };

  static String _entityId(LegacyBankContentChange change) => switch (change.changeType) {
    'add media' => change.payload['sha256'] as String,
    'add content' => change.payload['content_id'] as String,
    'add sentence' => change.payload['sentence_id'] as String,
    'add sentence group' => change.payload['sentence_group_id'] as String,
    'add exercise' => change.payload['exercise_id'] as String,
    _ => throw StateError('Unsupported generated change type "${change.changeType}"'),
  };

  static int _requiredInt(Object? value, String type, int exerciseId) {
    if (value is int) return value;
    throw StateError('Legacy $type exercise $exerciseId has no required content reference');
  }

  static String _id(int id) => id.toString();
}

final class _MappedContent {
  final List<LegacyBankContentChange> changes;
  final Map<String, Map<String, Object?>> mediaBySha;

  const _MappedContent(this.changes, this.mediaBySha);
}
