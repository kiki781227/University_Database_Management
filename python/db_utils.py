import pyodbc
import pandas as pd
import warnings
from config import DB_SETTINGS


warnings.filterwarnings(
    "ignore",
    message="pandas only supports SQLAlchemy connectable",
    category=UserWarning
)


def get_connection():
    driver = DB_SETTINGS["driver"]
    server = DB_SETTINGS["server"]
    database = DB_SETTINGS["database"]

    if DB_SETTINGS.get("trusted_connection", "yes").lower() == "yes":
        conn_str = (
            f"DRIVER={driver};"
            f"SERVER={server};"
            f"DATABASE={database};"
            "Trusted_Connection=yes;"
        )
    else:
        username = DB_SETTINGS["username"]
        password = DB_SETTINGS["password"]
        conn_str = (
            f"DRIVER={driver};"
            f"SERVER={server};"
            f"DATABASE={database};"
            f"UID={username};"
            f"PWD={password};"
        )

    return pyodbc.connect(conn_str)


def run_select(query: str, params=None) -> pd.DataFrame:
    if params is None:
        params = []

    conn = get_connection()
    try:
        df = pd.read_sql(query, conn, params=params)
    finally:
        conn.close()
    return df


def run_non_query(query: str, params=None):
    if params is None:
        params = []

    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute(query, params)
        conn.commit()
    except Exception as e:
        conn.rollback()
        return str(e)
    finally:
        conn.close()

    return None


def run_sql_script(path: str):
    with open(path, "r", encoding="cp1252") as f: 
        script = f.read()

    # découpage sur les lignes "GO"
    blocks = []
    current = []
    for line in script.splitlines():
        if line.strip().upper() == "GO":
            if current:
                blocks.append("\n".join(current))
                current = []
        else:
            current.append(line)
    if current:
        blocks.append("\n".join(current))

    conn = get_connection()
    try:
        cur = conn.cursor()
        for block in blocks:
            sql = block.strip()
            if not sql:
                continue
            cur.execute(sql)
        conn.commit()
    except Exception as e:
        conn.rollback()
        raise e
    finally:
        conn.close()
