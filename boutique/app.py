"""Boutique en ligne de la coopérative d'artisans de Foumban et de Bamenda.

Lancer : python app.py  puis ouvrir http://127.0.0.1:5000
"""
import json
import os
import re
import secrets
import sqlite3
from datetime import date, datetime
from functools import wraps

from flask import (Flask, abort, flash, g, jsonify, redirect, render_template,
                   request, session, url_for)
from werkzeug.security import check_password_hash
from werkzeug.utils import secure_filename

DOSSIER = os.path.abspath(os.path.dirname(__file__))
CHEMIN_BASE = os.path.join(DOSSIER, "projet.db")
DOSSIER_UPLOADS = os.path.join(DOSSIER, "static", "uploads")
EXTENSIONS_IMAGE = {"png", "jpg", "jpeg", "webp"}  # pas de SVG envoyé : il peut contenir du script

MODES_PAIEMENT = {"livraison": "Paiement à la livraison", "mobile_money": "Mobile money"}
STATUTS = ["reçue", "préparée", "livrée", "annulée"]
# Passages de statut autorisés (« livrée » et « annulée » sont définitifs)
TRANSITIONS = {"reçue": ["préparée", "annulée"], "préparée": ["livrée", "annulée"],
               "livrée": [], "annulée": []}
# Liste blanche des tris : la valeur choisie par le visiteur ne va jamais directement dans le SQL
TRIS = {"nom": "p.nom ASC", "prix_asc": "p.prix ASC", "prix_desc": "p.prix DESC"}
SEUIL_ALERTE_STOCK = 5

app = Flask(__name__)
# En production, définir la variable d'environnement SECRET_KEY
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "cle-de-developpement-a-changer")
app.config["MAX_CONTENT_LENGTH"] = 2 * 1024 * 1024  # images de 2 Mo maximum


# ----------------------------------------------------------------------------
# Base de données
# ----------------------------------------------------------------------------
def get_db():
    """Ouvre (une fois par requête) la connexion SQLite, clés étrangères activées."""
    if "db" not in g:
        g.db = sqlite3.connect(CHEMIN_BASE)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


@app.teardown_appcontext
def fermer_db(_erreur):
    db = g.pop("db", None)
    if db is not None:
        db.close()


# ----------------------------------------------------------------------------
# Sécurité : jeton CSRF sur tous les formulaires POST, en-têtes de protection
# ----------------------------------------------------------------------------
@app.before_request
def verifier_csrf():
    if request.method == "POST":
        attendu = session.get("csrf", "")
        recu = request.form.get("csrf", "")
        if not attendu or not secrets.compare_digest(attendu, recu):
            abort(400)


@app.context_processor
def contexte_commun():
    """Variables disponibles dans tous les gabarits."""
    if "csrf" not in session:
        session["csrf"] = secrets.token_hex(16)
    return {"csrf": session["csrf"], "admin_connecte": "admin_id" in session,
            "MODES_PAIEMENT": MODES_PAIEMENT, "SEUIL": SEUIL_ALERTE_STOCK}


@app.after_request
def en_tetes_securite(reponse):
    reponse.headers["X-Content-Type-Options"] = "nosniff"
    reponse.headers["Content-Security-Policy"] = (
        "default-src 'self'; img-src 'self' data:; frame-ancestors 'none'")
    return reponse


@app.template_filter("fcfa")
def filtre_fcfa(montant):
    """12500 -> « 12 500 FCFA » (espace insécable fine)."""
    return f"{int(montant):,}".replace(",", "\u202f") + "\u00a0FCFA"


@app.template_filter("classe_statut")
def filtre_classe_statut(statut):
    """« préparée » -> « preparee » pour nommer une classe CSS."""
    return statut.replace("é", "e").replace("ç", "c")


def connexion_requise(vue):
    """Décorateur : réserve une route à l'administrateur connecté."""
    @wraps(vue)
    def enveloppe(*args, **kwargs):
        if "admin_id" not in session:
            if request.path.startswith("/api/"):
                return jsonify(erreur="Connexion requise"), 401
            return redirect(url_for("admin_connexion", suivant=request.path))
        return vue(*args, **kwargs)
    return enveloppe


# ----------------------------------------------------------------------------
# Fonctions utilitaires
# ----------------------------------------------------------------------------
def chercher_produits(categorie=None, recherche="", tri="nom", ids=None, artisan=None):
    """Renvoie les produits actifs, filtrés et triés (requête toujours paramétrée)."""
    sql = ("SELECT p.*, c.nom AS categorie FROM produits p "
           "JOIN categories c ON c.id = p.categorie_id WHERE p.actif = 1")
    params = []
    if categorie:
        sql += " AND p.categorie_id = ?"
        params.append(categorie)
    if recherche:
        sql += " AND (p.nom LIKE ? OR p.description LIKE ? OR p.artisan LIKE ?)"
        params += [f"%{recherche}%"] * 3
    if artisan:
        sql += " AND p.artisan = ?"
        params.append(artisan)
    if ids:
        sql += " AND p.id IN (%s)" % ",".join("?" * len(ids))  # seuls des « ? » sont insérés
        params += ids
    sql += " ORDER BY " + TRIS.get(tri, TRIS["nom"])
    return get_db().execute(sql, params).fetchall()


def produit_en_dict(p):
    """Version JSON d'un produit."""
    return {"id": p["id"], "nom": p["nom"], "categorie": p["categorie"], "description": p["description"],
            "prix": p["prix"], "stock": p["stock"], "en_stock": p["stock"] > 0, "artisan": p["artisan"],
            "image": url_for("static", filename=p["image"]),
            "url": url_for("produit", produit_id=p["id"])}


def lire_panier(brut):
    """Transforme le JSON envoyé par le navigateur en {produit_id: quantité}.

    On ne garde QUE les identifiants et les quantités : jamais un prix venant du navigateur.
    Renvoie None si le contenu est invalide.
    """
    try:
        donnees = json.loads(brut or "[]")
    except ValueError:
        return None
    if not isinstance(donnees, list):
        return None
    panier = {}
    for ligne in donnees:
        try:
            pid, quantite = int(ligne["id"]), int(ligne["quantite"])
        except (KeyError, TypeError, ValueError):
            return None
        if not 1 <= quantite <= 99:
            return None
        panier[pid] = panier.get(pid, 0) + quantite
    return panier


def calculer_statistiques(db):
    """Les quatre statistiques demandées."""
    ca_par_mois = [dict(r) for r in db.execute(
        "SELECT strftime('%Y-%m', date) AS mois, SUM(total) AS chiffre_affaires "
        "FROM commandes WHERE statut = 'livrée' GROUP BY mois ORDER BY mois")]
    top_produits = [dict(r) for r in db.execute(
        "SELECT p.nom, SUM(l.quantite) AS quantite FROM lignes_commande l "
        "JOIN commandes c ON c.id = l.commande_id JOIN produits p ON p.id = l.produit_id "
        "WHERE c.statut != 'annulée' GROUP BY p.id ORDER BY quantite DESC, p.nom LIMIT 5")]
    moyenne = db.execute("SELECT AVG(total) FROM commandes WHERE statut != 'annulée'").fetchone()[0]
    paiements = [dict(r) for r in db.execute(
        "SELECT mode_paiement, COUNT(*) AS nombre FROM commandes GROUP BY mode_paiement")]
    return {"chiffre_affaires_par_mois": ca_par_mois, "top_produits": top_produits,
            "panier_moyen": round(moyenne) if moyenne else 0, "paiements": paiements}


class ErreurCommande(Exception):
    """Erreur métier lors de la validation d'une commande (message affiché au client)."""


# ----------------------------------------------------------------------------
# Partie publique
# ----------------------------------------------------------------------------
@app.route("/")
def catalogue():
    categorie = request.args.get("categorie", type=int)
    tri = request.args.get("tri", "nom")
    if tri not in TRIS:
        tri = "nom"
    recherche = request.args.get("q", "").strip()[:60]
    categories = get_db().execute("SELECT * FROM categories ORDER BY nom").fetchall()
    produits = chercher_produits(categorie, recherche, tri)
    return render_template("catalogue.html", produits=produits, categories=categories,
                           categorie=categorie, tri=tri, recherche=recherche)


@app.route("/produit/<int:produit_id>")
def produit(produit_id):
    lignes = chercher_produits(ids=[produit_id])
    if not lignes:
        abort(404)
    return render_template("produit.html", p=lignes[0])


@app.route("/artisan/<nom>")
def artisan(nom):
    produits = chercher_produits(artisan=nom)
    if not produits:
        abort(404)
    return render_template("artisan.html", nom=nom, produits=produits)


@app.route("/panier")
def panier():
    # Le contenu du panier vit dans le navigateur (localStorage) : voir static/js/panier.js
    return render_template("panier.html")


@app.route("/commande", methods=["GET", "POST"])
def commande():
    if request.method == "GET":
        return render_template("commande.html", valeurs={})

    nom = request.form.get("nom", "").strip()
    telephone = request.form.get("telephone", "").replace(" ", "")
    adresse = request.form.get("adresse", "").strip()
    mode = request.form.get("mode_paiement", "")
    code_texte = request.form.get("code", "").strip().upper()
    panier_client = lire_panier(request.form.get("panier"))

    # 1) Toutes les données sont revérifiées côté serveur
    erreurs = []
    if not 2 <= len(nom) <= 80:
        erreurs.append("Le nom doit contenir entre 2 et 80 caractères.")
    if not re.fullmatch(r"(\+?237)?6\d{8}", telephone):
        erreurs.append("Téléphone invalide : 9 chiffres commençant par 6 (ex. 677123456).")
    if not 5 <= len(adresse) <= 200:
        erreurs.append("L'adresse de livraison doit contenir entre 5 et 200 caractères.")
    if mode not in MODES_PAIEMENT:
        erreurs.append("Choisissez un mode de paiement.")
    if not panier_client:
        erreurs.append("Votre panier est vide ou invalide.")
    if code_texte and not re.fullmatch(r"[A-Z0-9]{3,20}", code_texte):
        erreurs.append("Code de réduction invalide.")
    valeurs = {"nom": nom, "telephone": telephone, "adresse": adresse, "mode_paiement": mode, "code": code_texte}
    if erreurs:
        for e in erreurs:
            flash(e, "erreur")
        return render_template("commande.html", valeurs=valeurs), 400

    # 2) Le serveur recalcule tout à partir de la base ; le stock est vérifié puis diminué
    db = get_db()
    db.execute("BEGIN IMMEDIATE")  # un seul client à la fois peut modifier le stock
    try:
        lignes = []
        for pid, quantite in panier_client.items():
            p = db.execute("SELECT id, nom, prix, stock, actif FROM produits WHERE id = ?", (pid,)).fetchone()
            if p is None or not p["actif"]:
                raise ErreurCommande(f"Le produit n°{pid} n'est plus disponible.")
            if p["stock"] < quantite:
                raise ErreurCommande(f"Stock insuffisant pour « {p['nom']} » : "
                                     f"{p['stock']} exemplaire(s) disponible(s).")
            lignes.append((p, quantite))
        sous_total = sum(p["prix"] * q for p, q in lignes)

        reduction, code_id = 0, None
        if code_texte:
            code = db.execute("SELECT * FROM codes_reduction WHERE code = ?", (code_texte,)).fetchone()
            if code is None or code["date_expiration"] < date.today().isoformat():
                raise ErreurCommande("Ce code de réduction est invalide ou expiré.")
            code_id = code["id"]
            reduction = sous_total * code["pourcentage"] // 100

        cur = db.execute(
            "INSERT INTO commandes (client_nom, client_telephone, adresse, date, mode_paiement,"
            " statut, sous_total, reduction, code_id, total) VALUES (?, ?, ?, ?, ?, 'reçue', ?, ?, ?, ?)",
            (nom, telephone, adresse, datetime.now().strftime("%Y-%m-%d %H:%M:%S"), mode,
             sous_total, reduction, code_id, sous_total - reduction))
        commande_id = cur.lastrowid
        for p, quantite in lignes:
            # Le prix est copié dans la ligne : les anciennes commandes ne changent jamais
            db.execute("INSERT INTO lignes_commande (commande_id, produit_id, quantite, prix_unitaire)"
                       " VALUES (?, ?, ?, ?)", (commande_id, p["id"], quantite, p["prix"]))
            maj = db.execute("UPDATE produits SET stock = stock - ? WHERE id = ? AND stock >= ?",
                             (quantite, p["id"], quantite))
            if maj.rowcount != 1:
                raise ErreurCommande(f"Stock insuffisant pour « {p['nom']} ».")
        db.commit()
    except ErreurCommande as e:
        db.rollback()
        flash(str(e), "erreur")
        return render_template("commande.html", valeurs=valeurs), 409
    except sqlite3.Error:
        db.rollback()
        flash("Une erreur technique est survenue. Réessayez dans un instant.", "erreur")
        return render_template("commande.html", valeurs=valeurs), 500

    session["derniere_commande"] = commande_id
    return redirect(url_for("confirmation", commande_id=commande_id))


@app.route("/confirmation/<int:commande_id>")
def confirmation(commande_id):
    # Seul le client qui vient de commander peut voir sa confirmation
    if session.get("derniere_commande") != commande_id:
        abort(404)
    db = get_db()
    c = db.execute("SELECT * FROM commandes WHERE id = ?", (commande_id,)).fetchone()
    lignes = db.execute("SELECT l.*, p.nom FROM lignes_commande l JOIN produits p ON p.id = l.produit_id "
                        "WHERE l.commande_id = ?", (commande_id,)).fetchall()
    return render_template("confirmation.html", c=c, lignes=lignes)


# ----------------------------------------------------------------------------
# API JSON
# ----------------------------------------------------------------------------
@app.route("/api/produits")
def api_produits():
    """Produits actifs. Paramètres facultatifs : categorie, q, tri, ids (ex. ids=1,4,7)."""
    ids = [int(x) for x in request.args.get("ids", "").split(",") if x.strip().isdigit()][:100]
    if "ids" in request.args and not ids:
        return jsonify([])
    produits = chercher_produits(request.args.get("categorie", type=int),
                                 request.args.get("q", "").strip()[:60],
                                 request.args.get("tri", "nom"), ids or None)
    return jsonify([produit_en_dict(p) for p in produits])


@app.route("/api/statistiques")
@connexion_requise
def api_statistiques():
    return jsonify(calculer_statistiques(get_db()))


# ----------------------------------------------------------------------------
# Administration
# ----------------------------------------------------------------------------
@app.route("/admin/connexion", methods=["GET", "POST"])
def admin_connexion():
    if request.method == "POST":
        login = request.form.get("login", "").strip()
        admin = get_db().execute("SELECT * FROM administrateurs WHERE login = ?", (login,)).fetchone()
        if admin and check_password_hash(admin["empreinte"], request.form.get("mot_de_passe", "")):
            session.clear()  # nouvelle session : évite la fixation de session
            session["admin_id"] = admin["id"]
            suivant = request.args.get("suivant", "")
            if not (suivant.startswith("/admin") and not suivant.startswith("//")):
                suivant = url_for("admin_tableau")
            return redirect(suivant)
        flash("Identifiant ou mot de passe incorrect.", "erreur")
    return render_template("admin_connexion.html")


@app.route("/admin/deconnexion", methods=["POST"])
def admin_deconnexion():
    session.clear()
    flash("Vous êtes déconnecté.", "succes")
    return redirect(url_for("catalogue"))


@app.route("/admin")
@connexion_requise
def admin_tableau():
    db = get_db()
    alertes = db.execute("SELECT id, nom, stock FROM produits WHERE stock < ? AND actif = 1 "
                         "ORDER BY stock, nom", (SEUIL_ALERTE_STOCK,)).fetchall()
    a_traiter = db.execute("SELECT COUNT(*) FROM commandes WHERE statut = 'reçue'").fetchone()[0]
    return render_template("admin_tableau.html", alertes=alertes, a_traiter=a_traiter)


@app.route("/admin/produits")
@connexion_requise
def admin_produits():
    produits = get_db().execute(
        "SELECT p.*, c.nom AS categorie FROM produits p JOIN categories c ON c.id = p.categorie_id "
        "ORDER BY p.actif DESC, p.nom").fetchall()
    return render_template("admin_produits.html", produits=produits)


def enregistrer_image(fichier):
    """Enregistre l'image envoyée et renvoie son chemin (relatif à static/), ou None."""
    if not fichier or not fichier.filename:
        return None
    nom = secure_filename(fichier.filename)
    extension = nom.rsplit(".", 1)[-1].lower() if "." in nom else ""
    if extension not in EXTENSIONS_IMAGE:
        raise ValueError("Image refusée : formats acceptés PNG, JPG ou WEBP.")
    os.makedirs(DOSSIER_UPLOADS, exist_ok=True)
    nom_final = f"{secrets.token_hex(8)}.{extension}"
    fichier.save(os.path.join(DOSSIER_UPLOADS, nom_final))
    return "uploads/" + nom_final


@app.route("/admin/produits/nouveau", methods=["GET", "POST"])
@app.route("/admin/produits/<int:produit_id>/modifier", methods=["GET", "POST"])
@connexion_requise
def admin_formulaire_produit(produit_id=None):
    db = get_db()
    existant = None
    if produit_id is not None:
        existant = db.execute("SELECT * FROM produits WHERE id = ?", (produit_id,)).fetchone()
        if existant is None:
            abort(404)
    categories = db.execute("SELECT * FROM categories ORDER BY nom").fetchall()

    if request.method == "POST":
        f = request.form
        erreurs = []
        nom, artisan_nom = f.get("nom", "").strip(), f.get("artisan", "").strip()
        description = f.get("description", "").strip()
        categorie_id = f.get("categorie_id", type=int)
        prix, stock = f.get("prix", type=int), f.get("stock", type=int)
        if not 2 <= len(nom) <= 100:
            erreurs.append("Le nom doit contenir entre 2 et 100 caractères.")
        if not 2 <= len(artisan_nom) <= 100:
            erreurs.append("Le nom de l'artisan est obligatoire.")
        if len(description) > 1000:
            erreurs.append("La description est limitée à 1000 caractères.")
        if not db.execute("SELECT 1 FROM categories WHERE id = ?", (categorie_id,)).fetchone():
            erreurs.append("Catégorie invalide.")
        if prix is None or prix <= 0:
            erreurs.append("Le prix doit être un entier positif (en FCFA).")
        if stock is None or stock < 0:
            erreurs.append("Le stock doit être un entier positif ou nul.")
        image = existant["image"] if existant else "img/defaut.jpg"
        try:
            nouvelle = enregistrer_image(request.files.get("image"))
            image = nouvelle or image
        except ValueError as e:
            erreurs.append(str(e))
        actif = 1 if f.get("actif") == "1" else 0
        if not erreurs:
            valeurs = (nom, categorie_id, description, prix, stock, image, artisan_nom, actif)
            if existant:
                db.execute("UPDATE produits SET nom=?, categorie_id=?, description=?, prix=?, stock=?,"
                           " image=?, artisan=?, actif=? WHERE id=?", valeurs + (produit_id,))
            else:
                db.execute("INSERT INTO produits (nom, categorie_id, description, prix, stock, image,"
                           " artisan, actif) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", valeurs)
            db.commit()
            flash("Produit enregistré.", "succes")
            return redirect(url_for("admin_produits"))
        for e in erreurs:
            flash(e, "erreur")
        existant = {"nom": nom, "categorie_id": categorie_id, "description": description, "prix": prix,
                    "stock": stock, "artisan": artisan_nom, "actif": actif, "image": image}
    return render_template("admin_produit_form.html", p=existant, categories=categories,
                           nouveau=produit_id is None)


@app.route("/admin/produits/<int:produit_id>/basculer", methods=["POST"])
@connexion_requise
def admin_basculer_produit(produit_id):
    """Active ou désactive un produit (on ne supprime pas : les anciennes commandes le référencent)."""
    db = get_db()
    maj = db.execute("UPDATE produits SET actif = 1 - actif WHERE id = ?", (produit_id,))
    db.commit()
    if maj.rowcount == 0:
        abort(404)
    flash("Visibilité du produit modifiée.", "succes")
    return redirect(url_for("admin_produits"))


@app.route("/admin/commandes")
@connexion_requise
def admin_commandes():
    statut = request.args.get("statut", "")
    sql, params = "SELECT * FROM commandes", []
    if statut in STATUTS:
        sql += " WHERE statut = ?"
        params.append(statut)
    else:
        statut = ""
    commandes = get_db().execute(sql + " ORDER BY date DESC", params).fetchall()
    return render_template("admin_commandes.html", commandes=commandes, statut=statut, statuts=STATUTS)


def charger_commande(db, commande_id):
    c = db.execute("SELECT * FROM commandes WHERE id = ?", (commande_id,)).fetchone()
    if c is None:
        abort(404)
    lignes = db.execute("SELECT l.*, p.nom FROM lignes_commande l JOIN produits p ON p.id = l.produit_id "
                        "WHERE l.commande_id = ?", (commande_id,)).fetchall()
    return c, lignes


@app.route("/admin/commandes/<int:commande_id>")
@connexion_requise
def admin_commande(commande_id):
    c, lignes = charger_commande(get_db(), commande_id)
    return render_template("admin_commande.html", c=c, lignes=lignes, suivants=TRANSITIONS[c["statut"]])


@app.route("/admin/commandes/<int:commande_id>/statut", methods=["POST"])
@connexion_requise
def admin_changer_statut(commande_id):
    nouveau = request.form.get("statut", "")
    db = get_db()
    db.execute("BEGIN IMMEDIATE")
    c = db.execute("SELECT statut FROM commandes WHERE id = ?", (commande_id,)).fetchone()
    if c is None:
        db.rollback()
        abort(404)
    if nouveau not in TRANSITIONS[c["statut"]]:
        db.rollback()
        flash("Changement de statut non autorisé.", "erreur")
        return redirect(url_for("admin_commande", commande_id=commande_id))
    if nouveau == "annulée":
        # Une commande annulée remet les quantités en stock
        db.execute("UPDATE produits SET stock = stock + (SELECT quantite FROM lignes_commande l "
                   "WHERE l.produit_id = produits.id AND l.commande_id = ?) "
                   "WHERE id IN (SELECT produit_id FROM lignes_commande WHERE commande_id = ?)",
                   (commande_id, commande_id))
    db.execute("UPDATE commandes SET statut = ? WHERE id = ?", (nouveau, commande_id))
    db.commit()
    flash(f"Commande n°{commande_id} : statut « {nouveau} ».", "succes")
    return redirect(url_for("admin_commande", commande_id=commande_id))


@app.route("/admin/codes", methods=["GET", "POST"])
@connexion_requise
def admin_codes():
    db = get_db()
    if request.method == "POST":
        code = request.form.get("code", "").strip().upper()
        pourcentage = request.form.get("pourcentage", type=int)
        expiration = request.form.get("date_expiration", "")
        try:
            datetime.strptime(expiration, "%Y-%m-%d")
            date_valide = True
        except ValueError:
            date_valide = False
        if not re.fullmatch(r"[A-Z0-9]{3,20}", code):
            flash("Code : 3 à 20 lettres ou chiffres.", "erreur")
        elif pourcentage is None or not 1 <= pourcentage <= 100:
            flash("Le pourcentage doit être compris entre 1 et 100.", "erreur")
        elif not date_valide:
            flash("Date d'expiration invalide.", "erreur")
        else:
            try:
                db.execute("INSERT INTO codes_reduction (code, pourcentage, date_expiration) VALUES (?, ?, ?)",
                           (code, pourcentage, expiration))
                db.commit()
                flash("Code créé.", "succes")
            except sqlite3.IntegrityError:
                flash("Ce code existe déjà.", "erreur")
        return redirect(url_for("admin_codes"))
    codes = db.execute("SELECT * FROM codes_reduction ORDER BY date_expiration DESC").fetchall()
    return render_template("admin_codes.html", codes=codes, aujourdhui=date.today().isoformat())


# ----------------------------------------------------------------------------
# Pages d'erreur
# ----------------------------------------------------------------------------
@app.errorhandler(404)
def page_introuvable(_erreur):
    return render_template("404.html", code=404, titre="Page introuvable",
                           message="Cette page n'existe pas ou n'est plus disponible."), 404


@app.errorhandler(400)
@app.errorhandler(413)
def requete_refusee(_erreur):
    return render_template("404.html", code=400, titre="Requête refusée",
                           message="Le formulaire a expiré ou le fichier est trop volumineux. "
                                   "Revenez en arrière et réessayez."), 400


if __name__ == "__main__":
    app.run(debug=False)  # debug=False dans la version rendue
