[⬅️ Retour à la documentation principale](../index.md) | [💾 Voir le code source](../../lib/screens/)

# 🖥️ Dossier `screens/`

## 🎯 Rôle
Ce dossier contient **les écrans principaux de l’application** et le **routeur** (`MainRouter`) responsable de la navigation entre eux.  
Chaque écran est une simple page Flutter (`StatelessWidget`) avec son propre `AppBar`.

---

## 📂 Contenu

- [`home_screen.dart`](home_screen.md) — classe `HomeScreen`, Page d’accueil, point d’entrée de l’application.
- [`main_router.dart`](main_router.md) — classe `MainRouter`, Gère la navigation entre les trois écrans via une barre de navigation inférieure.
- [`statistic_screen.dart`](statistic_screen.md) — classe `StatisticScreen`, Affiche les statistiques d’apprentissage.
- [`setting_screen.dart`](setting_screen.md) — classe `SettingScreen`, Gère les paramètres utilisateur et les préférences.

---

## 🧭 Navigation entre les écrans

- `MainRouter` utilise un `BottomNavigationBar` pour naviguer entre les trois pages.  
- Chaque onglet correspond à un écran différent :
  - **Home** → `HomeScreen`
  - **Statistiques** → `StatisticScreen`
  - **Paramètres** → `SettingScreen`
- Le `MainRouter` gère également la **barre d’application (`AppBar`)** associée à chaque écran via des fonctions comme `buildHomeAppBar`.

---

## 🔗 Dépendances

- `flutter/material.dart`  
- Aucune dépendance directe vers les autres modules (`models/`, `services/`), car ces écrans sont purement UI.

---

_Fichier : `docs/screens/index.md`_
