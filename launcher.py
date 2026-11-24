import threading
import time
import tkinter as tk
import webbrowser
import urllib.request
import urllib.error

from app import run_server


APP_NAME = "Team Task Planner"
APP_URL = "http://127.0.0.1:5000/welcome"


def server_is_ready():
    try:
        with urllib.request.urlopen(APP_URL, timeout=1):
            return True

    except (urllib.error.URLError, TimeoutError):
        return False


def wait_for_server(root, status_label, open_button):
    """
    Gaida, līdz Flask serveris sāk atbildēt.
    Pēc tam GUI galvenajā pavedienā atjaunina statusu.
    """

    for _ in range(30):

        if server_is_ready():
            root.after(
                0,
                lambda: set_server_ready(
                    status_label,
                    open_button
                )
            )
            return

        time.sleep(0.2)

    root.after(
        0,
        lambda: set_server_error(
            status_label
        )
    )


def set_server_ready(status_label, open_button):
    status_label.config(
        text="Statuss: Aktīvs",
        fg="#fade24"
    )

    open_button.config(
        state="normal"
    )


def set_server_error(status_label):
    status_label.config(
        text="Statuss: Kļūda",
        fg="#dc2626"
    )


def open_browser():
    webbrowser.open(
        APP_URL,
        new=2
    )


def close_program(root):
    root.destroy()


def main():
    root = tk.Tk()

    root.title(APP_NAME)
    root.geometry("560x400")
    root.resizable(False, False)

    root.configure(
        bg="#302C2C"
    )


    # Programmas nosaukums
    title_label = tk.Label(
        root,
        text=APP_NAME,
        font=("Segoe UI", 20, "bold"),
        bg="#302C2C",
        fg="white"
    )

    title_label.pack(
        pady=(30, 25)
    )


    # Servera statuss
    status_label = tk.Label(
        root,
        text="Statuss: Startējas...",
        font=("Segoe UI", 12),
        bg="#302C2C",
        fg="#f59e0b"
    )

    status_label.pack(
        anchor="w",
        padx=45
    )


    # Adreses nosaukums
    address_title = tk.Label(
        root,
        text="Adrese:",
        font=("Segoe UI", 11, "bold"),
        bg="#302C2C",
        fg="#e5e7eb"
    )

    address_title.pack(
        anchor="w",
        padx=45,
        pady=(27, 5)
    )


    # URL
    address_label = tk.Label(
        root,
        text=APP_URL,
        font=("Consolas", 12, "underline"),
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
        lambda event: open_browser()
    )


    # Atvērt pārlūkā poga
    open_button = tk.Button(
        root,
        text="Atvērt pārlūkā",
        command=open_browser,
        state="disabled",
        font=("Segoe UI", 11),
        bg="#4add6c",
        fg="#292626",
        activebackground="#4aa54e",
        activeforeground="white",
        relief="flat",
        padx=25,
        pady=9,
        cursor="hand2"
    )

    open_button.pack(
        pady=(25, 25)
    )


    # Informatīvais teksts
    info_label = tk.Label(
        root,
        text=(
            "Programma darbojas, kamēr šis logs ir atvērts."
        ),
        font=("Segoe UI", 10),
        bg="#c43b67",
        fg="#095be7"
    )

    info_label.pack(
        pady=(0, 25)
    )


    # Aizvērt poga
    close_button = tk.Button(
        root,
        text="Aizvērt",
        command=lambda: close_program(root),
        font=("Segoe UI", 10),
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


    # Aizverot logu ar X, aizveram launcher.
    root.protocol(
        "WM_DELETE_WINDOW",
        lambda: close_program(root)
    )


    # Flask palaižam atsevišķā pavedienā,
    # lai Tkinter logs neiesaltu.
    flask_thread = threading.Thread(
        target=run_server,
        daemon=True
    )

    flask_thread.start()


    # Citā pavedienā gaidām, līdz serveris reāli sāk atbildēt.
    wait_thread = threading.Thread(
        target=wait_for_server,
        args=(
            root,
            status_label,
            open_button
        ),
        daemon=True
    )

    wait_thread.start()


    root.mainloop()


if __name__ == "__main__":
    main()