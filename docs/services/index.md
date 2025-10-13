[🏠 Retour à la documentation principale](../index.md) | [💾 Voir le code source](../../lib/services/)

# 🧰 Dossier `services/`

Ce dossier contient les **services de bas niveau** de l’application — tout ce qui touche aux **données**, à leur **conversion** et à leur **stockage**.

---

## 📁 Fichiers

- [`convert_utils.dart`](convert_utils.md) — Fonctions sécurisées pour convertir et parser les données.
- [`database_service.dart`](database_service.md) — Gestion centralisée de la base SQLite, création des tables et requêtes CRUD.
  - [`schema_bd.md`](./schema_db.md) — Explication et détail sur le schéma de la base de donnée

---

## 🔗 Relations avec les autres modules
- Les **models** utilisent `convert_utils.dart` pour sérialiser/désérialiser leurs données.
- Le **DatabaseService** orchestre la persistance de ces modèles en tables SQLite.
- Les **screens** interagiront indirectement avec la base via un gestionnaire plus haut niveau (non encore implémenté).

---

_Fichier : `docs/services/index.md`_