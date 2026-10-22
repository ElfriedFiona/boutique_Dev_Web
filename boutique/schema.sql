-- schema.sql : structure de la base SQLite de la boutique d'artisanat
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS lignes_commande;
DROP TABLE IF EXISTS commandes;
DROP TABLE IF EXISTS codes_reduction;
DROP TABLE IF EXISTS produits;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS administrateurs;

-- Comptes de l'espace d'administration (mot de passe stocké sous forme d'empreinte)
CREATE TABLE administrateurs (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    login     TEXT NOT NULL UNIQUE,
    empreinte TEXT NOT NULL
);

CREATE TABLE categories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nom         TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT ''
);

-- Prix en francs CFA (entiers : le franc CFA n'a pas de centimes)
CREATE TABLE produits (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    nom          TEXT    NOT NULL,
    categorie_id INTEGER NOT NULL REFERENCES categories(id),
    description  TEXT    NOT NULL DEFAULT '',
    prix         INTEGER NOT NULL CHECK (prix > 0),
    stock        INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    image        TEXT    NOT NULL DEFAULT 'img/defaut.jpg',
    artisan      TEXT    NOT NULL,
    actif        INTEGER NOT NULL DEFAULT 1 CHECK (actif IN (0, 1))
);

-- Bonus : codes de réduction avec date d'expiration (format AAAA-MM-JJ)
CREATE TABLE codes_reduction (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    code            TEXT    NOT NULL UNIQUE,
    pourcentage     INTEGER NOT NULL CHECK (pourcentage BETWEEN 1 AND 100),
    date_expiration TEXT    NOT NULL
);

CREATE TABLE commandes (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    client_nom       TEXT    NOT NULL,
    client_telephone TEXT    NOT NULL,
    adresse          TEXT    NOT NULL,
    date             TEXT    NOT NULL,   -- AAAA-MM-JJ HH:MM:SS
    mode_paiement    TEXT    NOT NULL CHECK (mode_paiement IN ('livraison', 'mobile_money')),
    statut           TEXT    NOT NULL DEFAULT 'reçue'
                     CHECK (statut IN ('reçue', 'préparée', 'livrée', 'annulée')),
    sous_total       INTEGER NOT NULL CHECK (sous_total >= 0),
    reduction        INTEGER NOT NULL DEFAULT 0 CHECK (reduction >= 0),
    code_id          INTEGER REFERENCES codes_reduction(id),
    total            INTEGER NOT NULL CHECK (total >= 0)
);

-- Le prix unitaire est copié ici : les anciennes commandes ne changent jamais
CREATE TABLE lignes_commande (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    commande_id   INTEGER NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
    produit_id    INTEGER NOT NULL REFERENCES produits(id),
    quantite      INTEGER NOT NULL CHECK (quantite > 0),
    prix_unitaire INTEGER NOT NULL CHECK (prix_unitaire > 0),
    UNIQUE (commande_id, produit_id)
);

CREATE INDEX idx_produits_categorie ON produits(categorie_id);
CREATE INDEX idx_commandes_statut   ON commandes(statut);
CREATE INDEX idx_lignes_commande    ON lignes_commande(commande_id);
