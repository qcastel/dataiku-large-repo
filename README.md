# Test manuel SC-247625 — tour avant review Jiffy

Préparé le 12 octobre 2026 pour la PR 41785 ; actualisé pour les correctifs de précision des tailles de la dernière revue.

Prévoir environ 30–45 minutes pour le parcours principal. Les cas marqués
« complément » peuvent être faits après. Cocher les résultats au fur et à mesure.

## Préparation

Utiliser un projet de test, par exemple `TEST_GIT_LARGE`, et des chemins locaux
neufs. Le dépôt commun à tous les tests est :

```text
git@github.com:qcastel/dataiku-large-repo.git
```

Laisser les champs login/password vides pour cette URL SSH.

Configurer ces propriétés sur l'instance de développement et redémarrer DSS :

```properties
git.clone.soft.limit.mb=5
git.clone.hard.limit.mb=10
```

Noter les anciennes valeurs pour les restaurer à la fin. Les fichiers synthétiques
sont compressibles : on teste les tailles des fichiers présents sur disque,
pas le volume réel du transfert réseau. Les tailles sont affichées en KB/MB/GB,
sans minimum artificiel de 1 MB. Les limites sont comparées en octets ; la valeur
exacte est accessible en survolant une taille. Charger le backend et le frontend
contenant ce correctif ensemble pour retester.

| Usage | Valeur exacte du champ Checkout |
| --- | --- |
| Limites et sous-dossiers | `codex/sc247625-tour-20261012-limits` |
| Motifs et noms spéciaux | `codex/sc247625-tour-20261012-patterns` |
| Pull et push après rebase | `codex/sc247625-tour-20261012-sync` |
| Changements distants préparés, à appliquer au test 7 | `codex/sc247625-tour-20261012-remote-update` |

Toutes les exclusions sont relatives à la racine du dépôt, même quand on importe
un sous-dossier. Sauf indication contraire, remplacer entièrement le champ
Denied files par les motifs indiqués ; « vide » signifie supprimer aussi les
motifs par défaut.

Comportement actuel : checkout du dépôt avec filtrage par blacklist, puis copie
du sous-dossier demandé dans DSS. La taille et la liste du rapport ne concernent
que ce sous-dossier. On ne teste pas un checkout physiquement limité à remotePath.

## 1. Petit sous-dossier : aucun blocage causé par le reste du dépôt

Importer avec ces champs :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-limits
Path in Git repository: fixtures/scope-small
Local target path: tour-small
Denied files: vide
```

- [ ] Import réussi sans modale de limite.
- [ ] La bibliothèque contient uniquement `code.py`.
- [ ] Le fichier extérieur de 40 MiB n'a pas déclenché la hard limit.

## 2. Blacklist dans un sous-dossier, puis soft limit

Importer :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-limits
Path in Git repository: fixtures/scope-soft
Local target path: tour-soft
```

Denied files :

```text
/fixtures/scope-soft/cache/
```

- [ ] Modale soft limit : taille totale **6 MB**.
- [ ] Git reference path affiche `fixtures/scope-soft`, pas `tour-soft`.
- [ ] La liste contient `fixtures/scope-soft/large.payload` (6 MB).
- [ ] `outside-large` et `cache` ne sont pas listés.
- [ ] Proceed Anyway est disponible. Cliquer dessus.
- [ ] La bibliothèque contient `large.payload` et `code.py`, sans cache.

Réduire la fenêtre à environ 1024 × 600 pendant ce test :

- [ ] Le titre et les boutons restent accessibles ; le corps peut défiler.
- [ ] Même contrôle dans Edit Git reference après l'import.

## 3. Hard limit, bouton +, Update & Retry

Importer :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-limits
Path in Git repository: fixtures/scope-hard
Local target path: tour-hard
Denied files: vide
```

- [ ] Modale hard limit : **12 MB**, limite **10 MB**.
- [ ] Deux entrées de 6 MB : `fixtures/scope-hard/part-a.payload` et
  `fixtures/scope-hard/part-b.payload`.
- [ ] Aucun fichier extérieur dans la liste.
- [ ] Proceed Anyway est indisponible.

Cliquer sur + à côté de `part-b.payload` :

- [ ] Le motif ajouté est `fixtures/scope-hard/part-b.payload` ; un slash initial
  serait aussi valide, mais le bouton n'en ajoute pas automatiquement.
- [ ] Un second clic sur + ne duplique pas le motif.
- [ ] Update & Retry donne maintenant une soft limit à **6 MB**.
- [ ] Proceed Anyway réussit ; `part-a.payload` est importé, `part-b.payload` absent.

## 4. Chemin incorrect : erreur API, sans rejet non géré

Ouvrir la console du navigateur, puis essayer deux nouvelles importations sur la
branche limits, avec Denied files vide et des destinations locales distinctes :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-limits
Path in Git repository: missing-directory
Local target path: tour-invalid-directory
```

Puis :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-limits
Path in Git repository: fixtures/scope-small/code.py
Local target path: tour-invalid-file
```

- [ ] Les deux opérations affichent une erreur de chemin invalide, pas une limite.
- [ ] Le deuxième cas rejette bien un fichier utilisé comme répertoire.
- [ ] L'erreur API normale peut apparaître dans la console.
- [ ] Aucun `Possibly unhandled rejection` ajouté par l'opération.
- [ ] Les bibliothèques créées aux étapes précédentes restent utilisables.

## 5. Le bouton + doit exclure un nom littéral, pas ses voisins

Premier cas :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-patterns
Path in Git repository: cases/brackets
Local target path: tour-brackets
Denied files: vide
```

- [ ] Soft limit à **8 MB** : `file[1].txt` (6 MB) et `file1.txt` (2 MB).
- [ ] Le nom affiché dans la liste est `file[1].txt`, sans antislash ajouté.
- [ ] + sur ce fichier ajoute `cases/brackets/file\[1\].txt`.
- [ ] Update & Retry réussit à **2 MB** ; `file1.txt` reste présent.

Complément : refaire exactement le même test pour :

| Path in Git repository | Local target path | Fichier 6 MB à exclure | Voisin 2 MB à conserver | Motif ajouté attendu |
| --- | --- | --- | --- | --- |
| `cases/star` | `tour-star` | `file*.txt` | `fileABC.txt` | `cases/star/file\*.txt` |
| `cases/question` | `tour-question` | `file?.txt` | `fileA.txt` | `cases/question/file\?.txt` |

## 6. Éditer les exclusions puis pull ; dossiers de dépendances imbriqués

Importer sur la branche patterns, en gardant les exclusions par défaut :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-patterns
Path in Git repository: deps
Local target path: tour-deps
```

Si les défauts de ton instance ne contiennent pas ce motif, l'ajouter :

```text
**/node_modules/
```

- [ ] Import réussi ; les dossiers `a` et `b` contiennent chacun `keep.py`.
- [ ] Aucun `node_modules` importé.

Ouvrir Edit Git reference, vider Denied files, puis Save and Retrieve :

- [ ] Hard limit à **16 MB** : `deps/a` et `deps/b`, 8 MB chacun.
- [ ] Le chemin affiché reste `deps`.

Dans la modale de retry, remettre :

```text
**/node_modules/
```

- [ ] Update & Retry réussit ; les fichiers `keep.py` sont toujours présents.
- [ ] Réouvrir Edit Git reference : le motif est conservé.
- [ ] Reset from remote HEAD réussit sans demander une nouvelle dérogation.

## 7. Push avec rebase : recopier les ajouts distants et préserver les exclus

Ce scénario fait évoluer la branche sync. Ne pas utiliser la branche
remote-update comme Checkout dans DSS : elle sert à préparer la divergence.

Importer d'abord :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-tour-20261012-sync
Path in Git repository: library
Local target path: tour-sync
```

Denied files :

```text
**/denied.txt
```

- [ ] `code.py` est importé ; `denied.txt` et `remote_added.py` sont absents.

Dans DSS, ajouter à la fin de `code.py` :

```python
# DSS SUBDIR CHANGE
```

Créer également un fichier local `denied.txt` dans `tour-sync`, contenu :

ui: now that I relook at it, the modal is too high, if we have an error message above, it is very hard to do anything on a smaller screen
<img width="851" height="821" alt="Image" src="https://github.com/user-attachments/assets/d94a58bc-c572-404e-a2b2-2b3fb6be1c77" />

ui: we still have an unhandled rejection on the wrong path (ok kind of nitpick, just ot very clean)
<img width="1570" height="830" alt="Image" src="https://github.com/user-attachments/assets/f0a73474-3704-429b-bea0-e190d82be3ae" />

paths mismath:
- set a soft limit to 2 MB
- clone https://github.com/dataiku/dataiku-api-client-python
- set a remote path to `dataikuapi`
- set a local path to whatever
- I have the list below

<img width="843" height="708" alt="Image" src="https://github.com/user-attachments/assets/40e1ad23-edc4-4da9-9f79-c758d0c33d96" />

I would have expected `git reference path` to be `dataikuapi` and to see directories **inside** `dataikuapi`, not outside
```

Complément pour couvrir le même bug à la racine : avant la commande ci-dessous,
importer aussi la branche sync avec Path in Git repository vide, Local target
path `tour-sync-root`, et le même motif `**/denied.txt`. Modifier uniquement son
`code.py` à la racine en ajoutant `# DSS ROOT CHANGE`, puis créer un `denied.txt`
local à la racine avec le même contenu. Ne pas modifier son `library/code.py`.

Appliquer maintenant les changements distants, depuis un terminal. Utiliser un
nom de dossier temporaire encore libre :

```sh
git clone --single-branch --branch codex/sc247625-tour-20261012-sync \
  git@github.com:qcastel/dataiku-large-repo.git \
  /tmp/sc247625-tour-sync-client

git -C /tmp/sc247625-tour-sync-client fetch origin \
  refs/heads/codex/sc247625-tour-20261012-remote-update:refs/remotes/origin/tour-remote-update

git -C /tmp/sc247625-tour-sync-client merge --ff-only origin/tour-remote-update

git -C /tmp/sc247625-tour-sync-client push origin HEAD:codex/sc247625-tour-20261012-sync
```

Dans DSS, faire Commit and push sur `tour-sync`, message `Manual subdirectory push`.

- [ ] Push réussi, sans conflit.
- [ ] `code.py` conserve `# DSS SUBDIR CHANGE`.
- [ ] `remote_added.py` apparaît immédiatement dans `tour-sync`, sans pull manuel.
- [ ] Le fichier local `denied.txt` conserve `LOCAL DENIED MUST SURVIVE`.
- [ ] Le résultat du push signale le fichier local exclu ; la référence est à jour.

Vérifier le distant :

```sh
git -C /tmp/sc247625-tour-sync-client fetch origin

git -C /tmp/sc247625-tour-sync-client show origin/codex/sc247625-tour-20261012-sync:library/code.py

git -C /tmp/sc247625-tour-sync-client show origin/codex/sc247625-tour-20261012-sync:library/remote_added.py

git -C /tmp/sc247625-tour-sync-client show origin/codex/sc247625-tour-20261012-sync:library/denied.txt
```

- [ ] Le distant contient le changement DSS et l'ajout distant.
- [ ] Son `library/denied.txt` contient `REMOTE DENIED V2`, jamais le contenu local.

Si la bibliothèque racine optionnelle a été préparée avant l'avance distante,
faire ensuite Commit and push sur `tour-sync-root` : le fichier racine
`remote_added.py` doit apparaître, le changement racine DSS et le fichier local
exclu doivent être conservés. Aucun conflit attendu, les modifications portent
sur deux `code.py` distincts.

Enfin, ajouter `# UNPUSHED LOCAL CHANGE` dans `tour-sync/code.py`, puis Reset from
remote HEAD et confirmer le remplacement :

- [ ] Le marqueur non poussé disparaît ; le marqueur poussé reste.
- [ ] `remote_added.py` reste présent et `denied.txt` local est préservé.

## Compléments rapides

### Comparer dossier sélectionné et racine

Sur la branche limits, Path in Git repository vide, Local target path `tour-root`,
Denied files vide : hard limit d'environ **66 MB**, Git reference path `/`, et
`outside-large` apparaît avec **40 MB**.

Avec Path `fixtures/scope-soft`, Local target `tour-soft-with-cache`, Denied files
vide : hard limit **14 MB**, le cache de 8 MB est bien compté. Cela confirme que le
résultat 6 MB de l'étape 2 vient de l'exclusion.

### !, #, points, + et espaces

Sur la branche patterns, importer la racine dans `tour-prefix`, en remplaçant
Denied files par :

```text
/cases/
/deps/
```

Hard limit d'environ **20 MB**. + sur `!important.txt` puis `#notes.txt` doit
ajouter ces deux motifs :

```text
\!important.txt
\#notes.txt
```

Update & Retry donne une soft limit à **8 MB**. Proceed Anyway conserve
`fileC.toto`, `plus+name.txt`, `space name.txt` et `ordinary.txt`.
Dans Edit Git reference, ajouter ces deux lignes :

```text
fileC.toto
plus+name.txt
```

Save and Retrieve réussit ; les deux fichiers sont exclus, les deux autres
restent. Il ne faut pas d'échappement regex du point ou du +.

### Motifs relatifs au dépôt

Importer `deps/a` sur la branche patterns dans `tour-root-pattern`, avec :

```text
/node_modules/
```

Soft limit **8 MB** : ce motif ne vise que le node_modules à la racine du dépôt.
Remplacer par `/deps/a/node_modules/` et Update & Retry : succès, seul `keep.py`
est importé.

## Fin du tour

- [ ] Restaurer les propriétés soft/hard et redémarrer DSS si elles ont été changées.
- [ ] Relever les cas KO avec Checkout, remotePath, motifs et capture de la modale.
- [ ] Sur les opérations création/pull/push, vérifier que le log de progression
  reste accessible. En cas de problème, relever l'operationId et les traces
  `Git reference operation started`, `Repository size evaluated`, ainsi que les
  traces de synchronisation locale et de fin de push.

Les branches limits/patterns sont des fixtures statiques. La branche sync est
volontairement avancée puis modifiée par ce test. Pour refaire le rebase depuis
zéro, utiliser une nouvelle branche issue du commit initial (voir FIXTURES.json),
plutôt que forcer le reset de la branche partagée.
