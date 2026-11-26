import 'dart:convert';

import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/infrastructure/persistence/dao/bank_change_dao.dart';
import 'package:psitta/infrastructure/persistence/mappers/legacy_bank_content_mapper.dart';
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase db;
  const mapper = LegacyBankContentMapper();
  final uid = CommitUid('test-release-root');
  final hash = List.filled(64, 'a').join();

  setUp(() async {
    db = await PersistenceTestDatabase.create();
    await db.database.writeTransaction((tx) async {
      await tx.execute('INSERT INTO content (id) VALUES (1), (2), (3)');
      await tx.execute("INSERT INTO exercise (id, type) VALUES (1, 'word')");
      await tx.execute("INSERT INTO exercise (id, type) VALUES (2, 'sentence')");
      await tx.execute("INSERT INTO exercise (id, type) VALUES (3, 'character')");
      await tx.execute('INSERT INTO word_exercise VALUES (1, 1)');
      await tx.execute('INSERT INTO sentence_group VALUES (1)');
      await tx.execute('INSERT INTO sentence_exercise VALUES (2, 1)');
      await tx.execute('INSERT INTO sentence_instance VALUES (1, 1, 2)');
      await tx.execute('INSERT INTO character_exercise VALUES (3, 3)');
      await tx.execute("INSERT INTO field_definition VALUES (1, 'html', 'front')");
      await tx.execute('INSERT INTO media VALUES (1, ?, ?, ?, ?)', [
        'local/audio.ogg',
        'audio/ogg',
        123,
        hash,
      ]);
      await tx.execute('INSERT INTO field_value VALUES (1, 1, 1, ?, NULL, 0)', [
        '<audio src="psitta://media/$hash"></audio>',
      ]);
      await tx.execute("INSERT INTO field_value VALUES (2, 2, 1, 'sentence', NULL, 0)");
      await tx.execute("INSERT INTO field_value VALUES (3, 3, 1, 'kana', NULL, 0)");
    });
  });

  tearDown(() => db.dispose());

  test('root conversion is deterministic and excludes user settings', () async {
    Future<List<String>> convert(Map<String, Object> settings) {
      return db.database.writeTransaction((tx) async {
        final root = await mapper.mapRootCommit(
          tx,
          commitUid: uid,
          sourceLanguage: 'en',
          targetLanguage: 'ja',
          description: 'Japanese',
          defaultSettings: settings,
        );
        expect(root.commit.uid, uid);
        expect(root.commit.parentUid, isNull);
        expect(root.commit.isFrozen, isTrue);
        expect(
          root.changes.map((change) => change.ref.changeId),
          orderedEquals(List.generate(root.changes.length, (index) => index)),
        );
        expect(
          root.changes.where((change) => change.changeType == 'add media'),
          hasLength(1),
        );
        return root.changes.map((change) => jsonEncode(change.payload)).toList();
      });
    }

    final first = await convert({'b': true, 'a': 4});
    await db.database.execute("INSERT INTO app_setting VALUES ('theme', 'dark')");
    await db.database.execute("UPDATE media SET path = '/another/location/audio.ogg'");
    expect(await convert({'a': 4, 'b': true}), first);
    expect(first, hasLength(13));
  });

  test('root and changes can be persisted together', () async {
    await db.database.writeTransaction((tx) async {
      final root = await mapper.mapRootCommit(
        tx,
        commitUid: uid,
        sourceLanguage: 'en',
        targetLanguage: 'ja',
        description: 'Japanese',
        defaultSettings: {'limit': 4},
      );
      await BankChangeDao().insertCommit(tx, commit: root.commit, changes: root.changes);
      expect(
        root.changes.where((change) => change.changeType == 'add exercise'),
        hasLength(3),
      );
    });
    expect(await db.countRows('bank_commit'), 1);
    expect(await db.countRows('bank_change'), 12);
    expect(await db.database.getAll('PRAGMA foreign_key_check'), isEmpty);
  });

  test('snapshot references target exact changes with integer entity IDs', () async {
    final changes = await db.database.writeTransaction(
      (tx) => mapper.mapDomainChanges(tx, commitUid: uid),
    );
    final byId = {for (final change in changes) change.ref.changeId: change};
    void verify(Object? value, String type, String key, int id) {
      final ref = value as Map;
      expect(ref['commit_uid'], uid.value);
      final target = byId[ref['change_id']];
      expect(target?.changeType, type);
      expect(target?.payload[key], id);
    }

    for (final change in changes) {
      final payload = change.payload;
      expect(payload.containsKey('commit_uid'), isFalse);
      expect(payload.containsKey('change_id'), isFalse);
      switch (change.changeType) {
        case 'add exercise':
          final id = payload['exercise_id'] as int;
          expect(payload['priority_order'], id);
          if (payload['exercise_type'] == 'sentence') {
            verify(payload['sentence_group_ref'], 'add sentence group', 'sentence_group_id', 1);
          } else {
            verify(payload['content_ref'], 'add content', 'content_id', id);
          }
          break;
        case 'add sentence':
          expect(payload['sentence_id'], 1);
          verify(payload['content_ref'], 'add content', 'content_id', 2);
          break;
        case 'add sentence group':
          expect(payload['sentence_group_id'], 1);
          final refs = payload['sentence_refs'] as List;
          expect(refs, hasLength(1));
          verify(refs.single, 'add sentence', 'sentence_id', 1);
          break;
        case 'add content':
          expect(payload['content_id'], isA<int>());
          break;
      }
    }
  });

  test('missing HTML media fails conversion', () async {
    await db.database.execute('DELETE FROM media');
    await expectLater(
      db.database.writeTransaction((tx) => mapper.mapDomainChanges(tx, commitUid: uid)),
      throwsStateError,
    );
  });
}
