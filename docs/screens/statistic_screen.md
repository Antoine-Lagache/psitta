[⬅️ Retour à l’index des écrans](index.md) | [💾 Voir le code source](../../lib/screens/statistic_screen.dart)

# 📊 `statistic_screen.dart`

## 🎯 Rôle du fichier
Affiche la **page des statistiques** d’apprentissage.  
Permettra ultérieurement de visualiser les performances de l’utilisateur (taux de réussite, progression, etc.).

---

## 🔗 Dépendances
```dart
import 'package:flutter/material.dart';
```

---

## 🧩 Classes principales

### `StatisticScreen`

`StatelessWidget` affichant simplement :

```dart
Center(
  child: Text("Page des statistiques"),
)
```

### `buildStatisticAppBar(BuildContext context)`

Retourne une `AppBar` avec :

* le titre `"Statistic"`
* une couleur de fond issue du thème actuel

---

## 📝 Notes

* Pourra être complétée avec des graphiques Flutter (`charts_flutter`, `recharts`, etc.).
* Reliée à `MainRouter` (deuxième onglet).

---

*Fichier : `docs/screens/statistic_screen.md`*
