# RHEL 9 Admin Dashboard

A small Flask web dashboard that runs Bash scripts to perform administration tasks on a RHEL 9 system.

## What it does

<!-- Fill in from your own code. Examples: show disk and memory usage, list running services,
     restart a service, list users, show logs. Keep it to what really works. -->
- add and edit users
- add and edit groups
- show all groups and users

## Tech stack

Python, Flask, Bash, Linux (RHEL 9)

## How it works

```
Browser  ->  Flask (app.py)  ->  Bash scripts (bash_scripts/)  ->  RHEL 9 system
```

The Flask routes call the scripts in `bash_scripts/` and show the result in the templates.

## Run it

```bash
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python app.py
```

Open http://localhost:5000

## Security notes

- The scripts run commands on the server, so run this only on a machine you own
- Do not expose it to the internet without authentication
- Review every script before running it

## Screenshots

![Dashboard](docs/dashboard.png)

## What I learned

- [one or two real lessons, e.g. calling shell scripts safely from Python]

## Next steps

- [ ] Add login
- [ ] Add a Dockerfile
- [ ] Add a CI check
