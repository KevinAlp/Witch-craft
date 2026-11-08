# L'Atelier des Glyphes

Compilateur magique visuel réalisé avec Godot. Le joueur dessine un pentacle
sur une feuille blanche ; le programme reconnaît ses traits, reconstruit les
glyphes, valide le « programme » magique et calcule son résultat physique.

## Fonctionnalités

- dessin libre à la souris ou à la tablette ;
- plume, gomme, annulation et rétablissement ;
- tutoriel illustré, passable et accessible à tout moment ;
- sources élémentaires : eau, feu, air et terre ;
- opérateurs : sélection, convergence, accélération, maintien et dispersion ;
- correction vectorielle des glyphes imparfaits ;
- compilation en pseudo-code ;
- estimation du rendement, de la puissance, de la masse, de la vitesse, de la
  durée, de l'énergie d'impact et des dommages ;
- diagnostics des erreurs de syntaxe, de type et de stabilité.

La reconnaissance actuelle est géométrique et déterministe : elle rééchantillonne
les traits, les normalise, les compare à des modèles sous plusieurs rotations et
calcule un score de confiance. Aucun modèle d'IA externe, service en ligne ou
compte utilisateur n'est nécessaire.

## Utiliser la version Linux publiée

### Systèmes pris en charge

- Linux 64 bits sur processeur `x86_64` ;
- distribution avec `glibc` 2.28 ou plus récente ;
- session graphique X11 ou Wayland avec prise en charge XWayland ;
- carte graphique et pilote compatibles OpenGL 3.3 au minimum.

### Installation

Télécharger l'archive depuis la page des releases, puis :

```bash
tar -xzf AtelierDesGlyphes-Linux-x86_64.tar.gz
cd AtelierDesGlyphes-Linux-x86_64
chmod +x AtelierDesGlyphes
./AtelierDesGlyphes
```

Le paquet officiel est autonome : Godot, les scripts et les ressources du jeu
sont intégrés à l'exécutable. Il n'utilise ni Python, ni Node.js, ni Java, ni
base de données, ni connexion réseau.

### Dépendances d'exécution

Les bibliothèques suivantes sont normalement déjà présentes sur une distribution
Linux de bureau :

- `glibc` 2.28 ou plus récente et le chargeur ELF 64 bits ;
- les bibliothèques de fenêtre X11/XCB ou Wayland fournies par la distribution ;
- un pilote OpenGL fonctionnel, généralement Mesa ou le pilote du constructeur ;
- les bibliothèques audio ALSA/PulseAudio si le système les utilise.

Pour identifier une bibliothèque manquante sur une machine particulière :

```bash
ldd ./AtelierDesGlyphes | grep "not found"
```

Sur Debian ou Ubuntu, les dépendances graphiques de base peuvent être installées
avec :

```bash
sudo apt update
sudo apt install libc6 libx11-6 libxcursor1 \
  libxinerama1 libxi6 libxrandr2 libgl1 libasound2
```

Les noms de paquets diffèrent sur Fedora, Arch Linux et les autres distributions.

### Avertissement `DRI_PRIME`

Le message suivant vient du pilote graphique et non du jeu :

```text
Inconsistent value (...) for DRI_PRIME
```

Il est généralement sans conséquence. Pour lancer le jeu sans cette variable :

```bash
env -u DRI_PRIME ./AtelierDesGlyphes
```

## Développer le projet

### Dépendances obligatoires

| Dépendance | Version | Utilité |
| --- | --- | --- |
| Godot Standard | `4.4.1` | Éditeur, exécution, tests et export |
| Modèles d'export Godot | `4.4.1` | Création du binaire Linux publié |
| Git | version récente | Gestion du dépôt |

Utiliser l'édition **Standard** de Godot, et non l'édition .NET/Mono. Le projet
n'utilise aucun module natif, plugin, paquet GDScript externe ou sous-module Git.

Pour vérifier la version installée :

```bash
godot --version
```

Le résultat doit commencer par `4.4.1`.

### Cloner et lancer

```bash
git clone <URL_DU_DEPOT>
cd Witch-craft
godot --path .
```

Il est aussi possible d'importer `project.godot` depuis le gestionnaire de
projets Godot.

### Lancer les vérifications

Validation des scripts et des ressources :

```bash
godot --headless --path . --editor --quit
```

Test du compilateur magique :

```bash
godot --headless --path . --script tests/compiler_smoke_test.gd
```

Le test doit afficher une ligne commençant par `PASS`.

### Installer les modèles d'export

Dans l'éditeur Godot :

1. ouvrir **Éditeur > Gérer les modèles d'export** ;
2. télécharger les modèles correspondant exactement à Godot `4.4.1` ;
3. attendre la fin de l'installation avant de lancer l'export.

Les modèles d'une autre version de Godot ne doivent pas être utilisés.

### Construire la version Linux

```bash
mkdir -p build
godot --headless --path . \
  --export-release "Linux" build/AtelierDesGlyphes.x86_64
chmod +x build/AtelierDesGlyphes.x86_64
```

Pour créer l'archive distribuable :

```bash
mkdir -p build/AtelierDesGlyphes-Linux-x86_64
cp build/AtelierDesGlyphes.x86_64 \
  build/AtelierDesGlyphes-Linux-x86_64/AtelierDesGlyphes
tar -czf build/AtelierDesGlyphes-Linux-x86_64.tar.gz \
  -C build AtelierDesGlyphes-Linux-x86_64
```

Le dossier `build/` est volontairement ignoré par Git. Les exécutables et
archives doivent être publiés comme pièces jointes d'une release, pas ajoutés
au dépôt.

## Structure du dépôt

```text
.
├── main.tscn                   # scène principale
├── project.godot               # configuration Godot
├── export_presets.cfg          # préréglages d'export versionnés
├── scripts/
│   ├── main.gd                 # interface principale
│   ├── drawing_canvas.gd       # feuille et saisie des traits
│   ├── magic_language.gd       # alphabet et formes canoniques
│   ├── magic_compiler.gd       # reconnaissance et physique
│   ├── tutorial_overlay.gd     # tutoriel intégré
│   └── glyph_preview.gd        # aperçu des glyphes
└── tests/
    └── compiler_smoke_test.gd  # test fonctionnel minimal
```

Les fichiers `.gd.uid` générés par Godot sont versionnés volontairement : ils
stabilisent les références aux scripts. Le dossier `.godot/`, en revanche, est
un cache local et ne doit jamais être ajouté au dépôt.

## Dépannage

### Le jeu n'a pas la permission de s'exécuter

```bash
chmod +x AtelierDesGlyphes
```

### Godot ne trouve pas une classe ou un script

Supprimer uniquement le cache local, puis laisser Godot le reconstruire :

```bash
rm -rf .godot
godot --headless --path . --editor --quit
```

Ne pas supprimer les fichiers `.gd.uid` suivis par Git.

### Le rendu OpenGL ne démarre pas

Vérifier le pilote :

```bash
glxinfo -B
```

Sur une machine hybride, essayer également :

```bash
env -u DRI_PRIME godot --path .
```

