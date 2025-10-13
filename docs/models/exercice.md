[⬅️ Retour à la documentation Models](index.md) | [💾 Voir le code source](../../lib/models/exercice.dart)

# 🧩 `models/exercice.dart`

## 🎯 Rôle du fichier
Ce module définit la structure des **exercices** utilisés par le système de répétition espacée (**SRS**).  
Chaque exercice combine une **carte** (`Card`), un **état SRS** (`SRSState`) et des métadonnées comme la disponibilité (`availableAt`).  
Il fait le lien entre la logique d’apprentissage, la base de données, et les sessions de révision.

---

## 🔗 Dépendances
```dart
import '../services/convert_utils.dart';
import 'srs.dart';
import 'note.dart';
```

- `convert_utils.dart` — fournit les fonctions de conversion (dates, int, JSON, etc.).  
- `srs.dart` — définit la logique et les paramètres du système de répétition espacée.  
- `note.dart` — contient les classes `Note`, `CardTemplate`, et `Card` utilisées par les exercices.

---

## 🧩 Contenu principal

### `enum ExerciceType`
```dart
enum ExerciceType { word }
```
- `word` — exercice basé sur les cartes de vocabulaire.  
> (Des types futurs pourront être ajoutés : `sentence`, `grammar`, `listening`, etc.)

#### Fonctions associées :
- `exerciceTypeToText(ExerciceType type)` → convertit un type en chaîne (`"word"`).  
- `exerciceTypeFromText(String? text)` → conversion inverse (avec fallback par défaut sur `word`).

---

### `abstract class Exercice`
Classe de base pour tous les exercices, quelle que soit leur nature.

#### **Propriétés :**
- `int? id` — identifiant unique dans la base SQLite.  
- `ExerciceType type` — type d’exercice.  
- `SRSState srsData` — données du système de répétition (easeFactor, intervalle, etc.).  
- `DateTime? availableAt` — date à partir de laquelle l’exercice redevient disponible.

#### **Méthodes :**
- `Map<String, dynamic> toMap()` — sérialisation commune pour stockage en base.

---

### `class WordExercice extends Exercice`
Représente un **exercice de vocabulaire** lié à une `Card`.

**Propriétés supplémentaires :**
- `Card card` — carte associée (contenant le contenu linguistique et le modèle HTML).

**Méthodes :**
- `toMap()` — encode l’objet pour insertion SQLite (`id`, `type`, `available_at`, `card_id`).  
- `fromMap()` — recrée un `WordExercice` depuis les données SQL, en reconstruisant sa `Card` et son `SRSState`.

---

## 📘 Résumé
`exercice.dart` définit la structure générique des tâches d’apprentissage.  
Il s’agit du **point d’entrée logique** entre :
- la base de données (`services/database_service.dart`),
- la logique de répétition (`models/srs.dart`),
- et les entités de contenu (`models/note.dart`).

Ce module est central pour tout le fonctionnement des **sessions de révision**.
