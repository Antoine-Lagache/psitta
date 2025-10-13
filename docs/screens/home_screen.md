[⬅️ Retour à l’index des écrans](index.md) | [💾 Voir le code source](../../lib/screens/home_screen.dart)

# 🏠 `home_screen.dart`

## 🎯 Rôle du fichier
Affiche la **page d’accueil** de l’application.  
C’est la première vue accessible via la barre de navigation inférieure.

---

## 🔗 Dépendances
```dart
import 'package:flutter/material.dart';
```

---

## 🧩 Classes principales

### `HomeScreen`

Un `StatelessWidget` très simple affichant un texte centré :

```dart
Center(
  child: Text("Page d’accueil"),
)
```

### `buildHomeAppBar(BuildContext context)`

Renvoie un `AppBar` configuré avec :

* un titre : `"Home"`
* une couleur de fond issue du `Theme`
* une ombre (`elevation: 10`)

---

## 📝 Notes

* Utilisée par `MainRouter` comme premier onglet.
* Peut servir de point d’entrée pour les futures fonctionnalités (ex. progression, bouton “Commencer la session”, etc.).

---

*Fichier : `docs/screens/home_screen.md`*
