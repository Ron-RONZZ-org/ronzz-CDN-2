# Git referenco

## Rimedoj

- [Lerni](https://learngitbranching.js.org/)

## Bazoj

### `git config`

```bash
git config --global user.name "Rong Zhou"
git config --global user.email "ron@ronzz.org"
git config user.<valeur>
git config credential.helper 'cache --timeout 36000' # --global
```

### `git log`

- loka branĉo
  ```bash
  git log --graph --oneline --decorate {branch-name : default HEAD} # --all --color
  ```
- malloka branĉo
  ```bash
  git fetch origin
  git log --graph --oneline --decorate --color origin/feature-x
  ```
- 
### `git commit`, `git branch`, kaj `git rebase`

```bash
git commit
git branch {branch_name}
git switch {branch_name/commit_name/relative_commit_reference} # kreos se ne ekzistas --orphan : sen historio

git merge {branch_name}
git branch -d {branch_name} # forigi lokan branĉon jam kunfanditan
git push origin --delete init # forigi malloka ref
git rebase {target_parent_branch_name} # -i por interactive
```

### `git rollback`

```bash
git branch -f {branch/HEAD_to_move} {destination-branch/HEAD} # movas branĉon/HEAD sen movi commit-ojn
git reset HEAD~1 # nuligi lastan commit (LOKA)
git revert HEAD # krei nova commit kiu nuligas HEAD
```

### `git restore`

```bash
git restore --source main resources/ # `restaŭri dosieron inter branĉoj`
```

### `git cherry-pick`

```bash
git cherry-pick {commit}
git commit --amend
```

### `git tag`

```bash
git tag {tag_name} {target_commit : default HEAD}
git describe {commit}
```

### `git stash`

```bash
git stash push -m "mesaĝo" # -k nur sekvitaj -u inkluzivi untracked
git stash list
git stash show -p stash@{0}
git stash pop stash@{0}
git stash apply stash@{0} # ne forigas stash
git stash drop stash@{0}
git stash clear # DANGEROZA
```

## Kunlaboro en linio

### `git clone`

```bash
git clone <URL>
git clone --single-branch --branch <branĉo> <url>
```

### `.gitignore`

- Placiĝu en radiko de deponejo.
  ```text
  passwords.txt
  *.txt
  ```

### Bazaj ordonoj

```bash
rm -rf .git
git init
git status # -s por mallonga
git add .
git add <file>
git diff # --staged por staged diff
git commit -m "mesaĝo" -a # -a = add automata
```

### Rollback specife

```bash
git reset --soft HEAD~1
```

### Repo malproksima

```bash
git remote add origin <URL>
git branch -M main
git pull origin main # = fetch + merge
git push -u origin main --force-with-lease
git push --set-upstream origin bugfix1
```

Reiri al stato de malproksima (forviŝi lokalen):

```bash
git fetch origin
git reset --hard origin/main
```

## Submodules kaj Subtrees

### `git submodule add/update`

```bash
git submodule add -b main https://github.com/orga/projet-externe.git path/to/submodule
git submodule update --init --recursive
git submodule update --remote --merge
```

Poste: `cd path/to/submodule` -> fetch/pull -> reveni al parent -> `git add path/to/submodule` + commit

#### `git submodule deinit` (Forigi submodule)

```bash
git submodule deinit -f path/to/submodule
git rm -f path/to/submodule
rm -rf .git/modules/path/to/submodule
git commit -m "Remove submodule"
```

### `git subtree`

```bash
git remote add {projet-externe} https://github.com/orga/projet-externe.git
git fetch {projet-externe}
git subtree add --prefix=path/to/subtree {projet-externe} main --squash
git subtree pull --prefix=path/to/subtree {projet-externe} main --squash
git subtree push --prefix=path/to/subtree {projet-externe} main
```

## Problemoj oftaj

- `reveal.js/reveal.js` — atentu duoblan nomadon en subdosieroj
- `.git` en subdosieroj: prefere `subtree` aŭ forigi `.git`
- `pdf`/`toml` ofte ekzkludataj: uzi `git add -f` por devigi

### `Please enter a commit message` (editor)

- Uzu sagetojn por navigi
- `o` por enmeti linion
- tiam `esc` + `:wq` por savi kaj eliri.

## Github / Gitlab

- uzu oficialajn etendaĵojn por VSCode por Gitlab/Github
- Github CLI
  ```bash
  gh auth login
  gh auth status
  gh repo create
  ```


## Diagnostiko

```bash
git fsck --full
```
