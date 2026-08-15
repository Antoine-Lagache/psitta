[Documentation Index](/docs/index.md)

# Hypotheses and Scope of the SRS Model

This document describes the **non-mathematical hypotheses** of the spaced repetition model (SRS) used in the application.

It complements:

* the mathematical SRS documentation [`maths_srs.md`](maths_srs.md),
* the architecture diagrams (Domain, Sessions, Application).

Its purpose is to make **explicit the cognitive, pedagogical, and product choices** that guide the model, in order to:

* avoid ambiguity during future evolutions,
* clearly distinguish what is intentionally simplified from what is genuinely missing,
* define the scope of the MVP.

---

## 1. Core Hypothesis: the SRS evaluates a task, not abstract knowledge

Each **exercise** (in the sense of: type of task) has its own SRS state.

The same content (word, rule, sentence) may therefore be associated with **several distinct exercises**, for example:

* language A → language B,
* language B → language A,
* recognition vs. active recall.

The SRS never evaluates a "global mastery" of a word or rule, but only the ability to succeed at **one specific task**.

This choice allows:

* avoiding any ambiguity about what it means to "know" an item,
* aligning the model with Anki (one note → multiple cards),
* keeping the SRS simple and local.

---

## 2. Hypothesis on the response signal: subjective self-assessment

The model assumes that the user is capable of honestly self-assessing after each exercise.

The possible responses (Easy / Good / Medium / Hard / Again) reflect:

* the correctness of the answer,
* the degree of hesitation felt,
* the perceived time to answer,
* confidence in the response.

**Actual measured time** is not used. The signal is intentionally subjective.

This choice is deliberate because:

* users perceive their own difficulty better than a raw time measurement would,
* it avoids heavy and fragile instrumentation,
* it is the model successfully used by Anki.

---

## 3. Hypothesis on delay: success takes precedence over elapsed time

A successful response to an exercise is **never penalised**, even after a significant delay.

The model considers that:

* if the user succeeds despite the delay, the mastery state was sufficient,
* elapsed time alone is not more reliable information than the success itself.

Delay is only taken into account **when the exercise is failed**, in order to:

* reset or weaken the SRS state,
* prevent repeated lucky successes from masking a real fragility.

This choice favours:

* SRS stability,
* user confidence,
* a simple and explainable system behaviour.

---

## 4. Hypothesis of local independence between exercises

Each exercise is treated as **independent from the others**.

The SRS does not model:

* skill transfer between exercises,
* dependencies between vocabulary and grammar,
* hierarchical relationships between items of knowledge.

This choice is intentional.

It rests on the idea that:

* good vocabulary coverage is critical,
* sentences serve mainly as exposure and contextualisation,
* a poorly mastered sentence should simply reappear sooner.

The approximation is considered acceptable as long as:

* words are correctly revised,
* errors on sentences lead to rapid repetition.

---

## 5. Hypothesis on the role of sentences

Sentences are not fundamental units of knowledge.

They serve primarily to:

* illustrate grammatical rules,
* provide real-world context,
* reinforce memorisation through repeated exposure.

The SRS for sentences may be less precise than that for words without compromising overall learning.

Aids (e.g. displaying word translations within a sentence) are acceptable and do not invalidate the exercise, since the primary objective remains exposure and comprehension.

---

## 6. Product hypothesis: priority on simplicity and explainability

The model favours:

* simple rules,
* predictable behaviour,
* complete explainability for both the user and the developer.

It does not aim for maximum theoretical optimality.

This implies in particular:

* no Bayesian probabilistic model,
* fixed global parameters,
* no automatic parameter learning.

These limitations are accepted for the MVP.

---

## 7. Session management (MVP)

Sessions are **ephemeral** objects.

Their role is to:

* orchestrate a sequence of exercises,
* collect responses,
* delegate SRS updates.

**Exercise prioritisation** (e.g. if 150 exercises are due but the daily maximum is 100) is performed **before the session**, in the Application layer.

Inside a session:

* no additional sorting is necessary,
* exercises are presented in the order defined at session creation.

---

## 8. Cognitive load management (MVP)

The model has no global representation of the user's state (fatigue, declining performance).

For the MVP, management relies on simple rules:

* the user may interrupt a session at any time,
* a stop or pause may be suggested in case of repeated errors.

Occasional errors or a poor session should not permanently penalise the SRS state.

---

## 9. Explicit MVP scope

The MVP **does not attempt** to solve the following problems:

* fine-grained probabilistic memory modelling,
* skill transfer between items of knowledge,
* automatic SRS parameter learning,
* global model adaptation to the user.

These evolutions are considered **post-MVP** and must not influence current choices as long as the hypotheses above are respected.

---

## 10. Role of this document

This document serves as a reference for:

* justifying the SRS model choices,
* guiding future evolutions without distorting the system,
* preventing the introduction of features inconsistent with the founding hypotheses.

Any major SRS modification must be evaluated against the hypotheses described here.

---

## TODO:

* Suggestion to stop or pause in case of repeated errors.
* **Exercise prioritisation** in the application layer based on recall probability (rather than interval).