"use strict";
/* admin.js : charge les statistiques depuis /api/statistiques (fetch) et les affiche en barres. */
(function () {
  const section = document.getElementById("stats");
  if (!section) return;
  const etat = document.getElementById("stats-etat");
  const NOMS_PAIEMENT = { livraison: "À la livraison", mobile_money: "Mobile money" };
  const fcfa = n => new Intl.NumberFormat("fr-FR").format(n) + " FCFA";

  function barres(idZone, elements, etiquette, valeur, texte) {
    const zone = document.getElementById(idZone);
    zone.replaceChildren();
    if (elements.length === 0) { zone.textContent = "Aucune donnée."; return; }
    const max = Math.max(...elements.map(valeur));
    elements.forEach(function (x) {
      const ligne = document.createElement("div"); ligne.className = "barre-ligne";
      const nom = document.createElement("span"); nom.textContent = etiquette(x);
      const fond = document.createElement("div"); fond.className = "barre-fond";
      const barre = document.createElement("div"); barre.className = "barre";
      barre.textContent = texte(x);
      barre.style.width = Math.max(8, Math.round(100 * valeur(x) / max)) + "%";
      fond.append(barre); ligne.append(nom, fond); zone.append(ligne);
    });
  }

  fetch(section.dataset.url)
    .then(r => { if (!r.ok) throw new Error(r.status); return r.json(); })
    .then(function (s) {
      barres("stat-ca", s.chiffre_affaires_par_mois, x => x.mois, x => x.chiffre_affaires, x => fcfa(x.chiffre_affaires));
      barres("stat-top", s.top_produits, x => x.nom, x => x.quantite, x => x.quantite + " vendus");
      document.getElementById("stat-panier").textContent = fcfa(s.panier_moyen);
      barres("stat-paiement", s.paiements, x => NOMS_PAIEMENT[x.mode_paiement] || x.mode_paiement, x => x.nombre, x => x.nombre + " commandes");
      etat.hidden = true;
      document.getElementById("stats-contenu").hidden = false;
    })
    .catch(function () { etat.textContent = "Impossible de charger les statistiques."; });
})();
