"use strict";
/* panier-page.js : affiche le panier (pages /panier et /commande) avec le total mis à jour en direct.
   Les informations produits viennent de l'API : fetch('/api/produits?ids=...'). */
(function () {
  const zone = document.getElementById("panier-zone");
  if (!zone) return;
  const modifiable = zone.dataset.modifiable === "oui";
  const actions = document.getElementById("panier-actions");

  function el(balise, texte, classe) {
    const e = document.createElement(balise);
    if (texte !== undefined) e.textContent = texte;
    if (classe) e.className = classe;
    return e;
  }

  async function charger() {
    const panier = lirePanier();
    if (panier.length === 0) return { lignes: [], panier: panier };
    try {
      const reponse = await fetch("/api/produits?ids=" + panier.map(l => l.id).join(","));
      if (!reponse.ok) throw new Error("HTTP " + reponse.status);
      const produits = await reponse.json();
      const lignes = [];
      const valide = [];
      panier.forEach(function (l) {
        const p = produits.find(x => x.id === l.id);
        if (!p || !p.en_stock) return;           // produit retiré ou épuisé : on l'enlève
        l.quantite = Math.min(l.quantite, p.stock);
        valide.push(l);
        lignes.push({ p: p, quantite: l.quantite });
      });
      if (valide.length !== panier.length || valide.some((l, i) => l.quantite !== panier[i].quantite)) ecrirePanier(valide);
      return { lignes: lignes, panier: valide };
    } catch (e) {
      return { erreur: true, lignes: [], panier: panier };
    }
  }

  function totalDe(lignes) {
    return lignes.reduce((s, l) => s + l.p.prix * l.quantite, 0);
  }

  function dessiner(etat) {
    zone.replaceChildren();
    if (etat.erreur) {
      zone.append(el("p", "Impossible de charger le panier. Vérifiez votre connexion puis rechargez la page."));
      return;
    }
    if (etat.lignes.length === 0) {
      zone.append(el("p", "Votre panier est vide."));
      const lien = el("a", "Voir le catalogue");
      lien.href = "/";
      zone.append(lien);
      if (actions) actions.hidden = true;
      const form = document.getElementById("form-commande");
      if (form) form.querySelector("button[type=submit]").disabled = true;
      return;
    }
    if (actions) actions.hidden = false;
    const total = el("p", "", "total-panier");
    const majTotal = () => { total.textContent = "Total : " + formatPrix(totalDe(etat.lignes)); };

    etat.lignes.forEach(function (ligne) {
      const bloc = el("div", undefined, "ligne-panier");
      const img = document.createElement("img");
      img.src = ligne.p.image; img.alt = ligne.p.nom; img.width = 96; img.height = 72;
      const infos = el("div");
      infos.append(el("strong", ligne.p.nom), el("br"), document.createTextNode(formatPrix(ligne.p.prix) + " l'unité"));
      bloc.append(img, infos);
      const sousTotal = el("strong", formatPrix(ligne.p.prix * ligne.quantite));

      if (modifiable) {
        const controles = el("div", undefined, "controles");
        const etiquette = el("label", "Quantité");
        const champ = document.createElement("input");
        champ.type = "number"; champ.min = 1; champ.max = ligne.p.stock; champ.value = ligne.quantite;
        champ.id = "q-" + ligne.p.id; etiquette.htmlFor = champ.id;
        champ.addEventListener("input", function () {
          let q = parseInt(champ.value, 10);
          if (!Number.isInteger(q) || q < 1) return;
          q = Math.min(q, ligne.p.stock);
          ligne.quantite = q;
          ecrirePanier(etat.lignes.map(l => ({ id: l.p.id, quantite: l.quantite })));
          sousTotal.textContent = formatPrix(ligne.p.prix * q);
          majTotal();                       // total mis à jour en direct
        });
        const retirer = el("button", "Retirer", "bouton-lien");
        retirer.type = "button";
        retirer.addEventListener("click", function () {
          etat.lignes = etat.lignes.filter(l => l !== ligne);
          ecrirePanier(etat.lignes.map(l => ({ id: l.p.id, quantite: l.quantite })));
          dessiner(etat);
        });
        controles.append(etiquette, champ, sousTotal, retirer);
        bloc.append(controles);
      } else {
        bloc.append(el("span", ligne.quantite + " × " + formatPrix(ligne.p.prix)), sousTotal);
      }
      zone.append(bloc);
    });
    majTotal();
    zone.append(total);
  }

  charger().then(dessiner);
})();
