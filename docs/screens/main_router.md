[⬅️ Retour à l’index des écrans](index.md) | [💾 Voir le code source](../../lib/screens/main_router.dart)

# 🚦 `main_router.dart`

## 🎯 Rôle du fichier
Assure la **navigation principale** entre les écrans.  
C’est le conteneur principal (`Scaffold`) de l’application, avec :
- une `AppBar` dynamique selon la page active ;
- un `BottomNavigationBar` pour changer d’écran.

---

## 🔗 Dépendances
```dart
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'statistic_screen.dart';
import 'setting_screen.dart';
```

---

## 🧩 Classes principales

### `MainRouter`

`StatefulWidget` racine responsable de la navigation entre les onglets.

### `_MainRouterState`

Contient :

* `_currentIndex` — l’index de l’onglet actif.
* `_page` — la liste des écrans (`HomeScreen`, `StatisticScreen`, `SettingScreen`).
* `_pageAppBars` — les fonctions générant les `AppBar` correspondantes.

#### Méthode `build(BuildContext context)`

Construit :

```dart
Scaffold(
  appBar: _pageAppBars[_currentIndex](context),
  body: _page[_currentIndex],
  bottomNavigationBar: BottomNavigationBar(...),
)
```

---

## 🧭 Navigation

Le `BottomNavigationBar` permet de passer d’un écran à l’autre :

```dart
onTap: (index) {
  setState(() { _currentIndex = index; });
}
```

Les icônes utilisées :

* 🏠 `Icons.home_rounded`
* 📊 `Icons.bar_chart_rounded`
* ⚙️ `Icons.settings_rounded`

---

## 📝 Remarques

* La logique est minimale pour un MVP.
* À terme, on pourra utiliser `GoRouter` ou `Navigator 2.0` pour une navigation plus complexe.
* Chaque écran définit son `AppBar` séparément (bonne pratique pour modularité).

---

*Fichier : `docs/screens/main_router.md`*
