import os
from flask import Flask, render_template, request, redirect, session
from dotenv import load_dotenv
from database.db import get_connection
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps

load_dotenv()

app = Flask(__name__)
app.config["SECRET_KEY"] = os.getenv("SECRET_KEY")

if not app.config["SECRET_KEY"]:
    raise RuntimeError(
        "SECRET_KEY nav norādīta .env failā."
    )

def login_required(view_function):
    @wraps(view_function)
    def wrapped_view(*args, **kwargs):

        if "user_id" not in session:
            return redirect("/login")

        return view_function(*args, **kwargs)

    return wrapped_view

@app.route("/welcome")
def welcome():
    if "user_id" in session:
        return redirect("/")

    return render_template("welcome.html")

@app.route("/")
@login_required
def home():
    return render_template("index.html")

@app.route("/tasks")
@login_required
def tasks():
    user_id = session["user_id"]

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam pieteiktā lietotāja komandu.
            cursor.execute("""
                SELECT team_id
                FROM Users
                WHERE id = %s
            """, (user_id,))

            current_user = cursor.fetchone()

            if current_user is None:
                return "Lietotājs nav atrasts.", 404

            if current_user["team_id"] is None:
                return render_template(
                    "tasks.html",
                    tasks=[],
                    no_team=True
                )

            team_id = current_user["team_id"]

            # Rādām TIKAI pašreizējās komandas uzdevumus.
            cursor.execute("""
                SELECT
                    t.id,
                    t.title,
                    t.description,
                    t.created_at,
                    s.name AS status,
                    u.name AS assigned_user
                FROM Tasks t
                JOIN Status s
                    ON t.status_id = s.id
                LEFT JOIN Users u
                    ON t.assigned_to = u.id
                WHERE t.team_id = %s
                ORDER BY t.id DESC
            """, (team_id,))

            tasks = cursor.fetchall()

    finally:
        connection.close()

    return render_template(
        "tasks.html",
        tasks=tasks,
        no_team=False
    )


@app.route("/tasks/add", methods=["GET", "POST"])
@login_required
def add_task():
    user_id = session["user_id"]
    error = None

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam pieteiktā lietotāja komandu.
            cursor.execute("""
                SELECT team_id
                FROM Users
                WHERE id = %s
            """, (user_id,))

            current_user = cursor.fetchone()

            if current_user is None or current_user["team_id"] is None:
                return "Lai izveidotu uzdevumu, vispirms jāpievienojas komandai.", 403

            team_id = current_user["team_id"]

            # Iegūstam visas komandas dalībniekus.
            cursor.execute("""
                SELECT
                    id,
                    name,
                    email
                FROM Users
                WHERE team_id = %s
                ORDER BY name
            """, (team_id,))

            members = cursor.fetchall()

            # Iegūstam iespējamos statusus.
            cursor.execute("""
                SELECT id, name
                FROM Status
                ORDER BY id
            """)

            statuses = cursor.fetchall()

            if request.method == "POST":

                title = request.form["title"].strip()
                description = request.form["description"].strip()
                status_id = request.form["status_id"]
                assigned_to = request.form["assigned_to"]

                if not title:
                    error = "Uzdevuma nosaukums nedrīkst būt tukšs."

                else:
                    # Drošības pārbaude:
                    # atbildīgajam jābūt tās pašas komandas dalībniekam.
                    cursor.execute("""
                        SELECT id
                        FROM Users
                        WHERE id = %s
                          AND team_id = %s
                    """, (
                        assigned_to,
                        team_id
                    ))

                    assigned_user = cursor.fetchone()

                    if assigned_user is None:
                        error = "Izvēlētais lietotājs nav tavas komandas dalībnieks."

                    else:
                        cursor.execute("""
                            INSERT INTO Tasks
                            (
                                title,
                                description,
                                status_id,
                                assigned_to,
                                team_id
                            )
                            VALUES
                            (%s, %s, %s, %s, %s)
                        """, (
                            title,
                            description,
                            status_id,
                            assigned_to,
                            team_id
                        ))

                        connection.commit()

                        return redirect("/tasks")

    finally:
        connection.close()

    return render_template(
        "add_task.html",
        members=members,
        statuses=statuses,
        error=error
    )

@app.route("/tasks/<int:task_id>")
@login_required
def task_details(task_id):
    user_id = session["user_id"]

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam pieteiktā lietotāja komandu.
            cursor.execute("""
                SELECT team_id
                FROM Users
                WHERE id = %s
            """, (user_id,))

            current_user = cursor.fetchone()

            if current_user is None:
                return "Lietotājs nav atrasts.", 404

            if current_user["team_id"] is None:
                return "Tu neesi pievienots nevienai komandai.", 403

            team_id = current_user["team_id"]

            # Atļaujam apskatīt tikai savas komandas uzdevumu.
            cursor.execute("""
                SELECT
                    t.id,
                    t.title,
                    t.description,
                    t.created_at,
                    s.name AS status,
                    u.name AS assigned_user,
                    tm.name AS team_name
                FROM Tasks t
                JOIN Status s
                    ON t.status_id = s.id
                LEFT JOIN Users u
                    ON t.assigned_to = u.id
                JOIN Teams tm
                    ON t.team_id = tm.id
                WHERE t.id = %s
                  AND t.team_id = %s
            """, (
                task_id,
                team_id
            ))

            task = cursor.fetchone()

            if task is None:
                return "Uzdevums nav atrasts vai nepieder tavai komandai.", 404

            # Nolasa komentārus kopā ar autora vārdu.
            cursor.execute("""
                SELECT
                    c.id,
                    c.text,
                    c.created_at,
                    c.user_id,
                    u.name AS author_name
                FROM Comments c
                JOIN Users u
                    ON c.user_id = u.id
                WHERE c.task_id = %s
                ORDER BY c.created_at ASC, c.id ASC
            """, (task_id,))

            comments = cursor.fetchall()

    finally:
        connection.close()

    return render_template(
        "task_details.html",
        task=task,
        comments=comments
    )

@app.route("/tasks/<int:task_id>/comments/add", methods=["POST"])
@login_required
def add_comment(task_id):
    user_id = session["user_id"]
    text = request.form.get("text", "").strip()

    if not text:
        return redirect(f"/tasks/{task_id}")

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam pieteiktā lietotāja komandu.
            cursor.execute("""
                SELECT team_id
                FROM Users
                WHERE id = %s
            """, (user_id,))

            current_user = cursor.fetchone()

            if current_user is None:
                return "Lietotājs nav atrasts.", 404

            if current_user["team_id"] is None:
                return "Tu neesi pievienots nevienai komandai.", 403

            team_id = current_user["team_id"]

            # Pārbaudām, vai komentējamais uzdevums
            # tiešām pieder lietotāja komandai.
            cursor.execute("""
                SELECT id
                FROM Tasks
                WHERE id = %s
                  AND team_id = %s
            """, (
                task_id,
                team_id
            ))

            task = cursor.fetchone()

            if task is None:
                return "Uzdevums nav atrasts vai nepieder tavai komandai.", 404

            cursor.execute("""
                INSERT INTO Comments
                (
                    task_id,
                    user_id,
                    text
                )
                VALUES
                (%s, %s, %s)
            """, (
                task_id,
                user_id,
                text
            ))

            connection.commit()

    finally:
        connection.close()

    return redirect(f"/tasks/{task_id}")

@app.route("/tasks/<int:task_id>/edit", methods=["GET", "POST"])
@login_required
def edit_task(task_id):
    user_id = session["user_id"]
    error = None

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam lietotāja komandu.
            cursor.execute("""
                SELECT team_id
                FROM Users
                WHERE id = %s
            """, (user_id,))

            current_user = cursor.fetchone()

            if current_user is None:
                return "Lietotājs nav atrasts.", 404

            if current_user["team_id"] is None:
                return "Tu neesi pievienots nevienai komandai.", 403

            team_id = current_user["team_id"]

            # Meklējam uzdevumu TIKAI lietotāja komandā.
            cursor.execute("""
                SELECT
                    id,
                    title,
                    description,
                    status_id,
                    assigned_to
                FROM Tasks
                WHERE id = %s
                  AND team_id = %s
            """, (
                task_id,
                team_id
            ))

            task = cursor.fetchone()

            if task is None:
                return "Uzdevums nav atrasts vai nepieder tavai komandai.", 404

            # Statusi dropdown sarakstam.
            cursor.execute("""
                SELECT id, name
                FROM Status
                ORDER BY id
            """)

            statuses = cursor.fetchall()

            # TIKAI pašreizējās komandas dalībnieki.
            cursor.execute("""
                SELECT
                    id,
                    name,
                    email
                FROM Users
                WHERE team_id = %s
                ORDER BY name
            """, (team_id,))

            members = cursor.fetchall()

            if request.method == "POST":
                title = request.form["title"].strip()
                description = request.form["description"].strip()
                status_id = request.form["status_id"]
                assigned_to = request.form["assigned_to"]

                if not title:
                    error = "Uzdevuma nosaukums nedrīkst būt tukšs."

                else:
                    # Pārbaudām, ka izvēlētais atbildīgais
                    # tiešām pieder šai komandai.
                    cursor.execute("""
                        SELECT id
                        FROM Users
                        WHERE id = %s
                          AND team_id = %s
                    """, (
                        assigned_to,
                        team_id
                    ))

                    assigned_user = cursor.fetchone()

                    if assigned_user is None:
                        error = "Izvēlētais lietotājs nav tavas komandas dalībnieks."

                    else:
                        cursor.execute("""
                            UPDATE Tasks
                            SET
                                title = %s,
                                description = %s,
                                status_id = %s,
                                assigned_to = %s
                            WHERE id = %s
                              AND team_id = %s
                        """, (
                            title,
                            description,
                            status_id,
                            assigned_to,
                            task_id,
                            team_id
                        ))

                        connection.commit()

                        return redirect(f"/tasks/{task_id}")

    finally:
        connection.close()

    return render_template(
        "edit_task.html",
        task=task,
        statuses=statuses,
        users=members,
        error=error
    )

@app.route("/tasks/<int:task_id>/delete", methods=["POST"])
@login_required
def delete_task(task_id):
    user_id = session["user_id"]

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam lietotāja komandu.
            cursor.execute("""
                SELECT team_id
                FROM Users
                WHERE id = %s
            """, (user_id,))

            current_user = cursor.fetchone()

            if current_user is None:
                return "Lietotājs nav atrasts.", 404

            if current_user["team_id"] is None:
                return "Tu neesi pievienots nevienai komandai.", 403

            team_id = current_user["team_id"]

            # Dzēšam tikai savas komandas uzdevumu.
            cursor.execute("""
                DELETE FROM Tasks
                WHERE id = %s
                  AND team_id = %s
            """, (
                task_id,
                team_id
            ))
            
            if cursor.rowcount == 0:
                return "Uzdevums nav atrasts vai nepieder tavai komandai.", 404
            
            connection.commit()

    finally:
        connection.close()

    return redirect("/tasks")


@app.route("/team")
@login_required
def team():
    user_id = session["user_id"]

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Lietotāja komanda un komandas vadītājs
            cursor.execute("""
                SELECT
                    u.team_id,
                    t.name AS team_name,
                    t.owner_id
                FROM Users u
                LEFT JOIN Teams t
                    ON u.team_id = t.id
                WHERE u.id = %s
            """, (user_id,))

            team_data = cursor.fetchone()

            is_owner = False
            members = []

            statistics = {
                "total": 0,
                "new": 0,
                "in_progress": 0,
                "done": 0
            }

            if team_data and team_data["team_id"]:

                team_id = team_data["team_id"]

                # Pārbaudām, vai pašreizējais lietotājs
                # ir komandas vadītājs
                if team_data["owner_id"] == user_id:
                    is_owner = True


                # Komandas dalībnieki
                cursor.execute("""
                    SELECT
                        id,
                        name,
                        email
                    FROM Users
                    WHERE team_id = %s
                    ORDER BY name
                """, (team_id,))

                members = cursor.fetchall()


                # Komandas uzdevumu statistika
                cursor.execute("""
                    SELECT
                        COUNT(*) AS total,

                        SUM(
                            CASE
                                WHEN s.name = 'New'
                                THEN 1
                                ELSE 0
                            END
                        ) AS new_count,

                        SUM(
                            CASE
                                WHEN s.name = 'In Progress'
                                THEN 1
                                ELSE 0
                            END
                        ) AS in_progress_count,

                         SUM(
                            CASE
                                WHEN s.name = 'Done'
                                THEN 1
                                ELSE 0
                            END
                        ) AS done_count

                    FROM Tasks t

                    JOIN Status s
                        ON t.status_id = s.id

                    WHERE t.team_id = %s
                """, (team_id,))

                stats_result = cursor.fetchone()

                if stats_result:
                    statistics = {
                        "total": stats_result["total"] or 0,
                        "new": stats_result["new_count"] or 0,
                        "in_progress": stats_result["in_progress_count"] or 0,
                        "done": stats_result["done_count"] or 0
                    }

    finally:
       connection.close()

    return render_template(
        "team.html",
        team=team_data,
        members=members,
        is_owner=is_owner,
        statistics=statistics
    )

@app.route("/team/create", methods=["GET", "POST"])
@login_required
def create_team():
    error = None

    if request.method == "POST":
        team_name = request.form["team_name"].strip()

        if not team_name:
            error = "Komandas nosaukums nedrīkst būt tukšs."

        else:
            connection = get_connection()

            try:
                with connection.cursor() as cursor:

                    # Pārbaudām, vai lietotājam jau nav komandas
                    cursor.execute("""
                        SELECT team_id
                        FROM Users
                        WHERE id = %s
                    """, (session["user_id"],))

                    user = cursor.fetchone()

                    if user and user["team_id"] is not None:
                        error = "Tu jau esi pievienots komandai."

                    else:
                        # Izveidojam komandu
                        cursor.execute("""
                            INSERT INTO Teams (name, owner_id)
                            VALUES (%s, %s)
                        """, (
                            team_name,
                            session["user_id"]
                        ))

                        team_id = cursor.lastrowid


                        # Piesaistām izveidotāju jaunajai komandai
                        cursor.execute("""
                            UPDATE Users
                            SET team_id = %s
                            WHERE id = %s
                        """, (
                            team_id,
                            session["user_id"]
                        ))

                        connection.commit()

            finally:
                connection.close()

            if error is None:
                return redirect("/team")

    return render_template(
        "create_team.html",
        error=error
    )

@app.route("/team/add-member", methods=["GET", "POST"])
@login_required
def add_team_member():
    error = None
    success = None
    user_id = session["user_id"]

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam pieteiktā lietotāja komandu
            # un pārbaudām, vai lietotājs ir tās vadītājs.
            cursor.execute("""
                SELECT
                    t.id AS team_id,
                    t.name AS team_name,
                    t.owner_id
                FROM Teams t
                JOIN Users u
                    ON u.team_id = t.id
                WHERE u.id = %s
            """, (user_id,))

            team = cursor.fetchone()

            if team is None:
                return "Tev nav komandas.", 403

            if team["owner_id"] != user_id:
                return "Tikai komandas vadītājs var pievienot dalībniekus.", 403

            if request.method == "POST":
                email = request.form["email"].strip().lower()

                if not email:
                    error = "Ievadi lietotāja e-pasta adresi."

                else:
                    # Meklējam reģistrētu lietotāju.
                    cursor.execute("""
                        SELECT
                            id,
                            name,
                            email,
                            team_id
                        FROM Users
                        WHERE email = %s
                    """, (email,))

                    member = cursor.fetchone()

                    if member is None:
                        error = "Lietotājs ar šādu e-pasta adresi nav atrasts."

                    elif member["id"] == user_id:
                        error = "Tu jau esi šīs komandas vadītājs."

                    elif member["team_id"] == team["team_id"]:
                        error = "Šis lietotājs jau ir tavā komandā."

                    elif member["team_id"] is not None:
                        error = "Šis lietotājs jau ir pievienots citai komandai."

                    else:
                        cursor.execute("""
                            UPDATE Users
                            SET team_id = %s
                            WHERE id = %s
                        """, (
                            team["team_id"],
                            member["id"]
                        ))

                        connection.commit()

                        success = (
                            f'Lietotājs {member["name"]} '
                            'veiksmīgi pievienots komandai.'
                        )

    finally:
        connection.close()

    return render_template(
        "add_team_member.html",
        error=error,
        success=success
    )

@app.route("/team/remove-member/<int:member_id>", methods=["POST"])
@login_required
def remove_team_member(member_id):
    user_id = session["user_id"]

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            # Noskaidrojam pieteiktā lietotāja komandu
            # un pārbaudām vadītāja tiesības.
            cursor.execute("""
                SELECT
                    t.id AS team_id,
                    t.owner_id
                FROM Teams t
                JOIN Users u
                    ON u.team_id = t.id
                WHERE u.id = %s
            """, (user_id,))

            team = cursor.fetchone()

            if team is None:
                return "Tev nav komandas.", 403

            if team["owner_id"] != user_id:
                return "Tikai komandas vadītājs var noņemt dalībniekus.", 403

            # Vadītājs pats sevi noņemt nedrīkst.
            if member_id == user_id:
                return "Komandas vadītāju nevar noņemt no savas komandas.", 400

            # Pārbaudām, vai norādītais lietotājs tiešām
            # atrodas šajā komandā.
            cursor.execute("""
                SELECT
                    id,
                    name,
                    team_id
                FROM Users
                WHERE id = %s
            """, (member_id,))

            member = cursor.fetchone()

            if member is None:
                return "Lietotājs nav atrasts.", 404

            if member["team_id"] != team["team_id"]:
                return "Šis lietotājs nav tavas komandas dalībnieks.", 403

            # Noņemam lietotāju no viņam piešķirtajiem
            # šīs komandas uzdevumiem.
            cursor.execute("""
                UPDATE Tasks
                SET assigned_to = NULL
                WHERE assigned_to = %s
                    AND team_id = %s
            """, (
                member_id,
                team["team_id"]
            ))

            # Izņemam lietotāju no komandas.
            cursor.execute("""
                UPDATE Users
                SET team_id = NULL
                WHERE id = %s
            """, (member_id,))

            connection.commit()

    finally:
        connection.close()

    return redirect("/team")

@app.route("/register", methods=["GET", "POST"])
def register():

    error = None

    if request.method == "POST":

        name = request.form["name"].strip()
        email = request.form["email"].strip().lower()
        password = request.form["password"]
        password_confirm = request.form["password_confirm"]

        # Pamatvalidācija
        if not name:
            error = "Lūdzu, ievadi vārdu."

        elif not email:
            error = "Lūdzu, ievadi e-pasta adresi."

        elif not password:
            error = "Lūdzu, ievadi paroli."

        elif len(password) < 6:
            error = "Parolei jābūt vismaz 6 rakstzīmes garai."

        elif password != password_confirm:
            error = "Ievadītās paroles nesakrīt."

        else:
            connection = get_connection()

            try:
                with connection.cursor() as cursor:

                    # Pārbaudām, vai e-pasts jau nav reģistrēts
                    cursor.execute("""
                        SELECT id
                        FROM Users
                        WHERE email = %s
                    """, (email,))

                    existing_user = cursor.fetchone()

                    if existing_user:
                        error = "Lietotājs ar šādu e-pasta adresi jau eksistē."

                    else:
                        password_hash = generate_password_hash(password)

                        cursor.execute("""
                            INSERT INTO Users
                            (
                                name,
                                email,
                                password,
                                team_id
                            )
                            VALUES
                            (%s, %s, %s, NULL)
                        """, (
                            name,
                            email,
                            password_hash
                        ))

                        connection.commit()

            finally:
                connection.close()

            if error is None:
                return redirect("/login")

    return render_template(
        "register.html",
        error=error
    )

@app.route("/login", methods=["GET", "POST"])
def login():
    error = None

    if request.method == "POST":
        email = request.form["email"].strip().lower()
        password = request.form["password"]

        connection = get_connection()

        try:
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT
                        id,
                        name,
                        email,
                        password,
                        team_id
                    FROM Users
                    WHERE email = %s
                """, (email,))

                user = cursor.fetchone()

        finally:
            connection.close()

        if user is None:
            error = "Nepareizs e-pasts vai parole."

        elif not check_password_hash(user["password"], password):
            error = "Nepareizs e-pasts vai parole."

        else:
            session.clear()
            session.permanent = False

            session["user_id"] = user["id"]
            session["user_name"] = user["name"]
            session["user_email"] = user["email"]

            return redirect("/")

    return render_template(
        "login.html",
        error=error
    )

@app.route("/logout")
def logout():
    session.clear()
    return redirect("/welcome")

def run_server():
    app.run(
        host="127.0.0.1",
        port=5000,
        debug=False,
        use_reloader=False
    )


if __name__ == "__main__":
    run_server()