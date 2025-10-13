[🏠  Retour à la documentation principale](index.md) | [💾 Voir le code source](../lib/main.dart)

# ⚙️ `main.dart`

## 🎯 Rôle du fichier
Point d’entrée de l’application Flutter.  
Il initialise l’application et fournit la configuration globale de l’UI (titre, thème, widget racine).

---

## 🔗 Dépendances
```dart
import 'package:flutter/material.dart';
import 'screens/main_router.dart';
```

* `flutter/material.dart` — framework UI principal.
* `screens/main_router.dart` — routeur principal qui gère la navigation entre écrans.

---

## 🧩 Contenu principal

### `main()`

Fonction d’entrée exécutée au démarrage.

```dart
void main() {
  //runApp(const MyApp());
  runApp(const MyApp());
}
```

* Lance l’application en instanciant `MyApp`.
* Commenter/décommenter `runApp` peut servir lors de tests manuels ou d’expérimentations.

---

### `class MyApp extends StatelessWidget`

Widget racine de l’application.

#### Propriétés / Constructeur

* `const MyApp({super.key});`

#### `build(BuildContext context)`

Retourne un `MaterialApp` configuré :

* `title` : "App pour apprentissage de langue".
* `theme` : construit via `ColorScheme.fromSeed(seedColor: Colors.lightBlue)`.
* `home` : `MainRouter()` — point de départ de la navigation (défini dans `lib/screens/main_router.dart`).

Extrait :

```dart
return MaterialApp(
  title: "App pour apprentissage de langue",
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlue),
  ),
  home: MainRouter(),
);
```

---

## 📝 Remarques pratiques

* `MainRouter` centralise la navigation et les AppBars des écrans.
* Le thème est minimal ; tu peux externaliser la configuration du thème dans `services/theme.dart` si besoin.
* Pour le hot-reload / tests UI, `main()` peut être adapté pour injecter des dépendances (ex. mock services) avant `runApp`.

---

*Fichier : `docs/main.md` — documentation de `main.dart`.*

