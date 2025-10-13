[🏠 Retour à la documentation principale](../index.md) | [💾 Voir le code source](../../lib/models/)

# 📁 Documentation — Models

Ce dossier contient la documentation des fichiers situés dans `lib/models/`.  
Chaque fichier `.md` décrit les classes, méthodes et structures de données du fichier Dart correspondant.

---

## 📚 Contenu


- [exercice.md](exercice.md) — classes `Exercice`, `WordExercice` et type `ExerciceType`
- [note.md](note.md) — classe `Note`, `CardTemplate` et `Card` et gestion du contenu linguistique
- [session.md](session.md) — classe `Session` et logique d’organisation et de progression des sessions d’étude
- [srs.md](srs.md) — classes `SRSState` et `SRSConfig`, paramètres et états du système SRS
  - [maths_srs.md](maths_srs.md) — information sur l'algorithme SRS utilisé


---

## 🧩 Rôle général du module

Le dossier `models/` regroupe **l’ensemble des entités métier** de l’application.  
Il définit toutes les structures manipulées par la logique d’apprentissage :
- les notes et cartes utilisées dans les exercices,  
- les états de révision gérés par le système SRS,  
- la configuration et le suivi des sessions d’étude.

Ce module constitue le **cœur logique** de l’application :  
il décrit *ce que l’application manipule* (les données et leur structure),  

---

## 🔗 Relations entre les classes

- Une **`Card`** relie une `Note` (contenu) et un `CardTemplate` (présentation).  
- Une **`Note`** peut être utilisée dans plusieurs **`Card`** (ex : français → anglais, anglais → français).  
- Un **`CardTemplate`** peut servir à plusieurs cartes différentes.  
- Un **`WordExercice`** associe une **`Card`** et un **`SRSState`**, qui gère sa progression.
- Un **`SRSState`** correspond toujours à un unique **`Exercice`**
- Le **`SRSConfig`** définit les paramètres globaux de l’algorithme SRS pour toutes les cartes.  

---

_Fichier : `docs/models/index.md`_