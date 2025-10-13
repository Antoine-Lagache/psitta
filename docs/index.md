# 🧭 Documentation interne du projet

Ce dossier contient la documentation technique de l’application d’apprentissage des langues développée en Flutter/Dart.  
Il complète le fichier [README.md](../README.md) à la racine, qui décrit le projet dans ses grandes lignes.

---

## 🔗 Navigation

- [models/](models/index.md) — classes principales (Note, Card, Exercice, SRS…)
- [playground/](playground/index.md) — tests et expérimentations
- [screens/](screens/index.md) — interfaces utilisateur et logique de navigation
- [services/](services/index.md) — gestion base de donnée et utilitaires
- [main.dart](main.md) — point d’entrée de l’application

---

## 🧩 Structure générale

Organisation des principaux dossiers :

```
lib/
├── models/          → Définitions des entités : Note, Card, Exercice, SRSState, etc
├── playground/      → Tests et expérimentations
├── screens/         → Interfaces utilisateur et logique de navigation
├── services/        → Accès à la base de données (SQLite) et utilitaires
└── main.dart        → Point d’entrée de l’application
```

---

## 🧩 Aperçu technique

### 🔹 Base de données SQLite
- Tables : `notes`, `card_templates`, `cards`, `exercices`, `word_exercices`, `srs_states`, `srs_configs`.  
- Fonctions CRUD : `services/database_service.dart`  
- Conversions communes : `services/convert_utils.dart` (JSON, durée, booléens, dates…)

### 🔹 Système SRS
- Inspiré de l'algorithme **SM-2**.  
- Chaque `Exercice` est lié à un `SRSState` contenant des paramètre comme: easeFactor, intervalle, etc. 
- Paramètres ajustables stockés dans `SRSConfig`  
- Objectif : planifier les révisions selon la performance de l’utilisateur

---

## 🔗 Liens utiles

Ressources officielles et documentations recommandées :

- **Dart** : [https://dart.dev/guides](https://dart.dev/guides)
- **Flutter** : [https://flutter.dev/docs](https://flutter.dev/docs)
- **sqflite (SQLite pour Flutter)** : [https://pub.dev/packages/sqflite](https://pub.dev/packages/sqflite)
- **JSON et encodage/décodage** : [https://api.dart.dev/stable/dart-convert/dart-convert-library.html](https://api.dart.dev/stable/dart-convert/dart-convert-library.html)
- **Documentation Flutter (widgets)** : [https://api.flutter.dev/flutter/widgets/widgets-library.html](https://api.flutter.dev/flutter/widgets/widgets-library.html)

---

_Fichier : `docs/index.md` – version actuelle de la documentation interne._
