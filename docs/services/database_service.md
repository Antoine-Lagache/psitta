[⬅️ Retour à l’index des services](index.md) | [💾 Voir le code source](../../lib/services/database_service.dart)

# 🗄️ `database_service.dart`

## 🎯 Rôle du fichier
Gère **l’intégralité des interactions SQLite** de l’application.  
C’est le cœur de la **persistance locale** : toutes les entités (`Note`, `Card`, `Exercice`, `SRSState`, etc.) y sont créées, lues, mises à jour et supprimées.

Implémentation via le package Flutter `sqflite`.

>   [`schema_bd.md`](./schema_db.md) — Explication et détail sur le schéma de la base de donnée

---

## 🔗 Dépendances
```dart
import 'package:sqflite/sqflite.dart';
import '../models/note.dart';
import '../models/exercice.dart';
import '../models/srs.dart';
import 'convert_utils.dart';
```

---

## 🧩 Classe principale

### `class DatabaseService`

Singleton garantissant une seule instance active de la base de données :

```dart
static final DatabaseService instance = DatabaseService._init();
```

### ⚙️ Initialisation

* Ouverture automatique de `app.db` (création si inexistante).
* Activation des **clés étrangères** SQLite via `PRAGMA foreign_keys = ON`.
* Appelle `initDB` lors de la première création.

---

## 🗂️ Tables créées

| Table            | Description                                          | Relation                            |
| ---------------- | ---------------------------------------------------- | ----------------------------------- |
| `notes`          | Contient le texte brut, tags, et date de création.   | —                                   |
| `card_templates` | Modèles HTML (recto/verso).                          | —                                   |
| `cards`          | Lien entre une note et un template.                  | n:1 vers `notes` & `card_templates` |
| `exercices`      | Contient le type et la disponibilité.                | 1:1 avec `word_exercices`           |
| `word_exercices` | Associe une carte à un exercice.                     | 1:1 avec `exercices`                |
| `srs_states`     | Stocke les paramètres SRS pour chaque exercice.      | 1:1 avec `exercices`                |
| `srs_configs`    | Contient les configurations globales du système SRS. | —                                   |

---

## 📦 Méthodes CRUD par entité

### Notes

* `insertNote`, `getNoteById`, `getAllNotes`, `updateNote`, `deleteNote`

### CardTemplate

* `insertCardTemplate`, `getCardTemplateById`, `getAllCardTemplates`, `updateCardTemplate`, `deleteCardTemplate`

### Card

* `insertCard`, `getCardById`, `getCardsByNoteId`, `updateCard`, `deleteCard`

### WordExercice

* `insertWordExercice`, `getWordExerciceById`, `getAllWordExercices`, `getDueExercices`, `updateWordExercice`, `deleteWordExercice`

### SRSState

* `insertSrsState`, `getSrsStateByExerciceId`, `updateSrsState`, `deleteSrsState`

### SRSConfig

* `insertSrsConfig`, `getSrsConfigById`, `getAllSrsConfigs`, `updateSrsConfig`, `deleteSrsConfig`

---

## 🧱 Particularités techniques

* **Transactions SQLite** utilisées pour les insertions complexes (ex. WordExercice + SRSState).
* **Jointures SQL (`JOIN`)** pour reconstituer les objets complets en une seule requête.
* **Sécurité** : toute erreur de parsing passe par `convert_utils`.

---

## 🧩 Exemple simplifié : insertion complète

```dart
final note = Note(data: {'front': 'dog', 'back': 'chien'});
final template = CardTemplate(null, '{{front}}', '{{back}}');
final card = Card(null, note, template);
final srs = SRSState();
final exo = WordExercice(card: card, srsData: srs);

final db = DatabaseService.instance;
await db.insertWordExercice(exo);
```

---

*Fichier : `docs/services/database_service.md`*
