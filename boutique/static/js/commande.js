"use strict";
/* commande.js : vérification du formulaire de commande avant l'envoi.
   Le serveur refait toutes ces vérifications : ce script sert uniquement au confort. */
(function () {
  const form = document.getElementById("form-commande");
  if (!form) return;

  function erreur(champ, idMessage, texte) {
    document.getElementById(idMessage).textContent = texte;
    if (champ) champ.setAttribute("aria-invalid", texte ? "true" : "false");
    return texte === "";
  }

  form.addEventListener("submit", function (e) {
    const nom = form.elements["nom"], tel = form.elements["telephone"], adresse = form.elements["adresse"];
    const mode = form.querySelector("input[name=mode_paiement]:checked");
    const telPropre = tel.value.replace(/\s/g, "");
    const resultats = [
      erreur(nom, "err-nom", nom.value.trim().length >= 2 ? "" : "Saisissez votre nom (2 caractères minimum)."),
      erreur(tel, "err-telephone", /^(\+?237)?6\d{8}$/.test(telPropre) ? "" : "Téléphone invalide : 9 chiffres commençant par 6."),
      erreur(adresse, "err-adresse", adresse.value.trim().length >= 5 ? "" : "Indiquez une adresse de livraison (5 caractères minimum)."),
      erreur(null, "err-mode", mode ? "" : "Choisissez un mode de paiement."),
    ];
    const panier = lirePanier();
    if (panier.length === 0) { resultats.push(false); alert("Votre panier est vide."); }
    if (resultats.includes(false)) {
      e.preventDefault();
      const premier = form.querySelector("[aria-invalid=true]");
      if (premier) premier.focus();
      return;
    }
    document.getElementById("champ-panier").value = JSON.stringify(panier);
  });
})();
