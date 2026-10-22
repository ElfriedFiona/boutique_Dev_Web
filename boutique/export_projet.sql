BEGIN TRANSACTION;
CREATE TABLE administrateurs (
    id        INTEGER PRIMARY KEY AUTOINCREMENT,
    login     TEXT NOT NULL UNIQUE,
    empreinte TEXT NOT NULL
);
INSERT INTO "administrateurs" VALUES(1,'admin','scrypt:32768:8:1$I4wG4HdmnsbCVA0V$64e86e9f9b77ae7f58a9e59d6c09c0409010b3b78321b647bc5e728509cfaa606864c5187dd1fdb3b2288464f81347d37e34722c8644e0f0afdc6b6164b124f3');
CREATE TABLE categories (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nom         TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT ''
);
INSERT INTO "categories" VALUES(1,'Sculptures','Bois sculpté, laiton et objets royaux des Grassfields.');
INSERT INTO "categories" VALUES(2,'Sacs en raphia','Sacs et paniers tressés en fibres de raphia.');
INSERT INTO "categories" VALUES(3,'Tissus','Ndop, toghu, batik et broderies de l''Ouest.');
INSERT INTO "categories" VALUES(4,'Bijoux','Perles, laiton et bronze travaillés à la main.');
INSERT INTO "categories" VALUES(5,'Décoration','Terre cuite, rotin, bambou et laiton pour la maison.');
CREATE TABLE codes_reduction (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    code            TEXT    NOT NULL UNIQUE,
    pourcentage     INTEGER NOT NULL CHECK (pourcentage BETWEEN 1 AND 100),
    date_expiration TEXT    NOT NULL
);
INSERT INTO "codes_reduction" VALUES(1,'BIENVENUE10',10,'2027-10-14');
INSERT INTO "codes_reduction" VALUES(2,'FETE15',15,'2027-10-14');
INSERT INTO "codes_reduction" VALUES(3,'ETE2025',20,'2025-09-01');
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
INSERT INTO "commandes" VALUES(1,'Aline Tchoupo','671833230','Akwa, Yaoundé','2026-10-14 13:15:50','livraison','préparée',105500,0,NULL,105500);
INSERT INTO "commandes" VALUES(2,'Moussa Kamga','650848731','Centre-ville, Yaoundé','2026-10-13 11:27:50','livraison','préparée',52500,0,NULL,52500);
INSERT INTO "commandes" VALUES(3,'Rose Mbarga','684449368','Nkolbisson, Bafoussam','2026-09-21 16:34:50','mobile_money','livrée',72000,0,NULL,72000);
INSERT INTO "commandes" VALUES(4,'Sandra Mbarga','659800873','Mvog-Ada, Douala','2026-10-12 13:23:50','livraison','préparée',51500,0,NULL,51500);
INSERT INTO "commandes" VALUES(5,'Paul Nkeng','669712650','Makepe, Bamenda','2026-09-30 11:56:50','livraison','livrée',256000,0,NULL,256000);
INSERT INTO "commandes" VALUES(6,'Marie Ekane','664456272','Mvog-Ada, Kribi','2026-05-09 19:13:50','livraison','livrée',52500,0,NULL,52500);
INSERT INTO "commandes" VALUES(7,'Paul Kamga','668487336','Bastos, Yaoundé','2026-04-26 15:29:50','livraison','livrée',244000,0,NULL,244000);
INSERT INTO "commandes" VALUES(8,'Estelle Njoya','652253031','Bastos, Douala','2026-10-12 19:26:50','livraison','reçue',124500,0,NULL,124500);
INSERT INTO "commandes" VALUES(9,'Ibrahim Kamga','684213115','Nkolbisson, Garoua','2026-03-01 18:47:50','livraison','livrée',58000,0,NULL,58000);
INSERT INTO "commandes" VALUES(10,'Kevin Bello','697175395','Makepe, Kribi','2026-10-14 13:23:50','livraison','reçue',61000,0,NULL,61000);
INSERT INTO "commandes" VALUES(11,'Rose Fotso','655171716','Bastos, Bafoussam','2026-09-16 19:19:50','livraison','annulée',29000,0,NULL,29000);
INSERT INTO "commandes" VALUES(12,'Brice Fotso','662726327','Nkolbisson, Bamenda','2026-02-26 14:30:50','livraison','livrée',65000,0,NULL,65000);
INSERT INTO "commandes" VALUES(13,'Ibrahim Fotso','656417985','Nkolbisson, Garoua','2026-10-11 20:11:50','livraison','reçue',110000,0,NULL,110000);
INSERT INTO "commandes" VALUES(14,'Rose Ekane','671164686','Nkolbisson, Garoua','2026-03-09 12:35:50','mobile_money','annulée',38000,0,NULL,38000);
INSERT INTO "commandes" VALUES(15,'Paul Nkeng','685799667','Centre-ville, Douala','2026-07-17 11:55:50','mobile_money','livrée',77500,11625,2,65875);
INSERT INTO "commandes" VALUES(16,'Estelle Kamga','666110622','Mvog-Ada, Douala','2026-06-25 11:53:50','livraison','livrée',56000,0,NULL,56000);
INSERT INTO "commandes" VALUES(17,'Estelle Njoya','685472441','Mvog-Ada, Kribi','2026-10-09 14:58:50','mobile_money','préparée',76000,0,NULL,76000);
INSERT INTO "commandes" VALUES(18,'Rose Kamga','655098175','Bastos, Kribi','2026-05-26 18:26:50','livraison','livrée',63000,0,NULL,63000);
INSERT INTO "commandes" VALUES(19,'Estelle Bello','661422633','Bastos, Garoua','2026-06-26 10:43:50','mobile_money','livrée',64000,0,NULL,64000);
INSERT INTO "commandes" VALUES(20,'Brice Ngo Bassa','686953166','Centre-ville, Foumban','2026-09-21 16:36:50','livraison','livrée',26500,2650,1,23850);
INSERT INTO "commandes" VALUES(21,'Paul Tchoupo','662950888','Nkolbisson, Douala','2026-04-14 14:03:50','mobile_money','livrée',22500,0,NULL,22500);
INSERT INTO "commandes" VALUES(22,'Moussa Nkeng','697159521','Nkolbisson, Buea','2026-10-02 11:06:50','mobile_money','livrée',116000,0,NULL,116000);
INSERT INTO "commandes" VALUES(23,'Estelle Bello','664606980','Mvog-Ada, Kribi','2026-02-27 17:54:50','livraison','livrée',28500,0,NULL,28500);
INSERT INTO "commandes" VALUES(24,'Kevin Fotso','666426265','Centre-ville, Yaoundé','2026-04-15 15:44:50','livraison','livrée',54000,0,NULL,54000);
INSERT INTO "commandes" VALUES(25,'Aline Atangana','686534336','Nkolbisson, Bamenda','2026-04-17 16:57:50','livraison','annulée',146000,0,NULL,146000);
INSERT INTO "commandes" VALUES(26,'Estelle Kamga','693700025','Mvog-Ada, Bamenda','2026-10-08 10:47:50','livraison','préparée',219000,0,NULL,219000);
INSERT INTO "commandes" VALUES(27,'Kevin Bello','668961107','Bonamoussadi, Bamenda','2026-10-12 13:10:50','mobile_money','préparée',116000,0,NULL,116000);
INSERT INTO "commandes" VALUES(28,'Aline Njoya','685492066','Akwa, Bafoussam','2026-10-10 10:59:50','mobile_money','préparée',168000,25200,2,142800);
INSERT INTO "commandes" VALUES(29,'Aline Kamga','655871360','Akwa, Foumban','2026-07-23 14:51:50','livraison','livrée',35000,0,NULL,35000);
INSERT INTO "commandes" VALUES(30,'Kevin Bello','659461839','Akwa, Garoua','2026-03-29 19:55:50','mobile_money','livrée',60000,0,NULL,60000);
INSERT INTO "commandes" VALUES(31,'Paul Nkeng','655233774','Makepe, Kribi','2026-04-18 16:14:50','mobile_money','livrée',141000,14100,1,126900);
INSERT INTO "commandes" VALUES(32,'Brice Mbarga','678937982','Mvog-Ada, Yaoundé','2026-10-11 17:13:50','mobile_money','reçue',115500,0,NULL,115500);
INSERT INTO "commandes" VALUES(33,'Kevin Tchoupo','668753457','Centre-ville, Foumban','2026-09-27 11:58:50','mobile_money','livrée',169500,0,NULL,169500);
INSERT INTO "commandes" VALUES(34,'Marie Ngo Bassa','677563202','Akwa, Buea','2026-05-10 11:25:50','mobile_money','livrée',58000,0,NULL,58000);
INSERT INTO "commandes" VALUES(35,'Sandra Njoya','694635017','Makepe, Kribi','2026-05-22 14:08:50','livraison','livrée',131000,0,NULL,131000);
INSERT INTO "commandes" VALUES(36,'Moussa Mbarga','654936453','Akwa, Foumban','2026-06-04 17:21:50','mobile_money','livrée',101000,0,NULL,101000);
INSERT INTO "commandes" VALUES(37,'Rose Kamga','675902401','Centre-ville, Buea','2026-04-20 16:27:50','mobile_money','annulée',54000,0,NULL,54000);
INSERT INTO "commandes" VALUES(38,'Marie Bello','679891626','Nkolbisson, Garoua','2026-08-06 15:23:50','mobile_money','livrée',159000,15900,1,143100);
INSERT INTO "commandes" VALUES(39,'Ibrahim Mbarga','659283822','Bastos, Bafoussam','2026-09-19 17:18:50','livraison','livrée',55500,0,NULL,55500);
INSERT INTO "commandes" VALUES(40,'Sandra Fotso','654235884','Nkolbisson, Foumban','2026-05-04 12:14:50','mobile_money','annulée',396500,0,NULL,396500);
INSERT INTO "commandes" VALUES(41,'Paul Atangana','659362911','Nkolbisson, Kribi','2026-09-15 19:30:50','mobile_money','livrée',253500,25350,1,228150);
INSERT INTO "commandes" VALUES(42,'Ibrahim Nkeng','691010496','Makepe, Bamenda','2026-05-12 16:45:50','livraison','livrée',70000,0,NULL,70000);
INSERT INTO "commandes" VALUES(43,'Aline Tchoupo','689962498','Mvog-Ada, Bafoussam','2026-04-02 17:04:50','mobile_money','livrée',64500,0,NULL,64500);
INSERT INTO "commandes" VALUES(44,'Brice Atangana','681925626','Makepe, Kribi','2026-10-14 16:39:50','livraison','préparée',53500,0,NULL,53500);
INSERT INTO "commandes" VALUES(45,'Moussa Ngo Bassa','685101803','Centre-ville, Kribi','2026-10-09 18:04:50','mobile_money','reçue',139000,0,NULL,139000);
INSERT INTO "commandes" VALUES(46,'Brice Njoya','651532210','Akwa, Buea','2026-10-12 12:04:50','livraison','reçue',60500,0,NULL,60500);
INSERT INTO "commandes" VALUES(47,'Ibrahim Fotso','697312936','Centre-ville, Foumban','2026-04-02 16:01:50','mobile_money','livrée',59000,0,NULL,59000);
INSERT INTO "commandes" VALUES(48,'Rose Bello','676718473','Nkolbisson, Buea','2026-10-14 12:35:50','livraison','préparée',119000,0,NULL,119000);
INSERT INTO "commandes" VALUES(49,'Estelle Mbarga','697750676','Mvog-Ada, Bamenda','2026-06-20 19:06:50','livraison','livrée',76000,0,NULL,76000);
INSERT INTO "commandes" VALUES(50,'Ibrahim Bello','682037191','Bonamoussadi, Bafoussam','2026-10-13 11:46:50','livraison','reçue',119000,0,NULL,119000);
INSERT INTO "commandes" VALUES(51,'Moussa Ngo Bassa','668361353','Centre-ville, Yaoundé','2026-04-16 17:54:50','mobile_money','livrée',184000,0,NULL,184000);
INSERT INTO "commandes" VALUES(52,'Paul Njoya','685702160','Nkolbisson, Bafoussam','2026-10-10 15:57:50','mobile_money','reçue',76500,0,NULL,76500);
INSERT INTO "commandes" VALUES(53,'Estelle Bello','675577416','Makepe, Foumban','2026-03-18 20:34:50','mobile_money','livrée',136000,0,NULL,136000);
INSERT INTO "commandes" VALUES(54,'Rose Fotso','680621086','Akwa, Bamenda','2026-06-20 15:07:50','mobile_money','livrée',48000,7200,2,40800);
INSERT INTO "commandes" VALUES(55,'Kevin Ngo Bassa','684446344','Bastos, Bamenda','2026-03-06 18:54:50','mobile_money','annulée',155500,15550,1,139950);
INSERT INTO "commandes" VALUES(56,'Estelle Mbarga','691147909','Akwa, Foumban','2026-10-09 19:14:50','mobile_money','reçue',116500,0,NULL,116500);
INSERT INTO "commandes" VALUES(57,'Sandra Mbarga','676014016','Bastos, Douala','2026-08-17 19:04:50','mobile_money','livrée',237000,0,NULL,237000);
INSERT INTO "commandes" VALUES(58,'Moussa Nkeng','663895475','Mvog-Ada, Garoua','2026-09-07 16:26:50','mobile_money','livrée',101500,15225,2,86275);
INSERT INTO "commandes" VALUES(59,'Rose Njoya','685068760','Akwa, Kribi','2026-06-19 16:15:50','mobile_money','livrée',322000,48300,2,273700);
INSERT INTO "commandes" VALUES(60,'Ibrahim Mbarga','684605016','Bonamoussadi, Kribi','2026-03-10 12:22:50','livraison','livrée',196000,0,NULL,196000);
CREATE TABLE lignes_commande (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    commande_id   INTEGER NOT NULL REFERENCES commandes(id) ON DELETE CASCADE,
    produit_id    INTEGER NOT NULL REFERENCES produits(id),
    quantite      INTEGER NOT NULL CHECK (quantite > 0),
    prix_unitaire INTEGER NOT NULL CHECK (prix_unitaire > 0),
    UNIQUE (commande_id, produit_id)
);
INSERT INTO "lignes_commande" VALUES(1,1,23,2,28500);
INSERT INTO "lignes_commande" VALUES(2,1,28,3,12500);
INSERT INTO "lignes_commande" VALUES(3,1,27,1,11000);
INSERT INTO "lignes_commande" VALUES(4,2,29,1,3500);
INSERT INTO "lignes_commande" VALUES(5,2,9,2,12000);
INSERT INTO "lignes_commande" VALUES(6,2,28,2,12500);
INSERT INTO "lignes_commande" VALUES(7,3,11,2,15500);
INSERT INTO "lignes_commande" VALUES(8,3,27,1,11000);
INSERT INTO "lignes_commande" VALUES(9,3,32,2,15000);
INSERT INTO "lignes_commande" VALUES(10,4,36,1,16500);
INSERT INTO "lignes_commande" VALUES(11,4,32,2,15000);
INSERT INTO "lignes_commande" VALUES(12,4,10,1,5000);
INSERT INTO "lignes_commande" VALUES(13,5,6,3,19500);
INSERT INTO "lignes_commande" VALUES(14,5,12,1,11500);
INSERT INTO "lignes_commande" VALUES(15,5,5,3,62000);
INSERT INTO "lignes_commande" VALUES(16,6,27,3,11000);
INSERT INTO "lignes_commande" VALUES(17,6,38,3,6500);
INSERT INTO "lignes_commande" VALUES(18,7,30,1,11000);
INSERT INTO "lignes_commande" VALUES(19,7,21,2,23500);
INSERT INTO "lignes_commande" VALUES(20,7,5,3,62000);
INSERT INTO "lignes_commande" VALUES(21,8,16,1,17000);
INSERT INTO "lignes_commande" VALUES(22,8,24,2,23000);
INSERT INTO "lignes_commande" VALUES(23,8,19,3,20500);
INSERT INTO "lignes_commande" VALUES(24,9,36,2,16500);
INSERT INTO "lignes_commande" VALUES(25,9,10,3,5000);
INSERT INTO "lignes_commande" VALUES(26,9,18,1,10000);
INSERT INTO "lignes_commande" VALUES(27,10,18,1,10000);
INSERT INTO "lignes_commande" VALUES(28,10,3,2,25500);
INSERT INTO "lignes_commande" VALUES(29,11,10,1,5000);
INSERT INTO "lignes_commande" VALUES(30,11,35,2,12000);
INSERT INTO "lignes_commande" VALUES(31,12,14,3,16000);
INSERT INTO "lignes_commande" VALUES(32,12,16,1,17000);
INSERT INTO "lignes_commande" VALUES(33,13,12,2,11500);
INSERT INTO "lignes_commande" VALUES(34,13,22,3,29000);
INSERT INTO "lignes_commande" VALUES(35,14,15,2,6000);
INSERT INTO "lignes_commande" VALUES(36,14,13,2,7500);
INSERT INTO "lignes_commande" VALUES(37,14,30,1,11000);
INSERT INTO "lignes_commande" VALUES(38,15,26,1,7500);
INSERT INTO "lignes_commande" VALUES(39,15,35,1,12000);
INSERT INTO "lignes_commande" VALUES(40,15,22,2,29000);
INSERT INTO "lignes_commande" VALUES(41,16,8,1,33000);
INSERT INTO "lignes_commande" VALUES(42,16,25,2,7500);
INSERT INTO "lignes_commande" VALUES(43,16,37,1,8000);
INSERT INTO "lignes_commande" VALUES(44,17,40,3,17500);
INSERT INTO "lignes_commande" VALUES(45,17,21,1,23500);
INSERT INTO "lignes_commande" VALUES(46,18,13,3,7500);
INSERT INTO "lignes_commande" VALUES(47,18,27,3,11000);
INSERT INTO "lignes_commande" VALUES(48,18,25,1,7500);
INSERT INTO "lignes_commande" VALUES(49,19,39,2,8500);
INSERT INTO "lignes_commande" VALUES(50,19,21,2,23500);
INSERT INTO "lignes_commande" VALUES(51,20,20,1,20500);
INSERT INTO "lignes_commande" VALUES(52,20,15,1,6000);
INSERT INTO "lignes_commande" VALUES(53,21,32,1,15000);
INSERT INTO "lignes_commande" VALUES(54,21,26,1,7500);
INSERT INTO "lignes_commande" VALUES(55,22,16,1,17000);
INSERT INTO "lignes_commande" VALUES(56,22,8,2,33000);
INSERT INTO "lignes_commande" VALUES(57,22,30,3,11000);
INSERT INTO "lignes_commande" VALUES(58,23,31,2,12500);
INSERT INTO "lignes_commande" VALUES(59,23,29,1,3500);
INSERT INTO "lignes_commande" VALUES(60,24,16,2,17000);
INSERT INTO "lignes_commande" VALUES(61,24,18,2,10000);
INSERT INTO "lignes_commande" VALUES(62,25,5,2,62000);
INSERT INTO "lignes_commande" VALUES(63,25,27,2,11000);
INSERT INTO "lignes_commande" VALUES(64,26,25,2,7500);
INSERT INTO "lignes_commande" VALUES(65,26,31,2,12500);
INSERT INTO "lignes_commande" VALUES(66,26,1,2,89500);
INSERT INTO "lignes_commande" VALUES(67,27,32,2,15000);
INSERT INTO "lignes_commande" VALUES(68,27,2,2,43000);
INSERT INTO "lignes_commande" VALUES(69,28,2,3,43000);
INSERT INTO "lignes_commande" VALUES(70,28,6,2,19500);
INSERT INTO "lignes_commande" VALUES(71,29,25,2,7500);
INSERT INTO "lignes_commande" VALUES(72,29,18,2,10000);
INSERT INTO "lignes_commande" VALUES(73,30,2,1,43000);
INSERT INTO "lignes_commande" VALUES(74,30,16,1,17000);
INSERT INTO "lignes_commande" VALUES(75,31,24,3,23000);
INSERT INTO "lignes_commande" VALUES(76,31,11,3,15500);
INSERT INTO "lignes_commande" VALUES(77,31,39,3,8500);
INSERT INTO "lignes_commande" VALUES(78,32,5,1,62000);
INSERT INTO "lignes_commande" VALUES(79,32,38,3,6500);
INSERT INTO "lignes_commande" VALUES(80,32,16,2,17000);
INSERT INTO "lignes_commande" VALUES(81,33,22,2,29000);
INSERT INTO "lignes_commande" VALUES(82,33,1,1,89500);
INSERT INTO "lignes_commande" VALUES(83,33,27,2,11000);
INSERT INTO "lignes_commande" VALUES(84,34,31,2,12500);
INSERT INTO "lignes_commande" VALUES(85,34,30,3,11000);
INSERT INTO "lignes_commande" VALUES(86,35,22,2,29000);
INSERT INTO "lignes_commande" VALUES(87,35,2,1,43000);
INSERT INTO "lignes_commande" VALUES(88,35,32,2,15000);
INSERT INTO "lignes_commande" VALUES(89,36,6,2,19500);
INSERT INTO "lignes_commande" VALUES(90,36,16,3,17000);
INSERT INTO "lignes_commande" VALUES(91,36,27,1,11000);
INSERT INTO "lignes_commande" VALUES(92,37,20,2,20500);
INSERT INTO "lignes_commande" VALUES(93,37,38,2,6500);
INSERT INTO "lignes_commande" VALUES(94,38,17,3,29000);
INSERT INTO "lignes_commande" VALUES(95,38,15,1,6000);
INSERT INTO "lignes_commande" VALUES(96,38,8,2,33000);
INSERT INTO "lignes_commande" VALUES(97,39,19,1,20500);
INSERT INTO "lignes_commande" VALUES(98,39,15,2,6000);
INSERT INTO "lignes_commande" VALUES(99,39,24,1,23000);
INSERT INTO "lignes_commande" VALUES(100,40,7,3,72500);
INSERT INTO "lignes_commande" VALUES(101,40,1,2,89500);
INSERT INTO "lignes_commande" VALUES(102,41,26,3,7500);
INSERT INTO "lignes_commande" VALUES(103,41,32,3,15000);
INSERT INTO "lignes_commande" VALUES(104,41,5,3,62000);
INSERT INTO "lignes_commande" VALUES(105,42,34,2,27500);
INSERT INTO "lignes_commande" VALUES(106,42,25,2,7500);
INSERT INTO "lignes_commande" VALUES(107,43,14,1,16000);
INSERT INTO "lignes_commande" VALUES(108,43,17,1,29000);
INSERT INTO "lignes_commande" VALUES(109,43,6,1,19500);
INSERT INTO "lignes_commande" VALUES(110,44,19,1,20500);
INSERT INTO "lignes_commande" VALUES(111,44,30,3,11000);
INSERT INTO "lignes_commande" VALUES(112,45,18,1,10000);
INSERT INTO "lignes_commande" VALUES(113,45,10,1,5000);
INSERT INTO "lignes_commande" VALUES(114,45,5,2,62000);
INSERT INTO "lignes_commande" VALUES(115,46,35,1,12000);
INSERT INTO "lignes_commande" VALUES(116,46,32,3,15000);
INSERT INTO "lignes_commande" VALUES(117,46,29,1,3500);
INSERT INTO "lignes_commande" VALUES(118,47,37,1,8000);
INSERT INTO "lignes_commande" VALUES(119,47,3,2,25500);
INSERT INTO "lignes_commande" VALUES(120,48,23,2,28500);
INSERT INTO "lignes_commande" VALUES(121,48,27,3,11000);
INSERT INTO "lignes_commande" VALUES(122,48,22,1,29000);
INSERT INTO "lignes_commande" VALUES(123,49,21,2,23500);
INSERT INTO "lignes_commande" VALUES(124,49,17,1,29000);
INSERT INTO "lignes_commande" VALUES(125,50,24,3,23000);
INSERT INTO "lignes_commande" VALUES(126,50,40,2,17500);
INSERT INTO "lignes_commande" VALUES(127,50,32,1,15000);
INSERT INTO "lignes_commande" VALUES(128,51,20,3,20500);
INSERT INTO "lignes_commande" VALUES(129,51,36,2,16500);
INSERT INTO "lignes_commande" VALUES(130,51,1,1,89500);
INSERT INTO "lignes_commande" VALUES(131,52,27,2,11000);
INSERT INTO "lignes_commande" VALUES(132,52,31,3,12500);
INSERT INTO "lignes_commande" VALUES(133,52,16,1,17000);
INSERT INTO "lignes_commande" VALUES(134,53,19,3,20500);
INSERT INTO "lignes_commande" VALUES(135,53,20,3,20500);
INSERT INTO "lignes_commande" VALUES(136,53,38,2,6500);
INSERT INTO "lignes_commande" VALUES(137,54,13,2,7500);
INSERT INTO "lignes_commande" VALUES(138,54,16,1,17000);
INSERT INTO "lignes_commande" VALUES(139,54,37,2,8000);
INSERT INTO "lignes_commande" VALUES(140,55,29,3,3500);
INSERT INTO "lignes_commande" VALUES(141,55,7,2,72500);
INSERT INTO "lignes_commande" VALUES(142,56,22,2,29000);
INSERT INTO "lignes_commande" VALUES(143,56,35,3,12000);
INSERT INTO "lignes_commande" VALUES(144,56,25,3,7500);
INSERT INTO "lignes_commande" VALUES(145,57,28,1,12500);
INSERT INTO "lignes_commande" VALUES(146,57,7,3,72500);
INSERT INTO "lignes_commande" VALUES(147,57,29,2,3500);
INSERT INTO "lignes_commande" VALUES(148,58,34,3,27500);
INSERT INTO "lignes_commande" VALUES(149,58,27,1,11000);
INSERT INTO "lignes_commande" VALUES(150,58,37,1,8000);
INSERT INTO "lignes_commande" VALUES(151,59,1,3,89500);
INSERT INTO "lignes_commande" VALUES(152,59,30,3,11000);
INSERT INTO "lignes_commande" VALUES(153,59,19,1,20500);
INSERT INTO "lignes_commande" VALUES(154,60,7,2,72500);
INSERT INTO "lignes_commande" VALUES(155,60,16,3,17000);
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
INSERT INTO "produits" VALUES(1,'Masque bamiléké',1,'Masque bamiléké. Sculpté à la main dans un bois local, pièce unique.',89500,2,'img/sculpture.jpg','Atelier Njoya (Foumban)',1);
INSERT INTO "produits" VALUES(2,'Statuette de la reine mère',1,'Statuette de la reine mère. Sculpté à la main dans un bois local, pièce unique.',43000,20,'img/sculpture.jpg','Atelier Njoya (Foumban)',1);
INSERT INTO "produits" VALUES(3,'Tabouret royal sculpté',1,'Tabouret royal sculpté. Sculpté à la main dans un bois local, pièce unique.',25500,0,'img/sculpture.jpg','Moussa Bello',1);
INSERT INTO "produits" VALUES(4,'Éléphant en bois',1,'Éléphant en bois. Sculpté à la main dans un bois local, pièce unique.',77500,10,'img/sculpture.jpg','Moussa Bello',1);
INSERT INTO "produits" VALUES(5,'Tambour parleur',1,'Tambour parleur. Sculpté à la main dans un bois local, pièce unique.',62000,7,'img/sculpture.jpg','Atelier Njoya (Foumban)',1);
INSERT INTO "produits" VALUES(6,'Calebasse gravée',1,'Calebasse gravée. Sculpté à la main dans un bois local, pièce unique.',19500,18,'img/sculpture.jpg','Atelier Njoya (Foumban)',1);
INSERT INTO "produits" VALUES(7,'Pipe bamoun en laiton',1,'Pipe bamoun en laiton. Sculpté à la main dans un bois local, pièce unique.',72500,6,'img/sculpture.jpg','Moussa Bello',1);
INSERT INTO "produits" VALUES(8,'Panneau de case sculpté',1,'Panneau de case sculpté. Sculpté à la main dans un bois local, pièce unique.',33000,39,'img/sculpture.jpg','Pierre Tchoupo',1);
INSERT INTO "produits" VALUES(9,'Sac cabas en raphia',2,'Sac cabas en raphia. Tressé en raphia naturel, léger et solide.',12000,33,'img/raphia.jpg','Coopérative des tisseuses de Bamenda',1);
INSERT INTO "produits" VALUES(10,'Sac à bandoulière tressé',2,'Sac à bandoulière tressé. Tressé en raphia naturel, léger et solide.',5000,15,'img/raphia.jpg','Coopérative des tisseuses de Bamenda',1);
INSERT INTO "produits" VALUES(11,'Pochette raphia et wax',2,'Pochette raphia et wax. Tressé en raphia naturel, léger et solide.',15500,22,'img/raphia.jpg','Rose Ekane',0);
INSERT INTO "produits" VALUES(12,'Panier de marché',2,'Panier de marché. Tressé en raphia naturel, léger et solide.',11500,26,'img/raphia.jpg','Rose Ekane',1);
INSERT INTO "produits" VALUES(13,'Chapeau en raphia',2,'Chapeau en raphia. Tressé en raphia naturel, léger et solide.',7500,29,'img/raphia.jpg','Rose Ekane',1);
INSERT INTO "produits" VALUES(14,'Sac à dos en raphia',2,'Sac à dos en raphia. Tressé en raphia naturel, léger et solide.',16000,27,'img/raphia.jpg','Coopérative des tisseuses de Bamenda',1);
INSERT INTO "produits" VALUES(15,'Cabas rayé bleu',2,'Cabas rayé bleu. Tressé en raphia naturel, léger et solide.',6000,34,'img/raphia.jpg','Rose Ekane',1);
INSERT INTO "produits" VALUES(16,'Tapis de raphia',2,'Tapis de raphia. Tressé en raphia naturel, léger et solide.',17000,10,'img/raphia.jpg','Coopérative des tisseuses de Bamenda',1);
INSERT INTO "produits" VALUES(17,'Pagne ndop indigo',3,'Pagne ndop indigo. Tissu teint et brodé à la main selon les motifs traditionnels.',29000,0,'img/tissus.jpg','Aline Fotso',1);
INSERT INTO "produits" VALUES(18,'Toghu brodé',3,'Toghu brodé. Tissu teint et brodé à la main selon les motifs traditionnels.',10000,7,'img/tissus.jpg','Aline Fotso',1);
INSERT INTO "produits" VALUES(19,'Écharpe bamoun',3,'Écharpe bamoun. Tissu teint et brodé à la main selon les motifs traditionnels.',20500,23,'img/tissus.jpg','Sandra Mbarga',1);
INSERT INTO "produits" VALUES(20,'Nappe en batik',3,'Nappe en batik. Tissu teint et brodé à la main selon les motifs traditionnels.',20500,11,'img/tissus.jpg','Coopérative des teinturières de Foumban',1);
INSERT INTO "produits" VALUES(21,'Coussin ndop',3,'Coussin ndop. Tissu teint et brodé à la main selon les motifs traditionnels.',23500,34,'img/tissus.jpg','Aline Fotso',1);
INSERT INTO "produits" VALUES(22,'Tenue kaba',3,'Tenue kaba. Tissu teint et brodé à la main selon les motifs traditionnels.',29000,15,'img/tissus.jpg','Coopérative des teinturières de Foumban',1);
INSERT INTO "produits" VALUES(23,'Chemin de table brodé',3,'Chemin de table brodé. Tissu teint et brodé à la main selon les motifs traditionnels.',28500,18,'img/tissus.jpg','Aline Fotso',1);
INSERT INTO "produits" VALUES(24,'Batik de Foumban',3,'Batik de Foumban. Tissu teint et brodé à la main selon les motifs traditionnels.',23000,9,'img/tissus.jpg','Aline Fotso',1);
INSERT INTO "produits" VALUES(25,'Collier de perles bamiléké',4,'Collier de perles bamiléké. Bijou fait main, fermoir solide, livré dans une pochette.',7500,0,'img/bijoux.jpg','Marie Atangana',1);
INSERT INTO "produits" VALUES(26,'Bracelet en laiton',4,'Bracelet en laiton. Bijou fait main, fermoir solide, livré dans une pochette.',7500,34,'img/bijoux.jpg','Ibrahim Njoya',1);
INSERT INTO "produits" VALUES(27,'Boucles d''oreilles en raphia',4,'Boucles d''oreilles en raphia. Bijou fait main, fermoir solide, livré dans une pochette.',11000,40,'img/bijoux.jpg','Marie Atangana',1);
INSERT INTO "produits" VALUES(28,'Bague en bronze',4,'Bague en bronze. Bijou fait main, fermoir solide, livré dans une pochette.',12500,8,'img/bijoux.jpg','Marie Atangana',1);
INSERT INTO "produits" VALUES(29,'Collier en perles de verre',4,'Collier en perles de verre. Bijou fait main, fermoir solide, livré dans une pochette.',3500,25,'img/bijoux.jpg','Ibrahim Njoya',0);
INSERT INTO "produits" VALUES(30,'Bracelet cuir et perles',4,'Bracelet cuir et perles. Bijou fait main, fermoir solide, livré dans une pochette.',11000,2,'img/bijoux.jpg','Marie Atangana',1);
INSERT INTO "produits" VALUES(31,'Pendentif masque en laiton',4,'Pendentif masque en laiton. Bijou fait main, fermoir solide, livré dans une pochette.',12500,18,'img/bijoux.jpg','Ibrahim Njoya',1);
INSERT INTO "produits" VALUES(32,'Parure de perles',4,'Parure de perles. Bijou fait main, fermoir solide, livré dans une pochette.',15000,34,'img/bijoux.jpg','Marie Atangana',1);
INSERT INTO "produits" VALUES(33,'Vase en terre cuite',5,'Vase en terre cuite. Fabriqué à la main, finition naturelle pour la maison.',12000,13,'img/decoration.jpg','Paul Ngo Bassa',1);
INSERT INTO "produits" VALUES(34,'Lampe en rotin',5,'Lampe en rotin. Fabriqué à la main, finition naturelle pour la maison.',27500,2,'img/decoration.jpg','Rose Ekane',1);
INSERT INTO "produits" VALUES(35,'Miroir au cadre sculpté',5,'Miroir au cadre sculpté. Fabriqué à la main, finition naturelle pour la maison.',12000,32,'img/decoration.jpg','Rose Ekane',1);
INSERT INTO "produits" VALUES(36,'Corbeille en bambou',5,'Corbeille en bambou. Fabriqué à la main, finition naturelle pour la maison.',16500,28,'img/decoration.jpg','Paul Ngo Bassa',1);
INSERT INTO "produits" VALUES(37,'Bougeoir en laiton',5,'Bougeoir en laiton. Fabriqué à la main, finition naturelle pour la maison.',8000,37,'img/decoration.jpg','Kevin Tchoupo',1);
INSERT INTO "produits" VALUES(38,'Panier à linge tressé',5,'Panier à linge tressé. Fabriqué à la main, finition naturelle pour la maison.',6500,8,'img/decoration.jpg','Paul Ngo Bassa',1);
INSERT INTO "produits" VALUES(39,'Suspension en raphia',5,'Suspension en raphia. Fabriqué à la main, finition naturelle pour la maison.',8500,4,'img/decoration.jpg','Rose Ekane',1);
INSERT INTO "produits" VALUES(40,'Plateau en bois',5,'Plateau en bois. Fabriqué à la main, finition naturelle pour la maison.',17500,9,'img/decoration.jpg','Kevin Tchoupo',1);
CREATE INDEX idx_produits_categorie ON produits(categorie_id);
CREATE INDEX idx_commandes_statut   ON commandes(statut);
CREATE INDEX idx_lignes_commande    ON lignes_commande(commande_id);
DELETE FROM "sqlite_sequence";
INSERT INTO "sqlite_sequence" VALUES('categories',5);
INSERT INTO "sqlite_sequence" VALUES('produits',40);
INSERT INTO "sqlite_sequence" VALUES('codes_reduction',3);
INSERT INTO "sqlite_sequence" VALUES('commandes',60);
INSERT INTO "sqlite_sequence" VALUES('lignes_commande',155);
INSERT INTO "sqlite_sequence" VALUES('administrateurs',1);
COMMIT;
