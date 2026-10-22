# Projet 2 : Boutique en ligne d'artisanat (Mains de l'Ouest)

Boutique pour une coopérative d'artisans de Foumban et de Bamenda : catalogue, panier,
commande (paiement à la livraison ou mobile money), espace d'administration, API JSON et statistiques.
Stack : Python 3, Flask, SQLite (module `sqlite3`), HTML5, CSS, JavaScript.

## Installation

```
python -m venv venv
venv\Scripts\activate          (Windows)
source venv/bin/activate       (Linux / macOS)
pip install -r requirements.txt
```

## Lancement (la base `projet.db` est déjà remplie)

```
python app.py
```

Puis ouvrir http://127.0.0.1:5000

## Recréer les données de test

```
python donnees_test.py     # recrée projet.db : 5 catégories, 40 produits, 60 commandes, 155 lignes
python exporter.py         # regénère export_projet.sql
```

Pour recréer la base depuis l'export SQL :
`sqlite3.connect("projet.db").executescript(open("export_projet.sql", encoding="utf-8").read())`

## Compte administrateur de test

- Adresse : http://127.0.0.1:5000/admin/connexion
- login : `admin`
- mot de passe : `Admin!2026`

## Ce qu'il faut tester

| Fonction | Où |
|---|---|
| Catalogue, filtre par catégorie, tri par prix, recherche | `/` |
| Fiche produit « en stock » / « épuisé » (produits n°3 et n°17 épuisés) | `/produit/1`, `/produit/3` |
| Panier (ajout, quantités, retrait, total en direct) | `/panier` |
| Validation de commande + confirmation | `/commande` |
| Codes de réduction (bonus) : `BIENVENUE10`, `FETE15` valides, `ETE2025` expiré | `/commande` |
| Fiche artisan (bonus) | clic sur le nom de l'artisan d'un produit |
| Produits, commandes filtrées par statut, alerte stock < 5, statistiques | `/admin` |
| API JSON | `/api/produits` (public), `/api/statistiques` (connexion admin requise) |

## Règles métier

- **Total recalculé par le serveur** : le navigateur n'envoie que des identifiants et des quantités, jamais de prix.
- **Stock** : vérifié puis diminué à la validation (transaction `BEGIN IMMEDIATE`) ; une commande annulée remet ses quantités en stock.
- **Prix copié** dans `lignes_commande.prix_unitaire` : changer un prix ne modifie pas les anciennes commandes.
- **Statuts** : reçue → préparée → livrée ; une commande reçue ou préparée peut être annulée. « livrée » et « annulée » sont définitifs.
- **Statistiques** : le chiffre d'affaires par mois ne compte que les commandes livrées ; le top 5 des produits et le panier moyen excluent les commandes annulées ; la répartition par paiement compte toutes les commandes.

## Structure

```
app.py            routes Flask, API, administration
schema.sql        tables, clés étrangères, contraintes (NOT NULL, UNIQUE, CHECK)
donnees_test.py   remplit la base (random.seed(42) : données reproductibles)
exporter.py       export SQL de la base
templates/        base.html dont héritent toutes les pages, 404.html
static/css|js|img style.css (mobile d'abord), panier.js, panier-page.js, commande.js, admin.js
```

## Sécurité

Requêtes SQL paramétrées, mots de passe hachés (`generate_password_hash`), jeton CSRF sur chaque formulaire POST,
modifications et suppressions uniquement en POST, données revérifiées côté serveur, envoi d'image limité à PNG/JPG/WEBP (2 Mo),
`debug=False`. Pour un vrai déploiement, définir la variable d'environnement `SECRET_KEY`.

## Validation W3C

Les pages principales se valident sur https://validator.w3.org/#validate_by_input : ouvrir la page, clic droit
« Afficher le code source », copier le code dans le validateur (pages d'administration : après connexion).
