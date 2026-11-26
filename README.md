
# TeamyTasker!

---

**TeamyTasker!** ir tīmekļa lietotne komandas uzdevumu organizēšanai un pārvaldībai.

Sistēmas ļauj reģistrēt lietotājus, izveidot komandu, pievienot dalībniekus, veidot un piešķirt uzdevumus, mainīt to statusu, pievienot komentārus un sekot komandas darba statistikai.

---

## Galvenā funkcionalitāte

- lietotāju reģistrācija un pieteikšanās;
- komandu izveide;
- komandas vadītāja tiesības;
- dalībnieku pievienošana un noņemšana;
- uzdevumu izveide, apskate, rediģēšana un dzēšana;
- uzdevumu piešķiršana komandas dalībniekiem;
- statusi `New`, `In Progress` un `Done`;
- komentāri pie uzdevumiem;
- komandas uzdevumu statistika;
- datu nodalīšana starp komandām.

---

## Izmantotās tehnoloģijas

- Python
- Flask
- MariaDB
- PyMySQL
- HTML / Jinja2
- CSS
- Werkzeug
- python-dotenv
- PyInstaller
- Git / GitHub

---

## Programmas palaišana

### Gatavā Windows versija

Gatavajā versijā nav nepieciešams atsevišķi instalēt Python vai MariaDB!

1. Atvērt `TeamyTasker` programmas mapi.
2. Palaist `TeamyTasker.exe`.
3. Gaidīt, līdz launcher logā parādās:

```text
Datubāze: Aktīva
Programma: Aktīva
```

4. Nospiest **Atvērt pārlūkā**.

*Programma tiek atvērta noklusējuma tīmekļa pārlūkprogrammā.*

**Svarīgi!**
*Launcher logam programmas lietošanas laikā jāpaliek atvērtam. Aizverot logu, programma pārtrauc darbību!*

---

### Palaišana no pirmkoda

1. Izveidot virtuālo vidi:

```cmd
python -m venv venv
```

2. Aktivizēt `.venv`:

```cmd
venv\Scripts\activate
```

3. Instalēt nepieciešamās pakotnes:

```cmd
pip install -r requirements.txt
```

4. Izveidot `.env` failu pēc `.env.example` parauga un konfigurēt MariaDB savienojumu.

5. Palaist programmu:

```cmd
python app.py
```

---

## Datubāze

Datubāzes sākotnējās struktūras izveides skripts:

```text
database/create_database.sql
```

*Gatavā portatīvā versija izmanto savu lokālo MariaDB instanci.*

## Dokumentācija

Detalizēta tehniskā dokumentācija atrodas:

```text
docs/documentation.md
```

---

# Saite uz Github repozitoriju

Github repo: https://github.com/Gosha2251/TeamyTasker

---
