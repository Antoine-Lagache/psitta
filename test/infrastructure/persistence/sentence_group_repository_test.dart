import 'package:psitta/infrastructure/persistence/repositories/sentence_group_repository.dart';
import 'package:sqlite_async/sqlite_async.dart' as sqlite;
import 'package:test/test.dart';

import 'support/persistence_test_database.dart';

void main() {
  late PersistenceTestDatabase testDatabase;
  late sqlite.SqliteDatabase database;
  late SentenceGroupRepository repository;

  setUp(() async {
    testDatabase = await PersistenceTestDatabase.create();
    database = testDatabase.database;
    repository = SentenceGroupRepository(database);
  });

  tearDown(() => testDatabase.dispose());

  group('SentenceGroupRepository', () {
    test('creates an instance with its initial sentence state', () async {
      final groupId = await repository.createGroup();
      final contentId = await testDatabase.insertContent();

      final instanceId = await repository.createInstance(groupId, contentId);

      final rows = await database.readTransaction(
        (transaction) => transaction.getAll(
          '''
          SELECT
            si.sentence_group_id,
            si.content_id,
            ss.shown_count,
            ss.accumulated_score,
            ss.is_in_learning
          FROM sentence_instance si
          JOIN sentence_state ss ON ss.sentence_instance_id = si.id
          WHERE si.id = ?
          ''',
          [instanceId],
        ),
      );
      expect(rows, hasLength(1));
      expect(rows.single['sentence_group_id'], groupId);
      expect(rows.single['content_id'], contentId);
      expect(rows.single['shown_count'], 0);
      expect(rows.single['accumulated_score'], 0.0);
      expect(rows.single['is_in_learning'], 0);
    });

    test('moves an instance while preserving its state', () async {
      final sourceGroupId = await repository.createGroup();
      final targetGroupId = await repository.createGroup();
      final instanceId = await repository.createInstance(
        sourceGroupId,
        await testDatabase.insertContent(),
      );
      await database.execute(
        '''
        UPDATE sentence_state
        SET shown_count = 3, accumulated_score = 2.4, is_in_learning = 1
        WHERE sentence_instance_id = ?
        ''',
        [instanceId],
      );

      await repository.moveSentenceInstance(instanceId, targetGroupId);

      final rows = await database.readTransaction(
        (transaction) => transaction.getAll(
          '''
          SELECT
            si.sentence_group_id,
            ss.shown_count,
            ss.accumulated_score,
            ss.is_in_learning
          FROM sentence_instance si
          JOIN sentence_state ss ON ss.sentence_instance_id = si.id
          WHERE si.id = ?
          ''',
          [instanceId],
        ),
      );
      expect(rows.single['sentence_group_id'], targetGroupId);
      expect(rows.single['shown_count'], 3);
      expect(rows.single['accumulated_score'], 2.4);
      expect(rows.single['is_in_learning'], 1);
    });

    test('deleting an instance cascades to its sentence state', () async {
      final groupId = await repository.createGroup();
      final instanceId = await repository.createInstance(
        groupId,
        await testDatabase.insertContent(),
      );

      await repository.deleteSentenceInstance(instanceId);

      expect(await testDatabase.countRows('sentence_instance'), 0);
      expect(await testDatabase.countRows('sentence_state'), 0);
      expect(await testDatabase.countRows('sentence_group'), 1);
    });

    test('deleting a group cascades to instances and sentence states', () async {
      final groupId = await repository.createGroup();
      await repository.createInstance(groupId, await testDatabase.insertContent());

      await repository.deleteSentenceGroup(groupId);

      expect(await testDatabase.countRows('sentence_group'), 0);
      expect(await testDatabase.countRows('sentence_instance'), 0);
      expect(await testDatabase.countRows('sentence_state'), 0);
    });

    test('rejects instances and moves targeting a missing group', () async {
      final contentId = await testDatabase.insertContent();
      await expectLater(
        repository.createInstance(999, contentId),
        throwsA(isA<StateError>()),
      );

      final groupId = await repository.createGroup();
      final instanceId = await repository.createInstance(groupId, contentId);
      await expectLater(
        repository.moveSentenceInstance(instanceId, 999),
        throwsA(isA<StateError>()),
      );
    });
  });
}
