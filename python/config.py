import os

NUM_DEPARTMENTS = 20 # 40 Max
NUM_PROFESSORS = 30 
NUM_STUDENTS = 200
NUM_COURSES_PER_DEPT = 20 # environ 40  Max
NUM_CLUBS = 15 # 55 Max
NUM_ENROLLMENTS = 500
NUM_STUDENT_CLUBS = 70
MY_NAME = 'RABENARIVO KIADY MANITRIALA' 

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR) 
OUTPUT_PATH = os.path.join(PROJECT_ROOT, 'data')


SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))  
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)                
SQL_DIR = os.path.join(PROJECT_ROOT, "sql")               



DB_SETTINGS = {
    "driver": "{ODBC Driver 17 for SQL Server}",
    
    "server": "localhost\\SQLEXPRESS",
  
    "database": "Kiady",

    "trusted_connection": "yes",

    "username": "",
    "password": "",
}



