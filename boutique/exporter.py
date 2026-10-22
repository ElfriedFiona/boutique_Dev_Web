"""exporter.py : sauvegarde toute la base dans un fichier SQL lisible (export_projet.sql)."""
import os
import sqlite3

dossier = os.path.dirname(os.path.abspath(__file__))
db = sqlite3.connect(os.path.join(dossier, "projet.db"))
with open(os.path.join(dossier, "export_projet.sql"), "w", encoding="utf-8") as f:
    for ligne in db.iterdump():  # CREATE TABLE puis tous les INSERT
        f.write(ligne + "\n")
db.close()
print("Export terminé : export_projet.sql")
