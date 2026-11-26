import json
import os
import secrets
import subprocess
import sys
import threading
import time
import tkinter as tk
import urllib.error
import urllib.request
import webbrowser

from pathlib import Path
from tkinter import messagebox

import pymysql


# ============================================================
# Programmas pamatkonfigurācija
# ============================================================

APP_NAME = "TeamyTasker!"
APP_URL = "http://127.0.0.1:5000/welcome"

DB_HOST = "127.0.0.1"
DB_PORT = 3307
DB_USER = "root"
DB_NAME = "team_task_planner"

CREATE_NO_WINDOW = (
    0x08000000
    if os.name == "nt"
    else 0
)


# ============================================================
# Globālie mainīgie
# ============================================================

mariadb_process = None
mariadb_log_handle = None
database_started_by_launcher = False


# ============================================================
# Failu un mapju ceļi
# ============================================================

def resource_path(*parts):
    """
    Atgriež ceļu uz programmas ārējiem resursiem.

    Izstrādes režīmā resursi atrodas projekta mapē.

    PyInstaller EXE režīmā runtime un database mapes
    atrodas blakus TeamTaskPlanner.exe.
    """

    if getattr(sys, "frozen", False):
        base_path = Path(
            sys.executable
        ).resolve().parent

    else:
        base_path = Path(
            __file__
        ).resolve().parent

    return base_path.joinpath(*parts)


def get_app_data_directory():
    """
    Izveido programmas datu mapi lietotāja LOCALAPPDATA.

    Šajā mapē glabājas:
    - portatīvās MariaDB dati;
    - automātiski ģenerētā DB parole;
    - Flask SECRET_KEY;
    - launcher kļūdu žurnāls;
    - MariaDB žurnāls.
    """

    local_app_data = os.getenv(
        "LOCALAPPDATA"
    )

    if local_app_data:

        app_data_directory = (
            Path(local_app_data)
            / "TeamTaskPlanner"
        )

    else:

        app_data_directory = (
            Path.home()
            / "TeamTaskPlanner"
        )

    app_data_directory.mkdir(
        parents=True,
        exist_ok=True
    )

    return app_data_directory


APP_DATA_DIR = get_app_data_directory()

DB_DATA_DIR = (
    APP_DATA_DIR
    / "mariadb-data"
)

CONFIG_FILE = (
    APP_DATA_DIR
    / "config.json"
)

LAUNCHER_LOG_FILE = (
    APP_DATA_DIR
    / "launcher_error.log"
)

MARIADB_LOG_FILE = (
    APP_DATA_DIR
    / "mariadb.log"
)


# ============================================================
# MariaDB failu atrašanās vietas
# ============================================================

MARIADB_DIR = resource_path(
    "runtime",
    "mariadb"
)

MARIADB_BIN_DIR = (
    MARIADB_DIR
    / "bin"
)

MARIADBD_EXE = (
    MARIADB_BIN_DIR
    / "mariadbd.exe"
)

MARIADB_EXE = (
    MARIADB_BIN_DIR
    / "mariadb.exe"
)

MARIADB_ADMIN_EXE = (
    MARIADB_BIN_DIR
    / "mariadb-admin.exe"
)

MARIADB_INSTALL_DB_EXE = (
    MARIADB_BIN_DIR
    / "mariadb-install-db.exe"
)

SQL_FILE = resource_path(
    "database",
    "create_database.sql"
)

ICON_FILE = resource_path(
    "assets",
    "TeamyTasker.ico"
    )

# ============================================================
# Lokālā konfigurācija
# ============================================================

def load_or_create_config():
    """
    Nolasa esošo Team Task Planner konfigurāciju.

    Ja konfigurācija vēl neeksistē, tiek automātiski
    ģenerēta MariaDB root parole un Flask SECRET_KEY.
    """

    if CONFIG_FILE.exists():

        try:

            with CONFIG_FILE.open(
                "r",
                encoding="utf-8"
            ) as file:

                config = json.load(file)

            if (
                config.get("db_password")
                and config.get("secret_key")
            ):
                return config

        except (
            OSError,
            json.JSONDecodeError
        ):
            pass

    config = {
        "db_password": (
            secrets.token_urlsafe(24)
        ),
        "secret_key": (
            secrets.token_hex(32)
        )
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
    Iestata portatīvās aplikācijas vides mainīgos.

    Šīs vērtības pārraksta .env konfigurāciju tikai
    pašreizējā launcher procesa laikā.
    """

    os.environ["DB_HOST"] = DB_HOST
    os.environ["DB_PORT"] = str(DB_PORT)
    os.environ["DB_USER"] = DB_USER
    os.environ["DB_PASSWORD"] = DB_PASSWORD
    os.environ["DB_NAME"] = DB_NAME
    os.environ["SECRET_KEY"] = SECRET_KEY


# ============================================================
# Kļūdu žurnāls
# ============================================================

def write_launcher_log(message):
    """
    Saglabā launcher kļūdas tekstu LOCALAPPDATA mapē.
    """

    try:

        with LAUNCHER_LOG_FILE.open(
            "w",
            encoding="utf-8"
        ) as file:

            file.write(message)

    except OSError:
        pass


# ============================================================
# Nepieciešamo failu pārbaude
# ============================================================

def check_required_files():
    """
    Pārbauda MariaDB un SQL failu pieejamību.
    """

    required_files = [
        MARIADBD_EXE,
        MARIADB_EXE,
        MARIADB_ADMIN_EXE,
        MARIADB_INSTALL_DB_EXE,
        SQL_FILE
    ]

    missing_files = []

    for file_path in required_files:

        if not file_path.exists():
            missing_files.append(
                str(file_path)
            )

    if missing_files:

        missing_text = "\n".join(
            missing_files
        )

        raise FileNotFoundError(
            "Nav atrasti nepieciešamie faili:\n\n"
            f"{missing_text}\n\n"
            "Pārbaudi, vai blakus EXE atrodas "
            "runtime un database mapes."
        )


# ============================================================
# MariaDB inicializācija
# ============================================================

def database_is_initialized():
    """
    Pārbauda, vai MariaDB sistēmas tabulas
    jau ir izveidotas.
    """

    mysql_directory = (
        DB_DATA_DIR
        / "mysql"
    )

    configuration_file = (
        DB_DATA_DIR
        / "my.ini"
    )

    return (
        mysql_directory.exists()
        and configuration_file.exists()
    )


def initialize_database_server():
    """
    Pirmajā palaišanas reizē inicializē
    neatkarīgu portatīvo MariaDB instanci.
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

        output = (
            f"STDOUT:\n{result.stdout}\n\n"
            f"STDERR:\n{result.stderr}"
        )

        raise RuntimeError(
            "Neizdevās inicializēt "
            "portatīvo MariaDB.\n\n"
            f"{output}"
        )

    if not database_is_initialized():

        raise RuntimeError(
            "MariaDB inicializācijas process beidzās, "
            "bet nepieciešamie sistēmas faili netika "
            "izveidoti.\n\n"
            f"Datu mape:\n{DB_DATA_DIR}"
        )


# ============================================================
# MariaDB palaišana
# ============================================================

def database_is_ready():
    """
    Pārbauda, vai portatīvā MariaDB atbild uz porta 3307.
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


def start_database_server():
    """
    Palaiž portatīvo MariaDB serveri.
    """

    global mariadb_process
    global mariadb_log_handle
    global database_started_by_launcher

    if database_is_ready():
        return

    configuration_file = (
        DB_DATA_DIR
        / "my.ini"
    )

    if not configuration_file.exists():

        raise FileNotFoundError(
            "Nav atrasts portatīvās MariaDB "
            "konfigurācijas fails:\n\n"
            f"{configuration_file}"
        )

    command = [
        str(MARIADBD_EXE),
        f"--defaults-file={configuration_file}",
        "--console"
    ]

    try:

        mariadb_log_handle = (
            MARIADB_LOG_FILE.open(
                "a",
                encoding="utf-8"
            )
        )

        mariadb_process = subprocess.Popen(
            command,
            cwd=str(MARIADB_DIR),
            stdout=mariadb_log_handle,
            stderr=mariadb_log_handle,
            creationflags=CREATE_NO_WINDOW
        )

    except OSError as error:

        if mariadb_log_handle is not None:
            mariadb_log_handle.close()
            mariadb_log_handle = None

        raise RuntimeError(
            "Neizdevās palaist mariadbd.exe.\n\n"
            f"{error}"
        ) from error

    database_started_by_launcher = True

    for _ in range(80):

        if database_is_ready():
            return

        if (
            mariadb_process is not None
            and mariadb_process.poll() is not None
        ):

            raise RuntimeError(
                "MariaDB process negaidīti "
                "pārtrauca darbu.\n\n"
                "Detalizēta informācija saglabāta:\n"
                f"{MARIADB_LOG_FILE}"
            )

        time.sleep(0.25)

    raise RuntimeError(
        "MariaDB serveris netika palaists "
        "paredzētajā laikā.\n\n"
        "Detalizēta informācija saglabāta:\n"
        f"{MARIADB_LOG_FILE}"
    )


# ============================================================
# Aplikācijas datubāzes izveide
# ============================================================

def application_database_exists():
    """
    Pārbauda, vai portatīvajā MariaDB jau
    eksistē team_task_planner datubāze.
    """

    connection = pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        connect_timeout=3,
        cursorclass=(
            pymysql.cursors.DictCursor
        )
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
    ja aplikācijas datubāze vēl neeksistē.
    """

    if application_database_exists():
        return

    if not SQL_FILE.exists():

        raise FileNotFoundError(
            "Nav atrasts datubāzes SQL fails:\n\n"
            f"{SQL_FILE}"
        )

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
            "Neizdevās izveidot Team Task Planner "
            "datubāzi.\n\n"
            f"STDOUT:\n{result.stdout}\n\n"
            f"STDERR:\n{result.stderr}"
        )

    if not application_database_exists():

        raise RuntimeError(
            "SQL fails tika izpildīts, bet "
            "team_task_planner datubāze netika atrasta."
        )


# ============================================================
# Flask serveris
# ============================================================

def run_flask_server():
    """
    Importē Flask aplikāciju tikai pēc tam,
    kad datubāze un vides mainīgie ir sagatavoti.
    """

    from app import run_server

    run_server()


def flask_is_ready():
    """
    Pārbauda, vai Flask atbild uz lokālo URL.
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

    for _ in range(80):

        if flask_is_ready():
            return True

        time.sleep(0.25)

    return False


# ============================================================
# MariaDB apturēšana
# ============================================================

def stop_database_server():
    """
    Korekti aptur MariaDB, ja launcher to palaida.
    """

    global mariadb_process
    global mariadb_log_handle
    global database_started_by_launcher

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

    if mariadb_log_handle is not None:

        try:
            mariadb_log_handle.close()

        except OSError:
            pass

        mariadb_log_handle = None

    database_started_by_launcher = False


# ============================================================
# Launcher darbības
# ============================================================

def open_browser():
    """
    Atver aplikāciju noklusējuma pārlūkprogrammā.
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
    Parāda kļūdu launcher logā, Windows paziņojumā
    un saglabā pilno tekstu launcher_error.log.
    """

    database_status.config(
        text="Datubāze: Kļūda",
        fg="#dc2626"
    )

    application_status.config(
        text="Programma: Kļūda",
        fg="#dc2626"
    )

    write_launcher_log(message)

    messagebox.showerror(
        "Team Task Planner kļūda",
        (
            f"{message}\n\n"
            "Kļūdas žurnāls:\n"
            f"{LAUNCHER_LOG_FILE}"
        )
    )


def start_system(
    root,
    database_status,
    application_status,
    open_button
):
    """
    Pilna sistēmas palaišanas secība.

    Funkcija darbojas atsevišķā pavedienā,
    lai Tkinter logs startēšanas laikā neiesaltu.
    """

    current_stage = "Failu pārbaude"

    try:

        check_required_files()

        current_stage = "MariaDB inicializācija"

        root.after(
            0,
            lambda: database_status.config(
                text="Datubāze: Inicializējas...",
                fg="yellow"
            )
        )

        initialize_database_server()

        current_stage = "MariaDB palaišana"

        root.after(
            0,
            lambda: database_status.config(
                text="Datubāze: Startējas...",
                fg="yellow"
            )
        )

        start_database_server()

        current_stage = "Aplikācijas DB izveide"

        create_application_database()

        root.after(
            0,
            lambda: database_status.config(
                text="Datubāze: Aktīva",
                fg="limegreen"
            )
        )

        current_stage = "Flask konfigurācija"

        configure_environment()

        root.after(
            0,
            lambda: application_status.config(
                text="Programma: Startējas...",
                fg="yellow"
            )
        )

        current_stage = "Flask palaišana"

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
                fg="limegreen"
            )
        )

        root.after(
            0,
            lambda: open_button.config(
                state="normal",
                cursor="hand2"
            )
        )

    except Exception as error:

        error_message = (
            f"Posms: {current_stage}\n\n"
            f"{type(error).__name__}: {error}"
        )

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
    Aptur portatīvo MariaDB un aizver launcher.
    """

    root.withdraw()

    stop_database_server()

    root.destroy()


# ============================================================
# Launcher lietotāja saskarne
# ============================================================

def main():
    root = tk.Tk()

    root.title(APP_NAME)

    if ICON_FILE.exists():
        try:
            root.iconbitmap(
                str(ICON_FILE)
            )
        except tk.TclError:
            pass

    root.geometry("560x430")
    root.resizable(False, False)
    root.configure(bg="#302C2C")


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
        fg="limegreen"
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
        fg="orange"
    )

    database_status.pack(
        anchor="w"
    )


    # Programmas statuss
    application_status = tk.Label(
        status_frame,
        text="Programma: Gaida...",
        font=(
            "Segoe UI",
            12
        ),
        bg="#302C2C",
        fg="orange"
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
        fg="limegreen"
    )

    address_title.pack(
        anchor="w",
        padx=45,
        pady=(25, 5)
    )


    # URL
    address_label = tk.Label(
        root,
        text=APP_URL,
        font=(
            "Consolas",
            12,
            "underline"
        ),
        bg="black",
        fg="limegreen",
        cursor="hand2"
    )

    address_label.pack(
        anchor="w",
        padx=45
    )

    address_label.bind(
        "<Button-1>",
        lambda event: open_browser()
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
        bg="limegreen",
        fg="black",
        activebackground="#4aa54e",
        activeforeground="white",
        disabledforeground="#777777",
        relief="flat",
        padx=25,
        pady=9,
        cursor="arrow"
    )

    open_button.pack(
        pady=(25, 22)
    )


    # Informatīvais teksts
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
        bg="#302C2C",
        fg="limegreen",
    )

    info_label.pack(
        pady=(0, 22)
    )


    # Aizvērt poga
    close_button = tk.Button(
        root,
        text="Aizvērt",
        command=lambda: close_program(root),
        font=(
            "Segoe UI",
            10
        ),
        bg="limegreen",
        fg="black",
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
        lambda: close_program(root)
    )


    # DB un Flask startēšana atsevišķā pavedienā
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