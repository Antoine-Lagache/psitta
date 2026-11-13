-- Target schema for Psitta 0.3, after the legacy content tables have been
-- converted and removed. This is a schema specification, not a migration script
-- to run over an existing 0.2 database.

CREATE TABLE bank_commit (
  uid TEXT PRIMARY KEY NOT NULL,
  parent_uid TEXT,
  is_frozen INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (parent_uid) REFERENCES bank_commit(uid)
);

CREATE TABLE bank_change (
  commit_uid TEXT NOT NULL,
  change_id INTEGER NOT NULL,
  previous_commit_uid TEXT,
  previous_change_id INTEGER,
  change_type TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  PRIMARY KEY (commit_uid, change_id),
  FOREIGN KEY (commit_uid) REFERENCES bank_commit(uid) ON DELETE CASCADE,
  FOREIGN KEY (previous_commit_uid, previous_change_id)
    REFERENCES bank_change(commit_uid, change_id)
);

CREATE INDEX bank_change_previous_ref_idx
  ON bank_change(previous_commit_uid, previous_change_id);

CREATE TABLE learning_bank (
  id INTEGER PRIMARY KEY,
  head_commit_uid TEXT NOT NULL,
  FOREIGN KEY (head_commit_uid) REFERENCES bank_commit(uid) ON DELETE RESTRICT
);

CREATE TABLE media (
  id INTEGER PRIMARY KEY,
  path TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size INTEGER NOT NULL,
  sha256 TEXT NOT NULL UNIQUE
);

CREATE TABLE exercise_progress (
  id INTEGER PRIMARY KEY,
  learning_bank_id INTEGER NOT NULL,
  exercise_id TEXT NOT NULL,
  active_commit_uid TEXT NOT NULL,
  active_change_id INTEGER NOT NULL,
  UNIQUE (learning_bank_id, exercise_id),
  FOREIGN KEY (learning_bank_id) REFERENCES learning_bank(id) ON DELETE CASCADE,
  FOREIGN KEY (active_commit_uid, active_change_id)
    REFERENCES bank_change(commit_uid, change_id) ON DELETE RESTRICT
);

CREATE TABLE srs_state (
  exercise_progress_id INTEGER PRIMARY KEY,
  state INTEGER NOT NULL,
  step INTEGER,
  stability REAL,
  difficulty REAL,
  due INTEGER NOT NULL,
  last_review INTEGER,
  FOREIGN KEY (exercise_progress_id)
    REFERENCES exercise_progress(id) ON DELETE CASCADE
);

CREATE TABLE exercise_history (
  id INTEGER PRIMARY KEY,
  exercise_progress_id INTEGER NOT NULL,
  sentence_id TEXT,
  grade INTEGER NOT NULL,
  answered_at TEXT NOT NULL,
  status INTEGER NOT NULL,
  FOREIGN KEY (exercise_progress_id)
    REFERENCES exercise_progress(id) ON DELETE CASCADE
);

CREATE TABLE sentence_instance_progress (
  exercise_progress_id INTEGER NOT NULL,
  sentence_id TEXT NOT NULL,
  shown_count INTEGER NOT NULL,
  accumulated_score REAL NOT NULL,
  is_in_learning INTEGER NOT NULL,
  PRIMARY KEY (exercise_progress_id, sentence_id),
  FOREIGN KEY (exercise_progress_id)
    REFERENCES exercise_progress(id) ON DELETE CASCADE
);

CREATE TABLE session_result (
  id INTEGER PRIMARY KEY,
  session_type_index INTEGER NOT NULL,
  number_unique_exercises_completed INTEGER NOT NULL,
  total_time_spent_microseconds INTEGER NOT NULL DEFAULT 0,
  started_at TEXT,
  end_at TEXT,
  learning_bank_id INTEGER NOT NULL,
  bank_commit_uid TEXT NOT NULL,
  FOREIGN KEY (learning_bank_id) REFERENCES learning_bank(id) ON DELETE CASCADE,
  FOREIGN KEY (bank_commit_uid) REFERENCES bank_commit(uid) ON DELETE RESTRICT
);

CREATE TABLE session_result_status_count (
  id_session_result INTEGER NOT NULL,
  status_index INTEGER NOT NULL,
  number_exercise_completed INTEGER NOT NULL,
  PRIMARY KEY (id_session_result, status_index),
  FOREIGN KEY (id_session_result)
    REFERENCES session_result(id) ON DELETE CASCADE
);

CREATE TABLE active_session_exercise (
  session_result_id INTEGER NOT NULL,
  exercise_progress_id INTEGER NOT NULL,
  status_index INTEGER NOT NULL,
  training_count INTEGER,
  PRIMARY KEY (session_result_id, exercise_progress_id),
  FOREIGN KEY (session_result_id) REFERENCES session_result(id) ON DELETE CASCADE,
  FOREIGN KEY (exercise_progress_id)
    REFERENCES exercise_progress(id) ON DELETE CASCADE
);

CREATE TABLE app_setting (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
