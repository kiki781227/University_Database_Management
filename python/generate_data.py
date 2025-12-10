from faker import Faker
import pandas as pd
import random
import json
import os
from config import *
from noisy_data import professors_noisy, student_noisy


os.makedirs(OUTPUT_PATH, exist_ok=True)

fake = Faker()


json_path = os.path.join(SCRIPT_DIR, 'liste_depart_cours_club.json')
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

all_departments_courses = data['departments_courses']
all_club_names = data['club_names']

######################################################################################################################

# Générer Departments et Courses
selected_departments = random.sample(list(all_departments_courses.keys()), min(NUM_DEPARTMENTS, len(all_departments_courses)))
departments_data = []
courses_data = []
dept_id = 1
course_id = 1

for dept_name in selected_departments:
    departments_data.append({
        'DepartmentID': dept_id,
        'Name': dept_name,
        'HeadOfDepartment': None,  # Sera rempli après création des professeurs
        'student_fullname': MY_NAME
    })

    # Choisir NUM_COURSES_PER_DEPT cours au hasard pour ce département
    available_courses = all_departments_courses[dept_name]
    selected_courses = random.sample(available_courses, min(NUM_COURSES_PER_DEPT, len(available_courses)))
    for course_name in selected_courses:
        courses_data.append({
            'CourseID': course_id,
            'CourseName': course_name,
            'Credits': random.randint(1, 10), # Les crédits valident sont (1,3,6,8) mais randint(1,10) est utilisé pour générer du bruit
            'DepartmentID': dept_id,
            'student_fullname': MY_NAME
        })
        course_id += 1
    dept_id += 1

df_departments = pd.DataFrame(departments_data)
df_courses = pd.DataFrame(courses_data)

df_departments.to_csv(os.path.join(OUTPUT_PATH, 'departments.csv'), index=False, encoding='utf-8-sig')
df_courses.to_csv(os.path.join(OUTPUT_PATH, 'courses.csv'), index=False, encoding='utf-8-sig')
print(f"{len(df_departments)} départements générés -> departments.csv")
print(f"{len(df_courses)} cours générés -> courses.csv")

#######################################################################################################################

# Générer Professors
professors_data = []
for i in range(1, NUM_PROFESSORS + 1):
    name = fake.name() 
    email = name.replace(" ", ".").lower() + "@university.example"

    professors_data.append({
        'ProfessorID': i,
        'Name': name,
        'DepartmentID': random.randint(1, NUM_DEPARTMENTS),
        'Email': None, # A remplir avec des requêtes SQL plus tard (Tache A)
        'student_fullname': MY_NAME
    })

df_professors = pd.DataFrame(professors_data)
df_professors.to_csv(os.path.join(OUTPUT_PATH, 'professors.csv'), index=False, encoding='utf-8-sig')
print(f"{len(df_professors)} professeurs générés -> professors.csv")

#######################################################################################################################

# Mettre à jour HeadOfDepartment dans Departments
for i in range(len(df_departments)):
    # Choisir un professeur aléatoire du département (ou None pour certains)
    dept_id = df_departments.loc[i, 'DepartmentID']
    dept_professors = df_professors[df_professors['DepartmentID'] == dept_id]
    
    if len(dept_professors) > 0 and random.random() > 0.2:  # 80% ont un chef
        df_departments.loc[i, 'HeadOfDepartment'] = dept_professors.sample(1)['ProfessorID'].values[0]

df_departments.to_csv(os.path.join(OUTPUT_PATH, 'departments.csv'), index=False, encoding='utf-8-sig')
print(f"Départements mis à jour avec chefs")

#######################################################################################################################

# Générer Students
students_data = []
for i in range(1, NUM_STUDENTS + 1):
    dob = fake.date_of_birth(minimum_age=18, maximum_age=25)
    students_data.append({
        'StudentID': i,
        'Name': fake.name(),
        'Email': None, 
        'DOB': dob.strftime('%Y-%m-%d'),
        'student_fullname': MY_NAME
    })

df_students = pd.DataFrame(students_data)
df_students.to_csv(os.path.join(OUTPUT_PATH, 'students.csv'), index=False, encoding='utf-8-sig')
print(f"{len(df_students)} étudiants générés -> students.csv")

#######################################################################################################################

# Générer Enrollments
enrollments_data = []
enrollment_id = 1
cmpt_doublons = 0

for _ in range(NUM_ENROLLMENTS):
    student_id = random.randint(1, NUM_STUDENTS)
    total_courses = NUM_DEPARTMENTS * NUM_COURSES_PER_DEPT
    course_id = random.randint(1, total_courses)
    semester = random.randint(1, 4)
    
    # Éviter les doublons (même étudiant, même cours, même semestre)
    if not any(e['StudentID'] == student_id and e['CourseID'] == course_id and e['Semester'] == semester for e in enrollments_data):
        # 70% ont une note, 30% sont NULL (pas encore notés)
        grade = round(random.uniform(0, 100), 2) if random.random() > 0.3 else None
        
        enrollments_data.append({
            'EnrollmentID': enrollment_id,
            'StudentID': student_id,
            'CourseID': course_id,
            'Semester': semester,
            'Grade': grade,
            'student_fullname': MY_NAME
        })
        enrollment_id += 1
    else:
        cmpt_doublons += 1

df_enrollments = pd.DataFrame(enrollments_data)
df_enrollments.to_csv(os.path.join(OUTPUT_PATH, 'enrollments.csv'), index=False, encoding='utf-8-sig')
print(f"{len(df_enrollments)} inscriptions générées -> enrollments.csv | avec {cmpt_doublons} doublons évités")

#######################################################################################################################

# Générer Clubs
all_club_names = data['club_names']
club_names = random.sample(all_club_names, min(NUM_CLUBS, len(all_club_names)))
clubs_data = []
club_id = 1

for club_name in club_names:
    clubs_data.append({
        'ClubID': club_id,
        'ClubName': club_name,
        'Description': fake.sentence(nb_words=10),
        'student_fullname': MY_NAME
    })
    club_id += 1

df_clubs = pd.DataFrame(clubs_data)
df_clubs.to_csv(os.path.join(OUTPUT_PATH, 'clubs.csv'), index=False, encoding='utf-8-sig')
print(f"{len(df_clubs)} clubs générés -> clubs.csv")

#######################################################################################################################

# Générer StudentClubs 
student_clubs_data = []
generated_pairs = set()
cmpt_doublons = 0

for _ in range(NUM_STUDENT_CLUBS):
    student_id = random.randint(1, NUM_STUDENTS)
    club_id = random.randint(1, NUM_CLUBS)
    
    # Éviter les doublons
    pair = (student_id, club_id)
    if pair not in generated_pairs:
        generated_pairs.add(pair)
        student_clubs_data.append({
            'StudentID': student_id,
            'ClubID': club_id,
            'student_fullname': MY_NAME
        })
    else:
        cmpt_doublons += 1

df_student_clubs = pd.DataFrame(student_clubs_data)
df_student_clubs.to_csv(os.path.join(OUTPUT_PATH, 'student_clubs.csv'), index=False, encoding='utf-8-sig')
print(f"{len(student_clubs_data)} adhésions aux clubs générées -> student_clubs.csv | avec {cmpt_doublons} doublons évités")


professors_noisy(df_professors)
student_noisy(df_students)




