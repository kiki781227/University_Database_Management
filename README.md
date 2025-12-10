# Projet — Advanced Database (BD3)

Base de données universitaire pour le module **Advanced Database (BD3)**.

- SGBD : **SQL Server**
- Auteur : **RABENARIVO KIADY MANITRIALA**
- Tâches choisies : **Tâche A (Nettoyage & Requêtes avancées)** et **Tâche B (Programmabilité, Transactions & Monitoring)**

---

## 1. Contexte & objectifs

Ce mini-projet illustre l’usage de fonctionnalités avancées de bases de données relationnelles :

- concevoir et instancier une BDD complète ;
- générer et charger des **données synthétiques réalistes** (avec une colonne `student_fullname` dans chaque table) ;
- implémenter deux tâches avancées :  
  - **Tâche A** : nettoyage / formatage + requêtes avancées,  
  - **Tâche B** : procédures stockées, transactions, trigger d’audit et monitoring.

---

## 2. Schéma & génération de données

### 2.1 Schéma (vue d’ensemble)

Domaine choisi : **université**.  
Tables principales :

- `Departments` : départements académiques ;
- `Professors` : professeurs (FK vers Departments) ;
- `Students` : étudiants (email, date de naissance, etc.) ;
- `Courses` : cours (FK vers Departments, crédits) ;
- `Enrollments` : inscriptions étudiants–cours (notes, semestre) ;
- `Clubs` : clubs étudiants ;
- `StudentClubs` : appartenance des étudiants aux clubs.

> **Captures associées :** 
> - `Creation_BD/` *(diagramme et MCD)*


### 2.2 Génération & bruit

Les données sont générées par le script **`python/generate_data.py`** :

- utilisation de **Python + Faker** pour les noms, emails, dates ;
- utilisation d’un fichier JSON interne pour des noms de cours et de clubs plus réalistes **`python/liste_depart_cours_club.json`**;
- export d’un CSV par table dans le dossier `data/`.

Le script introduit aussi du **bruit** contrôlé (noms mal formatés, emails invalides, crédits aléatoires, etc.) pour justifier la phase de nettoyage SQL a l'aide du script **`python/noisy_data.py`**

> **Captures associées :** 
> - `Insertion_data/` *(avant et apres insertion + config insertion)*
---


## 3. Tâche A — Nettoyage & requêtes avancées

Scripts principaux : `sql/Task_A_cleaning.sql` et `sql/task_A_reports.sql`.

### 3.1 Nettoyage / formatage

Opérations réalisées dans `Task_A_cleaning.sql` :

- normalisation des noms (trim des espaces, casse cohérente) ;
- nettoyage des emails :
  - mise à `NULL` des emails invalides,
  - régénération d’emails propres à partir des noms (`nom@university.mu`) ;
- Gestion des doublons;
- harmonisation des crédits `Courses.Credits` vers un ensemble cohérent `{1, 3, 6, 8}`.

> **Captures associées :** 
> - `Nettoyage_Task_A/` *(avant avec bruit et apres nettoyage)*

### 3.2 Requêtes avancées (rapports)

Le script `task_A_reports.sql` contient plusieurs rapports, notamment :

- statistiques par département (nombre d’étudiants, professeurs, cours, moyenne des crédits, moyenne des notes) ;
- classement des étudiants par département (moyenne de notes + rang) ;
- PIVOT des crédits par département (répartition des cours selon 1/3/6/8 crédits) ;
- top des cours par moyenne de note (avec un minimum d’inscriptions).

Ces requêtes utilisent des **jointures**, **agrégats**, éventuellement **CTE** et **PIVOT**.

> **Captures associées :** 
> - `Requetes_avancees_Task_A/` *(
    Resultat screenshots : 
    Q1 : Statistiques globales par département,
    Q2 : Moyenne et classement des étudiants par département,
    Q3 : PIVOT - nombre de cours par département et par crédits (colonnes 1,3,6,8 crédits),
    Q4 : Top 5 des cours par moyenne de note
 )*

---

## 4. Tâche B — Programmabilité, transactions & monitoring

Scripts principaux : `sql/procedures_triggers_transactions.sql` et `sql/monitoring_script.sql`.

### 4.1 Procédures & transactions

- `sp_AddEnrollment` : inscrit un étudiant à un cours (avec contrôles métier et `TRY...CATCH` + `BEGIN TRAN / COMMIT / ROLLBACK`) ;
- `sp_RemoveEnrollment` : désinscrit un étudiant d’un cours.

Ces procédures garantissent la cohérence des opérations sur `Enrollments`.

> **Captures associées :** 
> - `Trigger_Procedures_Transaction_Task_B/`

### 4.2 Trigger d’audit

- Table `EnrollmentAudit` : journal des opérations sur `Enrollments` ;
- Trigger `trg_Enrollments_Audit` (AFTER INSERT/DELETE/UPDATE) :
- logue chaque modification d’inscription dans `EnrollmentAudit`.

> **Captures associées :** 
> - `Trigger_Procedures_Transaction_Task_B/`

### 4.3 Monitoring

Le script `monitoring_script.sql` interroge les DMV de SQL Server pour :

- suivre l’utilisation des index ;
- lister les requêtes actives et leurs temps d’exécution ;
- afficher les principaux types d’attentes (waits) sur l’instance.

> **Captures associées :** 
> - `Monitoring/` * (
    Resultat screenshots : 
    M1 : Utilisation des index,
    M2 : Lister les requêtes actives et leurs temps d’exécution,
    M3 : Afficher les principaux types d’attentes (waits) sur l’instance
)*

---

## 5. Reproduction du projet

### 5.1 Option 1 — Restaurer le backup

1. Créer une base vide (ou directement restaurer) dans SQL Server.
2. Restaurer le fichier `db/Kiady.bak` via SSMS.
3. La base est immédiatement exploitable.

### 5.2 Option 2 — Scripts SQL

Dans l’ordre :

1. `sql/DropTables.sql` (optionnel, pour repartir de zéro)  
2. `sql/create_tables.sql`  
3. `python/generate_data.py` pour régénérer les CSV dans `data/`  
4. `sql/insert_data.sql` (BULK INSERT depuis `data/`)  
5. `sql/Task_A_cleaning.sql` (nettoyage)  
6. `sql/procedures_triggers_transactions.sql` (procédures, trigger, table d’audit)  
7. `sql/monitoring_script.sql` (pour les requêtes de monitoring)

---

## 6. Structure des dossiers

- `sql/` : scripts SQL (création, insertion, nettoyage, requêtes avancées, procédures, trigger, monitoring)
- `python/` : scripts Python (`generate_data.py`, utilitaires)
- `data/` : fichiers CSV générés pour chaque table
- `db/` : backup SQL Server (`Kiady.bak`)
- `screenshots/` : captures avant/après (nettoyage, exécution des procédures, audit, monitoring)

---

## 7. Bonus — Interface Streamlit (optionnelle)

Une interface simple a été développée avec **Streamlit** pour :

- visualiser rapidement les tables principales (TOP 50 lignes) ;
- exécuter les rapports de la Tâche A ;
- tester les procédures d’inscription / désinscription (Tâche B) ;
- consulter la table d’audit et les vues de monitoring.

### Lancer l’interface

Installer streamlit :

```bash
python -m pip install streamlit
```

Depuis la racine du projet :

```bash
python -m streamlit run .\python\app.py
```

> **Captures associées :** 
> - `Bonus - Interface/`


## 8. Conclusion (résumé)

Le projet montre :

- la mise en place d’un schéma relationnel cohérent pour une université ;
- la génération et la dégradation contrôlée de données synthétiques ;
- le **nettoyage** et la **valorisation** de ces données via des requêtes avancées (Tâche A) ;
- l’usage de **procédures stockées**, de **transactions**, d’un **trigger d’audit** et du **monitoring** basé sur les DMV de SQL Server (Tâche B).

