# RHEL 9 Admin Dashboard

A small web page for managing **users and groups** on a RHEL 9 machine.
The real work is done by **Bash scripts**; a tiny Flask app (`app.py`) only logs you in, calls the scripts and shows the result.

![Users page](docs/users-page.png)
*(screenshot uses sample data)*

## How it works

```
Browser  ->  app.py (login, forms)  ->  bash_scripts/*.sh  ->  useradd, usermod, groupadd, ...
                     ^                          |
                     +---- JSON / messages -----+
```

| Script | What it does |
|---|---|
| `users.sh`, `groups.sh` | Print users / groups as **JSON** (read `/etc/passwd`, `/etc/group` with `awk`) |
| `user_count.sh`, `groups_count.sh` | Print how many regular users / groups exist |
| `user_add.sh` | Create a user (password read from **stdin**) |
| `group_add.sh` | Create a group |
| `change_user_details.sh` | Change full name, shell, home, lock or unlock a user |
| `change_group_details.sh` | Rename a group, add or remove a member |
| `lib.sh` | Shared helpers: `die`, `check_name`, `require_root`, protection of system accounts |

"Regular" users and groups means ID 1000-59999. `root` and other system accounts are hidden and cannot be changed.

## Run it (use a practice VM, not a production server)

```bash
sudo dnf install -y python3 python3-pip
pip3 install -r requirements.txt

# 1. choose a dashboard password (12+ characters) and make its hash
export DASHBOARD_PASSWORD_HASH="$(python3 -c 'import getpass; from werkzeug.security import generate_password_hash as g; print(g(getpass.getpass()))')"

# 2. start it. Adding/changing users needs root, so run with sudo (keeps the variable with -E)
sudo -E python3 app.py        # then open http://127.0.0.1:5000  (user: admin)
```

It listens on `127.0.0.1` only. To use it from another PC, use an SSH tunnel: `ssh -L 5000:127.0.0.1:5000 your-server`.

## Run the tests

```bash
bash tests/run_tests.sh                 # Bash scripts (read-only + input checks)
sudo bash tests/run_tests.sh            # ...plus real create/modify/delete of a throw-away user and group
python3 -m unittest discover -s tests   # Python side
```

## Safety notes

- Scripts validate every name, refuse system accounts, and never edit `/etc/passwd` by hand (they use `useradd`, `usermod`, `groupadd`, ...).
- Passwords are sent through **stdin**, never as arguments (arguments are visible in `ps`).
- Python starts scripts with an argument **list**, so no shell can interpret user input.
- Login required, forms have CSRF tokens, debug mode is off, secrets come from environment variables.
- Running the whole app as root is acceptable on a practice VM but not on a real server; a production setup would run unprivileged and allow only specific commands through `sudoers`.
