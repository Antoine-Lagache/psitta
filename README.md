# 📘 Flutter App Langue


Application Flutter d’apprentissage des langues basée sur un algorithme de répétition espacée (SRS).
Ce projet sert à la fois de terrain d’apprentissage pour **Dart/Flutter** et de base pour une application complète d’étude de vocabulaire et de révision intelligente.

---

## 🚀 Objectifs

- Créer une application Flutter multi-plateformes (Android, iOS, Web, Desktop).
- Implémenter un système de répétition espacée (Spaced Repetition System) inspiré d’Anki/SM-2.
- Construire une architecture modulaire et extensible avec une base de données SQLite.
- Appliquer les bonnes pratiques de conception logicielle (clean architecture, séparation des couches, code testable).

---

## 🧩 Architecture générale

L’application est divisée en plusieurs couches :

- [models/](flutter_project/lib/models/) $\rightarrow$ définitions des objets métier (`Note`, `Card`, `Exercice`, `SRSState`, `SRSConfig`, etc.)
- [services/](flutter_project/lib/services) $\rightarrow$  logique d’accès aux données et conversions
- [screens/](flutter_project/lib/screen/) $\rightarrow$  interfaces utilisateur (HomeScreen, StatisticScreen, SettingScreen)
- [playground/](flutter_project/lib/playground) $\rightarrow$  fichiers de test et d’expérimentation
- Les détails complets se trouvent dans [STRUCTURE.md](STRUCTURE.md)

---
## 🧠 Fonctionnement SRS

Chaque exercice est associé à un `SRSState` :

- l'algorithme utilisé est inspiré de l'algorithme SM-2 utilisé par Anki.
- l' algorithme se base sur la formule: $P(t) = (1-\omega) exp(-k t) + \omega$ avec $P(I) = R^*$.
  - $k$ correspond à la mémoire court terme est est un paramètre utilisé par SM-2
  - $\omega$ noté aussi $w$ correspond au poid de la mémoire long terme
- `SRSConfig` définit définit des paramètres globaux alors que `SRSState` définit des paramètres qui varie à chaque session.

Plus de détail dans [STRUCTURE.md](STRUCTURE.md)

---

## 🗄️ Base de données SQLite

- Tables : notes, card_templates, cards, exercices, word_exercices, srs_states, srs_configs  
- Relations avec FOREIGN KEY et ON DELETE CASCADE  
- Conversions robustes : DateTime ↔ TEXT, Duration ↔ INTEGER, Map/List ↔ JSON  
- Chaque modèle a toMap/fromMap pour la conversion objet ↔ base

---

## ⚙️ État actuel (MVP) - chronologie

1. Modèles métier définis : Note, CardTemplate, Card, Exercice, WordExercice, SRSState, SRSConfig  
2. Fonctions utilitaires de conversion dans convert_utils.dart  
3. Base SQLite créée avec toutes les tables et relations  
4. Méthodes toMap/fromMap implémentées pour tous les modèles  
5. CRUD complet pour chaque table, transactions pour WordExercice et SRSState  
6. Requêtes optimisées avec jointures pour reconstruire les objets complexes  
7. Gestion uniforme des dates (UTC) et durées (millisecondes)  
8. Tests manuels et vérification de cohérence

---

## 📈 Étapes suivantes

- Logique complète de session et enchaînement des exercices  
- Statistiques et résumé de session  
- Interface utilisateur finale  
- Tests unitaires pour toutes les fonctionnalités


---
## Progrès:
voir le fichier [STRUCTURE.md](STRUCTURE.md) pour la structure du projet



## ✅ Avancement

Voir le fichier [PLAN.md](PLAN.md) pour la liste détaillée des objectifs.  
