# Git — Mallonga referenco

## FOSS versia kontrolilo

- desegnita por kunlabora programado je komunuma skalo  
  - $\Delta$‑bazitaj momentfotoj  
    - simpla dezajno : tre fidinda  
    - minimuma rimed-uzo  
    - alta rapido  
    - forta subteno por nelineara evoluo  
      - miloj da paralelaj branĉoj  
    - plene distribuita

## Evoluigita de Linus Torvalds kaj la Linuksa programista komunumo

- por anstataŭigi la proprietan *BitKeeper*  
  - kiu estis provizita al ili senpage ĝis 2005

## Tutmonda famo

- varbovorto  
  - *Github*  
  - *Gitlab*

## Rimedoj

- [learngitbranching.js.org](https://learngitbranching.js.org/)

## 1. Bazoj

### `git init`

```bash
echo "# koda-ronzz-org" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin {remote-url}
git push -u origin main
```

### `git config`

```bash
git config --global user.name "Rong Zhou"
git config --global user.email "ron@ronzz.org"
git config user.<valeur>
git config credential.helper 'cache --timeout 36000' # --global
```

### `git log`

- loka branĉo:

  ```bash
  git log --graph --oneline --decorate {branch-name : default HEAD} # --all --color
  ```

- malloka branĉo:

  ```bash
  git fetch origin
  git log --graph --oneline --decorate --color origin/feature-x
  ```

### `git commit`, `git branch`, `git rebase`

```bash
git commit
git branch {branch_name}
git switch {branch_name/commit/relative_ref} # kreos se ne ekzistas; --orphan = sen historio

git merge {branch_name}
git branch -d {branch_name} # forigi lokan jam kunfanditan
git push origin --delete init # forigi mallokan referencon

git rebase {target_parent_branch} # -i por interaktiva
```

### `git rollback`

```bash
git branch -f {branch/HEAD_to_move} {destination} # movas ref sen movi commit-ojn
git reset HEAD~1     # nuligi lastan commit (loka)
git revert HEAD       # krei novan commit kiu nuligas HEAD
```

### `git restore`

```bash
git restore --source main resources/ # restaŭri dosieron el alia branĉo
```

### `git cherry-pick`

```bash
git cherry-pick {commit}
git commit --amend
```

### `git tag`

```bash
git tag {tag_name} {commit : default HEAD}
git describe {commit}
```

### `git stash`

```bash
git stash push -m "mesaĝo"   # -k nur tracked; -u inkluzivas untracked
git stash list
git stash show -p stash@{0}
git stash pop stash@{0}
git stash apply stash@{0}    # ne forigas stash
git stash drop stash@{0}
git stash clear               # danĝera
```

---

## 2. Kunlaboro en linio

### `git clone`

```bash
git clone <URL>
git clone --single-branch --branch <branĉo> <url>
```

### `.gitignore`

Placiĝu en radiko de deponejo:

```text
passwords.txt
*.txt
```

### Bazaj ordonoj

```bash
rm -rf .git
git init
git status        # -s por mallonga
git add .
git add <file>
git diff          # --staged por staged diff
git commit -m "mesaĝo" -a   # -a = aŭtomata add
```

### Rollback specife

```bash
git reset --soft HEAD~1
```

### Repo malloka

```bash
git remote add origin {URL}
git branch -M main
git pull origin main          # fetch + merge
git push -u origin main --force-with-lease
git push --set-upstream origin bugfix1
```

Reiri al stato de malloka (forviŝi lokalen):

```bash
git fetch origin
git reset --hard origin/main
```

---

## 3. Submodules kaj Subtrees

### `git submodule`

```bash
git submodule add -b main https://github.com/orga/projet-externe.git path/to/submodule
git submodule update --init --recursive
git submodule update --remote --merge
```

Poste:

1. `cd path/to/submodule`
2. `git fetch` / `git pull`
3. Reveni al parent
4. `git add path/to/submodule` + commit

#### Forigi submodule

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

---

## 4. Problemoj oftaj

- duobla nomado en subdosieroj (`reveal.js/reveal.js`)
- `.git` en subdosieroj → uzu `subtree` aŭ forigu `.git`
- `pdf`/`toml` ofte ekskludataj → `git add -f`

### `Please enter a commit message` (editor)

- sagetoj por navigi  
- `o` por enmeti linion  
- `esc` + `:wq` por savi kaj eliri  

---

## 5. Github / Gitlab

- uzu oficialajn VSCode-etendaĵojn
- Github CLI:

  ```bash
  gh auth login
  gh auth status
  gh repo create
  ```

---

## 6. Diagnostiko

```bash
git fsck --full
```
