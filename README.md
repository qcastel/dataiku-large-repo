# Test manuel — correctifs non committés de la PR 41785

Branche de démo préparée le 13 octobre 2026 : `codex/sc247625-uncommitted-20261013`.
Ce parcours cible les derniers changements : tailles précises, seuils exacts,
message de limite soft, bouton `+`, doublons et largeur du texte d’aide.
Prévoir environ 15–20 minutes. Aucun push depuis DSS n’est nécessaire.

## Préparation

Utiliser un projet de test et des chemins locaux neufs. Charger le backend et le
frontend contenant les modifications locales ensemble : reconstruire/redémarrer
l’instance de développement avec ces modifications, puis faire un rechargement
complet du navigateur.

Configurer les propriétés suivantes sur cette instance, puis redémarrer DSS.
Noter les anciennes valeurs pour les restaurer après le test.

```properties
git.clone.soft.limit.mb=1
git.clone.hard.limit.mb=3
```

Ici, 1 MB correspond à 1 048 576 octets. L’égalité avec la limite est autorisée ;
un octet au-dessus doit déclencher la limite. L’affichage arrondit les MB : le
survol d’une taille donne les octets exacts.

Depuis Library Editor, utiliser l’action d’import d’une référence Git. Laisser
login/password vides avec l’URL SSH. À chaque import, effacer les exclusions
préremplies avant de saisir celles indiquées. « Denied files : vide » signifie
un champ réellement vide, pas le mot `vide`.

Les fixtures sont synthétiques et compressibles. Un fichier de 8 MB se trouve
hors des sous-dossiers importés : il ne doit pas apparaître dans le rapport ni
compter dans leurs limites. Les exclusions restent relatives à la racine du dépôt.

## 1. Tailles, tri, message et largeur de la modal

Importer avec ces champs :

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-uncommitted-20261013
Path in Git repository: fixtures/ui
Local target path: round10-ui
Denied files: vide
```

La modal de limite soft doit s’ouvrir. Vérifier :

- Le message contient `Soft limit exceeded`, `Imported content size` et `soft limit: 1 MB`.
- La taille totale est environ `2.03 MB` ; son survol indique `2125788 bytes`.
- `Git reference path` vaut `fixtures/ui`.
- Aucun chemin `outside-import` n’apparaît.
- La liste affiche ces tailles, dans cet ordre :

| Entrée (préfixée par `fixtures/ui/`) | Affichage | Survol exact |
| --- | --- | --- |
| `large.payload` | 2 MB | 2097152 bytes |
| `govern_client.py` | 23 KB | 23552 bytes |
| `file[1].txt` | 2 KB | 2048 bytes |
| `govern` | environ 1.46 KB | 1500 bytes |
| `small.txt` | 1 KB | 1024 bytes |
| `file1.txt` | 0.5 KB | 512 bytes |
| `empty.txt` | 0 KB | 0 bytes |

Les petites entrées ne doivent plus toutes afficher `1 MB`, et le fichier vide
doit bien afficher `0 KB`. Le tri utilise les octets, même pour les tailles inférieures à 1 MB.

Réduire la fenêtre du navigateur, par exemple à environ 1000 × 700 pixels.
Vérifier que le texte sous la liste d’exclusions utilise toute la largeur de sa
colonne, sans rester coincé dans une étroite bande. Les boutons de bas de modal
doivent rester accessibles, avec défilement du contenu si nécessaire.
Garder cette modal ouverte pour le test suivant.

## 2. Bouton `+` et collision `govern` / `govern_client.py`

Dans la modal ouverte au test 1, coller exactement cette ligne dans les exclusions :

```text
fixtures/ui/govern_client.py
```

1. Le `+` de `govern_client.py` devient désactivé. Son survol affiche `Already in ignore list`.
2. Le `+` de `govern` reste actif : le nom plus long présent dans la liste ne doit pas bloquer ce dossier.
3. Cliquer sur le `+` de `govern`. La liste doit contenir exactement ces deux lignes :

```text
fixtures/ui/govern_client.py
fixtures/ui/govern
```

4. Le `+` de `govern` devient lui aussi désactivé. Aucun clic supplémentaire ne doit ajouter de doublon.
5. Effacer seulement la ligne `fixtures/ui/govern`. Son `+` redevient actif ; celui de `govern_client.py` reste désactivé.

La désactivation reconnaît la ligne exacte ajoutée par le bouton ; elle ne cherche
pas à déterminer si un autre glob plus large couvre déjà le chemin.

## 3. Nom avec crochets et retry

Toujours dans la même modal :

1. Vider entièrement les exclusions.
2. Cliquer sur le `+` de `file[1].txt`. La ligne ajoutée doit être :

```text
fixtures/ui/file\[1\].txt
```

3. Le bouton de ce fichier devient désactivé ; celui de `file1.txt` reste actif.
4. Cliquer sur le `+` de `large.payload`. La liste finale doit être :

```text
fixtures/ui/file\[1\].txt
fixtures/ui/large.payload
```

5. Cliquer sur **Update & Retry**. L’import doit réussir, car il ne reste que 26588 octets à importer.
6. Dans `round10-ui`, vérifier :
   - `large.payload` et `file[1].txt` sont absents ;
   - `file1.txt`, `govern_client.py`, `govern/code.py`, `small.txt` et `empty.txt` sont présents.

## 4. Exactement à la limite soft : aucun avertissement

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-uncommitted-20261013
Path in Git repository: fixtures/soft-exact
Local target path: round10-soft-exact
Denied files: vide
```

L’import doit réussir directement, sans modal de taille. Le dossier contient
uniquement `payload.dat`, de 1048576 octets : exactement 1 MB.

## 5. Un octet au-dessus de la limite soft

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-uncommitted-20261013
Path in Git repository: fixtures/soft-plus-one
Local target path: round10-soft-plus-one
Denied files: vide
```

La modal soft doit s’ouvrir. Elle peut afficher `1 MB` à cause de l’arrondi,
mais le survol de la taille totale et de `payload.dat` indique `1048577 bytes`.
Le message indique explicitement la limite soft de 1 MB.

Cliquer sur **Proceed Anyway** : l’import doit réussir et conserver `payload.dat`.

## 6. Exactement à la limite hard : dépassement soft uniquement

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-uncommitted-20261013
Path in Git repository: fixtures/hard-exact
Local target path: round10-hard-exact
Denied files: vide
```

Une modal soft est attendue, car 3 MB dépasse la soft limit de 1 MB.
Il ne doit pas y avoir de blocage hard : le survol indique `3145728 bytes`,
exactement la limite hard de 3 MB.

Cliquer sur **Proceed Anyway** : l’import doit réussir.

## 7. Un octet au-dessus de la limite hard

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-uncommitted-20261013
Path in Git repository: fixtures/hard-plus-one
Local target path: round10-hard-plus-one
Denied files: vide
```

La modal hard doit s’ouvrir : limite 3 MB, taille affichée arrondie à 3 MB,
mais survol exact à `3145729 bytes`. Il ne doit pas être possible de forcer
l’import avec **Proceed Anyway**.

Cliquer sur le `+` de `payload.dat`, puis **Update & Retry**. L’import doit réussir
avec un dossier sans fichier importé. Le fichier de 8 MB hors de ce chemin
ne doit pas bloquer le retry.

## 8. Fichier vide

```text
Remote URL: git@github.com:qcastel/dataiku-large-repo.git
Checkout: codex/sc247625-uncommitted-20261013
Path in Git repository: fixtures/empty
Local target path: round10-empty
Denied files: vide
```

L’import réussit directement. `empty.txt` est présent et vide. Sa taille dans le
rapport a déjà été vérifiée à `0 KB` au test 1.

## Fin du test

Restaurer les anciennes valeurs de limites et redémarrer si elles ont été changées.
En cas de problème, noter le numéro du test, les champs d’import, les exclusions
et le survol en octets. Une capture de la modal et les logs de l’opération seront utiles.

Ce plan fournit des fixtures vérifiées ; les résultats dans DSS restent à valider
manuellement. Il ne couvre pas à nouveau le rebase/push des précédentes corrections.
