"use strict";
/* panier.js : le panier est conservé dans le navigateur (localStorage).
   Format : [{"id": 3, "quantite": 2}, ...]  (jamais de prix : le serveur les relit en base) */
const CLE_PANIER = "panier";

function lirePanier() {
  try {
    const donnees = JSON.parse(localStorage.getItem(CLE_PANIER) || "[]");
    if (!Array.isArray(donnees)) return [];
    return donnees.filter(l => Number.isInteger(l.id) && Number.isInteger(l.quantite) && l.quantite > 0);
  } catch (e) {
    return [];
  }
}

function ecrirePanier(panier) {
  localStorage.setItem(CLE_PANIER, JSON.stringify(panier));
  majBadge();
}

function majBadge() {
  const total = lirePanier().reduce((somme, l) => somme + l.quantite, 0);
  document.querySelectorAll("[data-badge]").forEach(e => { e.textContent = total; });
}

function formatPrix(n) {
  return new Intl.NumberFormat("fr-FR").format(n) + " FCFA";
}

function annoncer(texte) {
  const zone = document.getElementById("message-panier");
  if (!zone) return;
  zone.textContent = texte;
  zone.hidden = false;
}

/* Clic sur « Ajouter au panier » (catalogue, fiche produit, page artisan) */
document.addEventListener("click", function (e) {
  const bouton = e.target.closest("[data-ajouter]");
  if (!bouton) return;
  const id = Number(bouton.dataset.ajouter);
  const stock = Number(bouton.dataset.stock);
  const champ = document.getElementById("qte-" + id);
  let quantite = champ ? parseInt(champ.value, 10) : 1;
  if (!Number.isInteger(quantite) || quantite < 1) quantite = 1;
  const panier = lirePanier();
  const ligne = panier.find(l => l.id === id);
  const deja = ligne ? ligne.quantite : 0;
  if (deja + quantite > stock) {
    annoncer("Stock insuffisant : il en reste " + stock + " et vous en avez déjà " + deja + " dans le panier.");
    return;
  }
  if (ligne) ligne.quantite += quantite; else panier.push({ id: id, quantite: quantite });
  ecrirePanier(panier);
  annoncer("Produit ajouté au panier.");
});

/* Après une commande réussie, on vide le panier */
if (document.querySelector("[data-vider-panier]")) localStorage.removeItem(CLE_PANIER);
majBadge();
