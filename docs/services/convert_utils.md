[⬅️ Retour à l’index des services](index.md) | [💾 Voir le code source](../../lib/services/convert_utils.dart)

# 🧮 `convert_utils.dart`

## 🎯 Rôle du fichier
Fournit une collection de **fonctions utilitaires** pour les conversions de types, notamment :
- nombres (`int`, `double`, `bool`)  
- dates et durées (`DateTime`, `Duration`)  
- encodage/décodage JSON  
- listes (`List<String>`)

Ces fonctions sont **sécurisées** : elles ne lèvent jamais d’exception et retournent toujours une valeur de repli (*fallback*).

---

## 🔗 Dépendances
```dart
import 'dart:convert';
```

---

## 🔧 Fonctions principales

### Conversion numérique

- `double safeToDouble(dynamic value, {double fallback = 0.0})`
Convertit une valeur dynamique en `double`.

- `int safeToInt(dynamic value, {int fallback = 0})`
Convertit une valeur dynamique en `int`.

- `bool safeToBool(dynamic value, {bool fallback = false})`
Convertit en booléen selon la valeur (`true`, `1`, `false`, `0`, etc.).

---

### Conversion temporelle

- `DateTime? safeParseDate(String? value)`
Retourne un `DateTime.utc` ou `null` si la valeur est invalide.

- `String? toIsoUtc(DateTime? date)`
Retourne une chaîne ISO8601 UTC.

- `Duration safeToDuration(dynamic value, {Duration fallback = Duration.zero})`
Interprète une valeur (ms) en `Duration`.

- `int safeFromDuration(Duration duration)`
Retourne la durée en millisecondes.

---

### Conversion JSON

- `Map<String, dynamic> safeJsonDecodeMap(String? jsonText)`
Décode du JSON en `Map`.

- `List<dynamic> safeJsonDecodeList(String? jsonText)`
Décode du JSON en `List`.

- `String? safeJsonEncode(Object? value)`
Encode en JSON. Retourne `null` si erreur.

---

### Conversion liste

- `List<String> safeJsonDecodeStringList(String? jsonText)`

Convertit une chaîne JSON en liste de chaînes (`List<String>`).

---

## 🧱 Notes

* Ces fonctions sont utilisées dans **tous les modèles** (`Note`, `Card`, `SRSState`, etc.) et dans la base de données.
* Elles centralisent la logique de conversion, ce qui évite les erreurs de parsing et garantit la compatibilité avec SQLite.

---

*Fichier : `docs/services/convert_utils.md`*
