# Schéma cible de la base de données 0.3

Ce document décrit le schéma cible après séparation entre contenu de banque et
données utilisateur. La migration v3 crée déjà `learning_bank`, `bank_commit`
et `bank_change`, ainsi que l'index garantissant un changement au plus par
entité et par commit. Les autres transformations décrites ici constituent le
schéma cible de la 0.3 ; elles ne sont pas encore appliquées par une migration.
La conversion des lignes 0.2 est également à faire.

## Principes retenus

- `bank_commit.uid` est l'identité portable d'un état de banque. Il n'existe pas
  de `bank_uid` distinct.
- Le commit racine d'une banque fournie par Psitta a un UID stable fourni par
  la banque ; il ne doit pas être généré indépendamment sur chaque appareil.
- `learning_bank.id` est un identifiant local à la base utilisateur. La table
  liste les banques installées et pointe vers leur commit courant.
- Les définitions d'exercices, les textes, les phrases, les langues, la
  description, les paramètres par défaut et les opérations sur les médias sont
  des changements de banque. Leur état courant est résolu depuis la chaîne de
  commits.
- Les identifiants d'entité sont dans `payload_json`, sous une enveloppe
  `entity` contenant `type` et `id`. Un commit ne peut contenir qu'un changement
  par entité.
- `media` est un catalogue local des fichiers physiques. Le SHA-256 identifie
  le contenu binaire et permet de partager le même fichier entre exercices,
  commits et banques.
- La progression, le SRS, l'historique des réponses et les sessions sont des
  données utilisateur, séparées du contenu versionné.

## Tables de banques et de commits

### `learning_bank`

| Colonne | Rôle |
|---|---|
| `id INTEGER PRIMARY KEY` | Identifiant local de la banque installée |
| `head_commit_uid TEXT NOT NULL` | Commit qui définit l'état courant |

`head_commit_uid` référence `bank_commit(uid)`. Les langues et la description
ne sont pas des colonnes de cette table : elles sont des changements du commit
racine.

### `bank_commit`

| Colonne | Rôle |
|---|---|
| `uid TEXT PRIMARY KEY` | Identité portable du commit et de l'état qu'il représente |
| `parent_uid TEXT NULL` | Parent unique ; nul pour un commit racine |
| `is_frozen INTEGER NOT NULL` | `0` pour un brouillon modifiable, `1` pour un commit figé |

Un commit figé ne peut pas être modifié. Il reste supprimable lorsque la banque
et les commits qui en dépendent sont supprimés.

### `bank_change`

| Colonne | Rôle |
|---|---|
| `commit_uid TEXT NOT NULL` | Commit contenant ce changement |
| `change_id INTEGER NOT NULL` | Identifiant local au commit |
| `previous_commit_uid TEXT NULL` | Commit du changement précédent de la même entité |
| `previous_change_id INTEGER NULL` | Identifiant du changement précédent |
| `change_type TEXT NOT NULL` | Opération, par exemple ajout, remplacement ou retrait |
| `payload_json TEXT NOT NULL` | Entité modifiée et données de l'opération |

Clé primaire : `(commit_uid, change_id)`. `change_id` est un entier local au
commit, attribuable par exemple par `MAX(change_id) + 1` dans une transaction.
La paire précédente est soit entièrement nulle, soit entièrement renseignée et
référence une ligne de `bank_change`. La validation que ce précédent appartient
à un ancêtre du commit et concerne la même entité est faite par le résolveur
applicatif.

Le payload porte une enveloppe de ce type :

```json
{
  "entity": { "type": "exercise", "id": "word-0001" },
  "value": { }
}
```

L'opération (`add`, `update`, `remove`, etc.) est dans `change_type`, pas
dupliquée dans le payload. Un changement d'exercice contient sa définition et
son contenu : champs ordonnés, valeurs texte/HTML, groupe de phrases et phrases
instances. Les médias y sont référencés par SHA-256 ; leurs changements
d'ajout/retrait restent des entités distinctes de type `media`.

L'index unique `bank_change_entity_per_commit_idx` sur
`(commit_uid, json_extract(payload_json, '$.entity.type'),
json_extract(payload_json, '$.entity.id'))` interdit deux changements de la
même entité dans un commit. Le `CHECK` du payload impose une enveloppe objet et
des identifiants d'entité non vides de type texte. Les références
`previous_commit_uid`/`previous_change_id` garantissent l'existence du
changement précédent ; l'applicatif doit vérifier qu'il concerne la même
entité et que son commit est un ancêtre. Aucun CHECK/trigger SQLite simple ne
garantit cette règle sur le graphe récursif.

Le schéma ne peut pas garantir qu'un `learning_bank.head_commit_uid` est
atteignable depuis un parent racine valide, que les langues racines sont
présentes et immuables, ni qu'un snapshot de session appartient à la lignée de
sa banque : ces invariants nécessitent le service de banque. Une banque est
identifiée par son commit racine et ses descendants ; il n'existe ni UID de
banque distinct, ni table de merge ou de parent multiple.

## Catalogue de fichiers média

La table `media` reste une table locale de stockage, avec une ligne par contenu
binaire distinct :

| Colonne | Rôle |
|---|---|
| `id INTEGER PRIMARY KEY` | Clé locale utilisée par le stockage |
| `path TEXT NOT NULL` | Chemin local du fichier |
| `mime_type TEXT NOT NULL` | Type du fichier |
| `size INTEGER NOT NULL` | Taille en octets |
| `sha256 TEXT NOT NULL UNIQUE` | Identité du contenu binaire |

Les changements de banque ajoutent ou retirent une référence de média par son
SHA-256. Ils peuvent porter les métadonnées éditoriales propres à la banque.
Retirer un média de l'état courant ne supprime pas son fichier tant qu'un
historique conservé le référence. La vérification de collecte physique peut
être optimisée ultérieurement. Les payloads des changements médias et des
exercices peuvent répéter le SHA-256 : c'est une duplication de métadonnées de
référence, pas une duplication des octets du fichier.

Les DAO d'insertion devront rechercher/réutiliser la ligne existante par SHA-256
avant d'insérer. L'index unique seul ne réalise pas cette déduplication.

## Progression utilisateur

### `exercise_progress`

| Colonne | Rôle |
|---|---|
| `id INTEGER PRIMARY KEY` | Clé locale courte utilisée par les FK des données de progression |
| `learning_bank_id INTEGER NOT NULL` | Banque locale à laquelle appartient cette progression |
| `exercise_id TEXT NOT NULL` | Identifiant portable de l'exercice dans la banque |
| `active_commit_uid TEXT NOT NULL` | Commit contenant la définition actuellement suivie |
| `active_change_id INTEGER NOT NULL` | Changement définissant actuellement l'exercice |

Contrainte unique : `(learning_bank_id, exercise_id)`. La paire active référence
`bank_change(commit_uid, change_id)`. Une FK composite peut assurer l'existence
de ce changement, mais elle ne peut pas assurer que son payload décrit
l'exercice de `exercise_id`; le résolveur doit le valider. Cette ligne est
conservée lorsque la définition change ; ses pointeurs vers le changement
actif sont mis à jour afin de préserver la progression. Une suppression
d'exercice n'efface donc pas automatiquement sa progression ni son historique.

### `srs_state`

| Colonne | Rôle |
|---|---|
| `exercise_progress_id INTEGER PRIMARY KEY` | Progression concernée et FK vers `exercise_progress(id)` |
| `state INTEGER NOT NULL` | État FSRS |
| `step INTEGER NULL` | Étape d'apprentissage/réapprentissage |
| `stability REAL NULL` | Stabilité FSRS |
| `difficulty REAL NULL` | Difficulté FSRS |
| `due INTEGER NOT NULL` | Échéance |
| `last_review INTEGER NULL` | Date de la dernière révision |

### `exercise_history`

| Colonne | Rôle |
|---|---|
| `id INTEGER PRIMARY KEY` | Identifiant local de l'événement |
| `exercise_progress_id INTEGER NOT NULL` | Progression concernée |
| `sentence_id TEXT NULL` | Phrase concernée, identifiant stable dans l'exercice |
| `grade INTEGER NOT NULL` | Note FSRS enregistrée |
| `answered_at TEXT NOT NULL` | Date de réponse |
| `status INTEGER NOT NULL` | Statut de l'exercice au moment de la réponse |

FK vers `exercise_progress(id)` en cascade. `sentence_id` n'a pas de FK SQL
vers le contenu, car celui-ci est résolu depuis la chaîne de changements.

### `sentence_instance_progress`

Cette table remplace `sentence_state`, qui mélangeait l'identifiant du contenu
et sa progression utilisateur :

| Colonne | Rôle |
|---|---|
| `exercise_progress_id INTEGER NOT NULL` | Progression de l'exercice phrase |
| `sentence_id TEXT NOT NULL` | Identifiant de la phrase dans le contenu de l'exercice |
| `shown_count INTEGER NOT NULL` | Nombre d'affichages |
| `accumulated_score REAL NOT NULL` | Score de sélection accumulé |
| `is_in_learning INTEGER NOT NULL` | État d'apprentissage de cette phrase |

Clé primaire : `(exercise_progress_id, sentence_id)`.

## Sessions

### `session_result`

| Colonne | Rôle |
|---|---|
| `id INTEGER PRIMARY KEY` | Identifiant local du résultat/session |
| `session_type_index INTEGER NOT NULL` | Type de session |
| `number_unique_exercises_completed INTEGER NOT NULL` | Nombre d'exercices terminés |
| `total_time_spent_microseconds INTEGER NOT NULL DEFAULT 0` | Durée cumulée, ≥ 0 |
| `started_at TEXT NULL` | Date de début |
| `end_at TEXT NULL` | Date de fin ; nulle si active |
| `learning_bank_id INTEGER NOT NULL` | Banque locale de la session |
| `bank_commit_uid TEXT NOT NULL` | État précis de la banque utilisé au démarrage |

Le commit est enregistré comme instantané de la session : le pointeur de la
banque peut avancer après la session. `bank_commit_uid` référence
`bank_commit(uid)`, et `learning_bank_id` référence l'installation locale. Ces
deux FKs garantissent uniquement que la banque installée et le commit existent,
pas que le commit appartient à sa lignée ; cette vérification est applicative.
La suppression d'une installation supprime ses résultats et sessions en cours
par cascade. Un commit ne peut être supprimé que s'il n'est référencé ni comme
parent, ni par un pointeur de banque, ni par un résultat de session. Ses
changements sont supprimés avec lui ; l'immutabilité interdit de les modifier
tant que le commit existe.

### `active_session_exercise`

| Colonne | Rôle |
|---|---|
| `session_result_id INTEGER NOT NULL` | Session parente |
| `exercise_progress_id INTEGER NOT NULL` | Progression de l'exercice |
| `status_index INTEGER NOT NULL` | Statut d'avancement dans la session |
| `training_count INTEGER NULL` | Nombre restant pour l'entraînement de phrase |

Clé primaire `(session_result_id, exercise_progress_id)`. FKs vers
`session_result(id)` et `exercise_progress(id)`, en cascade.

`session_result_status_count` conserve les colonnes `id_session_result INTEGER
NOT NULL`, `status_index INTEGER NOT NULL` et
`number_exercise_completed INTEGER NOT NULL`, la clé primaire
`(id_session_result, status_index)` et la FK cascade vers `session_result(id)`.

Pour `exercise_progress`, `srs_state`, `exercise_history` et
`sentence_instance_progress`, la suppression de la progression supprime les
données utilisateur dépendantes. La suppression d'une session supprime son
instantané d'exercices et ses compteurs, sans supprimer la progression elle-
même.

## Paramètres

`app_setting(key, value)` reste le stockage des paramètres globaux de
l'application, par exemple le thème et les statistiques globales. Les
paramètres propres à une banque sont des entités `setting` dans `bank_change`.
En 0.3, il n'y a qu'un profil par défaut ; le bouton de réinitialisation retire
les changements de ce profil dans le commit brouillon.

## Tables de contenu à retirer après conversion

Ces tables ne sont plus des sources de vérité dans le schéma cible ; leurs
contenus seront représentés par les changements de banque :

- `exercise`, `word_exercise`, `sentence_exercise`, `character_exercise` ;
- `content`, `field_definition`, `field_value` ;
- `sentence_group`, `sentence_instance`.

`sentence_state` est remplacée par `sentence_instance_progress`. `srs_state`,
`exercise_history`, `active_session_exercise` et `session_result` sont
conservées avec les nouvelles références décrites plus haut.

## Points à vérifier dans l'implémentation

1. L'importeur 0.2 perd les identifiants `exercise_id` des fichiers source et
   stocke des identifiants SQLite auto-incrémentés. La migration doit établir
   explicitement une correspondance portable avant de remplir
   `exercise_progress`.
2. Les anciennes lignes de `session_result` doivent être rattachées à la banque
   et au commit initial sans perdre les résultats ni les sessions en cours.
3. Le backup/restauration doit conserver commits figés, références aux commits
   précédents et progressions, y compris lors d'une restauration atomique.
4. Les insertions de média doivent être dédupliquées par SHA-256 dans les DAO.
