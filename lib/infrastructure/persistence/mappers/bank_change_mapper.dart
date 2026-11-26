import 'dart:convert';

import 'package:psitta/domain/identity/entity_id.dart';
import 'package:psitta/domain/learning_bank/bank_change.dart';

/// Translates change references and JSON snapshots without interpreting content.
class BankChangeMapper {
  const BankChangeMapper();

  static Map<String, Object?> toPersistence(BankChange domain) => {
    'commit_uid': domain.ref.commitUid.value,
    'change_id': domain.ref.changeId,
    'previous_commit_uid': domain.previousChangeRef?.commitUid.value,
    'previous_change_id': domain.previousChangeRef?.changeId,
    'change_type': domain.changeType,
    'payload_json': jsonEncode(domain.payload),
  };

  static BankChange toDomain(Map<String, Object?> row) {
    final previousUid = row['previous_commit_uid'] as String?;
    final previousId = row['previous_change_id'] as int?;
    if ((previousUid == null) != (previousId == null)) {
      throw StateError('Incomplete previous change reference');
    }
    return BankChange(
      ref: BankChangeRef(
        commitUid: CommitUid(row['commit_uid'] as String),
        changeId: row['change_id'] as int,
      ),
      previousChangeRef: previousUid == null
          ? null
          : BankChangeRef(commitUid: CommitUid(previousUid), changeId: previousId!),
      changeType: row['change_type'] as String,
      payload: jsonDecode(row['payload_json'] as String) as Map<String, Object?>,
    );
  }
}
