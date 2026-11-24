import os

import pymysql
from dotenv import load_dotenv


load_dotenv()


def get_connection(database=None):
    connection_database = database

    if connection_database is None:
        connection_database = os.getenv(
            "DB_NAME",
            "team_task_planner"
        )

    return pymysql.connect(
        host=os.getenv("DB_HOST", "127.0.0.1"),
        port=int(os.getenv("DB_PORT", "3306")),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", ""),
        database=connection_database,
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=False
    )