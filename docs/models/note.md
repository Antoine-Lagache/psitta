[⬅️ Retour à la documentation Models](index.md) | [💾 Voir le code source](../../lib/models/note.dart)

# 🧩 `models/note.dart`

## 🎯 Rôle du fichier
Ce module définit les entités de **contenu linguistique** manipulées dans l’application :  
- `Note` : le contenu brut (mots, phrases, définitions, etc.)  
- `CardTemplate` : la structure d’affichage HTML d’une carte  
- `Card` : la combinaison d’une `Note` et d’un `CardTemplate` utilisée pour créer un exercice.  

Ces classes constituent la **base de données de connaissance** de l’utilisateur.

---

## 🔗 Dépendances
```dart
import '../services/convert_utils.dart';
```

- `convert_utils.dart` — contient les fonctions de sérialisation et de conversion (`safeJsonEncode`, `safeToInt`, `toIsoUtc`, etc.).

---

## 🧩 Contenu principal

### `class Note`
Représente une **unité de connaissance** (ex : un mot, une phrase, ou une expression).  
Les `Note` sont stockées dans la table `notes` de la base SQLite.

#### **Propriétés :**
- `int? id` — identifiant unique (auto-incrémenté).  
- `Map<String, dynamic> data` — contenu flexible encodé en JSON (ex : `{"front": "cat", "back": "chat"}`).  
- `List<String> tags` — étiquettes associées à la note (`["animal", "anglais"]`).  
- `DateTime createdTime` — date de création.

#### **Méthodes :**
- `toMap()` — conversion vers un format SQL (encodage JSON + ISO8601).  
- `fromMap()` — reconstitution d’un objet `Note` depuis une ligne SQLite.

---

### `class CardTemplate`
Définit la **présentation HTML** utilisée pour afficher une carte.  
Stockée dans la table `card_templates`.

#### **Propriétés :**
- `int? id` — identifiant unique.  
- `String rectoHtml` — code HTML du recto.  
- `String versoHtml` — code HTML du verso.

#### **Méthodes :**
- `toMap()` — conversion pour stockage.  
- `fromMap()` — reconstruction à partir d’une ligne SQL.

> 🧠 Une même `CardTemplate` peut être utilisée par plusieurs `Card`.

---

### `class Card`
Fait le lien entre une `Note` (le contenu) et un `CardTemplate` (la forme).  
Chaque `Card` représente une carte d’apprentissage unique, liée à un ou plusieurs exercices.

#### **Propriétés :**
- `int? id` — identifiant unique.  
- `Note note` — contenu linguistique associé.  
- `CardTemplate template` — modèle HTML utilisé pour l’affichage.

#### **Méthodes :**
- `toMap()` — sérialisation pour insertion SQL (`note_id`, `template_id`).  
- `fromMap()` — création depuis la base, en reliant la note et le template correspondants.

---

## 🧠 Relations entre classes
```text
Note 1 ──< Card >── 1 CardTemplate
         \
          → WordExercice (dans exercice.dart)
```

Chaque **Note** peut générer plusieurs **Card**, chacune basée sur un **CardTemplate** différent (ex : recto = mot, verso = définition ou inversement).  
Ces cartes deviennent ensuite des **exercices** (`WordExercice`).

---

## 📘 Résumé
Le fichier `note.dart` décrit les **éléments de base de la connaissance** :
- `Note` stocke le contenu et ses tags  
- `CardTemplate` définit la forme d’affichage  
- `Card` relie les deux pour former une carte d’étude  

Ces classes sont au cœur du système d’apprentissage : elles alimentent les exercices (`WordExercice`) et la base SQLite.
