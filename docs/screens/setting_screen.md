[⬅️ Retour à l’index des écrans](index.md) | [💾 Voir le code source](../../lib/screens/setting_screen.dart)

# ⚙️ `setting_screen.dart`

## 🎯 Rôle du fichier
Affiche la **page des paramètres** de l’application.  
Destinée à gérer les préférences utilisateur (thème, langue, options SRS…).

---

## 🔗 Dépendances
```dart
import 'package:flutter/material.dart';
```

---

## 🧩 Classes principales

### `SettingScreen`

`StatelessWidget` affichant :

```dart
Center(
  child: Text("Page des paramètres"),
)
```

### `buildSettingAppBar(BuildContext context)`

Renvoie une `AppBar` avec :

* le titre `"Setting"`
* la couleur principale du thème (`Theme.of(context).colorScheme.primary`)

---

## 📝 Notes

* Actuellement statique.
* Pourra inclure à terme des **switchs**, **sliders** ou **listes déroulantes** pour modifier la configuration SRS et le comportement de l’app.

---

*Fichier : `docs/screens/setting_screen.md`*
