"""donnees_test.py : (re)crée projet.db et la remplit de données de test réalistes.

Volumes : 5 catégories, 40 produits, 60 commandes, plus de 150 lignes de commande.
Lancer : python donnees_test.py
"""
import os
import random
import sqlite3
from datetime import date, datetime, timedelta

from werkzeug.security import generate_password_hash

DOSSIER = os.path.dirname(os.path.abspath(__file__))

# Chaque catégorie : description, image, fourchette de prix (FCFA), artisans, phrase, produits
CATEGORIES = {
    "Sculptures": {
        "description": "Bois sculpté, laiton et objets royaux des Grassfields.",
        "image": "img/sculpture.jpg", "prix": (8000, 90000),
        "artisans": ["Atelier Njoya (Foumban)", "Pierre Tchoupo", "Moussa Bello"],
        "phrase": "Sculpté à la main dans un bois local, pièce unique.",
        "produits": ["Masque bamiléké", "Statuette de la reine mère", "Tabouret royal sculpté",
                     "Éléphant en bois", "Tambour parleur", "Calebasse gravée",
                     "Pipe bamoun en laiton", "Panneau de case sculpté"],
    },
    "Sacs en raphia": {
        "description": "Sacs et paniers tressés en fibres de raphia.",
        "image": "img/raphia.jpg", "prix": (5000, 25000),
        "artisans": ["Rose Ekane", "Coopérative des tisseuses de Bamenda"],
        "phrase": "Tressé en raphia naturel, léger et solide.",
        "produits": ["Sac cabas en raphia", "Sac à bandoulière tressé", "Pochette raphia et wax",
                     "Panier de marché", "Chapeau en raphia", "Sac à dos en raphia",
                     "Cabas rayé bleu", "Tapis de raphia"],
    },
    "Tissus": {
        "description": "Ndop, toghu, batik et broderies de l'Ouest.",
        "image": "img/tissus.jpg", "prix": (6000, 45000),
        "artisans": ["Sandra Mbarga", "Coopérative des teinturières de Foumban", "Aline Fotso"],
        "phrase": "Tissu teint et brodé à la main selon les motifs traditionnels.",
        "produits": ["Pagne ndop indigo", "Toghu brodé", "Écharpe bamoun", "Nappe en batik",
                     "Coussin ndop", "Tenue kaba", "Chemin de table brodé", "Batik de Foumban"],
    },
    "Bijoux": {
        "description": "Perles, laiton et bronze travaillés à la main.",
        "image": "img/bijoux.jpg", "prix": (2500, 20000),
        "artisans": ["Marie Atangana", "Ibrahim Njoya"],
        "phrase": "Bijou fait main, fermoir solide, livré dans une pochette.",
        "produits": ["Collier de perles bamiléké", "Bracelet en laiton", "Boucles d'oreilles en raphia",
                     "Bague en bronze", "Collier en perles de verre", "Bracelet cuir et perles",
                     "Pendentif masque en laiton", "Parure de perles"],
    },
    "Décoration": {
        "description": "Terre cuite, rotin, bambou et laiton pour la maison.",
        "image": "img/decoration.jpg", "prix": (4000, 35000),
        "artisans": ["Paul Ngo Bassa", "Kevin Tchoupo", "Rose Ekane"],
        "phrase": "Fabriqué à la main, finition naturelle pour la maison.",
        "produits": ["Vase en terre cuite", "Lampe en rotin", "Miroir au cadre sculpté",
                     "Corbeille en bambou", "Bougeoir en laiton", "Panier à linge tressé",
                     "Suspension en raphia", "Plateau en bois"],
    },
}

NOMS = ["Mbarga", "Ngo Bassa", "Fotso", "Atangana", "Njoya", "Ekane", "Tchoupo", "Bello", "Kamga", "Nkeng"]
PRENOMS = ["Aline", "Paul", "Kevin", "Marie", "Ibrahim", "Sandra", "Rose", "Moussa", "Estelle", "Brice"]
VILLES = ["Douala", "Yaoundé", "Bafoussam", "Garoua", "Kribi", "Buea", "Bamenda", "Foumban"]
QUARTIERS = ["Bonamoussadi", "Akwa", "Bastos", "Mvog-Ada", "Makepe", "Centre-ville", "Nkolbisson"]


def remplir(db):
    """Remplit d'abord les tables indépendantes, puis celles qui les référencent."""
    # --- catégories et produits ---
    produits_crees = []
    for nom_cat, cat in CATEGORIES.items():
        cur = db.execute("INSERT INTO categories (nom, description) VALUES (?, ?)",
                         (nom_cat, cat["description"]))
        cat_id = cur.lastrowid
        for nom in cat["produits"]:
            prix = random.randrange(cat["prix"][0], cat["prix"][1], 500)
            cur = db.execute(
                "INSERT INTO produits (nom, categorie_id, description, prix, stock, image, artisan, actif)"
                " VALUES (?, ?, ?, ?, ?, ?, ?, 1)",
                (nom, cat_id, f"{nom}. {cat['phrase']}", prix, random.randint(5, 40),
                 cat["image"], random.choice(cat["artisans"])))
            produits_crees.append(cur.lastrowid)

    # Quelques stocks bas (dont 2 épuisés) pour tester l'alerte, et 2 produits désactivés
    for pid in random.sample(produits_crees, 6):
        db.execute("UPDATE produits SET stock = ? WHERE id = ?", (random.randint(0, 4), pid))
    db.execute("UPDATE produits SET stock = 0 WHERE id IN (3, 17)")
    db.execute("UPDATE produits SET actif = 0 WHERE id IN (11, 29)")

    # --- codes de réduction (le dernier est expiré) ---
    demain_un_an = (date.today() + timedelta(days=365)).isoformat()
    db.executemany("INSERT INTO codes_reduction (code, pourcentage, date_expiration) VALUES (?, ?, ?)",
                   [("BIENVENUE10", 10, demain_un_an), ("FETE15", 15, demain_un_an),
                    ("ETE2025", 20, "2025-09-01")])

    # --- commandes et lignes de commande ---
    prix = dict(db.execute("SELECT id, prix FROM produits").fetchall())
    ids = list(prix)
    statuts = ["livrée"] * 36 + ["préparée"] * 9 + ["reçue"] * 9 + ["annulée"] * 6
    random.shuffle(statuts)
    avec_trois_lignes = set(random.sample(range(60), 35))   # 60*2 + 35 = 155 lignes
    for i, statut in enumerate(statuts):
        jours = random.randint(0, 6) if statut in ("reçue", "préparée") else random.randint(0, 240)
        quand = datetime.now() - timedelta(days=jours, minutes=random.randint(0, 600))
        lignes = [(pid, random.randint(1, 3), prix[pid])
                  for pid in random.sample(ids, 3 if i in avec_trois_lignes else 2)]
        sous_total = sum(q * p for _, q, p in lignes)
        code_id, pourcent = (None, 0)
        if random.random() < 0.2:
            code_id, pourcent = random.choice([(1, 10), (2, 15)])
        reduction = sous_total * pourcent // 100
        ville = random.choice(VILLES)
        cur = db.execute(
            "INSERT INTO commandes (client_nom, client_telephone, adresse, date, mode_paiement,"
            " statut, sous_total, reduction, code_id, total) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (f"{random.choice(PRENOMS)} {random.choice(NOMS)}",
             f"6{random.randint(5, 9)}{random.randint(0, 9999999):07d}",
             f"{random.choice(QUARTIERS)}, {ville}", quand.strftime("%Y-%m-%d %H:%M:%S"),
             random.choice(["livraison", "mobile_money"]), statut,
             sous_total, reduction, code_id, sous_total - reduction))
        for pid, q, p in lignes:
            db.execute("INSERT INTO lignes_commande (commande_id, produit_id, quantite, prix_unitaire)"
                       " VALUES (?, ?, ?, ?)", (cur.lastrowid, pid, q, p))

    # --- compte administrateur de test ---
    db.execute("INSERT INTO administrateurs (login, empreinte) VALUES (?, ?)",
               ("admin", generate_password_hash("Admin!2026")))
    db.commit()


if __name__ == "__main__":
    random.seed(42)  # mêmes données à chaque lancement
    chemin = os.path.join(DOSSIER, "projet.db")
    db = sqlite3.connect(chemin)
    db.execute("PRAGMA foreign_keys = ON")
    with open(os.path.join(DOSSIER, "schema.sql"), encoding="utf-8") as f:
        db.executescript(f.read())
    remplir(db)
    for table in ("categories", "produits", "codes_reduction", "commandes", "lignes_commande"):
        n = db.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
        print(f"{table} : {n} lignes")
    db.close()
