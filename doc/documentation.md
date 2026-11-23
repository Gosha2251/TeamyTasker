# Virtuāls uzdevumu plānotājs komandai

Tīmekļa lietotne komandas uzdevumu un dalībnieku pārvaldībai. Sistēma ļauj lietotājiem reģistrēties, veidot komandas, pārvaldīt uzdevumus, piešķirt tos komandas dalībniekiem un izmantot komentārus saziņai pie konkrētiem uzdevumiem.

---

## Galvenā funkcionalitāte

- lietotāju reģistrācija;
- pieteikšanās un izrakstīšanās;
- lietotāju sesijas;
- paroļu glabāšana hash formā;
- komandas izveide;
- komandas vadītāja tiesības;
- dalībnieku pievienošana un noņemšana;
- uzdevumu izveide, apskate, rediģēšana un dzēšana;
- uzdevumu piešķiršana komandas dalībniekiem;
- statusi `New`, `In Progress` un `Done`;
- komentāri pie uzdevumiem;
- komandas uzdevumu statistika;
- datu nodalīšana starp komandām.

---

## Tehnoloģijas

| Tehnoloģija | Pielietojums |
|---|---|
| Python | Programmas loģika |
| Flask | Tīmekļa lietotne un maršruti |
| MariaDB | Datubāze |
| PyMySQL | Savienojums starp Python un MariaDB |
| HTML / Jinja2 | Lietotāja saskarne |
| CSS | Saskarnes noformējums |
| Werkzeug | Paroļu hash izveide un pārbaude |
| python-dotenv | Vides mainīgo ielāde |
| Git / GitHub | Versiju kontrole |

---

## Projekta struktūra

```text
team-task-planner_byGosha/
│
├── database/
│   ├── create_database.sql
│   ├── db.py
│   └── team_task_planner_schema.sql
│
├── static/
│   └── css/
│       └── style.css
│
├── templates/
│   ├── add_task.html
│   ├── add_team_member.html
│   ├── base.html
│   ├── create_team.html
│   ├── edit_task.html
│   ├── index.html
│   ├── login.html
│   ├── register.html
│   ├── task_details.html
│   ├── tasks.html
│   ├── team.html
│   └── welcome.html
│
├── .env.example
├── .gitignore
├── app.py
├── README.md
└── requirements.txt
```

### Galvenie faili

- **`app.py`** — Flask aplikācijas galvenā loģika un maršruti.
- **`database/db.py`** — savienojums ar MariaDB.
- **`database/create_database.sql`** — datubāzes sākotnējās struktūras izveide.
- **`templates/`** — HTML/Jinja2 lapu veidnes.
- **`static/css/style.css`** — kopējais sistēmas vizuālais noformējums.
- **`.env.example`** — nepieciešamās konfigurācijas piemērs.
- **`requirements.txt`** — Python projekta atkarības.

---

## Datubāze

Projektā izmantota MariaDB datubāze.

Galvenās tabulas:

- `Users` — sistēmas lietotāji;
- `Teams` — komandas un to vadītāji;
- `Tasks` — komandas uzdevumi;
- `Status` — uzdevumu statusi;
- `Comments` — komentāri pie uzdevumiem.

### ER diagramma

*Skatīt mapē: doc/TTP_ER_Diagram.pdf*

Galvenās attiecības:

```text
Users.team_id        → Teams.id
Teams.owner_id       → Users.id

Tasks.status_id      → Status.id
Tasks.assigned_to    → Users.id
Tasks.team_id        → Teams.id

Comments.task_id     → Tasks.id
Comments.user_id     → Users.id
```

---

## Kā sistēma darbojas

Vienkāršota datu plūsma:

```text
Pārlūkprogramma
      ↓
HTML / Jinja2
      ↓
Flask
      ↓
PyMySQL
      ↓
MariaDB
```

---

## Autentifikācija

Lietotāja parole pirms saglabāšanas datubāzē tiek pārveidota par paroles hash.

Pieteikšanās laikā ievadītā parole tiek salīdzināta ar datubāzē saglabāto hash.

Pēc veiksmīgas pieteikšanās Flask sesijā tiek saglabāts lietotāja ID, vārds un e-pasta adrese.

Aizsargātajiem maršrutiem tiek izmantota pieteikšanās pārbaude. Lietotājs bez aktīvas sesijas tiek novirzīts uz `/login`.

---

## Komandas

Lietotājs var izveidot komandu, ja lietotājs vēl nav pievienots citai komandai.

Komandas izveidotājs kļūst par komandas vadītāju.

Vadītājs var:

- pievienot reģistrētus lietotājus komandai;
- noņemt dalībniekus no komandas.

Parastam komandas dalībniekam šīs pārvaldības funkcijas nav pieejamas.

---

## Uzdevumi

Uzdevumu modulī realizētas CRUD operācijas:

```text
Create  → izveidot
Read    → apskatīt
Update  → rediģēt
Delete  → dzēst
```

Uzdevumam tiek glabāts:

- nosaukums;
- apraksts;
- statuss;
- atbildīgais;
- komanda;
- izveides laiks.

Atbildīgo iespējams izvēlēties tikai no konkrētās komandas dalībniekiem.

Lietotāji var apskatīt un pārvaldīt tikai savas komandas uzdevumus.

---

## Komentāri

Komentāri tiek piesaistīti konkrētam uzdevumam un lietotājam.

Komentāra autora ID tiek iegūts no aktīvās lietotāja sesijas.

Pirms komentāra saglabāšanas tiek pārbaudīts, vai konkrētais uzdevums pieder lietotāja komandai.

---

## Statistika

Komandas skatā tiek attēlota aktuālā uzdevumu statistika:

- uzdevumi kopā;
- `New`;
- `In Progress`;
- `Done`.

Statistika tiek aprēķināta no MariaDB datiem un automātiski mainās, mainoties uzdevumu statusiem.

---

## Konfigurācija

Privātie konfigurācijas dati tiek glabāti `.env` failā.

Piemērs atrodas:

```text
.env.example
```

Nepieciešamie parametri:

```text
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_database_password
DB_NAME=team_task_planner

SECRET_KEY=your_secret_key
```

`.env` fails netiek glabāts Git repozitorijā.

---

## Uzstādīšana

### 1. Izveido virtuālo vidi

```text
python -m venv venv
```

Windows:

```text
venv\Scripts\activate
```

### 2. Instalē atkarības

```text
pip install -r requirements.txt
```

### 3. Izveido datubāzi

MariaDB serverim jābūt palaistam.

Izmanto:

```text
database/create_database.sql
```

### 4. Konfigurē `.env`

Nokopē `.env.example`, pārdēvē par `.env` un norādi savas MariaDB savienojuma vērtības.

### 5. Palaid aplikāciju

```text
python app.py
```

Atver:

```text
http://127.0.0.1:5000/welcome
```

---

## Testēšana

Programmai veikta manuāla funkcionālā testēšana.

Pārbaudītas:

- reģistrācija;
- pieteikšanās un izrakstīšanās;
- komandas izveide;
- dalībnieku pārvaldība;
- uzdevumu CRUD operācijas;
- statusu maiņa;
- komentāri;
- statistika;
- ievades validācija;
- piekļuves tiesības;
- dažādu komandu datu izolācija.

Sagatavotajos funkcionālajos testos galvenā sistēmas funkcionalitāte darbojās atbilstoši paredzētajam.

---

## Ekrānuzņēmumi

### Sākumlapa

**[Ievietot `01_welcome.png`]**

### Reģistrācija

**[Ievietot `02_register.png`]**

### Galvenā lapa

**[Ievietot `03_dashboard.png`]**

### Uzdevumi

**[Ievietot `04_tasks.png`]**

### Uzdevuma detaļas un komentāri

**[Ievietot `05_task_details.png`]**

### Komanda un statistika

**[Ievietot `06_team.png`]**

### Uzdevuma pievienošana

**[Ievietot `07_add_task.png`]**

---

## Iespējamie uzlabojumi

Projektu iespējams papildināt ar:

- uzdevumu termiņiem;
- prioritātēm;
- meklēšanu;
- uzdevumu filtrēšanu;
- papildu lietotāju lomām;
- paziņojumiem;
- paroles atjaunošanu;
- automātiskajiem testiem.

---

## Noderīgas saites

- [Flask dokumentācija](https://flask.palletsprojects.com/)
- [MariaDB dokumentācija](https://mariadb.com/docs/)
- [Python dokumentācija](https://docs.python.org/)
- [Werkzeug dokumentācija](https://werkzeug.palletsprojects.com/)
- [PyMySQL dokumentācija](https://pymysql.readthedocs.io/)

---

## Autors

**Deniss Cvetkovs**  
