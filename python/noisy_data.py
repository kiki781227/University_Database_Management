from config import OUTPUT_PATH 
import pandas as pd
import random
import os

random.seed(1)  # même bruit

def student_noisy(students):

    # 10% des étudiants : espaces au début/fin du Name
    for idx in students.sample(frac=0.10, random_state=1).index:
        name = str(students.loc[idx, "Name"])
        students.loc[idx, "Name"] = "  " + name + "  "   # à nettoyer avec TRIM en SQL

    # 10% des étudiants : Name tout en MAJUSCULES ou minuscules
    for idx in students.sample(frac=1, random_state=2).index:
        name = str(students.loc[idx, "Name"])
        if random.random() < 0.5:
            students.loc[idx, "Name"] = name.upper()
        else:
            students.loc[idx, "Name"] = name.lower()

    # 50% des étudiants : création d'email + parfois cassé (sans @)
    for idx in students.sample(frac=0.50, random_state=4).index:
        name_clean = str(students.loc[idx, "Name"]).strip().lower().replace(" ", ".")
        if not name_clean:
            name_clean = f"student{idx}"
        email = name_clean + "@university.mu"

        # 60% de ces emails deviennent invalides (suppression de @)
        if random.random() < 0.6:
            email = email.replace("@", "")

        students.loc[idx, "Email"] = email

    students_noisy_path = os.path.join(OUTPUT_PATH, "students.csv")
    students.to_csv(students_noisy_path, index=False, encoding="utf-8-sig")
    print("OK -> students.csv avec noise")


def professors_noisy(professors):

    # 10% : espaces au début/fin du Name
    for idx in professors.sample(frac=0.10, random_state=5).index:
        name = str(professors.loc[idx, "Name"])
        professors.loc[idx, "Name"] = " " + name + " "

    # 20% : casse du Name modifiée
    for idx in professors.sample(frac=0.20, random_state=6).index:
        name = str(professors.loc[idx, "Name"])
        professors.loc[idx, "Name"] = name.upper() if random.random() < 0.5 else name.lower()

    # 50% : création/casse d'email
    for idx in professors.sample(frac=0.50, random_state=7).index:
        name_clean = str(professors.loc[idx, "Name"]).strip().lower().replace(" ", ".")
        if not name_clean:
            name_clean = f"prof{idx}"
        email = name_clean + "@university.mu"

        # 1/3 de ces emails invalides (sans @)
        r = random.random()
        if r < 0.33:
            email = email.replace("@", "")
        elif r < 0.66:
            email = " " + email  # espace au début
        # sinon on laisse l'email correct

        professors.loc[idx, "Email"] = email

    prof_noisy_path = os.path.join(OUTPUT_PATH, "professors.csv")
    professors.to_csv(prof_noisy_path, index=False, encoding="utf-8-sig")
    print("OK -> professors.csv avec noise")


    