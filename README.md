# L'Atelier des Glyphes

Prototype de compilateur magique visuel réalisé avec Godot 4.4.

## Utilisation

1. Dessiner un emblème-source près du centre de la feuille.
2. Ajouter des opérateurs autour de la source.
3. Tracer un grand cercle fermé autour du programme.
4. Ajuster le contexte physique sous la feuille.
5. Cliquer sur **Compiler**.

Le tutoriel intégré montre toutes les formes reconnues. Le bouton **Charger un exemple** produit un pentacle d'eau complet.

## Reconnaissance

La version actuelle utilise une reconnaissance géométrique explicable : rééchantillonnage des traits, normalisation, comparaison de modèles sous plusieurs rotations, estimation de confiance et reconstruction vectorielle. Cette architecture permet d'ajouter plus tard un modèle appris sans modifier le compilateur physique.

## Lancer depuis le projet

```bash
godot --path .
```

## Version Linux

Le paquet prêt à lancer se trouve ici :

```text
build/AtelierDesGlyphes-Linux-x86_64.tar.gz
```

Après extraction, conserver `AtelierDesGlyphes` et
`AtelierDesGlyphes.pck` dans le même dossier, puis lancer :

```bash
./AtelierDesGlyphes
```

