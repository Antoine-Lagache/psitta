# Plan de développement - MVP Flutter (Entraînement enfants)

## 🎯 Objectifs et temps estimés

### Phase 0 – Préparation & Environnement
- Installer et configurer Flutter/Dart, IDE, simulateurs : **3h**
- Apprendre Git de base (init, commit, branch, push, pull) : **2h**
- Créer dépôt Git (privé) + README structuré : **2h**
- Créer un espace `learning/` pour les tests Dart : **1h**

⏱️ **Total : 8h**

---

### Phase 1 – Découverte de Dart & Flutter
- Bases de Dart (variables, fonctions, classes) : **5h**
- Exercices simples (petits scripts dans `learning/`) : **4h**
- Introduction Flutter : widgets de base (Text, Row, Column, Container) : **5h**
- Premier écran simple (hello world + boutons) : **4h**

⏱️ **Total : 18h**

---

### Phase 2 – Architecture & Organisation du projet
- Réflexion sur l’architecture (MVVM ou Clean-ish) : **3h**
- Création des classes abstraites (ex : `Game`, `Exercise`, `Level`) : **6h**
- Mise en place d’un système de navigation (Navigator 2.0 / go_router) : **4h**
- Organisation du code (`lib/screens`, `lib/models`, `lib/widgets`) : **3h**

⏱️ **Total : 16h**

---

### Phase 3 – Fonctionnalités principales du MVP
- Page d’accueil simple (choix d’un niveau/exercice) : **4h**
- Premier mini-jeu (logique simple, ex : calcul mental) : **8h**
- Gestion d’un “niveau terminé” (score, progression locale) : **6h**
- Persistance locale (SharedPreferences ou sqflite) : **6h**
- Structure extensible (ajouter un 2e mini-jeu rapidement) : **4h**

⏱️ **Total : 28h**

---

### Phase 4 – Améliorations & UX
- Écran de progression de l’enfant (niveau atteint, score cumulé) : **6h**
- Animation/feedback visuel (confettis, couleurs, sons simples) : **5h**
- Ergonomie & design basique (lisibilité enfants) : **5h**
- Tests unitaires simples (au moins sur `models/`) : **4h**

⏱️ **Total : 20h**

---

## 🧮 Récapitulatif des temps
- Phase 0 : 8h  
- Phase 1 : 18h  
- Phase 2 : 16h  
- Phase 3 : 28h  
- Phase 4 : 20h  

**Total ≈ 90h de travail**  
👉 Avec 2h/jour ≈ 45 jours (environ 6–7 semaines).

---

## ✅ Notes
- Le MVP **ne contient pas** de comptes utilisateurs ni sauvegarde cloud.  
- Les bases de données locales suffisent pour tester l’idée.  
- L’architecture pensée dès le départ évitera de “tout refaire”.  
- Chaque phase peut être validée indépendamment (progression incrémentale).  
