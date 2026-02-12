# Hypothèses et périmètre du modèle SRS

Ce document décrit **les hypothèses non mathématiques** du modèle de répétition espacée (SRS) utilisé dans l’application.

Il complète :

* la documentation mathématique du SRS [`maths_srs.md`](maths_srs.md),
* les diagrammes d’architecture (Domain, Sessions, Application).

Son objectif est de rendre **explicites les choix cognitifs, pédagogiques et produit** qui guident le modèle, afin :

* d’éviter des ambiguïtés lors des évolutions futures,
* de distinguer clairement ce qui est volontairement simplifié de ce qui est réellement manquant,
* de cadrer le périmètre du MVP.

---

## 1. Hypothèse centrale : le SRS évalue une épreuve, pas une connaissance abstraite

Chaque **exercice** (au sens : type d’épreuve) possède son propre état SRS.

Un même contenu (mot, règle, phrase) peut donc être associé à **plusieurs exercices distincts**, par exemple :

* langue A → langue B,
* langue B → langue A,
* reconnaissance vs rappel actif.

Le SRS n’évalue jamais une “maîtrise globale” d’un mot ou d’une règle, mais uniquement la capacité à réussir **une épreuve précise**.

Ce choix permet :

* d’éviter toute ambiguïté sur ce que signifie « connaître » un élément,
* d’aligner le modèle sur celui d’Anki (une note → plusieurs cartes),
* de garder un SRS simple et local.

---

## 2. Hypothèse sur le signal de réponse : auto‑évaluation subjective

Le modèle suppose que l’utilisateur est capable de s’auto‑évaluer honnêtement après chaque exercice.

Les réponses possibles (Easy / Good / Medium / Hard / Again) reflètent :

* la justesse de la réponse,
* le degré d’hésitation ressenti,
* le temps perçu pour répondre,
* la confiance dans la réponse.

Le **temps réel mesuré** n’est pas utilisé. Le signal est volontairement subjectif.

Ce choix est assumé car :

* l’utilisateur perçoit mieux sa propre difficulté que ne le ferait une mesure brute du temps,
* cela évite une instrumentation lourde et fragile,
* c’est le modèle utilisé par Anki avec succès.

---

## 3. Hypothèse sur le retard : la réussite prime sur le temps écoulé

Un succès à un exercice **n’est jamais pénalisé**, même en cas de retard important.

Le modèle considère que :

* si l’utilisateur réussit malgré le retard, l’état de maîtrise était suffisant,
* le temps écoulé ne constitue pas à lui seul une information plus fiable que la réussite.

Le retard n’est pris en compte **que lorsque l’exercice est échoué**, afin de :

* réinitialiser ou affaiblir l’état SRS,
* éviter qu’un succès chanceux répété masque une fragilité réelle.

Ce choix favorise :

* la stabilité du SRS,
* la confiance utilisateur,
* une interprétation simple et explicable du comportement du système.

---

## 4. Hypothèse d’indépendance locale des exercices

Chaque exercice est traité comme **indépendant des autres**.

Le SRS ne modélise pas :

* les transferts de compétence entre exercices,
* les dépendances entre vocabulaire et grammaire,
* les relations hiérarchiques entre connaissances.

Ce choix est volontaire.

Il repose sur l’idée que :

* une bonne couverture du vocabulaire est critique,
* les phrases servent surtout d’exposition et de contextualisation,
* une phrase mal maîtrisée doit simplement réapparaître plus tôt.

L’approximation est jugée acceptable tant que :

* les mots sont correctement révisés,
* les erreurs sur les phrases entraînent une répétition rapide.

---

## 5. Hypothèse sur le rôle des phrases

Les phrases ne sont pas des unités de connaissance fondamentales.

Elles servent principalement à :

* illustrer des règles grammaticales,
* fournir du contexte réel,
* renforcer la mémorisation par exposition répétée.

Le SRS des phrases peut être moins précis que celui des mots sans compromettre l’apprentissage global.

Des aides (ex. affichage de la traduction des mots dans une phrase) sont acceptables et ne remettent pas en cause l’exercice, car l’objectif principal reste l’exposition et la compréhension.

---

## 6. Hypothèse produit : priorité à la simplicité et à l’explicabilité

Le modèle privilégie :

* des règles simples,
* un comportement prévisible,
* une explicabilité complète pour l’utilisateur et le développeur.

Il ne cherche pas à atteindre une optimalité théorique maximale.

Ce choix implique notamment :

* l’absence de modèle probabiliste bayésien,
* des paramètres globaux fixes,
* l’absence d’apprentissage automatique des paramètres.

Ces limites sont assumées pour le MVP.

---

## 7. Gestion des sessions (MVP)

Les sessions sont des objets **éphémères**.

Elles ont pour rôle :

* d’orchestrer une suite d’exercices,
* de collecter les réponses,
* de déléguer la mise à jour du SRS.

La **priorisation des exercices** (ex. si 150 exercices sont dus mais que le maximum journalier est de 100) est réalisée **avant la session**, dans la couche Application.

À l’intérieur d’une session :

* aucun tri supplémentaire n’est nécessaire,
* les exercices sont présentés dans l’ordre défini à la création de la session.

---

## 8. Gestion de la surcharge cognitive (MVP)

Le modèle ne possède pas de représentation globale de l’état de l’utilisateur (fatigue, baisse de performance).

Pour le MVP, la gestion repose sur des règles simples :

* possibilité pour l’utilisateur d’interrompre une session à tout moment,
* suggestion d’arrêt ou de pause en cas d’erreurs répétées.

Les erreurs ponctuelles ou une mauvaise session ne doivent pas pénaliser durablement l’état SRS.

---

## 9. Périmètre explicite du MVP

Le MVP **n’essaie pas** de résoudre les problèmes suivants :

* modélisation probabiliste fine de la mémoire,
* transferts de compétence entre connaissances,
* apprentissage automatique des paramètres SRS,
* adaptation globale du modèle à l’utilisateur.

Ces évolutions sont considérées comme **post‑MVP** et ne doivent pas influencer les choix actuels tant que les hypothèses ci‑dessus sont respectées.

---

## 10. Rôle de ce document

Ce document sert de référence pour :

* justifier les choix du modèle SRS,
* guider les évolutions futures sans dénaturer le système,
* éviter l’introduction de fonctionnalités incohérentes avec les hypothèses fondatrices.

Toute modification majeure du SRS doit être évaluée au regard des hypothèses décrites ici.

---

## TODO :

* suggestion d’arrêt ou de pause en cas d’erreurs répétées.
* La **priorisation des exercices** dans la couche applicative selon la probabilité de rappel (et non pas selon l'interval)
