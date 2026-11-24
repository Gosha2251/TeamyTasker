import json
import os
import secrets
import subprocess
import threading
import time
import tkinter as tk
import urllib.error
import urllib.request
import webbrowser
from pathlib import Path

import pymysql


APP_NAME = "Team Task Planner"
APP_URL = "http://127.0.0.1:5000/welcome"

DB_HOST = "127.0.0.1"
DB_PORT = 3307
DB_USER = "root"
DB_NAME = "team_task_planner"

CREATE_NO_WINDOW = 0x08000000 if os.name == "nt" else 0

mariadb_process = None
database_started_by_launcher = False


def resource_path(*parts):
    """
    Atgriež ceļu uz projekta resursu.

    Darbojas gan parastajā Python režīmā,
    gan PyInstaller pakotnē.
    """
    base_path = Path(__file__).resolve().parent
    return base_path.joinpath(*parts)


def get_app_data_directory():
    """
    Programmas mainīgie dati tiek glabāti lietotāja
    LOCALAPPDATA mapē.
    """
    local_app_data = os.getenv("LOCALAPPDATA")

    if local_app_data:
        app_data = Path(local_app_data) / "TeamTaskPlanner"
    else:
        app_data = Path.home() / "TeamTaskPlanner"

    app_data.mkdir(
        parents=True,
        exist_ok=True
    )

    return app_data


APP_DATA_DIR = get_app_data_directory()

DB_DATA_DIR = APP_DATA_DIR / "mariadb-data"
CONFIG_FILE = APP_DATA_DIR / "config.json"

MARIADB_DIR = resource_path(
    "runtime",
    "mariadb"
)

MARIADB_BIN_DIR = MARIADB_DIR / "bin"

MARIADBD_EXE = MARIADB_BIN_DIR / "mariadbd.exe"
MARIADB_EXE = MARIADB_BIN_DIR / "mariadb.exe"
MARIADB_ADMIN_EXE = MARIADB_BIN_DIR / "mariadb-admin.exe"
MARIADB_INSTALL_DB_EXE = (
    MARIADB_BIN_DIR / "mariadb-install-db.exe"
)

SQL_FILE = resource_path(
    "database",
    "create_database.sql"
)


def load_or_create_config():
    """
    Izveido lokālo programmas konfigurāciju
    pirmajā palaišanas reizē.
    """
    if CONFIG_FILE.exists():

        with CONFIG_FILE.open(
            "r",
            encoding="utf-8"
        ) as file:

            return json.load(file)

    config = {
        "db_password": secrets.token_urlsafe(24),
        "secret_key": secrets.token_hex(32)
    }

    with CONFIG_FILE.open(
        "w",
        encoding="utf-8"
    ) as file:

        json.dump(
            config,
            file,
            indent=4
        )

    return config


CONFIG = load_or_create_config()

DB_PASSWORD = CONFIG["db_password"]
SECRET_KEY = CONFIG["secret_key"]


def configure_environment():
    """
    Norāda Flask aplikācijai portatīvās
    MariaDB savienojuma parametrus.
    """
    os.environ["DB_HOST"] = DB_HOST
    os.environ["DB_PORT"] = str(DB_PORT)
    os.environ["DB_USER"] = DB_USER
    os.environ["DB_PASSWORD"] = DB_PASSWORD
    os.environ["DB_NAME"] = DB_NAME
    os.environ["SECRET_KEY"] = SECRET_KEY


def check_required_files():
    """
    Pārbauda, vai MariaDB un SQL faili ir pieejami.
    """
    required_files = [
        MARIADBD_EXE,
        MARIADB_EXE,
        MARIADB_ADMIN_EXE,
        MARIADB_INSTALL_DB_EXE,
        SQL_FILE
    ]

    missing_files = [
        str(path)
        for path in required_files
        if not path.exists()
    ]

    if missing_files:

        missing_text = "\n".join(
            missing_files
        )

        raise FileNotFoundError(
            "Nav atrasti nepieciešamie faili:\n"
            f"{missing_text}"
        )


def database_is_ready():
    """
    Pārbauda, vai portatīvā MariaDB
    pieņem savienojumus.
    """
    try:

        connection = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            connect_timeout=1
        )

        connection.close()

        return True

    except pymysql.MySQLError:

        return False


def database_is_initialized():
    """
    Pārbauda, vai MariaDB data direktorijā
    jau ir izveidotas sistēmas tabulas.
    """
    mysql_directory = (
        DB_DATA_DIR / "mysql"
    )

    configuration_file = (
        DB_DATA_DIR / "my.ini"
    )

    return (
        mysql_directory.exists()
        and configuration_file.exists()
    )


def initialize_database_server():
    """
    Pirmajā palaišanas reizē inicializē
    portatīvo MariaDB instanci.
    """
    if database_is_initialized():
        return

    DB_DATA_DIR.mkdir(
        parents=True,
        exist_ok=True
    )

    command = [
        str(MARIADB_INSTALL_DB_EXE),
        f"--datadir={DB_DATA_DIR}",
        f"--password={DB_PASSWORD}",
        f"--port={DB_PORT}",
        "--silent"
    ]

    result = subprocess.run(
        command,
        cwd=str(MARIADB_DIR),
        capture_output=True,
        text=True,
        creationflags=CREATE_NO_WINDOW
    )

    if result.returncode != 0:

        raise RuntimeError(
            "Neizdevās inicializēt MariaDB.\n\n"
            f"{result.stdout}\n"
            f"{result.stderr}"
        )


def start_database_server():
    """
    Palaiž portatīvo MariaDB serveri.
    """
    global mariadb_process
    global database_started_by_launcher

    if database_is_ready():
        return

    configuration_file = (
        DB_DATA_DIR / "my.ini"
    )

    command = [
        str(MARIADBD_EXE),
        f"--defaults-file={configuration_file}",
        "--console"
    ]

    mariadb_process = subprocess.Popen(
        command,
        cwd=str(MARIADB_DIR),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=CREATE_NO_WINDOW
    )

    database_started_by_launcher = True

    for _ in range(60):

        if database_is_ready():
            return

        if mariadb_process.poll() is not None:

            raise RuntimeError(
                "MariaDB process negaidīti "
                "pārtrauca darbu."
            )

        time.sleep(0.25)

    raise RuntimeError(
        "MariaDB serveris netika palaists "
        "paredzētajā laikā."
    )


def application_database_exists():
    """
    Pārbauda, vai team_task_planner datubāze
    portatīvajā MariaDB jau eksistē.
    """
    connection = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        connect_timeout=3,
        cursorclass=pymysql.cursors.DictCursor
    )

    try:

        with connection.cursor() as cursor:

            cursor.execute(
                """
                SELECT SCHEMA_NAME
                FROM INFORMATION_SCHEMA.SCHEMATA
                WHERE SCHEMA_NAME = %s
                """,
                (DB_NAME,)
            )

            return (
                cursor.fetchone()
                is not None
            )

    finally:

        connection.close()


def create_application_database():
    """
    Izpilda create_database.sql tikai tad,
    ja projekta datubāze vēl neeksistē.
    """
    if application_database_exists():
        return

    with SQL_FILE.open(
        "r",
        encoding="utf-8"
    ) as sql_file:

        command = [
            str(MARIADB_EXE),
            f"--host={DB_HOST}",
            f"--port={DB_PORT}",
            f"--user={DB_USER}",
            f"--password={DB_PASSWORD}",
            "--default-character-set=utf8mb4"
        ]

        result = subprocess.run(
            command,
            stdin=sql_file,
            capture_output=True,
            text=True,
            creationflags=CREATE_NO_WINDOW
        )

    if result.returncode != 0:

        raise RuntimeError(
            "Neizdevās izveidot projekta "
            "datubāzi.\n\n"
            f"{result.stdout}\n"
            f"{result.stderr}"
        )


def run_flask_server():
    """
    Importē Flask aplikāciju tikai pēc tam,
    kad ir sagatavota portatīvā datubāze
    un vides mainīgie.
    """
    from app import run_server

    run_server()


def flask_is_ready():
    """
    Pārbauda, vai Flask serveris jau
    atbild uz HTTP pieprasījumiem.
    """
    try:

        with urllib.request.urlopen(
            APP_URL,
            timeout=1
        ):
            return True

    except (
        urllib.error.URLError,
        TimeoutError
    ):
        return False


def wait_for_flask():
    """
    Sagaida Flask servera palaišanos.
    """
    for _ in range(60):

        if flask_is_ready():
            return True

        time.sleep(0.25)

    return False


def stop_database_server():
    """
    Korekti aptur MariaDB serveri,
    ja launcher to ir palaidis.
    """
    global mariadb_process

    if not database_started_by_launcher:
        return

    try:

        command = [
            str(MARIADB_ADMIN_EXE),
            f"--host={DB_HOST}",
            f"--port={DB_PORT}",
            f"--user={DB_USER}",
            f"--password={DB_PASSWORD}",
            "shutdown"
        ]

        subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=10,
            creationflags=CREATE_NO_WINDOW
        )

    except (
        subprocess.SubprocessError,
        OSError
    ):
        pass

    if mariadb_process is not None:

        try:

            mariadb_process.wait(
                timeout=5
            )

        except subprocess.TimeoutExpired:

            mariadb_process.terminate()

            try:

                mariadb_process.wait(
                    timeout=3
                )

            except subprocess.TimeoutExpired:

                mariadb_process.kill()

        mariadb_process = None


def open_browser():
    """
    Atver Team Task Planner
    noklusējuma pārlūkprogrammā.
    """
    webbrowser.open(
        APP_URL,
        new=2
    )


def show_startup_error(
    database_status,
    application_status,
    message
):
    """
    Parāda kļūdas statusu launcher logā.
    """

    database_status.config(
        text="Datubāze: Kļūda",
        fg="#dc2626"
    )

    application_status.config(
        text="Programma: Kļūda",
        fg="#dc2626"
    )

    print(message)


def start_system(
    root,
    database_status,
    application_status,
    open_button
):
    """
    Pilna sistēmas startēšanas secība.

    Darbojas atsevišķā pavedienā,
    lai Tkinter logs neiesaltu.
    """
    try:

        check_required_files()

        root.after(
            0,
            lambda: database_status.config(
                text="Datubāze: Inicializējas...",
                fg="#fade24"
            )
        )

        initialize_database_server()

        root.after(
            0,
            lambda: database_status.config(
                text="Datubāze: Startējas...",
                fg="#fade24"
            )
        )

        start_database_server()

        create_application_database()

        root.after(
            0,
            lambda: database_status.config(
                text="Datubāze: Aktīva",
                fg="#fade24"
            )
        )

        configure_environment()

        root.after(
            0,
            lambda: application_status.config(
                text="Programma: Startējas...",
                fg="#fade24"
            )
        )

        flask_thread = threading.Thread(
            target=run_flask_server,
            daemon=True
        )

        flask_thread.start()

        if not wait_for_flask():

            raise RuntimeError(
                "Flask serveris netika palaists "
                "paredzētajā laikā."
            )

        root.after(
            0,
            lambda: application_status.config(
                text="Programma: Aktīva",
                fg="#fade24"
            )
        )

        root.after(
            0,
            lambda: open_button.config(
                state="normal"
            )
        )

    except Exception as error:

        error_message = str(error)

        root.after(
            0,
            lambda message=error_message:
            show_startup_error(
                database_status,
                application_status,
                message
            )
        )


def close_program(root):
    """
    Aptur portatīvo MariaDB
    un aizver launcher.
    """
    root.withdraw()

    stop_database_server()

    root.destroy()


def main():

    root = tk.Tk()

    root.title(APP_NAME)

    root.geometry(
        "560x430"
    )

    root.resizable(
        False,
        False
    )

    # Tava pamata fona krāsa.
    root.configure(
        bg="#302C2C"
    )


    # Programmas nosaukums
    title_label = tk.Label(
        root,
        text=APP_NAME,
        font=(
            "Segoe UI",
            20,
            "bold"
        ),
        bg="#302C2C",
        fg="white"
    )

    title_label.pack(
        pady=(30, 25)
    )


    # Statusu bloks
    status_frame = tk.Frame(
        root,
        bg="#302C2C"
    )

    status_frame.pack(
        fill="x",
        padx=45
    )


    # Datubāzes statuss
    database_status = tk.Label(
        status_frame,
        text="Datubāze: Gaida...",
        font=(
            "Segoe UI",
            12
        ),
        bg="#302C2C",
        fg="#fade24"
    )

    database_status.pack(
        anchor="w"
    )


    # Flask programmas statuss
    application_status = tk.Label(
        status_frame,
        text="Programma: Gaida...",
        font=(
            "Segoe UI",
            12
        ),
        bg="#302C2C",
        fg="#fade24"
    )

    application_status.pack(
        anchor="w",
        pady=(8, 0)
    )


    # Adreses virsraksts
    address_title = tk.Label(
        root,
        text="Adrese:",
        font=(
            "Segoe UI",
            11,
            "bold"
        ),
        bg="#302C2C",
        fg="#e5e7eb"
    )

    address_title.pack(
        anchor="w",
        padx=45,
        pady=(25, 5)
    )


    # Programmas URL
    address_label = tk.Label(
        root,
        text=APP_URL,
        font=(
            "Consolas",
            12,
            "underline"
        ),
        bg="#302C2C",
        fg="#4add6c",
        cursor="hand2"
    )

    address_label.pack(
        anchor="w",
        padx=45
    )

    address_label.bind(
        "<Button-1>",
        lambda event:
        open_browser()
    )


    # Atvērt pārlūkā poga
    open_button = tk.Button(
        root,
        text="Atvērt pārlūkā",
        command=open_browser,
        state="disabled",
        font=(
            "Segoe UI",
            11
        ),
        bg="#4add6c",
        fg="#292626",
        activebackground="#4aa54e",
        activeforeground="white",
        disabledforeground="#777777",
        relief="flat",
        padx=25,
        pady=9,
        cursor="hand2"
    )

    open_button.pack(
        pady=(25, 22)
    )


    # Tavs informatīvais bloks
    info_label = tk.Label(
        root,
        text=(
            "Programma darbojas, "
            "kamēr šis logs ir atvērts."
        ),
        font=(
            "Segoe UI",
            10
        ),
        bg="#c43b67",
        fg="#095be7"
    )

    info_label.pack(
        pady=(0, 22)
    )


    # Aizvērt poga
    close_button = tk.Button(
        root,
        text="Aizvērt",
        command=lambda:
        close_program(root),
        font=(
            "Segoe UI",
            10
        ),
        bg="#4add6c",
        fg="#292626",
        activebackground="#4aa54e",
        activeforeground="white",
        relief="flat",
        padx=25,
        pady=7,
        cursor="hand2"
    )

    close_button.pack()


    # Loga X poga
    root.protocol(
        "WM_DELETE_WINDOW",
        lambda:
        close_program(root)
    )


    # Pilnais DB + Flask starta process.
    startup_thread = threading.Thread(
        target=start_system,
        args=(
            root,
            database_status,
            application_status,
            open_button
        ),
        daemon=True
    )

    startup_thread.start()


    root.mainloop()


if __name__ == "__main__":
    main()