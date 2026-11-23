# Virtuāls uzdevumu plānotājs komandai

Tīmekļa lietotne komandas darba un uzdevumu organizēšanai. Sistēma ļauj veidot komandas, pārvaldīt to dalībniekus, izveidot un piešķirt uzdevumus, sekot uzdevumu statusiem un pievienot komentārus.

## Galvenās funkcijas

- lietotāju reģistrācija un pieteikšanās;
- komandu izveide un dalībnieku pārvaldība;
- komandas vadītāja tiesības;
- uzdevumu izveide, apskate, rediģēšana un dzēšana;
- uzdevumu piešķiršana komandas dalībniekiem;
- statusi `New`, `In Progress` un `Done`;
- komentāri pie uzdevumiem;
- komandas uzdevumu statistika;
- piekļuves kontrole starp komandām.

## Tehnoloģijas

- Python
- Flask
- MariaDB
- PyMySQL
- HTML / Jinja2
- CSS
- Werkzeug
- python-dotenv
- Git / GitHub

## Projekta struktūra

```text
team-task-planner_byGosha/
│
├── database/
│   ├── create_database.sql
│   ├── db.py
│   └── team_task_planner_schema.sql
│
├── docs/
│   ├── documentation.md
│   ├── ER_diagramma_final.png
│   └── screenshots/
│
├── static/
│   └── css/
│       └── style.css
│
├── templates/
│
├── .env.example
├── .gitignore
├── app.py
├── README.md
└── requirements.txt
```

## Uzstādīšana un palaišana

Izveidot un aktivizēt virtuālo vidi:

```text
python -m venv venv
venv\Scripts\activate
```

Instalēt projektat atkarības:

```text
pip install -r requirements.txt
```

Izveidot MariaDB datubāzi, izmantojot:

```text
database/create_database.sql
```

izmantot konfigurācijas paraugu `.env.example`, kā `.env` un norādīt nepiecišamo DB konfigurāciju:

```text
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_database_password
DB_NAME=team_task_planner

SECRET_KEY=your_secret_key
```

Palaist programmu:

```text
python app.py
```

Atvērt pārlūkā:

```text
http://127.0.0.1:5000/welcome
```

## Dokumentācija

Detalizētāka projekta tehniskā dokumentācija:

```text
docs/documentation.md
```

## Autors

**Deniss Cvetkovs**  
